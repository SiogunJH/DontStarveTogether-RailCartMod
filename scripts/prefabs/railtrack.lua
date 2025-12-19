local MAXBOOSTSPEED=38

require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/railtrack.zip"),
    Asset("ATLAS", "images/inventoryimages/railtrack.xml"),
    Asset("IMAGE", "images/inventoryimages/railtrack.tex"),
}


local prefabs =
{
}




----------------------

local function OnHammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.SoundEmitter:KillSound("firesuppressor_idle")
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

--[[
local function OnHit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        -- TODO: A hit animation for it when its closed and when its open, but not now
    end
end

]]--

local function OnBurnt(inst)
    DefaultBurntStructureFn(inst)
    inst:RemoveComponent("activatable")
    local point=inst:GetPosition()
    if inst.prefab == "railtrack_reverse" then
        inst._burnt:set(true)
    end
    
    if not TheWorld.Map:IsVisualGroundAtPoint(point.x, point.y, point.z) then
        OnHammered(inst, inst)
    end
end

local function OnBurntDirty(inst)
    if inst.tire ~= nil and inst._burnt:value() then
        inst.tire:Remove()
        inst.tire=nil
    end
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = not inst.is_fireproof
    end
    if inst.Transform then
        data.rotation=inst.Transform:GetRotation()
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil and inst.components.burnable.onburnt ~= nil and not inst.is_fireproof then
        inst.components.burnable.onburnt(inst)
    end
    if data ~= nil and data.rotation and inst.Transform then
        inst.Transform:SetRotation(data.rotation)
    end
end



local function OnActivate(inst,doer)
    inst.components.activatable.inactive=true
    if doer.components.railcart == nil then
        doer:AddComponent("railcart")
    end
    
    doer.components.railcart:SetSpeed(0)
    doer.components.railcart:SetTrack(inst)
end


local function DefaultPlace(inst)
    local point=inst:GetPosition()
    if not TheWorld.Map:IsVisualGroundAtPoint(point.x, point.y, point.z) then
        OnHammered(inst, inst)
    end
end

local function OceanPlace(inst)
    local point=inst:GetPosition()
    if TheWorld.Map:IsVisualGroundAtPoint(point.x, point.y, point.z) then
        OnHammered(inst, inst)
        return
    end
end

local function BoostPlace(inst)
    local point=inst:GetPosition()
    if not TheWorld.Map:IsVisualGroundAtPoint(point.x, point.y, point.z) then
        OnHammered(inst, inst)
    end
    inst.components.railtrack.track_boost=0.7
end

local function DampPlace(inst)
    local point=inst:GetPosition()
    if not TheWorld.Map:IsVisualGroundAtPoint(point.x, point.y, point.z) then
        OnHammered(inst, inst)
    end
    inst.components.railtrack.track_damp=0.7
end

local function CreateFloater()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("decor") --no mouse over, let the base prefab handle that
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.persists = false
    
    inst.AnimState:SetBank("railtrack")
    inst.AnimState:SetBuild("railtrack")
    inst.AnimState:PlayAnimation("railtrack_floater_place")
    inst.AnimState:PushAnimation("railtrack_floater")
    inst.AnimState:SetFinalOffset(1)
	inst.AnimState:SetSortOrder(4)
    return inst
end

local function CreateTire()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("decor") --no mouse over, let the base prefab handle that
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.persists = false
    
    inst.AnimState:SetBank("railtrack")
    inst.AnimState:SetBuild("railtrack")
    inst.AnimState:PushAnimation("railtrack_tire_place")
    inst.AnimState:PushAnimation("railtrack_tire")
    inst.AnimState:SetFinalOffset(1)
	inst.AnimState:SetSortOrder(4)
    return inst
end

local function OceanDecor(inst)
    local floater
    local fx
    local fpos={{-0.5,-0.75}, {-0.5,0.75}, {0.45,-0.75}, {0.45,0.75}}
    local floaters={}
    
    for k,v in pairs(fpos) do
        floater=CreateFloater()
        floater.entity:SetParent(inst.entity)
        floater.Transform:SetPosition(v[1],0,v[2])
        
        fx=SpawnPrefab("float_fx_back")
        fx.AnimState:PlayAnimation("idle_back_small", true)
        fx.AnimState:SetScale(0.7,0.7)
        fx.entity:SetParent(floater.entity)
        floater.AnimState:SetFloatParams(-0.05, 0.5, 1)
        table.insert(floaters,floater)
    end

    inst.AnimState:SetFloatParams(0, 0, 0.5)
    
    inst.highlightchildren=floaters
end

local function ReverseDecor(inst)
    if inst._burnt:value() then
        return
    end
    local tire=CreateTire()
    tire.Transform:SetPosition(inst:GetPosition():Get())
    tire.entity:SetParent(inst.entity)
    inst.highlightchildren={tire}
    inst.tire=tire
end


local function ReverseTrack(inst)
    inst.components.railcart:ChangeDirection()
    local pos=inst:GetPosition()
    local tpos=inst.components.railcart.current_track:GetPosition()
    local x,y,z = (tpos-pos):Get()
    inst.Transform:SetPosition(pos.x+inst.components.railcart.speed/MAXBOOSTSPEED*x,
                        pos.y+inst.components.railcart.speed/MAXBOOSTSPEED*y,
                        pos.z+inst.components.railcart.speed/MAXBOOSTSPEED*z)
    
end

local function create_railtrack(name,bank, build, anim, itemimage, entertrackfn, leavetrackfn, ontrackfn, placefn, decorfn, assets, prefabs)
    local function fn()
        local inst = CreateEntity()

        local minimap = inst.entity:AddMiniMapEntity()
	    minimap:SetIcon( itemimage )
            
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst:AddTag("structure")

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("railtrack")
        inst.AnimState:OverrideSymbol("railtrack_default","railtrack",anim)
        inst.AnimState:Hide("mouseover")
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(3)

        
        if name == "railtrack_reverse" then
            inst._burnt = net_bool(inst.GUID, "railtrack._burnt", "burntdirty")
            inst._burnt:set(false)
        end

        inst:AddTag("structure")
        inst:AddTag("railtrack")
        
        if decorfn ~= nil and not TheNet:IsDedicated() and not inst:HasTag("burnt") then
            decorfn(inst)
        end
        
        --if not TheWorld.ismastersim then -- client-side decor
        inst:ListenForEvent("burntdirty", OnBurntDirty)
        --    return inst
        --end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end


        inst.is_fireproof=false
    
        inst:AddComponent("inspectable")

        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(OnHammered)
        
        inst:AddComponent("railtrack")
        inst.components.railtrack.entertrackfn=entertrackfn
        inst.components.railtrack.leavetrackfn=leavetrackfn
        inst.components.railtrack.ontrackfn=ontrackfn
        
        inst:AddComponent("activatable")
        inst.components.activatable.OnActivate=OnActivate
        --inst.components.activatable.quickaction=true
        
        MakeSmallBurnable(inst, nil, nil, true)
        MakeSmallPropagator(inst)
        inst.components.burnable:SetOnBurntFn(OnBurnt)

        inst.OnSave = OnSave 
        inst.OnLoad = OnLoad
        
        
        inst.railtrack_item_prefab=name .. "_item"
        inst.components.lootdropper:SetLoot({inst.railtrack_item_prefab})
        
        if placefn ~= nil then
            inst:DoTaskInTime(0.02, function()
                placefn(inst) 
                local pos=inst:GetPosition()
                if inst ~= nil and inst:IsValid() and 
                (inst:GetCurrentPlatform() ~= nil or TheWorld.Map:GetTileAtPoint(inst:GetPosition():Get()) == 1 or
                 #TheSim:FindEntities(pos.x,0,pos.z,0.9*inst.components.railtrack.track_length, {'railtrack'}) > 1) then
                    OnHammered(inst,inst)
                end
            end)
        end
        
        return inst
    end
    return Prefab(name,fn, assets,prefabs)
end

local function create_railtrack_item(name,itembank, itembuild, itemanim, itematlas,itemimage,assets, prefabs)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(itembank)
        inst.AnimState:SetBuild(itembuild)
        inst.AnimState:PlayAnimation("railtrack_item")
        inst.AnimState:OverrideSymbol("railtrack_default","railtrack",itemanim)
        
        inst:AddTag("railtrack_item")
        
        MakeInventoryFloatable(inst, "small", 0.05, {0.75, 0.4, 0.75})

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
        
        inst:AddComponent("stackable")
-- 获取当前游戏中 stackable 组件的默认 maxsize
local default_maxsize = TUNING.STACK_SIZE_LARGEITEM or 60
inst.components.stackable.maxsize = default_maxsize

        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        
        if name ~= "railtrack_ocean" then
            inst.components.inventoryitem:SetSinks(true)
        end
        
        inst.components.inventoryitem.atlasname = itematlas
        inst.components.inventoryitem.imagename = itemimage
        
        MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
        MakeSmallPropagator(inst)
            
        inst.railtrack_prefab=name

        return inst
    end
    return Prefab(name .."_item",fn, assets,prefabs)
end

return  create_railtrack("railtrack_default","railtrack", "railtrack", "railtrack_default", "default.tex", nil, nil, nil, DefaultPlace, nil, assets, prefabs),
        create_railtrack_item("railtrack_default","railtrack", "railtrack", "railtrack_default", "images/inventoryimages/railtrack.xml","default", assets, prefabs),
        create_railtrack("railtrack_ocean","railtrack", "railtrack", "railtrack_ocean", "ocean.tex", nil, nil, nil, OceanPlace, OceanDecor, assets, prefabs),
        create_railtrack_item("railtrack_ocean","railtrack", "railtrack", "railtrack_ocean", "images/inventoryimages/railtrack.xml","ocean", assets, prefabs),
        create_railtrack("railtrack_boost","railtrack", "railtrack", "railtrack_boost", "boost.tex", nil, nil, nil, BoostPlace, nil, assets, prefabs),
        create_railtrack_item("railtrack_boost","railtrack", "railtrack", "railtrack_boost", "images/inventoryimages/railtrack.xml","boost", assets, prefabs),
        create_railtrack("railtrack_damp","railtrack", "railtrack", "railtrack_damp", "damp.tex", nil, nil, nil, DampPlace, nil, assets, prefabs),
        create_railtrack_item("railtrack_damp","railtrack", "railtrack", "railtrack_damp", "images/inventoryimages/railtrack.xml","damp", assets, prefabs),
        create_railtrack("railtrack_reverse","railtrack", "railtrack", "railtrack_reverse", "reverse.tex", ReverseTrack, nil, nil, DefaultPlace, ReverseDecor, assets, prefabs),
        create_railtrack_item("railtrack_reverse","railtrack", "railtrack", "railtrack_reverse", "images/inventoryimages/railtrack.xml","reverse", assets, prefabs)



