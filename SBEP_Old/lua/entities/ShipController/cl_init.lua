include('shared.lua')
--killicon.AddFont("seeker_missile", "CSKillIcons", "C", Color(255,80,0,255))
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.BCCommandable = true

function ENT:Initialize()

end

function ENT:Draw()
	
	self:DrawModel()

end