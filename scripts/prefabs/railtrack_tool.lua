local TRACK_LENGTH = 2

local assets =
{
    Asset("ANIM", "anim/railtrack_tool.zip"),
    Asset("ATLAS", "images/inventoryimages/railtrack_tool.xml"),
    Asset("IMAGE", "images/inventoryimages/railtrack_tool.tex"),

}


local prefabs =
{
}

local function IsValid(inst)
    return inst ~= nil and inst:IsValid() and not inst:HasTag("burnt")
end

local function IsOverWater(pos)
    return not TheWorld.Map:IsVisualGroundAtPoint(pos.x, pos.y, pos.z)
    --and inst:GetCurrentPlatform() == nil
end

local function IsValidTile(pos)
    return TheWorld.Map:GetTileAtPoint(pos.x, pos.y, pos.z) > 1
end

local function CreateRail(inst, target, pos)
    local tpos = pos
    local var = TheSim:FindEntities(pos.x, pos.y, pos.z, 5, { "railtrack" }, { "burnt" })

    if var ~= nil and #var > 0 then
        tpos = var[1]:GetPosition()
        local vec = pos - tpos
        local angle = math.atan2(vec.z, vec.x)
        tpos.x = tpos.x + TRACK_LENGTH * math.cos(angle)
        tpos.z = tpos.z + TRACK_LENGTH * math.sin(angle)
    end

    if not IsValidTile(tpos) then
        return
    end

    local track
    local item_stack = inst.components.container:GetItemInSlot(1)

    if item_stack == nil then
        return
    end

    if IsOverWater(tpos) then
        if item_stack.prefab ~= "railtrack_ocean_item" then
            return
        end
    else
        if item_stack.prefab == "railtrack_ocean_item" then
            return
        end
    end

    var = TheSim:FindEntities(tpos.x, 0, tpos.z, 0.9 * TRACK_LENGTH, { "railtrack" })
    if #var > 0 then
        return
    end

    local item = inst.components.container:RemoveItem(item_stack, false)
    if item ~= nil and item.railtrack_prefab ~= nil then
        item:Remove()
        track = SpawnPrefab(item.railtrack_prefab)
        track.AnimState:PlayAnimation("place")
        track.AnimState:PushAnimation("railtrack")
    else
        return
    end

    if track == nil or (track ~= nil and not track:IsValid()) then
        return
    end

    track.Transform:SetPosition(tpos:Get())
    track.components.railtrack:SetNeighborhood()
    track.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_craft")

    var = TheSim:FindEntities(pos.x, pos.y, pos.z, 15, { "railtrack" }, { "burnt" })
    for k, v in ipairs(var) do
        v.components.railtrack:SetNeighborhood()
    end
end

local function can_cast_fn(doer, target, pos)
    if target and target.components.railtrack or doer:HasTag("player") then
        return true
    end

    return false
end


local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "railtrack_tool", "swap_tool")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    inst.components.container:Open(owner)
    if owner.player_classified ~= nil then
        if inst.components.container:GetItemInSlot(1) ~= nil then
            owner.player_classified.railtrack_tool:set(false)
            owner.player_classified.railtrack_tool:set(true)
            owner.player_classified.railtrack_tool_isocean:set(
                inst.components.container:GetItemInSlot(1).prefab == "railtrack_ocean_item")
        end
        inst.owner = owner
    end
    inst:DoTaskInTime(1, function() -- If the player spawns with the tool in hands
        if owner ~= nil and inst.owner ~= nil and owner.player_classified then
            if inst.components.container:GetItemInSlot(1) ~= nil then
                owner.player_classified.railtrack_tool:set(false)
                owner.player_classified.railtrack_tool:set(true)
                owner.player_classified.railtrack_tool_isocean:set(
                    inst.components.container:GetItemInSlot(1).prefab == "railtrack_ocean_item")
            end
            inst.owner = owner
        end
    end)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    inst.components.container:Close()
    if owner.player_classified then
        owner.player_classified.railtrack_tool:set(false)
    end

    inst.owner = nil
end

local function OnTrackLoaded(inst, data)
    if inst.owner ~= nil and inst.owner:IsValid() and inst.owner.player_classified ~= nil then
        if data ~= nil and data.item ~= nil then
            inst.owner.player_classified.railtrack_tool:set(true)
            inst.owner.player_classified.railtrack_tool_isocean:set(data.item.prefab == "railtrack_ocean_item")
        else
            inst.owner.player_classified.railtrack_tool:set(false)
        end
    end
end

local function OnTrackUnloaded(inst, data)
    if inst.owner ~= nil and inst.owner:IsValid() and inst.owner.player_classified ~= nil then
        inst.owner.player_classified.railtrack_tool:set(false)
    end
end

local function tool_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("railtrack_tool")
    inst.AnimState:SetBuild("railtrack_tool")
    inst.AnimState:PlayAnimation("idle")

    --inst:AddTag("nopunch")
    inst:AddTag("railtrack_tool")
    inst:AddTag("weapon")

    inst.spelltype = "CONNECT_RAILTRACK"

    --Sneak these into pristine state for optimization
    inst:AddTag("veryquickcast")

    inst.entity:SetPristine()


    if not TheWorld.ismastersim then
        return inst
    end

    inst.owner = nil

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/railtrack_tool.xml"
    inst.components.inventoryitem.imagename = "railtrack_tool"
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddTag("allow_action_on_impassable")

    inst:AddComponent("spellcaster")
    --    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.veryquickcast = true
    --inst.components.spellcaster:SetCanCastFn(can_cast_fn)
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster:SetSpellFn(CreateRail)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("railtrack_tool")
    inst.components.container.canbeopened = false
    inst:ListenForEvent("itemget", OnTrackLoaded)
    inst:ListenForEvent("itemlose", OnTrackUnloaded)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.CANE_DAMAGE)


    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)


    return inst
end


return Prefab("railtrack_tool", tool_fn, assets, prefabs)
