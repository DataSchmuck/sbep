AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()

	self:SetModel( "models/Items/AR2_Grenade.mdl" )
	self:SetName("Artillery Shell")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	
	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableGravity(true)
		phys:EnableDrag(true)
		phys:EnableCollisions(true)
	end
	
	self.cbt = {}
	self.cbt.health = 5000
	self.cbt.armor = 500
	self.cbt.maxhealth = 5000
		
    --self:SetKeyValue("rendercolor", "0 0 0")
	self.PhysObj = self:GetPhysicsObject()
	self.CAng = self:GetAngles()
	util.SpriteTrail( self, 0, Color(50,50,50,50), false, 10, 0, 1, 1, "trails/smoke.vmt" ) --"trails/smoke.vmt"


end

function ENT:PhysicsUpdate(phys)

	local Vel = phys:GetVelocity()
	self:SetAngles( Vel:Angle() )
	phys:SetVelocity(Vel)

	if(self.Exploded) then
		self:Remove()
		return
	end

end

function ENT:Think()
	
	if (self.PreLaunch == false) then
		self.PreLaunch = true
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			phys:EnableGravity(true)
			phys:EnableDrag(true)
			phys:EnableCollisions(true)
			phys:EnableMotion(true)
		end
		 
		--self.PhysObj:SetVelocity(self:GetForward()*3100)

		self.PreLaunch = true
	end
	
	if self.RifleNade then
		self:GetPhysicsObject():SetVelocity(self:GetForward() * 3000)
	end
	
	local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:GetPos() + (self:GetVelocity())
	trace.filter = self
	local tr = util.TraceLine( trace )
	if tr.Hit and tr.HitSky then
		self:Remove()
	end
	
end

function ENT:PhysicsCollide( data, physobj )
	if(!self.Exploded) then
		self:GoBang()
	end
end

function ENT:OnTakeDamage( dmginfo )
	if(!self.Exploded) then
		--self:GoBang()
	end
end

function ENT:Use( activator, caller )

end

function ENT:GoBang()
	self.Exploded = true
	util.BlastDamage(self, self, self:GetPos(), 200, 75)
	--gcombat.hcgexplode( self:GetPos(), 200, math.Rand(50, 100), 7)

	self:EmitSound("explode_4")
	
	local effectdata = EffectData()
	effectdata:SetOrigin(self:GetPos())
	effectdata:SetStart(self:GetPos())
	effectdata:SetAngle(self:GetAngles())
	util.Effect( "TinyWhomphSplode", effectdata )
end