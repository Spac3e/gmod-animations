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
