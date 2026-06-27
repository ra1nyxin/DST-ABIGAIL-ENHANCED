local _G = GLOBAL
local SpawnPrefab = _G.SpawnPrefab
local Vector3 = _G.Vector3
local IsEntityElectricImmune = _G.IsEntityElectricImmune
local LightningStrikeAttack = _G.LightningStrikeAttack
local TheSim = _G.TheSim

local SHOCK_INTERVAL = 2
local LIGHT_RADIUS_MULT = 4
local LIGHT_REFRESH_INTERVAL = 1
local ABIGAIL_SPEED_MULT = 1.5
local TARGET_SLOW_MULT = 0.5
local TARGET_SLOW_DURATION = 60
local PLAYER_REGEN_INTERVAL = 10
local PLAYER_REGEN_RADIUS = 6
local PLAYER_REGEN_AMOUNT = 1
local ABIGAIL_SPEED_KEY = "dst_abigail_enhanced_speed"
local TARGET_SLOW_KEY = "dst_abigail_enhanced_slow"
local PLAYER_REGEN_MUST_TAGS = { "player" }
local PLAYER_REGEN_CANT_TAGS = { "INLIMBO", "playerghost" }

local function StopTargetLightning(inst)
    if inst._dae_lightning_task ~= nil then
        inst._dae_lightning_task:Cancel()
        inst._dae_lightning_task = nil
    end

    if inst._dae_lightning_target ~= nil then
        if inst._dae_on_target_death ~= nil then
            inst:RemoveEventCallback("death", inst._dae_on_target_death, inst._dae_lightning_target)
        end

        if inst._dae_on_target_removed ~= nil then
            inst:RemoveEventCallback("onremove", inst._dae_on_target_removed, inst._dae_lightning_target)
        end

        inst._dae_lightning_target = nil
    end
end

local function IsValidShockTarget(inst, target)
    return inst ~= nil
        and inst:IsValid()
        and not inst:IsInLimbo()
        and inst.components.health ~= nil
        and not inst.components.health:IsDead()
        and inst.components.combat ~= nil
        and target ~= nil
        and target:IsValid()
        and not target:IsInLimbo()
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and inst.components.combat.target == target
end

local function StrikeTargetWithLightning(target)
    local x, y, z = target.Transform:GetWorldPosition()

    local lightning = SpawnPrefab("lightning")
    if lightning ~= nil then
        lightning.Transform:SetPosition(x, y, z)
    end

    local hit_player = false
    if target.components.playerlightningtarget ~= nil then
        target.components.playerlightningtarget:DoStrike()
        hit_player = true
    else
        LightningStrikeAttack(target)
    end

    if not IsEntityElectricImmune(target) and target.lightning_strike_cb ~= nil then
        target.lightning_strike_cb(target, {
            hit_player = hit_player,
            pos = Vector3(x, y, z),
        })
    end
end

local function ShockCurrentTarget(inst)
    local target = inst._dae_lightning_target
    if not IsValidShockTarget(inst, target) then
        StopTargetLightning(inst)
        return
    end

    StrikeTargetWithLightning(target)
end

local function StartTargetLightning(inst, target)
    if inst._dae_lightning_target == target and inst._dae_lightning_task ~= nil then
        return
    end

    StopTargetLightning(inst)
    if not IsValidShockTarget(inst, target) then
        return
    end

    inst._dae_lightning_target = target
    inst:ListenForEvent("death", inst._dae_on_target_death, target)
    inst:ListenForEvent("onremove", inst._dae_on_target_removed, target)

    ShockCurrentTarget(inst)
    if inst._dae_lightning_target == target then
        inst._dae_lightning_task = inst:DoPeriodicTask(SHOCK_INTERVAL, ShockCurrentTarget, SHOCK_INTERVAL)
    end
end

local function OnNewCombatTarget(inst, data)
    local target = data ~= nil and data.target or nil
    if target == nil and inst.components.combat ~= nil then
        target = inst.components.combat.target
    end

    StartTargetLightning(inst, target)
end

local function OnDroppedTarget(inst, data)
    if inst._dae_lightning_target == nil then
        return
    end

    if data == nil or data.target == nil or data.target == inst._dae_lightning_target then
        StopTargetLightning(inst)
    end
end

local function ApplyAbigailImmunities(inst)
    inst:AddTag("electricdamageimmune")
    inst:AddTag("fireimmune")

    if inst.components.health ~= nil then
        inst.components.health.externalfiredamagemultipliers:SetModifier(inst, 0)
    end
end

local function RemoveTargetSlow(target)
    if target._dae_slow_task ~= nil then
        target._dae_slow_task:Cancel()
        target._dae_slow_task = nil
    end

    if target.components.locomotor ~= nil then
        target.components.locomotor:RemoveExternalSpeedMultiplier(target, TARGET_SLOW_KEY)
    end
end

local function ApplyTargetSlow(target)
    if target == nil or not target:IsValid() or target.components.locomotor == nil then
        return
    end

    if target._dae_slow_cleanup_registered ~= true then
        target._dae_slow_cleanup_registered = true
        target:ListenForEvent("death", RemoveTargetSlow)
        target:ListenForEvent("onremove", RemoveTargetSlow)
    end

    RemoveTargetSlow(target)
    target.components.locomotor:SetExternalSpeedMultiplier(target, TARGET_SLOW_KEY, TARGET_SLOW_MULT)
    target._dae_slow_task = target:DoTaskInTime(TARGET_SLOW_DURATION, RemoveTargetSlow)
end

local function OnAbigailHitOther(inst, data)
    local target = data ~= nil and data.target or nil
    if target ~= nil then
        ApplyTargetSlow(target)
    end
end

local function ApplyAbigailSpeedBoost(inst)
    if inst.components.locomotor ~= nil then
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, ABIGAIL_SPEED_KEY, ABIGAIL_SPEED_MULT)
    end
end

local function RefreshAbigailLight(inst)
    if inst.Light == nil then
        return
    end

    local level = 1
    if inst._playerlink ~= nil and inst._playerlink.components.ghostlybond ~= nil then
        level = inst._playerlink.components.ghostlybond.bondlevel
    end

    local light_vals = _G.TUNING.ABIGAIL_LIGHTING[level] or _G.TUNING.ABIGAIL_LIGHTING[1]
    if light_vals ~= nil and light_vals.r ~= nil then
        inst.Light:SetRadius(light_vals.r * LIGHT_RADIUS_MULT)
    end
end

local function RestoreNearbyPlayers(inst)
    if not inst:IsValid()
        or inst:IsInLimbo()
        or inst.components.health == nil
        or inst.components.health:IsDead()
    then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    local players = TheSim:FindEntities(
        x,
        y,
        z,
        PLAYER_REGEN_RADIUS,
        PLAYER_REGEN_MUST_TAGS,
        PLAYER_REGEN_CANT_TAGS
    )

    for _, player in ipairs(players) do
        if player.components.health ~= nil and not player.components.health:IsDead() then
            player.components.health:DoDelta(PLAYER_REGEN_AMOUNT, false, "abigail_enhanced")
        end

        if player.components.hunger ~= nil then
            player.components.hunger:DoDelta(PLAYER_REGEN_AMOUNT)
        end

        if player.components.sanity ~= nil then
            player.components.sanity:DoDelta(PLAYER_REGEN_AMOUNT)
        end
    end
end

local function IsAbigailGroundItemHaunt(target, haunter)
    return haunter ~= nil
        and haunter.prefab == "abigail"
        and target ~= nil
        and target:IsValid()
        and target.components.inventoryitem ~= nil
        and target.components.inventoryitem:GetGrandOwner() == nil
end

local function RestoreItemDurability(target)
    if target == nil or not target:IsValid() then
        return false
    end

    local restored = false

    if target.components.finiteuses ~= nil and target.components.finiteuses.total ~= nil then
        local finiteuses = target.components.finiteuses
        if finiteuses.total > 0
            and finiteuses.current ~= nil
            and finiteuses.current < finiteuses.total
        then
            finiteuses:SetUses(finiteuses.total)
            restored = true
        end
    end

    if target.components.armor ~= nil and target.components.armor.maxcondition ~= nil then
        local armor = target.components.armor
        if armor.maxcondition > 0
            and armor.condition ~= nil
            and armor.condition < armor.maxcondition
        then
            armor:SetCondition(armor.maxcondition)
            restored = true
        end
    end

    if target.components.fueled ~= nil and target.components.fueled.maxfuel ~= nil then
        local fueled = target.components.fueled
        if fueled.maxfuel > 0
            and fueled.currentfuel ~= nil
            and fueled.currentfuel < fueled.maxfuel
        then
            fueled:SetPercent(1)
            restored = true
        end
    end

    return restored
end

local function WrapHauntableForDurabilityRepair(inst)
    if _G.TheWorld == nil
        or not _G.TheWorld.ismastersim
        or inst == nil
        or not inst:IsValid()
        or inst._dae_haunt_repair_wrapped == true
        or inst.components.hauntable == nil
    then
        return
    end

    inst._dae_haunt_repair_wrapped = true

    local hauntable = inst.components.hauntable
    local original_onhaunt = hauntable.onhaunt
    hauntable:SetOnHauntFn(function(target, haunter)
        local restored = false
        if IsAbigailGroundItemHaunt(target, haunter) then
            restored = RestoreItemDurability(target)
        end

        local original_success = original_onhaunt ~= nil and original_onhaunt(target, haunter) or false

        return restored or original_success
    end)
end

AddPrefabPostInit("abigail", function(inst)
    if not _G.TheWorld.ismastersim then
        return
    end

    ApplyAbigailImmunities(inst)
    ApplyAbigailSpeedBoost(inst)
    RefreshAbigailLight(inst)
    inst._dae_light_refresh_task = inst:DoPeriodicTask(LIGHT_REFRESH_INTERVAL, RefreshAbigailLight)
    inst._dae_player_regen_task = inst:DoPeriodicTask(PLAYER_REGEN_INTERVAL, RestoreNearbyPlayers, PLAYER_REGEN_INTERVAL)

    inst._dae_on_target_death = function(target)
        if inst._dae_lightning_target == target then
            StopTargetLightning(inst)
        end
    end

    inst._dae_on_target_removed = function(target)
        if inst._dae_lightning_target == target then
            StopTargetLightning(inst)
        end
    end

    inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
    inst:ListenForEvent("droppedtarget", OnDroppedTarget)
    inst:ListenForEvent("onhitother", OnAbigailHitOther)
    inst:ListenForEvent("onareaattackother", OnAbigailHitOther)
    inst:ListenForEvent("death", StopTargetLightning)
    inst:ListenForEvent("onremove", StopTargetLightning)
end)

AddPrefabPostInitAny(function(inst)
    WrapHauntableForDurabilityRepair(inst)
end)
