if CLIENT then
	hook.Add( "NetworkEntityCreated", "NetworkEntityCreated_ix", function(entity)

		if (entity:IsPlayer()) then
			entity:SetIK(false)

			-- we've just discovered a new player, so we need to update their animation state
			if (entity != LocalPlayer()) then
				-- we don't need to call the PlayerWeaponChanged hook here since it'll be handled below,
				-- when this player's weapon has been discovered
				hook.Run("PlayerModelChanged", entity, entity:GetModel())
			end
		elseif (entity:IsWeapon()) then
			local owner = entity:GetOwner()

			if (IsValid(owner) and owner:IsPlayer() and entity == owner:GetActiveWeapon()) then
				hook.Run("PlayerWeaponChanged", owner, entity)
			end
		end
	end)
	
	hook.Add( "PlayerSwitchWeapon", "PlayerSwitchWeapon_IX", function( ply, oldWeapon, newWeapon )

		ply:SetIK(false)
	end )
	
	hook.Add("PlayerTick","AnimFix?",function(ply)
			hook.Run("PlayerWeaponChanged", ply, newWeapon)
	end)
end