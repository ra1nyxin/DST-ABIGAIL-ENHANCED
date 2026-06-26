local _G = GLOBAL
local SpawnPrefab = _G.SpawnPrefab
local Vector3 = _G.Vector3
local IsEntityElectricImmune = _G.IsEntityElectricImmune
local LightningStrikeAttack = _G.LightningStrikeAttack

local SHOCK_INTERVAL = 2
local LOG_PREFIX = "[DST-ABIGAIL-ENHANCED]"

local function DebugLog(message)
    print(string.format("%s %s", LOG_PREFIX, message))
end

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

    DebugLog(string.format("Striking target %s", tostring(target.prefab)))
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

AddPrefabPostInit("abigail", function(inst)
    if not _G.TheWorld.ismastersim then
        return
    end

    ApplyAbigailImmunities(inst)
    DebugLog("Applied Abigail enhancements to a spawned Abigail")

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
    inst:ListenForEvent("death", StopTargetLightning)
    inst:ListenForEvent("onremove", StopTargetLightning)
end)
