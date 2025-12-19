GLOBAL.setmetatable(env, {
    __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end
})

local Inv = require "widgets/inventorybar"


Assets = {
    Asset("ANIM", "anim/railcart_anim.zip"),
    Asset("ANIM", "anim/railcart_build.zip"),
    Asset("ANIM", "anim/railcart_hud.zip"),
    Asset("ANIM", "anim/railtrack_tool.zip"),
    Asset("ATLAS", "images/inventoryimages/railtrack.xml"),
    Asset("IMAGE", "images/inventoryimages/railtrack.tex"),
    Asset("ATLAS", "images/inventoryimages/railtrack_tool.xml"),
    Asset("IMAGE", "images/inventoryimages/railtrack_tool.tex"),

}

PrefabFiles =
{
    "railtrack",
    "railtrack_tool",
    "railcart_smoke",
}

AddModRPCHandler("railcart", "SpeedUp", function(player)
    if not TheWorld.ismastersim or player.components.railcart == nil then
        return
    end
    player.components.railcart:SpeedUp()
end)

AddModRPCHandler("railcart", "Brake", function(player)
    if not TheWorld.ismastersim or player.components.railcart == nil then
        return
    end
    player.components.railcart:Brake()
end)

AddModRPCHandler("railcart", "Reverse", function(player)
    if not TheWorld.ismastersim or player.components.railcart == nil then
        return
    end
    player.components.railcart:Reverse()
end)

AddModRPCHandler("railcart", "DropOff", function(player)
    if not TheWorld.ismastersim or player.components.railcart == nil then
        return
    end
    player.components.railcart:TryDropOff()
end)

AddPrefabPostInit("player_classified", function(inst)
    inst.railcart_ison = net_bool(inst.GUID, "railcart_ison", "railcart_ison")
    inst.railcart_nx = net_float(inst.GUID, "railcart_nx", "railcart_nx")
    inst.railcart_ny = net_float(inst.GUID, "railcart_ny", "railcart_ny")
    inst.railcart_nz = net_float(inst.GUID, "railcart_nz", "railcart_nz")
    inst.railcart_speed = net_float(inst.GUID, "railcart_speed", "railcart_speed")
    inst.railtrack_tool = net_bool(inst.GUID, "railtrack_tool", "railtrack_tool")
    inst.railtrack_tool_isocean = net_bool(inst.GUID, "railtrack_tool_isocean", "railtrack_tool_isocean")
    if TheWorld.ismastersim then
        inst.railcart_ison:set(false)
        inst.railcart_nx:set(0)
        inst.railcart_ny:set(0)
        inst.railcart_nz:set(0)
        inst.railcart_speed:set(0)
        inst.railtrack_tool:set(false)
        inst.railtrack_tool_isocean:set(false)
    else

    end
end)

local railtrack_prefabs = {
    "railtrack_default",
    "railtrack_ocean",
    "railtrack_boost",
    "railtrack_damp",
    "railtrack_reverse",
}

for k, v in pairs(railtrack_prefabs) do
    AddPrefabPostInit(v, function(inst)
        inst.is_fireproof = GetModConfigData("RAILCART_FIREPROOF")
        if inst.is_fireproof then
            inst:RemoveComponent("burnable")
        end
    end)
end

AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("railcart")
        inst.components.railcart:SetSpeedupFactor(0.010 * GetModConfigData("RAILCART_SPEEDUP"))
        inst.components.railcart:SetDampingFactor(0.025 * GetModConfigData("RAILCART_DAMPING"))
        inst.components.railcart:SetBrakingFactor(0.01 * GetModConfigData("RAILCART_BRAKING"))
        inst.components.railcart:SetPlaySound(GetModConfigData("RAILCART_PLAYSOUND"))
        inst.components.railcart:SetSpawnSmoke(GetModConfigData("RAILCART_SPAWNSMOKE"))
    end
    inst:AddComponent("railcartcontroller")
    inst:AddComponent("railtrackhelper")
    inst:DoTaskInTime(0, function(inst)
        -- Event Listeners post load
        -- On cart
        inst:ListenForEvent("railcart_ison", function()
            if inst ~= nil and inst.components.railcartcontroller ~= nil then
                if inst.player_classified.railcart_ison:value() == true then
                    inst.components.railcartcontroller:TurnOn()
                else
                    inst.components.railcartcontroller:TurnOff()
                end
            end
        end, inst.player_classified)
        -- On tool
        inst:ListenForEvent("railtrack_tool", function()
            if inst ~= nil and inst.components.railtrackhelper ~= nil then
                if inst.player_classified.railtrack_tool:value() == true then
                    inst.components.railtrackhelper:TurnOn()
                else
                    inst.components.railtrackhelper:TurnOff()
                end
            end
        end, inst.player_classified)
    end)
    inst.AnimState:AddOverrideBuild("railcart_build")
end)

---------------------------------------------------------------------------

local OnRailCart = State({
    name = "onrailcart",
    tags = { "pinned", "nopredict" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst:ClearBufferedAction()

        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:EnableMapControls(false)
            inst.components.playercontroller:Enable(false)
        end
        inst.Transform:SetFourFaced()
        inst.AnimState:PlayAnimation("railcart")
    end,

    onexit = function(inst)
        if inst.components.playercontroller ~= nil then
            inst:DoTaskInTime(0.55, function(inst)
                inst.components.playercontroller:EnableMapControls(true)
                inst.components.playercontroller:Enable(true)
            end)
        end
    end,

    events =
    {
        EventHandler("attacked", function(inst)
            if inst.components.railcart ~= nil then
                inst.components.railcart:DropOff()
            end
            if inst.components.playercontroller ~= nil then
                inst:DoTaskInTime(0.5, function(inst)
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end)
            end
        end),

        EventHandler("death", function(inst, data)
            if inst.components.railcart ~= nil then
                inst.components.railcart:DropOff()
            end
            if inst.components.playercontroller ~= nil then
                inst:DoTaskInTime(0.5, function(inst)
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end)
            end
        end)
    },

})

AddStategraphState("wilson", OnRailCart)


---------------------------------------------------------------------------

local containers = require "containers"
local params = containers.params

params.railtrack_tool =
{
    widget =
    {
        slotpos =
        {
            Vector3(0, 32 + 4, 0),
        },
        --slotbg =
        --{
        --    { image = "slingshot_ammo_slot.tex" },
        --},
        animbank = "ui_cookpot_1x2",
        animbuild = "ui_cookpot_1x2",
        pos = Vector3(0, 15, 0),
    },
    usespecificslotsforitems = true,
    type = "hand_inv",
}

local inventory = require("components/inventory")
if inventory ~= nil and inventory.maxslots ~= nil and inventory.maxslots > 15 then
    params.railtrack_tool.widget.pos = Vector3(-43, -282, 0)
    params.railtrack_tool.type = "pack"
end

function params.railtrack_tool.itemtestfn(container, item, slot)
    return item:HasTag("railtrack_item")
end

for k, v in pairs(params) do
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end

local HudSpeedometer = require("widgets/hudspeedometer")
AddGlobalClassPostConstruct("widgets/inventorybar", "Inv", function()
    -- Inspired on the way that "Extra Equip Slots" was code
    -- https://steamcommunity.com/sharedfiles/filedetails/?id=375850593
    -- The way it was coded is very simple and good to read! Thanks!

    local Inv_Rebuild_old = Inv.Rebuild or function() return "" end

    function Inv:Rebuild()
        Inv_Rebuild_old(self)
        Inv:LoadSpeedometer(self)
    end

    -- So, the code between these commented lines is nearly a hard-copy
    -- There is another way to do this with this simplicity?
    -- I don't know, but I really like the way you coded that!

    function Inv:LoadSpeedometer(self)
        self.hudspeedometer = self.root:AddChild(HudSpeedometer(self.owner))
        self.hudspeedometer:Hide()
        self.hudspeedometer:SetScale(0.5, 0.5)
        self.hudspeedometer:SetRotation(15)
        --self.hudspeedometer:SetPosition(Vector3(100,50,0))
        self.hudspeedometer:MoveToBack()
    end
end)

---------------------------------------------------------------------------

local craftamount = GetModConfigData("RAILCART_CRAFTAMOUNT")

AddMinimapAtlas("images/inventoryimages/railtrack.xml")

AddRecipe("railtrack_tool",
    { GLOBAL.Ingredient("gears", 1), GLOBAL.Ingredient("spear", 1),
        GLOBAL.Ingredient("goldnugget", 2) },
    GLOBAL.RECIPETABS.TOOLS,
    GLOBAL.TECH.SCIENCE_TWO,
    nil,                                         -- placer
    nil,                                         -- min_spacing
    nil,                                         -- nounlock
    nil,                                         -- numtogive
    nil,                                         -- builder_tag
    "images/inventoryimages/railtrack_tool.xml", -- atlas
    "railtrack_tool.tex")

AddRecipe("railtrack_default_item",
    { GLOBAL.Ingredient("boards", 1), GLOBAL.Ingredient("cutstone", 1),
        GLOBAL.Ingredient("flint", 1) },
    GLOBAL.RECIPETABS.TOWN,
    GLOBAL.TECH.SCIENCE_TWO,
    nil,                                    -- placer
    nil,                                    -- min_spacing
    nil,                                    -- nounlock
    craftamount,                            -- numtogive
    nil,                                    -- builder_tag
    "images/inventoryimages/railtrack.xml", -- atlas
    "default.tex")

AddRecipe("railtrack_ocean_item",
    { GLOBAL.Ingredient("boards", 1), GLOBAL.Ingredient("cutstone", 1),
        GLOBAL.Ingredient("mosquitosack", 1) },
    GLOBAL.RECIPETABS.TOWN,
    GLOBAL.TECH.SCIENCE_TWO,
    nil,                                    -- placer
    nil,                                    -- min_spacing
    nil,                                    -- nounlock
    craftamount,                            -- numtogive
    nil,                                    -- builder_tag
    "images/inventoryimages/railtrack.xml", -- atlas
    "ocean.tex")

AddRecipe("railtrack_boost_item",
    { GLOBAL.Ingredient("boards", 1), GLOBAL.Ingredient("cutstone", 1),
        GLOBAL.Ingredient("goldnugget", 12) },
    GLOBAL.RECIPETABS.TOWN,
    GLOBAL.TECH.SCIENCE_TWO,
    nil,                                    -- placer
    nil,                                    -- min_spacing
    nil,                                    -- nounlock
    craftamount,                            -- numtogive
    nil,                                    -- builder_tag
    "images/inventoryimages/railtrack.xml", -- atlas
    "boost.tex")

AddRecipe("railtrack_damp_item",
    { GLOBAL.Ingredient("boards", 1), GLOBAL.Ingredient("cutstone", 1),
        GLOBAL.Ingredient("charcoal", 1) },
    GLOBAL.RECIPETABS.TOWN,
    GLOBAL.TECH.SCIENCE_TWO,
    nil,                                    -- placer
    nil,                                    -- min_spacing
    nil,                                    -- nounlock
    craftamount,                            -- numtogive
    nil,                                    -- builder_tag
    "images/inventoryimages/railtrack.xml", -- atlas
    "damp.tex")

AddRecipe("railtrack_reverse_item",
    { GLOBAL.Ingredient("boards", 1), GLOBAL.Ingredient("cutstone", 1),
        GLOBAL.Ingredient("pigskin", 1) },
    GLOBAL.RECIPETABS.TOWN,
    GLOBAL.TECH.SCIENCE_TWO,
    nil,                                    -- placer
    nil,                                    -- min_spacing
    nil,                                    -- nounlock
    craftamount,                            -- numtogive
    nil,                                    -- builder_tag
    "images/inventoryimages/railtrack.xml", -- atlas
    "reverse.tex")

---------------------------------------------------------------------------
-- Language Selection
---------------------------------------------------------------------------

local LANGUAGE = GetModConfigData("RAILCART_LANGUAGE") or "en"

-- Load language strings from external files
local LANG_FILES = {
    en = "lang/en",
    pl = "lang/pl",
    zh = "lang/zh",
}

local L
local lang_file = LANG_FILES[LANGUAGE] or LANG_FILES["en"]
L = require(lang_file)

-- Apply strings
GLOBAL.STRINGS.NAMES.RAILTRACK_TOOL = L.RAILTRACK_TOOL_NAME
GLOBAL.STRINGS.RECIPE_DESC.RAILTRACK_TOOL = L.RAILTRACK_TOOL_RECIPE
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_TOOL = L.RAILTRACK_TOOL_DESCRIBE

GLOBAL.STRINGS.NAMES.RAILTRACK_DEFAULT = L.RAILTRACK_DEFAULT_NAME
GLOBAL.STRINGS.NAMES.RAILTRACK_DEFAULT_ITEM = L.RAILTRACK_DEFAULT_NAME
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_DEFAULT = L.RAILTRACK_DEFAULT_DESCRIBE
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_DEFAULT_ITEM = L.RAILTRACK_DEFAULT_ITEM_DESCRIBE
GLOBAL.STRINGS.RECIPE_DESC.RAILTRACK_DEFAULT_ITEM = L.RAILTRACK_DEFAULT_ITEM_RECIPE

GLOBAL.STRINGS.NAMES.RAILTRACK_OCEAN = L.RAILTRACK_OCEAN_NAME
GLOBAL.STRINGS.NAMES.RAILTRACK_OCEAN_ITEM = L.RAILTRACK_OCEAN_NAME
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_OCEAN = L.RAILTRACK_OCEAN_DESCRIBE
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_OCEAN_ITEM = L.RAILTRACK_OCEAN_ITEM_DESCRIBE
GLOBAL.STRINGS.RECIPE_DESC.RAILTRACK_OCEAN_ITEM = L.RAILTRACK_OCEAN_ITEM_RECIPE

GLOBAL.STRINGS.NAMES.RAILTRACK_BOOST = L.RAILTRACK_BOOST_NAME
GLOBAL.STRINGS.NAMES.RAILTRACK_BOOST_ITEM = L.RAILTRACK_BOOST_NAME
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_BOOST = L.RAILTRACK_BOOST_DESCRIBE
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_BOOST_ITEM = L.RAILTRACK_BOOST_ITEM_DESCRIBE
GLOBAL.STRINGS.RECIPE_DESC.RAILTRACK_BOOST_ITEM = L.RAILTRACK_BOOST_ITEM_RECIPE

GLOBAL.STRINGS.NAMES.RAILTRACK_DAMP = L.RAILTRACK_DAMP_NAME
GLOBAL.STRINGS.NAMES.RAILTRACK_DAMP_ITEM = L.RAILTRACK_DAMP_NAME
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_DAMP = L.RAILTRACK_DAMP_DESCRIBE
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_DAMP_ITEM = L.RAILTRACK_DAMP_ITEM_DESCRIBE
GLOBAL.STRINGS.RECIPE_DESC.RAILTRACK_DAMP_ITEM = L.RAILTRACK_DAMP_ITEM_RECIPE

GLOBAL.STRINGS.NAMES.RAILTRACK_REVERSE = L.RAILTRACK_REVERSE_NAME
GLOBAL.STRINGS.NAMES.RAILTRACK_REVERSE_ITEM = L.RAILTRACK_REVERSE_NAME
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_REVERSE = L.RAILTRACK_REVERSE_DESCRIBE
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RAILTRACK_REVERSE_ITEM = L.RAILTRACK_REVERSE_ITEM_DESCRIBE
GLOBAL.STRINGS.RECIPE_DESC.RAILTRACK_REVERSE_ITEM = L.RAILTRACK_REVERSE_ITEM_RECIPE