local PLUGIN = PLUGIN
PLUGIN.name = "Durability"
PLUGIN.author = "Wayne"
PLUGIN.desc = "Sets up a durability system for guns and melee weapons."

nut.config.add("maxValueDurability", 100, "Maximum value of the durability.", nil, {
	data = {min = 1, max = 1000},
	category = PLUGIN.name
})

if (SERVER) then
	function PLUGIN:EntityFireBullets(entity, bullet)
		if (IsValid(entity) and entity:IsPlayer()) then
			local weapon = entity:GetActiveWeapon()
		
			if (weapon) then
				local inventory = entity:getChar():getInv():getItems()
				for k, v in pairs(inventory) do
					if v.class == weapon:GetClass() and v:getData("equip", false) then
						local durability = v:getData("durability", nut.config.get("maxValueDurability", 100))
					
						if math.random(1, 16) == 1 and durability > 0 then
							v:setData("durability", durability - 1)
						end
						
						if durability < 1 then
							v:setData("equip", nil)
							entity.carryWeapons = entity.carryWeapons or {}

							local weapon = entity.carryWeapons[v.weaponCategory]
							if (!IsValid(weapon)) then
								weapon = entity:GetWeapon(v.class)
							end
		
							if (IsValid(weapon)) then
								v:setData("ammo", weapon:Clip1())

								entity:StripWeapon(v.class)
								entity.carryWeapons[v.weaponCategory] = nil
								entity:EmitSound("items/ammo_pickup.wav", 80)
								
								v:RemovePAC(entity)
							end
						end
						
						bullet.Damage = (bullet.Damage / 100) * durability
						bullet.Spread = bullet.Spread * (1 + (1 - ((1 / 100) * durability)))
						
						durability = nil
					end
				end
			end
		end
	end
end

function PLUGIN:InitializedPlugins()
	local max = nut.config.get("maxValueDurability", 100)
	
	for k, v in pairs(nut.item.list) do
		if not v.isWeapon then continue end
	
		if CLIENT then
			function v:PaintOver(item, w, h)
				if (item:getData("equip")) then
					surface.SetDrawColor(110, 255, 110, 100)
					surface.DrawRect(w - 14, h - 14, 8, 8)
				end
				
				local durability = math.Clamp(item:getData("durability", max) / max, 0, max)
				
				if durability > 0 then
					surface.SetDrawColor(255, 150, 50, 255)
					surface.DrawRect(0, h - 2, w * durability, 2)
				end
			end
			
			function v:getDesc()
				local desc = L(self.description or "noDesc")
				desc = desc .. "\n[*] "..L("DurabilityCondition")..": " .. self:getData("durability", max) .. "/" .. max
				return desc
			end
		end
		
		v.functions.Repair = {
			name = "Repair",
			tip = "equipTip",
			icon = "icon16/bullet_wrench.png",
			onRun = function(item)
				local client = item.player
				local has_remnabor = client:getChar():getInv():hasItem("remnabor_weapon")
				
				if has_remnabor then
					has_remnabor:remove()
					item:setData("durability", math.Clamp(item:getData("durability", max) + (25), 0, max))
					client:EmitSound("interface/inv_repair_kit.ogg", 80)
				else
					client:Notify(L("RepairKitWrong"))
				end	

				has_remnabor = nil
				
				return false
			end,
			
			OnCanRun = function(item)
				if item:getData("durability", max) >= max then return false end
				
				if not item.player:getChar():getInv():hasItem("remnabor_weapon") then
					return false
				end
				
				return true
			end
		}
	end
end

function PLUGIN:CanPlayerEquipItem(client, item)
	return item:getData("durability", ix.config.Get("maxValueDurability", 100)) > 0
end