local MAXDIST=10
local MAXSPEED=20
local MAXBOOSTSPEED=38
local DELAYSPEEDMAX=3
local DELAYDIRECTIONMAX=30
local HOLDBRAKE_DROPOFF=30
local FALLTRHESHOLD=10
local MAX_SMOKECOUNTER=30
local MAX_SOUNDCOUNTER=100
local DELAYDROPOFF=30

local function IsValid(inst)
    return inst ~= nil and inst:IsValid() and not inst:HasTag("burnt")
end

local function IsOverWater(point)
    return not TheWorld.Map:IsVisualGroundAtPoint(point.x, point.y, point.z)
end

local RailCart = Class(function(self, inst)
    self.inst = inst
    self.speed=0
    self.current_track=nil
    self.threshold=1
    self.old_dist=MAXDIST
    self.target=nil
    self.target_position=nil
    self.is_speedup=0
    self.is_brakedw=0
    self.is_reverse=0
    self.speedup_factor=0.01
    self.braking_factor=0.01
    self.damping_factor=0.025
    self.aux_var=(self.damping_factor+self.speedup_factor)*MAXSPEED/self.speedup_factor
    self.reverse_counter=0
    self.dropoff_counter=0
    self.getin_counter=0
    self.play_sound=true
    self.spawn_smoke=true
    self.sound_counter=MAX_SOUNDCOUNTER
    self.smoke_counter=MAX_SMOKECOUNTER
    self.current_anim="railcart"
end)


function RailCart:SetSpeed(num)
    self.speed=num
end

function RailCart:SetPlaySound(bool)
    self.play_sound=bool
end

function RailCart:SetSpawnSmoke(bool)
    self.spawn_smoke=bool
end

function RailCart:SetDampingFactor(num)
    self.damping_factor=num
    self.aux_var=(self.damping_factor+self.speedup_factor)*MAXSPEED/self.speedup_factor
end

function RailCart:SetSpeedupFactor(num)
    self.speedup_factor=num
    self.aux_var=(self.damping_factor+self.speedup_factor)*MAXSPEED/self.speedup_factor
end

function RailCart:SetBrakingFactor(num)
    self.braking_factor=num
    self.aux_var=(self.damping_factor+self.speedup_factor)*MAXSPEED/self.speedup_factor
end

function RailCart:SpeedUp()
    self.is_speedup=1
end

function RailCart:Brake()
    self.is_brakedw=1
end

function RailCart:Reverse()
    self.is_brakedw=1
    self.is_reverse=1
end

function RailCart:TryDropOff()
    self.is_brakedw=1
    if self.speed < 0.1 and self.getin_counter <= 0 and not IsOverWater(self.inst:GetPosition()) then
        self:DropOff()
    end
end

function RailCart:ChangeDirection()
    if IsValid(self.current_track) then
        if self.target == self.current_track.components.railtrack.uptrack then
            if IsValid(self.current_track.components.railtrack.dwtrack) then
                self.target = self.current_track.components.railtrack.dwtrack
            end
        else
            if IsValid(self.current_track.components.railtrack.uptrack) then
                self.target = self.current_track.components.railtrack.uptrack
            end
        end
        if IsValid(self.target) then
            self.target_position=self.target:GetPosition()
            self.inst:FacePoint(self.target_position)
            self.inst.Physics:SetMotorVel(self.speed, 0, 0)
            self.old_dist=MAXDIST
        end
    end
end


function RailCart:SetNetInfo()
    local pos=self.inst:GetPosition()
    self.inst.player_classified.railcart_speed:set(self.speed)
    if self.current_track ~= nil then
        pos=self.target_position
    end
    if pos ~= nil then
        self.inst.player_classified.railcart_nx:set(pos.x)
        self.inst.player_classified.railcart_ny:set(pos.y)
        self.inst.player_classified.railcart_nz:set(pos.z)
    end
    self.inst.player_classified.railcart_ison:set(self.current_track ~= nil)
end


function RailCart:SetTrack(track)
    if track ~= nil then
        
        self.old_dist=MAXDIST
        self.speed=0
        self.target=nil
        self.is_speedup=0
        self.is_brakedw=0
        self.is_reverse=0
        self.reverse_counter=0
        self.dropoff_counter=0
        self.getin_counter=DELAYDROPOFF
        self.sound_counter=MAX_SOUNDCOUNTER
        self.smoke_counter=MAX_SMOKECOUNTER
        self.current_anim="railcart"
        
        self.current_track=track
    	self:SetNextTarget()
        self.inst.Transform:SetPosition(self.current_track:GetPosition():Get())
        self.inst.Physics:ClearCollidesWith(COLLISION.LIMITS)

    	local fx=SpawnPrefab("collapse_small")
    	fx.Transform:SetPosition(self.inst:GetPosition():Get())
    	
        self.inst.sg:GoToState("onrailcart")
        
        if self.inst.components.drownable ~= nil then
            self.inst.components.drownable.enabled=false
        end
        self.inst.components.playercontroller:EnableMapControls(false)
        self.inst.components.playercontroller:Enable(false)
    	self.inst:StartUpdatingComponent(self)
        self:SetNetInfo()
        self.inst:PushEvent("railcart_inout")
    end
end

function RailCart:DropOff()
    self.inst:StopUpdatingComponent(self)
    if not self.inst.player_classified.railcart_ison:value() then
        return
    end
    local last_track=self.current_track
    if last_track == nil then
        last_track=self.inst
    end
    
    self.target=nil
    
	local fx=SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(self.inst:GetPosition():Get())
    
    local isoverwater=self.inst.components.drownable and self.inst.components.drownable:IsOverWater()

    self.inst.player_classified.railcart_ison:set(false)

    self.inst.Physics:Stop()
    self.current_track=nil
    self.old_dist=MAXDIST
    if self.inst.components.drownable ~= nil then
        self.inst.components.drownable.enabled=true
    end

    self.current_track=nil
    self.old_dist=MAXDIST
    self.inst:PushEvent("railcart_inout")
    
    if self.inst.sg.currentstate.name ~="death" then
        self.inst.Physics:CollidesWith(COLLISION.LIMITS)
        self.inst.sg:GoToState("idle")

        if self.inst.components.drownable ~= nil and self.inst.components.drownable:ShouldDrown() then
                self.inst.sg:GoToState("sink_fast")
                return
        end
        if self.speed > FALLTRHESHOLD and not isoverwater then
            self.inst:PushEvent("attacked",{attacker=self.inst})
            self.inst:PushEvent("knockback",{knocker=self.inst, radius=10})
        end
    end
    
    self.speed=0
    
end



function RailCart:SetNextTarget()
    if IsValid(self.current_track) then
        if self.current_track.components.railtrack.leavetrackfn ~= nil then
            self.current_track.components.railtrack.leavetrackfn(self.inst)
        end
        
        
        local last_target=self.current_track
        
        if IsValid(self.target) then
            self.current_track=self.target
        else
            self:DropOff()
        end
        
        local railtrack=self.current_track.components.railtrack
        
        railtrack:SetNeighborhood()

        if railtrack.entertrackfn ~= nil then
            railtrack.entertrackfn(self.inst)
            return
        end
        
        self.old_dist=railtrack.track_length+2*self.threshold
        
        local pos=self.inst:GetPosition()
        local up_dist=-1
        local dw_dist=-1
        if IsValid(railtrack.uptrack) then
            up_dist=(railtrack.uptrack:GetPosition()-pos):Length()
        end
        if IsValid(railtrack.dwtrack) then
            dw_dist=(railtrack.dwtrack:GetPosition()-pos):Length()
        end
        
        self.target = up_dist > dw_dist and railtrack.uptrack or railtrack.dwtrack
        
        if not IsValid(self.target) then
            self:DropOff()
            return
        end
        
        if self.target==last_target then
            self:DropOff()
            return
        end
        
        self.target_position=self.target:GetPosition()
        
    else
        self:DropOff()
    end
end

function RailCart:MoveCart()
    
	self.inst:FacePoint(self.target_position)
    self.inst.components.playercontroller:EnableMapControls(false)
    self.inst.components.playercontroller:Enable(false)
	self.inst.Physics:SetMotorVel(self.speed, 0, 0)
	self:SetNetInfo()
	
	local dist = (self.target_position-self.inst:GetPosition()):Length()
    if (dist > self.old_dist and self.speed > 2) or (dist > MAXDIST) then
	    self:DropOff()
	else
        self.old_dist=dist
        if dist < self.threshold*(1+self.speed/MAXBOOSTSPEED) then -- Faster cart requires less precision
            self:SetNextTarget()
            self:SetNetInfo()
        end
	end
end

function RailCart:SyncAnim()
    local speed_anim="railcart_" .. tostring(math.floor((9*(self.speed+4.35))/(MAXBOOSTSPEED+2)))
    if speed_anim ~= self.current_anim then
        self.inst.AnimState:PlayAnimation(speed_anim,true)
        self.current_anim=speed_anim
    end
end

function RailCart:OnUpdate(dt)
    if not IsValid(self.current_track) or self.inst:HasTag("playerghost") then
        self:DropOff()
        return
    end

    if not IsValid(self.target) or self.inst.sg.currentstate.name =="death" then
        self:DropOff()
        return
    end
    
    if self.current_track.components.railtrack.ontrackfn ~= nil then
        self.current_track.components.railtrack.ontrackfn(self.inst)
    end
    
    local track_boost=self.current_track.components.railtrack.track_boost
    local track_damp=self.current_track.components.railtrack.track_damp
        
    self.speed= (1-self.damping_factor)*self.speed
                +(self.is_speedup+track_boost*(1-self.is_brakedw))*self.speedup_factor*((1+track_boost)*self.aux_var-self.speed)
                -(self.is_brakedw+track_damp)*self.braking_factor*self.aux_var
    
    if self.speed > MAXBOOSTSPEED then
        self.speed=MAXBOOSTSPEED
    end
    

    if self.speed < 0.1 then
        self.speed=0
        self.dropoff_counter=self.dropoff_counter+self.is_brakedw
    
        if self.dropoff_counter*(1-self.is_reverse) > HOLDBRAKE_DROPOFF and not IsOverWater(self.inst:GetPosition()) then
            self:DropOff()
            return
        end

        if self.is_reverse==1 and self.reverse_counter <= 0 then
            self:ChangeDirection()
            local fx=SpawnPrefab("collapse_small")
	        fx.Transform:SetPosition(self.inst:GetPosition():Get())
            self.reverse_counter=DELAYDIRECTIONMAX
        end
    end
    
    if self.reverse_counter > 0 then
        self.reverse_counter=self.reverse_counter-1
    end 
    
    if self.getin_counter > 0 then
        self.getin_counter=self.getin_counter-1
    end 

    self.sound_counter=self.sound_counter-self.speed
    if self.sound_counter <= 0 then
        self.sound_counter=MAX_SOUNDCOUNTER
        if self.play_sound and self.inst.SoundEmitter and self.speed > 3 then
            self.inst.SoundEmitter:PlaySoundWithParams("dontstarve/common/fireAddFuel")
        end
    end
    
    self.smoke_counter=self.smoke_counter-self.speed
    if self.smoke_counter <= 0 then
        self.smoke_counter=MAX_SMOKECOUNTER
        if self.spawn_smoke then
            local fx=SpawnPrefab("railcart_smoke")
            --local pos=self.inst:GetPosition()
            --fx.Transform:SetPosition(pos.x,pos.y+1,pos.z)
            fx.Transform:SetPosition(self.inst:GetPosition():Get())
        end
    end

    
    self.dropoff_counter=self.dropoff_counter*self.is_brakedw*(1-self.is_reverse)
    
    self.is_speedup=0
    self.is_brakedw=0
    self.is_reverse=0
    
    self:SetNetInfo()
    
    self:SyncAnim()
    
    self:MoveCart()
end

return RailCart
