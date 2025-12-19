local RailCartController = Class(function(self, inst)
    self.inst = inst
    self.speed=0
    self.current_track=nil
    self.next_track=nil
    self.reverse=false
    self.inst:StopUpdatingComponent(self)
    self.camera_last=TheCamera:GetHeadingTarget()
    self.is_focuscamera=false
    self.was_on_railtrack=false
    self:SaveCamera()
end)

function RailCartController:TurnOn()
    self:SaveCamera()
    self.inst:PushEvent("railcart_inout")
    self.inst:StartUpdatingComponent(self)
end

function RailCartController:TurnOff()
    self:LoadCamera()
    self.inst:PushEvent("railcart_inout")
    self.inst:StopUpdatingComponent(self)
    self.inst.Physics:SetMotorVel(0,0,0)
    self.inst.Physics:Stop()
end

function RailCartController:SaveCamera()
    self.camera_last=TheCamera:GetHeadingTarget()
    self.camera_headinggain=TheCamera.headinggain
    self.camera_mindistpitch=TheCamera.mindistpitch
    self.camera_maxdistpitch=TheCamera.maxdistpitch
    self.camera_mindist=TheCamera.mindist
    self.camera_maxdist=TheCamera.maxdist
    self.camera_fov=TheCamera.fov
    self.camera_targetoffset=TheCamera.targetoffset
end

function RailCartController:LoadCamera()
    TheCamera:SetHeadingTarget(self.camera_last)
    TheCamera.headinggain=self.camera_headinggain
    TheCamera.mindistpitch=self.camera_mindistpitch
    TheCamera.maxdistpitch=self.camera_maxdistpitch
    TheCamera.mindist=self.camera_mindist
    TheCamera.maxdist=self.camera_maxdist
    TheCamera.fov=self.camera_fov
    TheCamera.targetoffset=self.camera_targetoffset
end

function RailCartController:OnUpdate(dt)
    if self.inst.player_classified == nil then
        return
    end

    self.speed=self.inst.player_classified.railcart_speed:value()
    self.nx=self.inst.player_classified.railcart_nx:value()
    self.ny=self.inst.player_classified.railcart_ny:value()
    self.nz=self.inst.player_classified.railcart_nz:value()
    self.inst:FacePoint(Vector3(self.nx,self.ny,self.nz))
    if TheInput:IsControlPressed(CONTROL_MOVE_UP) then
        SendModRPCToServer(MOD_RPC.railcart.SpeedUp)
        self.inst.Physics:SetMotorVel(self.speed,0,0)
    end
    if TheInput:IsControlPressed(CONTROL_MOVE_DOWN) then
        SendModRPCToServer(MOD_RPC.railcart.Brake)
    end
    if TheInput:IsControlPressed(CONTROL_MOVE_LEFT) or 
       TheInput:IsControlPressed(CONTROL_MOVE_RIGHT) then
        SendModRPCToServer(MOD_RPC.railcart.Reverse)
    end
    self.inst.Physics:SetMotorVel(self.speed,0,0)
    if  TheInput:IsControlPressed(CONTROL_ACTION) or
        TheInput:IsControlPressed(CONTROL_CONTROLLER_ACTION) then
        SendModRPCToServer(MOD_RPC.railcart.DropOff)
        return
    end
    if  TheInput:IsControlPressed(CONTROL_FORCE_ATTACK) or 
        TheInput:IsControlPressed(CONTROL_ATTACK) or
        TheInput:IsControlPressed(CONTROL_CONTROLLER_ATTACK) then
        self.is_focuscamera=true
        local pos=self.inst:GetPosition()
        self.angle=math.atan2(self.nz-pos.z,self.nx-pos.x)/math.pi*180+180
        TheCamera:SetHeadingTarget(self.angle)
        TheCamera.headinggain=5
        TheCamera.mindistpitch=7.5
        TheCamera.maxdistpitch=7.5
        TheCamera.mindist=30
        TheCamera.maxdist=60
        TheCamera.fov=10
        TheCamera.targetoffset=Vector3(0,3,0)
    else
        if self.is_focuscamera then
           self.is_focuscamera=false
           self:LoadCamera()
        end
        self:SaveCamera()
    end
    
    
end

return RailCartController
