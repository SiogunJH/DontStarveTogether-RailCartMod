local assets =
{
    Asset("ANIM", "anim/railcart_smoke.zip")
}

local function startfx(proxy)
    local inst = CreateEntity("railcart_smoke")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.Transform:SetFromProxy(proxy.GUID)
    inst.Transform:SetScale(1.2,1,1)

    inst.AnimState:SetBank("railcart_smoke")
    inst.AnimState:SetBuild("railcart_smoke")
    inst.AnimState:PlayAnimation("idle")


    inst:ListenForEvent("animover", inst.Remove)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        --Delay one frame so that we are positioned properly before starting the effect
        --or in case we are about to be removed
        inst:DoTaskInTime(0, startfx, inst)
    end

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

return Prefab("railcart_smoke", fn, assets)
