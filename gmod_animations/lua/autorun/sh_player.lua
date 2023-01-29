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