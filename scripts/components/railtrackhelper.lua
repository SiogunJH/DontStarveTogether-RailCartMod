local function CreateHelper()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")

    inst.AnimState:SetBank("railtrack_tool")
    inst.AnimState:SetBuild("railtrack_tool")
    inst.AnimState:PlayAnimation("helper_small")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetScale(1, 1)

    return inst
end

local RailTrackHelper = Class(function(self, inst)
    self.inst = inst
    self.pos=Vector3(0,0,0)
    self.ring_normal=nil
    self.ring_pos=nil
    self.ring_target=nil
    self.ring_connect=nil
    self.inst:StopUpdatingComponent(self)
    self.ison=false
    self.track_length=2
    self.isred=false
end)

local function IsValid(inst)
    return inst ~= nil and inst:IsValid() and not inst:HasTag("burnt")
end

local function IsOverWater(pos)
    return not TheWorld.Map:IsVisualGroundAtPoint(pos.x, pos.y, pos.z)
end

local function IsValidTile(pos)
    return TheWorld.Map:GetTileAtPoint(pos.x,pos.y,pos.z) > 1
end

local function IsOceanTrack(inst) 
    return inst and inst.player_classified and inst.player_classified.railtrack_tool_isocean:value()
end


function RailTrackHelper:TurnOn()
    if self.ison then
        return
    end
    self.ring_normal=CreateHelper()
    self.ring_normal.AnimState:PlayAnimation("helper_normal")
    self.ring_normal.AnimState:SetAddColour(0.5,0.5,0.5,0)
    self.ring_pos=CreateHelper()
    self.ring_pos.AnimState:SetAddColour(0,0.5,0,0)
    self.inst:StartUpdatingComponent(self)
    self.ison=true
end

function RailTrackHelper:TurnOff()
    if not self.ison then
        return
    end
    self.inst:StopUpdatingComponent(self)
    if IsValid(self.ring_normal) then
        self.ring_normal:Remove()
        self.ring_normal=nil
    end
    if IsValid(self.ring_pos) then
        self.ring_pos:Remove()
        self.ring_pos=nil
    end
    if IsValid(self.ring_target) then
        self.ring_target:Remove()
        self.ring_target=nil
    end
    if IsValid(self.ring_connect) then
        self.ring_connect:Remove()
        self.ring_connect=nil
    end

    self.ison=false
end

function RailTrackHelper:OnUpdate(dt)
    self.isred=false
    local pos=TheInput:GetWorldPosition()
    local ent=TheSim:FindEntities(pos.x,pos.y,pos.z, 5, {'railtrack'},{'burnt'})
    if IsValid(self.ring_normal) then
        self.ring_normal.Transform:SetPosition(pos:Get())
    end
    if IsValid(self.ring_pos) then
        if #ent == 0 then
            self.ring_pos.Transform:SetPosition(pos:Get())
            if IsValid(self.ring_target) then
                self.ring_target:Remove()
                self.ring_target=nil
            end
        else
            if self.ring_target == nil then
                self.ring_target=CreateHelper()
                self.ring_target.AnimState:SetAddColour(0.5,0.5,0.5,0)
            end
            local tpos=ent[1]:GetPosition()
            local vec=tpos-pos
            local angle=math.atan2(vec.z,vec.x)
            local dx=self.track_length*math.cos(angle)
            local dz=self.track_length*math.sin(angle)
            self.ring_target.Transform:SetPosition(tpos:Get())
             
            self.ring_pos.Transform:SetPosition(tpos.x-dx,0, tpos.z-dz)
            local var=TheSim:FindEntities(tpos.x-dx,0, tpos.z-dz, 0.9*self.track_length, {'railtrack'},{'burnt'})
            local aux=TheSim:FindEntities(tpos.x-dx,0, tpos.z-dz, 0.9*self.track_length, {'railtrack','burnt'})
            if #var > 0 or #aux > 0 then
                self.ring_pos.AnimState:SetAddColour(0.5,0.0,0,0)
                self.isred=true
            else
                self.ring_pos.AnimState:SetAddColour(0,0.5,0,0)
            end
            var=TheSim:FindEntities(tpos.x-dx,0, tpos.z-dz, self.track_length+0.5, {'railtrack'},{'burnt'})
            if #var > 1 then
                if self.ring_connect == nil then
                    self.ring_connect=CreateHelper()
                    self.ring_connect.AnimState:SetAddColour(0.5,0.5,0.5,0)
                end
                self.ring_target.Transform:SetPosition(var[1]:GetPosition():Get())
                self.ring_connect.Transform:SetPosition(var[2]:GetPosition():Get())
            else
                if IsValid(self.ring_connect) then
                    self.ring_connect:Remove()
                    self.ring_connect=nil
                end
            end
        end
        pos=self.ring_pos:GetPosition()
        if not IsValidTile(pos) then
            self.ring_pos.AnimState:SetAddColour(0.5,0.0,0,0)
        elseif not self.isred then
            self.ring_pos.AnimState:SetAddColour(0,0.5,0,0)
        end
        local isoceantrack=IsOceanTrack(self.inst)
        if IsOverWater(pos) then
            if not isoceantrack then
                self.ring_pos.AnimState:SetAddColour(0.5,0.0,0,0)
            elseif not self.isred then
                self.ring_pos.AnimState:SetAddColour(0,0.5,0,0)
            end
        else
            if isoceantrack then
                self.ring_pos.AnimState:SetAddColour(0.5,0.0,0,0)
            elseif not self.isred then
                self.ring_pos.AnimState:SetAddColour(0,0.5,0,0)
            end
        end
        local var=TheSim:FindEntities(pos.x,0, pos.z, 0.9*self.track_length, {'railtrack','burnt'})
        if #var > 0 then
            self.ring_pos.AnimState:SetAddColour(0.5,0.0,0,0)
            self.isred=true
        end
    end
end

-- ThePlayer.replica.inventory.classified:GetEquips().hands.replica._.container.classified._items[1]:value().prefab=="railtrack_ocean_item"

return RailTrackHelper
