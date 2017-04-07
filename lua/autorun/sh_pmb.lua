-- CONFIG, ONLY EDIT NUMBERS HERE --

PBM_CONFIG = {
	LEG_MAX_DAMAGE = 25, -- how much damage it takes for each leg to fully break
	ARM_MAX_DAMAGE = 15, -- how much damage it takes for each arm to fully break
	HEAD_MAX_DAMAGE = 10, -- how much damage it takes for your head to fully break
}

-- END CONFIG --

if SERVER then
	local pbm = {}
	pbm.punch = {
		[HITGROUP_LEFTLEG] = function(damage) return Angle(0, 0.25 * damage, 0) end,
		[HITGROUP_RIGHTLEG] = function(damage) return Angle(0, -0.25 * damage, 0) end,
		[HITGROUP_LEFTARM] = function(damage) return Angle(0, 0.75 * damage, 0) end,
		[HITGROUP_RIGHTARM] = function(damage) return Angle(0, -0.75 * damage, 0) end,
		[HITGROUP_HEAD] = function(damage) return Angle(-1 * damage, 0, 0) end,
	}

	pbm.damage = {
		[HITGROUP_LEFTLEG] = function(totalDamage, new, target)
			local maxDamage = PBM_CONFIG["LEG_MAX_DAMAGE"] * 2
			if (totalDamage - new) >= 1 then
				local old = totalDamage - new
				local oldMult = math.Clamp(old, 1, maxDamage) / maxDamage
				target:SetWalkSpeed(target:GetWalkSpeed() + (target:GetWalkSpeed() * 0.75 * oldMult))
				target:SetRunSpeed(target:GetRunSpeed() + (target:GetRunSpeed() * 0.75 * oldMult))
			end

			local mult = math.Clamp(totalDamage, 1, maxDamage) / maxDamage
			target:SetWalkSpeed(target:GetWalkSpeed() - (target:GetWalkSpeed() * 0.75 * mult))
			target:SetRunSpeed(target:GetRunSpeed() - (target:GetRunSpeed() * 0.75 * mult))
		end,

		[HITGROUP_RIGHTLEG] = function(totalDamage, new, target)
			local maxDamage = PBM_CONFIG["LEG_MAX_DAMAGE"] * 2
			if (totalDamage - new) >= 1 then
				local old = totalDamage - new
				local oldMult = math.Clamp(old, 1, maxDamage) / maxDamage
				target:SetWalkSpeed(target:GetWalkSpeed() + (target:GetWalkSpeed() * 0.75 * oldMult))
				target:SetRunSpeed(target:GetRunSpeed() + (target:GetRunSpeed() * 0.75 * oldMult))
			end

			local mult = math.Clamp(totalDamage, 1, maxDamage) / maxDamage
			target:SetWalkSpeed(target:GetWalkSpeed() - (target:GetWalkSpeed() * 0.75 * mult))
			target:SetRunSpeed(target:GetRunSpeed() - (target:GetRunSpeed() * 0.75 * mult))
		end,
	}

	function pbm.registerDeath(target)
		target.pbm = nil
	end

	function pbm.registerDamage(target, hitGroup, damageInfo)
		if !target.pbm then
			target.pbm = {
				[HITGROUP_LEFTLEG] = {0, false},
				[HITGROUP_RIGHTLEG] = {0, false},
				[HITGROUP_LEFTARM] = {0, false},
				[HITGROUP_RIGHTARM] = {0, false},
				[HITGROUP_HEAD] = {0, false}
			}
		end

		local damage = damageInfo:GetDamage()
		if target.pbm[hitGroup] != nil then
			target.pbm[hitGroup][1] = target.pbm[hitGroup][1] + damage
			local maxDamage = 25
			if hitGroup == HITGROUP_LEFTLEG or hitGroup == HITGROUP_RIGHTLEG then
				maxDamage = PBM_CONFIG["LEG_MAX_DAMAGE"]
			elseif hitGroup == HITGROUP_LEFTARM or hitGroup == HITGROUP_RIGHTARM then
				maxDamage = PBM_CONFIG["ARM_MAX_DAMAGE"]
			elseif hitgroup == HITGROUP_HEAD then
				maxDamage = PBM_CONFIG["HEAD_MAX_DAMAGE"]
			end

			if !target.pbm[hitGroup][2] and target.pbm[hitGroup][1] > maxDamage then
				target:EmitSound("npc/barnacle/neck_snap" .. tostring(math.random(1, 2)) .. ".wav")
				target.pbm[hitGroup][2] = true
			end

			if pbm.punch[hitGroup] != nil then
				target:ViewPunch(pbm.punch[hitGroup](damage))
			end

			if pbm.damage[hitGroup] != nil then
				pbm.damage[hitGroup](target.pbm[hitGroup][1], damage, target)
			end
		end
	end

	function pbm.increaseSpread(target, bulletData)
		if target and IsValid(target) and target:IsPlayer() and target.pbm then
			local maxDamage = PBM_CONFIG["ARM_MAX_DAMAGE"] * 2
			local damage = target.pbm[HITGROUP_LEFTARM][1] + target.pbm[HITGROUP_RIGHTARM][1]
			local mult = math.Clamp(damage, 1, maxDamage) / maxDamage
			bulletData.Spread = bulletData.Spread + (bulletData.Spread * mult)
			return true
		end
	end

	hook.Add("PlayerDeath", "pbm.registerDeath", pbm.registerDeath)
	hook.Add("ScalePlayerDamage", "pbm.registerDamage", pbm.registerDamage)
	hook.Add("EntityFireBullets", "pbm.increaseSpread", pbm.increaseSpread)
end