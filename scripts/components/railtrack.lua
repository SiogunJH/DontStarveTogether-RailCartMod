local RailTrack = Class(function(self, inst)
    self.inst = inst
    self.rotation=0
    self.uptrack=nil
    self.dwtrack=nil

    self.track_length=2
    self.track_boost=0
    self.track_damp=0
    self.float_ison=false
    self.float_pos=0
    self.float_freq=1/3.
    self.float_amp=0.05
    self.inst:DoTaskInTime(0, function() self:SetNeighborhood() end)
end)

function RailTrack:SetNeighborhood()
    if self.inst:HasTag("burnt") then
        return
    end
    local pos=self.inst:GetPosition()
    local ent=TheSim:FindEntities(pos.x,pos.y,pos.z,self.track_length+0.5,{"railtrack"},{"burnt"})
    
    
    if ent[2] ~= nil then
        if (pos-ent[2]:GetPosition()):Length() < 0.9*self.track_length then
            if self.inst.components.workable ~= nil and self.inst.components.workable.onfinish ~= nil then
                self.inst.components.workable.onfinish(self.inst,self.inst)
            end
            return
        end
        self.uptrack=ent[2]
    end
    if ent[3] ~= nil then
        self.dwtrack=ent[3]
    end
    
    self:RotateTrack()
    
end

function RailTrack:ClearConnections()
    self.uptrack=nil
    self.dwtrack=nil
end

function RailTrack:RotateTrack(track)
    if self.uptrack == nil and self.dwtrack == nil then
        return
    end
    local dwpos
    local uppos
    if self.uptrack == nil then
        uppos=self.inst:GetPosition()
    else
        uppos=self.uptrack:GetPosition()
    end
    if self.dwtrack == nil then
        dwpos=self.inst:GetPosition()
    else
        dwpos=self.dwtrack:GetPosition()
    end
    
    self.rotation=180*math.atan2(uppos.x-dwpos.x,uppos.z-dwpos.z)/math.pi-90
    
    self.inst.Transform:SetRotation(self.rotation)
    
end

function RailTrack:SetFloating(bool)
    local pos=self.inst:GetPosition()
    self.inst.Transform:SetPosition(pos.x,0,pos.z)
    self.float_ison=bool
    if self.float_ison then
        self:StartFloating()
    end
end

function RailTrack:StartFloating()
    local pos=self.inst:GetPosition()
    self.inst.Transform:SetPosition(pos.x,0,pos.z)
    self.inst:DoTaskInTime(math.random()/self.float_freq, function(inst)
        if inst.components.railtrack and inst.components.railtrack.float_ison then
            inst:StartUpdatingComponent(inst.components.railtrack)
        end
    end)
end

function RailTrack:StopFloating()
    local pos=self.inst:GetPosition()
    self.inst.Transform:SetPosition(pos.x,0,pos.z)
    self.inst:StopUpdatingComponent(self)
end

function RailTrack:OnEntitySleep()
    if self.float_ison then
        self:StopFloating()
    end
end

function RailTrack:OnEntityWake()
    if self.float_ison then
        self:StartFloating()
    end
end

function RailTrack:OnUpdate(dt)
    if not self.float_ison then
        self:StopFloating()
        return
    end
    local pos=self.inst:GetPosition()
    self.inst.Transform:SetPosition(pos.x,0.5*self.float_amp*(1+math.sin(FRAMES*self.float_pos*2*math.pi*self.float_freq)),pos.z)
    self.float_pos=self.float_pos+1
    if self.float_pos > 90 then
        self.float_pos=0
    end
end


return RailTrack
