
self.requiredEnergy = 0
self.requiredAir = 0
self.requiredCoolant = 0

self.model = ""
self.name = "Grappling Hook (Not Spawnable)"


--This is just the hook not the launcher:
function ENT:OnTouch( touchedEnt )
	if ( touchedEnt:IsPlayer() ) then
		--Do some damage to them
	elseif (touchedEnt:getClass() = "physics_prop") and --wire grab input is on
		constraint.Weld(self,touchedEnt,1,1,0, true)
	end
end

--When Wire active is off remove the constraint
-- constraint.RemoveConstraints(self, "weld")


--TODO: Elastic\Rope connection
