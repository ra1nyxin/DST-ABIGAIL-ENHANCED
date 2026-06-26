local _G = GLOBAL
local SpawnPrefab = _G.SpawnPrefab
local Vector3 = _G.Vector3
local IsEntityElectricImmune = _G.IsEntityElectricImmune
local LightningStrikeAttack = _G.LightningStrikeAttack

local SHOCK_INTERVAL = 2
local LIGHT_RADIUS_MULT = 1.5
local ABIGAIL_SPEED_MULT = 1.5
local TARGET_SLOW_MULT = 0.5
local TARGET_SLOW_DURATION = 60
local ABIGAIL_SPEED_KEY = "dst_abigail_enhanced_speed"
local TARGET_SLOW_KEY = "dst_abigail_enhanced_slow"

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

local function ApplyAbigailLightBoost(inst)
    if inst.Light == nil or inst._dae_light_radius_wrapped then
        return
    end

    local original_set_radius = inst.Light.SetRadius
    inst.Light.SetRadius = function(light, radius, ...)
        return original_set_radius(light, radius * LIGHT_RADIUS_MULT, ...)
    end
    inst._dae_light_radius_wrapped = true

    local ok, current_radius = pcall(function()
        return inst.Light:GetRadius()
    end)

    if ok and type(current_radius) == "number" then
        original_set_radius(inst.Light, current_radius * LIGHT_RADIUS_MULT)
    end
end

AddPrefabPostInit("abigail", function(inst)
    if not _G.TheWorld.ismastersim then
        return
    end

    ApplyAbigailImmunities(inst)
    ApplyAbigailSpeedBoost(inst)
    ApplyAbigailLightBoost(inst)

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
