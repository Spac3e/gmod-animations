ix = ix or {}
ix.anim = ix.anim or {}

--[[ Anim types: overwatch metrocop citizen_male citizen_female zombie fastZombie player (Default) vortigaunt ]]--
do
	local playerMeta = FindMetaTable("Player")
	if (SERVER) then
		util.AddNetworkString("PlayerModelChanged")
		util.AddNetworkString("PlayerSelectWeapon")

		local entityMeta = FindMetaTable("Entity")

		entityMeta.ixSetModel = entityMeta.ixSetModel or entityMeta.SetModel
		playerMeta.ixSelectWeapon = playerMeta.ixSelectWeapon or playerMeta.SelectWeapon

		function entityMeta:SetModel(model)
			local oldModel = self:GetModel()

			if (self:IsPlayer()) then
				hook.Run("PlayerModelChanged", self, model, oldModel)

				net.Start("PlayerModelChanged")
					net.WriteEntity(self)
					net.WriteString(model)
					net.WriteString(oldModel)
				net.Broadcast()
			end

			return self:ixSetModel(model)
		end

		function playerMeta:SelectWeapon(className)
			net.Start("PlayerSelectWeapon")
				net.WriteEntity(self)
				net.WriteString(className)
			net.Broadcast()

			return self:ixSelectWeapon(className)
		end
	else
		net.Receive("PlayerModelChanged", function(length)
			hook.Run("PlayerModelChanged", net.ReadEntity(), net.ReadString(), net.ReadString())
		end)

		net.Receive("PlayerSelectWeapon", function(length)
			local client = net.ReadEntity()
			local className = net.ReadString()

			if (!IsValid(client)) then
				hook.Run("PlayerWeaponChanged", client, NULL)
				return
			end

			for _, v in ipairs(client:GetWeapons()) do
				if (v:GetClass() == className) then
					hook.Run("PlayerWeaponChanged", client, v)
					break
				end
			end
		end)
	end
end
HOLDTYPE_TRANSLATOR = {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["ar2"] = "smg"
HOLDTYPE_TRANSLATOR["ar2_alt"] = "smg"
HOLDTYPE_TRANSLATOR["ar2_custom1"] = "smg"
HOLDTYPE_TRANSLATOR["crossbow"] = "shotgun"
HOLDTYPE_TRANSLATOR["sniper"] = "smg"
HOLDTYPE_TRANSLATOR["rpg"] = "shotgun"
HOLDTYPE_TRANSLATOR["slam"] = "normal"
HOLDTYPE_TRANSLATOR["grenade"] = "grenade"
HOLDTYPE_TRANSLATOR["fist"] = "normal"
HOLDTYPE_TRANSLATOR["melee2"] = "melee"
HOLDTYPE_TRANSLATOR["passive"] = "passive"
HOLDTYPE_TRANSLATOR["knife"] = "melee"
HOLDTYPE_TRANSLATOR["duel"] = "pistol"
HOLDTYPE_TRANSLATOR["camera"] = "smg"
HOLDTYPE_TRANSLATOR["smg_alt"] = "smg"
HOLDTYPE_TRANSLATOR["smg_pistol"] = "pistol"
HOLDTYPE_TRANSLATOR["magic"] = "normal"
HOLDTYPE_TRANSLATOR["revolver"] = "pistol"
HOLDTYPE_TRANSLATOR["deagle"] = "pistol"

PLAYER_HOLDTYPE_TRANSLATOR = {}
PLAYER_HOLDTYPE_TRANSLATOR[""] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["fist"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["pistol"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["grenade"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["melee"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["slam"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["melee2"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["passive"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["knife"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["duel"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["bugbait"] = "normal"

ALWAYS_RAISED = {}
ALWAYS_RAISED["weapon_physgun"] = true
ALWAYS_RAISED["gmod_tool"] = true
ALWAYS_RAISED["ix_poshelper"] = true

local PLAYER_HOLDTYPE_TRANSLATOR = PLAYER_HOLDTYPE_TRANSLATOR
local HOLDTYPE_TRANSLATOR = HOLDTYPE_TRANSLATOR
local animationFixOffset = Vector(16.5438, -0.1642, -20.5493)

hook.Add("TranslateActivity","TranslateActivity_ix",function(client, act)
	local clientInfo = client:GetTable()
	local modelClass = clientInfo.ixAnimModelClass or "player"
	local bRaised = true
	if (modelClass == "player") then
		local weapon = client:GetActiveWeapon()
		local bAlwaysRaised = true
		weapon = IsValid(weapon) and weapon or nil

		if (!bAlwaysRaised and weapon and !bRaised and client:OnGround()) then
			local model = string.lower(client:GetModel())

			if (string.find(model, "zombie")) then
				local tree = ix.anim.zombie

				if (string.find(model, "fast")) then
					tree = ix.anim.fastZombie
				end

				if (tree[act]) then
					return tree[act]
				end
			end

			local holdType = weapon and (weapon.HoldType or weapon:GetHoldType()) or "normal"

			if (!bAlwaysRaised and weapon and !bRaised and client:OnGround()) then
				holdType = PLAYER_HOLDTYPE_TRANSLATOR[holdType] or "passive"
			end

			local tree = ix.anim.player[holdType]

			if (tree and tree[act]) then
				if (isstring(tree[act])) then
					clientInfo.CalcSeqOverride = client:LookupSequence(tree[act])

					return
				else
					return tree[act]
				end
			end
		end
		if !GAMEMODE then return end
		return GAMEMODE.BaseClass:TranslateActivity(client, act)
	end

	local weapon = client:GetActiveWeapon()
	local weapon = IsValid(weapon) and weapon or nil
	local holdType = weapon and (weapon.HoldType or weapon:GetHoldType()) or "normal"
	clientInfo.ixAnimTable = ix.anim[modelClass][client.ixAnimHoldType]
	if (clientInfo.ixAnimTable) then
		local glide = clientInfo.ixAnimGlide

		if (client:InVehicle()) then
			act = clientInfo.ixAnimTable[1]

			local fixVector = clientInfo.ixAnimTable[2]

			if (isvector(fixVector)) then
				client:SetLocalPos(animationFixOffset)
			end

			if (isstring(act)) then
				clientInfo.CalcSeqOverride = client:LookupSequence(act)
			else
				return act
			end
		elseif (client:OnGround()) then
			if (clientInfo.ixAnimTable[act]) then
				local act2 = clientInfo.ixAnimTable[act][bRaised and 2 or 1]

				if (isstring(act2)) then
					clientInfo.CalcSeqOverride = client:LookupSequence(act2)
				else
					return act2
				end
			end
		elseif (glide) then
			if (isstring(glide)) then
				clientInfo.CalcSeqOverride = client:LookupSequence(glide)
			else
				return clientInfo.ixAnimGlide
			end
		end
	end
end)

hook.Add("DoAnimationEvent","DoAnimationEvent_ix",function(client, event, data)
	local class = client.ixAnimModelClass

	if (class == "player") then
		if !GAMEMODE then return end
		return GAMEMODE.BaseClass:DoAnimationEvent(client, event, data)
	else
		local weapon = client:GetActiveWeapon()

		if (IsValid(weapon)) then
			local animation = client.ixAnimTable
			if !animation then return end
			
			if (event == PLAYERANIMEVENT_ATTACK_PRIMARY) then
				client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1, true)

				return ACT_VM_PRIMARYATTACK
			elseif (event == PLAYERANIMEVENT_ATTACK_SECONDARY) then
				client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1, true)

				return ACT_VM_SECONDARYATTACK
			elseif (event == PLAYERANIMEVENT_RELOAD) then
				client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.reload or ACT_GESTURE_RELOAD_SMG1, true)

				return ACT_INVALID
			elseif (event == PLAYERANIMEVENT_JUMP) then
				client:AnimRestartMainSequence()

				return ACT_INVALID
			elseif (event == PLAYERANIMEVENT_CANCEL_RELOAD) then
				client:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)

				return ACT_INVALID
			end
		end
	end

	return ACT_INVALID
end)

hook.Add("EntityRemoved","EntityRemoved_ix",function(entity)
	if (SERVER) then
	elseif (entity:IsWeapon()) then
		local owner = entity:GetOwner()
		if (IsValid(owner) and owner:IsPlayer()) then
			hook.Run("PlayerWeaponChanged", owner, owner:GetActiveWeapon())
		end
	end
end)

local function UpdatePlayerHoldType(client, weapon)
	weapon = weapon or client:GetActiveWeapon()
	local holdType = "normal"

	if (IsValid(weapon)) then
		holdType = weapon.HoldType or weapon:GetHoldType()
		holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType
		
	end
	client.ixAnimHoldType = holdType
end

local function UpdateAnimationTable(client, vehicle)
	local baseTable = ix.anim[client.ixAnimModelClass] or {}

	if (IsValid(client) and IsValid(vehicle)) then
		local vehicleClass = vehicle:IsChair() and "chair" or vehicle:GetClass()

		if (baseTable.vehicle and baseTable.vehicle[vehicleClass]) then
			client.ixAnimTable = baseTable.vehicle[vehicleClass]
		else
			client.ixAnimTable = baseTable.normal[ACT_MP_CROUCH_IDLE]
		end
	else
		client.ixAnimTable = baseTable[client.ixAnimHoldType]
	end

	client.ixAnimGlide = baseTable["glide"]
end

hook.Add("PlayerWeaponChanged","PlayerWeaponChanged_ix",function(client, weapon)
	UpdatePlayerHoldType(client, weapon)
	UpdateAnimationTable(client)
end)

hook.Add("PlayerSwitchWeapon","PlayerSwitchWeapon_ix",function(client, oldWeapon, weapon)
	if (!IsFirstTimePredicted()) then
		return
	end
	if (SERVER) then
		net.Start("PlayerSelectWeapon")
			net.WriteEntity(client)
			net.WriteString(weapon:GetClass())
		net.Broadcast()
	end

	hook.Run("PlayerWeaponChanged", client, weapon)
end)

hook.Add("PlayerModelChanged","PlayerModelChanged_ix",function(client, model)
	client.ixAnimModelClass = ix.anim.GetModelClass(model)

	UpdateAnimationTable(client)
end)
do
	local vectorAngle = FindMetaTable("Vector").Angle
	local normalizeAngle = math.NormalizeAngle

	hook.Add("CalcMainActivity","CalcMainActivity_ix",function(client, velocity)
		local clientInfo = client:GetTable()
		local forcedSequence = client:GetNW2Var("forcedSequence")

		if (forcedSequence) then
			if (client:GetSequence() != forcedSequence) then
				client:SetCycle(0)
			end

			return -1, forcedSequence
		end

		client:SetPoseParameter("move_yaw", normalizeAngle(vectorAngle(velocity)[2] - client:EyeAngles()[2]))

		local sequenceOverride = clientInfo.CalcSeqOverride
		clientInfo.CalcSeqOverride = -1
		clientInfo.CalcIdeal = ACT_MP_STAND_IDLE

		if !GAMEMODE then return end
		local BaseClass = GAMEMODE.BaseClass

		if (BaseClass:HandlePlayerNoClipping(client, velocity) or
			BaseClass:HandlePlayerDriving(client) or
			BaseClass:HandlePlayerVaulting(client, velocity) or
			BaseClass:HandlePlayerJumping(client, velocity) or
			BaseClass:HandlePlayerSwimming(client, velocity) or
			BaseClass:HandlePlayerDucking(client, velocity)) then
		else
			local length = velocity:Length2DSqr()

			if (length > 22500) then
				clientInfo.CalcIdeal = ACT_MP_RUN
			elseif (length > 0.25) then
				clientInfo.CalcIdeal = ACT_MP_WALK
			end
		end

		clientInfo.m_bWasOnGround = client:OnGround()
		clientInfo.m_bWasNoclipping = (client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle())

		return clientInfo.CalcIdeal, sequenceOverride or clientInfo.CalcSeqOverride or -1
	end)
end
ix.anim.citizen_male = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	passive = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_SMG1_RELAXED},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_RIFLE_RELAXED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_RIFLE_RELAXED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_RANGE_ATTACK_PISTOL},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_ATTACK_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_RELOAD_PISTOL
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_RANGE_ATTACK_THROW
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING
	},
	glide = ACT_GLIDE,
	vehicle = {
		["prop_vehicle_prisoner_pod"] = {"podpose", Vector(-3, 0, 0)},
		["prop_vehicle_jeep"] = {ACT_BUSY_SIT_CHAIR, Vector(14, 0, -14)},
		["prop_vehicle_airboat"] = {ACT_BUSY_SIT_CHAIR, Vector(8, 0, -20)},
		chair = {ACT_BUSY_SIT_CHAIR, Vector(1, 0, -23)}
	},
}

ix.anim.citizen_female = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	passive = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_SMG1_RELAXED},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_RIFLE_RELAXED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_RIFLE_RELAXED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_RELOAD_PISTOL
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SMG1,
		reload = ACT_GESTURE_RELOAD_SMG1
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_RANGE_ATTACK_THROW
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING
	},
	glide = ACT_GLIDE,
	vehicle = ix.anim.citizen_male.vehicle
}
ix.anim.metrocop = {
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	passive = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK_PISTOL, ACT_WALK_AIM_PISTOL},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_PISTOL, ACT_RUN_AIM_PISTOL},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_GESTURE_RANGE_ATTACK_PISTOL,
		reload = ACT_GESTURE_RELOAD_PISTOL
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_COMBINE_THROW_GRENADE
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
		[ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING_GESTURE
	},
	glide = ACT_GLIDE,
	vehicle = {
		chair = {ACT_COVER_PISTOL_LOW, Vector(5, 0, -5)},
		["prop_vehicle_airboat"] = {ACT_COVER_PISTOL_LOW, Vector(10, 0, 0)},
		["prop_vehicle_jeep"] = {ACT_COVER_PISTOL_LOW, Vector(18, -2, 4)},
		["prop_vehicle_prisoner_pod"] = {ACT_IDLE, Vector(-4, -0.5, 0)}
	}
}
ix.anim.overwatch = {
	normal = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", "idle_unarmed"},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", "walkunarmed_all"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	passive = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SHOTGUN},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_SHOTGUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_SHOTGUN},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	grenade = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	melee = {
		[ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
		[ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
		[ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
		[ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
		[ACT_LAND] = {ACT_RESET, ACT_RESET},
		attack = ACT_MELEE_ATTACK_SWING_GESTURE
	},
	glide = ACT_GLIDE
}
ix.anim.vortigaunt = {
	melee = {
		["attack"] = ACT_MELEE_ATTACK1,
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "ActionIdle"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
	},
	grenade = {
		["attack"] = ACT_MELEE_ATTACK1,
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "ActionIdle"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK}
	},
	normal = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
		["attack"] = ACT_MELEE_ATTACK1
	},
	passive = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
		["attack"] = ACT_MELEE_ATTACK1
	},
	pistol = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		["reload"] = ACT_IDLE,
		[ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
	},
	shotgun = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		["reload"] = ACT_IDLE,
		[ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
	},
	smg = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		["reload"] = ACT_IDLE,
		[ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"}
	},
	beam = {
		[ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
		[ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
		[ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
		[ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
		[ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
		["attack"] = ACT_GESTURE_RANGE_ATTACK1,
		["reload"] = ACT_IDLE,
		["glide"] = {ACT_RUN, ACT_RUN}
	},
	glide = "jump_holding_glide"
}
ix.anim.player = {
	normal = {
		[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE,
		[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
		[ACT_MP_WALK] = ACT_HL2MP_WALK,
		[ACT_MP_RUN] = ACT_HL2MP_RUN,
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	},
	passive = {
		[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_PASSIVE,
		[ACT_MP_WALK] = ACT_HL2MP_WALK_PASSIVE,
		[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_PASSIVE,
		[ACT_MP_RUN] = ACT_HL2MP_RUN_PASSIVE,
		[ACT_LAND] = {ACT_RESET, ACT_RESET}
	}
}
ix.anim.zombie = {
	[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_ZOMBIE,
	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_01,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_ZOMBIE_02,
	[ACT_MP_RUN] = ACT_HL2MP_RUN_ZOMBIE,
	[ACT_LAND] = {ACT_RESET, ACT_RESET}
}
ix.anim.fastZombie = {
	[ACT_MP_STAND_IDLE] = ACT_HL2MP_WALK_ZOMBIE,
	[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
	[ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_ZOMBIE_05,
	[ACT_MP_WALK] = ACT_HL2MP_WALK_ZOMBIE_06,
	[ACT_MP_RUN] = ACT_HL2MP_RUN_ZOMBIE_FAST,
	[ACT_LAND] = {ACT_RESET, ACT_RESET}
}

local translations = {}

function ix.anim.SetModelClass(model, class)
	if (!ix.anim[class]) then
		error("'" .. tostring(class) .. "' is not a valid animation class!")
	end

	translations[model:lower()] = class
end
ix.anim.SetModelClass("models/police.mdl", "metrocop")
ix.anim.SetModelClass("models/combine_super_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldier_prisonGuard.mdl", "overwatch")
ix.anim.SetModelClass("models/combine_soldier.mdl", "overwatch")
ix.anim.SetModelClass("models/vortigaunt.mdl", "vortigaunt")
ix.anim.SetModelClass("models/vortigaunt_blue.mdl", "vortigaunt")
ix.anim.SetModelClass("models/vortigaunt_doctor.mdl", "vortigaunt")
ix.anim.SetModelClass("models/vortigaunt_slave.mdl", "vortigaunt")
function ix.anim.GetModelClass(model)
	model = string.lower(model)
	local class = translations[model]

	if (!class and string.find(model, "/player")) then
		return "player"
	end

	class = class or "citizen_male"

	if (class == "citizen_male" and (
		string.find(model, "female") or
		string.find(model, "alyx") or
		string.find(model, "mossman"))) then
		class = "citizen_female"
	end

	return class
end
if (SERVER) then
	util.AddNetworkString("ixSequenceSet")
	util.AddNetworkString("ixSequenceReset")

	local playerMeta = FindMetaTable("Player")
	function playerMeta:ForceSequence(sequence, callback, time, bNoFreeze)
		hook.Run("PlayerEnterSequence", self, sequence, callback, time, bNoFreeze)

		if (!sequence) then
			net.Start("ixSequenceReset")
				net.WriteEntity(self)
			net.Broadcast()

			return
		end

		sequence = self:LookupSequence(tostring(sequence))

		if (sequence and sequence > 0) then
			time = time or self:SequenceDuration(sequence)

			self.ixCouldShoot = self:GetNW2Var("canShoot", false)
			self.ixSeqCallback = callback
			self:SetCycle(0)
			self:SetPlaybackRate(1)
			self:SetNW2Var("forcedSequence", sequence)
			self:SetNW2Var("canShoot", false)

			if (!bNoFreeze) then
				self:SetMoveType(MOVETYPE_NONE)
			end

			if (time > 0) then
				timer.Create("ixSeq"..self:EntIndex(), time, 1, function()
					if (IsValid(self)) then
						self:LeaveSequence()
					end
				end)
			end

			net.Start("ixSequenceSet")
				net.WriteEntity(self)
			net.Broadcast()

			return time
		elseif (callback) then
			callback()
		end

		return false
	end
	function playerMeta:LeaveSequence()
		hook.Run("PlayerLeaveSequence", self)

		net.Start("ixSequenceReset")
			net.WriteEntity(self)
		net.Broadcast()

		self:SetNW2Var("canShoot", self.ixCouldShoot)
		self:SetNW2Var("forcedSequence", nil)
		self:SetMoveType(MOVETYPE_WALK)
		self.ixCouldShoot = nil

		if (self.ixSeqCallback) then
			self:ixSeqCallback()
		end
	end
else
	net.Receive("ixSequenceSet", function()
		local entity = net.ReadEntity()

		if (IsValid(entity)) then
			hook.Run("PlayerEnterSequence", entity)
		end
	end)

	net.Receive("ixSequenceReset", function()
		local entity = net.ReadEntity()

		if (IsValid(entity)) then
			hook.Run("PlayerLeaveSequence", entity)
		end
	end)
end
