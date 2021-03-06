AddCSLuaFile("autorun/client/cl_dynamic_gibs.lua")

local GCombatFF = CreateConVar("gcombat_fixes_nofriendlyfire","0",{ FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY })

--Models that shouldn't Gib. There actually should be....alot.
local blacklist = {"ragdoll","player","npc","wreckedstuff"}

local function GibEntityRemove( ent )
	if (ent.GibTime and ent.GibTime >= CurTime()) and ((not ent.GComGib) or ent.GComGib + 1 < CurTime()) and ent:IsValid() and (ent:Health() <= 0) and (ent:GetModel() ~= "") and (not IsPartiallyInTable(blacklist,ent:GetModel())) and (not IsPartiallyInTable(blacklist,ent:GetClass())) then	
		for k,v in pairs(player.GetAll()) do
			if v:GetInfo("cl_Dynamic_gibs") and v:GetInfo("cl_Dynamic_gibs") == "1" then
				DynamicGibEnt(ent,ply)
			end
		end
	end
end 
hook.Add("EntityRemoved","Dynamic_Gib_System_Hook",GibEntityRemove)

local function GibEntityData(ent, inflkr, atkr, amt, dmginfo)
	ent.GibTime = CurTime()+1
end
hook.Add("EntityTakeDamage","Dynamic_Gib_System_Data_Hook",GibEntityData)


function DynamicGibEnt(ent,ply)
	if ent and ent:IsValid() and ply and ply:IsValid() then
		umsg.Start("gib_message", ply)
			umsg.Angle( ent:GetAngles() )
			umsg.Vector( ent:GetPos() )
			if ent.environment and ent.environment.IsSpace and ent.environment:IsSpace() then
				umsg.Bool(ent.environment:IsSpace())
			else
				umsg.Bool(false)
			end
			umsg.String(ent:GetModel() or "")
			umsg.Short(ent:GetSkin())
		umsg.End() 
	end
end 

function IsPartiallyInTable(tbl,str)
	if tbl and str then
		for k,v in pairs(tbl) do
			if type(v) == "string" then
				if string.find(string.lower(str),string.lower(v)) then return true end
			end
		end
	end
	return false
end

local function RemoveValeFromTable(tbl,val)
	local ret = table.Copy(tbl)
	for k,v in ipairs(tbl) do
		if string.lower(v) == string.lower(val) then
			ret[k] = nil
		end
	end
	return ret
end

local function SaveBlacklistToFile()
	file.Write("DynamicGibBlacklist.txt",glon.encode(blacklist))
end

function AddItemToBlacklist(ply,cmd,arg)
	if ply:IsAdmin() then
		if type(arg) == "table" then
			table.insert(blacklist,table.concat(arg," "))
		elseif type(arg) == "string" then
			table.insert(blacklist,arg)
		end
		SaveBlacklistToFile()
	end
end
concommand.Add("sv_dynamic_gibs_addtoblacklist",AddItemToBlacklist)

function RemoveItemFromBlacklist(ply,cmd,arg)
	if ply:IsAdmin() then
		if type(arg) == "table" then
			RemoveValeFromTable(blacklist,table.concat(arg," "))
		elseif type(arg) == "string" then
			RemoveValeFromTable(blacklist,arg)
		end
		SaveBlacklistToFile()
	end
end
concommand.Add("sv_dynamic_gibs_removefromblacklist",RemoveItemFromBlacklist)

concommand.Add("sv_dynamic_gibs_printblacklist",function(ply,cmd,arg) 
	if ply:IsAdmin() then
		ply:ChatPrint("Dynamic Gib Mod by Levybreak, Current Serverside Gib Blacklist Banned Expressions:")
		for k,v in ipairs(blacklist) do
			ply:ChatPrint(v)
		end
	end
end)

local function PathIsEntity(path)
	path = string.GetPathFromFilename(path)
	if string.find(path,"/entities/",1,true) then
		local ret = nil
		local tbl = string.Explode(path,"//")
		for k,v in ipairs(tbl) do
			if v == "entities" then ret = tbl[k+1] break end
		end
		return ret
	end
end

hook.Add("InitPostEntity","Dynamic_Gibs_LoadConfig",function() 
	if file.Exists("DynamicGibBlacklist.txt") then
		blacklist = glon.decode(file.Read("DynamicGibBlacklist.txt"))
	end
	
	if gcombat then --we have gcombat... (this is so full of hax you should not read it for fear of utter confusion)
		local OldDevFunc = gcombat.devhit
		
		local lastEntCalled = nil
		local lastCallTS = 0
		local TSTolerance = 0.1
		local DistanceTolerance = 200
		function gcombat.devhit(e,d,p) --override the core hit functions, returning nil negates all effects
			lastEntCalled = e
			lastCallTS = CurTime()
			e.GibTime = 0
			e.GComGib = CurTime()
			return OldDevFunc(e,d,p)
		end
		function cbt_dealdevhit(e,d,p)
			lastEntCalled = e
			lastCallTS = CurTime()
			e.GibTime = 0
			e.GComGib = CurTime()
			return OldDevFunc(e,d,p)
		end
		
		local OldHCG = gcombat.hcghit
		function gcombat.hcghit( entity, damage, pierce, src, dest)
			local FF = GCombatFF:GetBool()
			if FF then
				if entity.Player or entity.GetPlayer or entity.Owner or CPPI then
					local info = debug.getinfo(2,"nSu") --me -> this func -> ent who called me
					if string.find(string.lower(info.source),"sv_combatdamage") then info = debug.getinfo(3,"nSu") end --we were called form the explode func, really.
					local class = PathIsEntity(info.source)
					if class then
						print(class)
						local tbl = ents.FindInSphere(src,DistanceTolerance)
						if tbl and tbl[1] then
							local ent = nil
							for k,v in ipairs(tbl) do
								if v:GetClass() == class then ent = v break end
							end
							if ent and ent:IsValid() and (ent.Player or ent.GetPlayer or ent.Owner or CPPI) then --now that we've gone through all that shit to determine who fired (hopefully)
								if ent.Player and entity.Player then
									if ent.Player == entity.Player then return end --fucked if I know, just another possibility
								elseif ent.GetPlayer and entity.GetPlayer then
									if (ent:GetPlayer() == entity:GetPlayer() or (ent:GetPlayer().IsFriend and ent:GetPlayer():IsFriend(entity:GetPlayer()))) then return end --Ownership mod
								elseif ent.Owner and entity.Owner then 
									if ent.Owner == entity.Owner then return end --fucked if I know, just another possibility
								elseif SPropProtection then
									if ent:CPPIGetOwner() and entity:CPPIGetOwner() and ((ent:CPPIGetOwner() == entity:CPPIGetOwner()) or table.HasValue(ent:CPPIGetOwner():CPPIGetFriends(),entity:CPPIGetOwner())) then return end --FPP, SPP, and UPS
								else	--how da fuc? lets go to default owner function then...???
									if ent:GetOwner() == entity:GetOwner() then return end
								end
							end
						end
					end
				end
			end
			return OldHCG(entity, damage, pierce, src, dest)
		end
		cbt_dealhcghit = gcombat.hcghit

		local OldNRG = gcombat.nrghit
		function gcombat.nrghit( entity, damage, pierce, src, dest)
			local FF = GCombatFF:GetBool()
			if FF then
				if entity.Player or entity.GetPlayer or entity.Owner or CPPI then
					local info = debug.getinfo(2,"nSu") --me -> this func -> ent who called me
					if string.find(string.lower(info.source),"sv_combatdamage") then info = debug.getinfo(3,"nSu") end --we were called form the explode func, really.
					local class = PathIsEntity(info.source)
					if class then
						print(class)
						local tbl = ents.FindInSphere(src,DistanceTolerance)
						if tbl and tbl[1] then
							local ent = nil
							for k,v in ipairs(tbl) do
								if v:GetClass() == class then ent = v break end
							end
							if ent and ent:IsValid() and (ent.Player or ent.GetPlayer or ent.Owner or CPPI) then --now that we've gone through all that shit to determine who fired (hopefully)
								if ent.Player and entity.Player then
									if ent.Player == entity.Player then return end --fucked if I know, just another possibility
								elseif ent.GetPlayer and entity.GetPlayer then
									if (ent:GetPlayer() == entity:GetPlayer() or (ent:GetPlayer().IsFriend and ent:GetPlayer():IsFriend(entity:GetPlayer()))) then return end --Ownership mod
								elseif ent.Owner and entity.Owner then 
									if ent.Owner == entity.Owner then return end --fucked if I know, just another possibility
								elseif SPropProtection then
									if ent:CPPIGetOwner() and entity:CPPIGetOwner() and ((ent:CPPIGetOwner() == entity:CPPIGetOwner()) or table.HasValue(ent:CPPIGetOwner():CPPIGetFriends(),entity:CPPIGetOwner())) then return end --FPP, SPP, and UPS
								else	--how da fuc? lets go to default owner function then...???
									if ent:GetOwner() == entity:GetOwner() then return end
								end
							end
						end
					end
				end
			end
			return OldNRG(entity, damage, pierce, src, dest)
		end
		cbt_dealnrghit = gcombat.nrghit
		
		local Entity = FindMetaTable("Entity")
		Entity.OldPreGCSetModel = Entity.SetModel
		function Entity:SetModel(str) --this is a fix for gcombat gibs not inheriting the parent's skin, it should work 99% of the time, unless someone's doing some wierd shit.
			if self:GetClass() == "wreckedstuff" and lastEntCalled and lastEntCalled:IsValid() and lastCallTS <= (CurTime() + TSTolerance) then
				if string.lower(str) == string.lower(lastEntCalled:GetModel()) then
					self:SetSkin(lastEntCalled:GetSkin())
				end
			end
			self:OldPreGCSetModel(str)
		end
		
		require("scripted_ents")
		
		local ENT = scripted_ents.Get("wreckedstuff") --override the model's init
		if ENT then 
			ENT.GCOldInit = ENT.Initialize
			
			function ENT:Initialize()
				if not self.copy then --we are the original, make the second half now.
				
					local PlaneNorm = Vector(math.Rand(0,1000),math.Rand(0,1000),math.Rand(0,1000)):Normalize()
					
					local pos = self:GetPos()
					local Force = Vector((pos.x + math.random(-400,400)),(pos.y + math.random(-400,400)),(pos.z + math.random(-400,400))):GetNormalized() * 300
				
					math.randomseed(CurTime())
					self.exploded = false
					self.fuseleft = CurTime() + 2
					self.deathtype = 0	
					self:PhysicsInit( SOLID_VPHYSICS )
					self:SetMoveType( MOVETYPE_VPHYSICS )
					self:SetSolid( SOLID_VPHYSICS ) 
					self:SetColor(Color(20,20,20,255))
					self:SetCollisionGroup( 0 )
					local phys = self:GetPhysicsObject()  	
					if (phys:IsValid()) then  		
						phys:Wake()
						phys:EnableGravity(false)
						phys:ApplyForceCenter(Force)
					end 
					
					self.brother = ents.Create("wreckedstuff")
					self.brother:SetModel( self:GetModel() )
					self.brother:SetAngles( self:GetAngles() )
					self.brother:SetPos( self:GetPos() )
					self.brother:SetSkin(self:GetSkin())
					self.brother.copy = true
					self.brother:Spawn()
					self.brother:Activate()
					local phys = self.brother:GetPhysicsObject()  	
					if (phys:IsValid()) then  		
						phys:Wake()
						phys:EnableGravity(false)
						phys:ApplyForceCenter(Force+((PlaneNorm+self:GetAngles():Forward()))*20)
					end 
					
					SendUserMessage("ApplyClippingPlaneToGCObject",player.GetAll(),self:EntIndex(),PlaneNorm,false)
					SendUserMessage("ApplyClippingPlaneToGCObject",player.GetAll(),self.brother:EntIndex(),PlaneNorm,true)
				else
					math.randomseed(CurTime())
					self.exploded = false
					self.fuseleft = CurTime() + 2
					self.deathtype = 0	
					self:PhysicsInit( SOLID_VPHYSICS )
					self:SetMoveType( MOVETYPE_VPHYSICS )
					self:SetSolid( SOLID_VPHYSICS ) 
					self:SetColor(Color(20,20,20,255))
					self:SetCollisionGroup( 0 )
				end
			end
			
			scripted_ents.Register(ENT,"wreckedstuff",true) --let's override it... hehehehe
		end
	end
end)