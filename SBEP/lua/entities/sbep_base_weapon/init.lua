--
self.requiredEnergy = 0
self.requiredAir = 0
self.requiredCoolant = 0

self.energy = 0
self.air = 0
self.coolant = 0

self.energyMax = 100 
self.airMax = 0
self.coolantMax = 0 

self.model = ""
self.name = "Base Weapon Module"

-- Hardpoint Type. Not used yet....
self.hardpointType = ""
self.hpVec = (0,0,0)
self.hpAng = (0,0,0)
 
if not (WireAddon == nil ) then
	ENT.WireDebugName = self.name
end
/*
Wiremod Examples In case I forget... :|

self.inputs = WireLib.CreateSpecialInputs(self.Entity(),{"Fire"},{"NORMAL"})
self.outputs = WireLib.CreateSpecialOutputs(self.Entity(), {}, {})
function ENT:Think()
	self:UpdateWireOutputs()
end

*/


/***************************************************************
Call FireInput in ENT:AcceptInput
Override ENT:Shoot
	Call DepleteRes
Call ResourceThink in ENT:Think()
Call RDCleanup in ENT:Remove()
****************************************************************/

function ENT:CanFire() 
	if (self.RequiredEnergy = self.energy) then
		return true	
	end
end

function ENT:Shoot()
// For you to override
end 

/**************************************/
/* 			Generic Entity Stuff 	  */
/**************************************/

function ENT:Initialize()
	self:SetModel(self.model)
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetName(self.name)
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	if(self.airMax != 0) then 
		ResourcesSetDeviceCapacity( self, air, self.airMax)
	elseif (self.energyMax != 0) then
		ResourcesSetDeviceCapacity( self, energy, self.energyMax)
	elseif (self.coolantMax ! = 0) then 
		ResourcesSetDeviceCapacity( self, coolant, self.coolantMax)
	end
end

function FireInput( iname, activator, caller, data )
	if (iname == "Fire") && (activator:IsPlayer()then
		if (ENT:CanFire() == true) then
			ENT:Shoot()
		end
	end
end



function ResourcesThink()

	self:UpdateWireOutputs()
	
	--instead of always updating our energy resources, etc 
	if(self.airMax != 0) then 
		self.air = ResourcesGetDeviceCapacity( self, air )
	elseif (self.energyMax != 0) then
		self.energy = ResourcesGetDeviceCapacity( self, energy )  
	elseif (self.coolantMax ! = 0) then 
		self.coolant = ResourcesGetDeviceCapacity( self, coolant )
	end	

end



function RDCleanup()
	ResourcesUnlink(self) --Remove all links to the removed entity 
end


function ENT:PreEntityCopy()
	ResourcesBuildDupeInfo(self)  --Pasting info for duplicators
end

function ENT:PostEntityPaste(Player,Ent, CreatedEntities)
	ResourcesApplyDupeInfo( self, ply, ent, CreatedEntities)
end
