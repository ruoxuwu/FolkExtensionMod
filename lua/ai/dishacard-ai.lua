--keep_value
sgs.ai_keep_value.PunctureSlash = 2.2
sgs.ai_keep_value.BloodSlash = 2.4
sgs.ai_keep_value.PoisonPeach = 5
sgs.ai_keep_value.Plague = -1
sgs.ai_keep_value.SuddenStrike = 3
sgs.ai_keep_value.Cover = 4.5
sgs.ai_keep_value.IrresistibleForce = 2
sgs.ai_keep_value.Rebound = 4.5
sgs.ai_keep_value.Rob = 3.5

--use_value
sgs.ai_use_value.PunctureSlash = 4.4
sgs.ai_use_value.BloodSlash = 4.4
sgs.ai_use_value.PoisonPeach = 2
sgs.ai_use_value.Plague = -1
sgs.ai_use_value.SuddenStrike = 3
sgs.ai_use_value.Cover = 6
sgs.ai_use_value.IrresistibleForce = 2
sgs.ai_use_value.Rebound = 6
sgs.ai_keep_value.Rob = 5.5

sgs.weapon_range.YitianJian = 2
sgs.weapon_range.QixingBlade = 2
sgs.weapon_range.JiaSuo = 1
sgs.weapon_range.LuofengBow = 1

function SmartAI:askForSinglePeach(dying)
	local card_str

	if self:isFriend(dying) then
		local buqu = dying:getPile("buqu")
		if not buqu:isEmpty() then
			local same = false
			for i, card_id in sgs.qlist(buqu) do
				for j, card_id2 in sgs.qlist(buqu) do
					if i ~= j and sgs.Sanguosha:getCard(card_id):getNumber() == sgs.Sanguosha:getCard(card_id2):getNumber() then
						same = true
						break
					end
				end
			end
			if not same then return "." end
		end
		if (self.player:objectName() == dying:objectName()) then
			card_str = self:getCards("Analeptic") or self:getCards("Peach")
		else
			card_str = self:getCards("Peach")
		end
	elseif not self:isFriend(dying) and self:objectiveLevel(dying) > 3 then
		card_str = self:getCardId("PoisonPeach")		
	end
	
	return card_str or "."
end

function SmartAI:useCardPunctureSlash(...)
	self:useCardSlash(...)
end

function SmartAI:useCardBloodSlash(...)
	self:useCardSlash(...)
end

function SmartAI:useCardPoisonPeach(card, use)
	if not self.player:hasSkill("yiji") then return end
	use.card = card
end

function sgs.ai_slash_weaponfilter.luofeng_bow(to, self)
	return to:getHandcardNum() > self.player:getHp()
end

sgs.ai_skill_invoke.yitian_jian = function(self, data)
	local damage = data:toDamage()
	if self:getCardsNum("Slash") < 2 then return false 
	else
		if self.player:inMyAttackRange(damage.to) then
			return true
		end
	end
end

sgs.ai_skill_choice.yitian_jian = function(self, choices)
	local target = self.room:getTag("Yitian_jianTarget"):toPlayer()
	if self:isFriend(target) then
		return "torecover"
	else
		return "todamage"
	end
end

function SmartAI:useCardJiaoLiao(card, use)
	use.broken = true
	for _, enemy in ipairs(self.enemies) do
		if not enemy:getArmor() and not self:hasSkills("jijiu|leiji|longhun",enemy) then
			use.card = card
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end

function sgs.ai_weapon_value.YitianJian(self, enemy)
	return 2 
end

function sgs.ai_weapon_value.QixingBlade(self, enemy)
	return 2
end

function sgs.ai_weapon_value.LuofengBow(self, enemy)
	if enemy and enemy:getHandcardNum() > self.player:getHp() then return 10 end
end

function sgs.ai_weapon_value.JiaSuo(self, enemy)
	return -10
end

sgs.ai_armor_value["jiaoliao"] = function()
	return -10
end

function SmartAI:useCardJiaSuo(card, use)
	use.broken = true
	for _, enemy in ipairs(self.enemies) do
		use.card = card
		if use.to then
			use.to:append(enemy)
		end
		return
	end
end

function SmartAI:useCardIrresistibleForce(card, use)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() > 0 then
			use.card = card
			return
		end
	end
end

function sgs.ai_slash_prohibit.leiji(self, to, card)
	if self:isFriend(to) then return false end
	if to:getArmor() and to:getArmor():inherits("JiaoLiao") then return false end	
	local hcard = to:getHandcardNum()
	if self.player:hasSkill("tieji") or
		(self.player:hasSkill("liegong") and (hcard>=self.player:getHp() or hcard<=self.player:getAttackRange())) then return false end
	if to:getHandcardNum() >= 2 then return true end
	if self:isEquip("EightDiagram", to) then
		local equips = to:getEquips()
		for _, equip in sgs.qlist(equips) do
			if equip:getSuitString() == "spade" then return true end
		end
	end
end

function SmartAI:askForNullification(trick, from, to, positive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local null_card
	null_card = self:getCardId("Nullification")
	if null_card then null_card = sgs.Card_Parse(null_card) else return end

	if positive then
		if from and self:isEnemy(from) and (sgs.ai_explicit[from:objectName()] ~= "" or sgs.isRolePredictable()) then
			if trick:inherits("ExNihilo") and self:getOverflow(from) == 0 then return null_card end
			if trick:inherits("IronChain") and not self:isEquip("Vine", to) then return nil end
			if self:isFriend(to) then
				if trick:inherits("Dismantlement") then
					if to:getArmor() then return null_card end
				else
					if trick:inherits("Snatch") then return null_card end
					if trick:inherits("Rob") then return null_card	end
					if trick:inherits("Rebound") then return null_card end
					if trick:inherits("Cover") then return null_card end
					if self:isWeak(to) then
						if trick:inherits("Duel") then
							return null_card
						elseif trick:inherits("FireAttack") then
							if from:getHandcardNum() > 2 then return null_card end
						end
					end
				end
			elseif self:isEnemy(to) then
				if (trick:inherits("Snatch") or trick:inherits("Dismantlement")) and to:getCards("j"):length() > 0 then
					return null_card
				end
			end
		end

		if self:isFriend(to) then
			if trick:inherits("Indulgence") or trick:inherits("SupplyShortage") then
				return null_card
			end
			if self:isWeak(to) then
				if trick:inherits("ArcheryAttack") then
					if self:getCardsNum("Jink", to) == 0 then return null_card end
				elseif trick:inherits("SavageAssault") then
					if self:getCardsNum("Slash", to) == 0 then return null_card end
				elseif trick:inherits("SuddenStrike") then
					if self:getCardsNum("Jink", to) == 0 then return null_card end
				elseif trick:inherits("IrresistibleForce") then
					if to:getEquips():length() > 0 then return null_card end
				end
			end
		end
		if from then
			if self:isEnemy(to) then
				if trick:inherits("GodSalvation") and self:isWeak(to) then
					return null_card
				end
			end
		end
	else
		if from then
			if from:objectName() == to:objectName() then
				if self:isFriend(from) then return null_card else return end
			end
			if not (trick:inherits("AmazingGrace") or trick:inherits("GodSalvation") or trick:inherits("AOE")) then
				if self:isFriend(from) then
					if ("snatch|dismantlement"):match(trick:objectName()) and to:isNude() then
					elseif trick:inherits("FireAttack") and to:isKongcheng() then
					else return null_card end
				end
			end
		else
			if self:isEnemy(to) and (sgs.ai_explicit[to:objectName()] ~= "" or sgs.isRolePredictable()) then return null_card else return end
		end
	end
end

function SmartAI:askForCover(effect)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local card
	card = self:getCardId("Cover")
	if card then card = sgs.Card_Parse(card) else return end
	
	if effect.card:inherits("Duel") and self.player ~= effect.to then
		if(self.player ~= effect.to and self:isFriend(effect.to)) then
			if(self:getCardsNum("Slash") > 0 or self:getCardsNum("Rebound") > 0)then
				return card
			end
		elseif(self.player:hasSkill("tianxiang"))then
			return card
		end
	elseif effect.card:inherits("Slash") and self.player ~= effect.to then
		if(self:isFriend(effect.to)) then
			if(effect.to:getArmor() and effect.to:getArmor():objectName() == "eight_diagram")then return end
			if(self.player:getArmor() and (self.player:getArmor():objectName() == "jiaoliao" or self.player:getArmor():objectName() == "vine"))then return end
			if(self:getCardsNum("Jink") > 0 or self:getCardsNum("Rebound") > 0)then
				return card
			end
		elseif(self.player:hasSkill("leiji") and self:getCardsNum("Jink") > 0)then
			return card
		end
    end
end

function SmartAI:askForRebound(damage)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local card
	card = self:getCardId("Rebound")
	if card then card = sgs.Card_Parse(card) else return end
	
	if damage.from and self.player == damage.to and not self:isFriend(damage.from) then
		return card
	end
end

function SmartAI:askForRob(damage)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local card
	card = self:getCardId("Rob")
	if card then card = sgs.Card_Parse(card) else return end
	
	if damage.from and self.player ~= damage.to and not self:isFriend(damage.from) then
		return card
	end
end

function SmartAI:askForSuddenStrike(player)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local card
	card = self:getCardId("SuddenStrike")
	if card then card = sgs.Card_Parse(card) else return end
	
	if self.player ~= player and not self:isFriend(player) then
		return card
	end
end

function sgs.getDefense(player)
	local defense = math.min(sgs.getValue(player), player:getHp() * 3)
	if player:getArmor() and not (player:getArmor():inherits("GaleShell") or player:getArmor():inherits("JiaoLiao")) then
		defense = defense + 2
	end
	if not player:getArmor() and player:hasSkill("bazhen") then
		defense = defense + 2
	end
	local m = sgs.masochism_skill:split("|")
	for _, masochism in ipairs(m) do
		if player:hasSkill(masochism) then
			defense = defense + 1
		end
	end
	if player:getArmor() and player:getArmor():inherits("EightDiagram") and player:hasSkill("tiandu") then
		defense = defense + 0.3
	end
	if player:hasSkill("jieming") then
		defense = defense + 1
	end
	if player:getMark("@tied")>0 then
		defense = defense + 1
	end
	if player:hasSkill("qingguo") and player:getHandcardNum()>1 then
		defense = defense + 0.5
	end
	if player:hasSkill("longdan") and player:getHandcardNum()>2 then
		defense = defense + 0.3
	end
	return defense
end

function SmartAI:filterEvent(event, player, data)
	if not sgs.recorder then
		sgs.recorder = self
	end
	sgs.lastevent = event
	sgs.lasteventdata = eventdata
	if event == sgs.ChoiceMade and self == sgs.recorder then
		local carduse = data:toCardUse()
		if carduse and carduse:isValid() then
			for _, aflag in ipairs(sgs.ai_global_flags) do
				sgs[aflag] = nil
			end
			for _, callback in ipairs(sgs.ai_choicemade_filter.cardUsed) do
				if callback and type(callback) == "function" then
					callback(player, carduse)
				end
			end
		elseif data:toString() then
			promptlist = data:toString():split(":")
			local callbacktable = sgs.ai_choicemade_filter[promptlist[1]]
			if callbacktable and type(callbacktable) == "table" then
				local index = 2
				if promptlist[1] == "cardResponsed" then index = 3 end
				local callback = callbacktable[promptlist[index]] or callbacktable.general
				if callback and type(callback) == "function" then
					callback(player, promptlist)
				end
			end
		end
	elseif event == sgs.CardUsed then
		self:updatePlayers()
	elseif event == sgs.CardEffect then
		self:updatePlayers()
	elseif event == sgs.Death then
		self:updatePlayers()
	end

	if (event == sgs.PhaseChange) or (event == sgs.GameStart) then
		self:updatePlayers()
	end

	if self ~= sgs.recorder then return end
	
	if event == sgs.CardEffect then
		local struct = data:toCardEffect()
		local card = struct.card
		local from = struct.from
		local to = struct.to
		if card:inherits("Collateral") then sgs.ai_collateral = true end
		if card:inherits("Dismantlment") or card:inherits("Snatch") or card:getSkillName() == "qixi" or card:getSkillName() == "jixi" then
			sgs.ai_snat_disma_effect = true
			sgs.ai_snat_dism_from = struct.from
			if to:getCards("j"):isEmpty() and
				not (to:getArmor() and (to:getArmor():inherits("GaleShell") or to:getArmor():inherits("SilverLion") or to:getArmor():inherits("JiaoLiao"))) then
				sgs.updateIntention(from, to, 80)
			end
		end
		if card:inherits("Slash") and to:hasSkill("leiji") and 
			(getCardsNum("Jink", to)>0 or (to:getArmor() and to:getArmor():objectName() == "eight_diagram"))
			and (to:getHandcardNum()>2 or from:getState() == "robot") then
			sgs.ai_leiji_effect = true
		end
	elseif event == sgs.Damaged then
		local damage = data:toDamage()
		local card = damage.card
		local from = damage.from
		local to   = damage.to
		local source = self.room:getCurrent()
		
		if not damage.card then
			local intention
			if sgs.ai_quhu_effect then
				sgs.quhu_effect = false
				local xunyu = self.room:findPlayerBySkillName("quhu")
				intention = 80
				from = xunyu
			else
				intention = 100 
			end
			
			if from then sgs.updateIntention(from, to, intention) end
		end
	elseif event == sgs.CardUsed then
		local struct = data:toCardUse()
		local card = struct.card
		local to = struct.to
		to = sgs.QList2Table(to)
		local from  = struct.from
		local source =  self.room:getCurrent()
		local str
		str = card:className() .. card:toString() .. ":"
		local toname = {}
		for _, ato in ipairs(to) do
			table.insert(toname, ato:getGeneralName())
		end
		if from then str = str .. from:getGeneralName() .. "->" .. table.concat(toname, "+") end
		if source then str = str .. "#" .. source:getGeneralName() end
		sgs.laststr = str
		--self.room:writeToConsole(str)

		local callback = sgs.ai_card_intention[card:className()]
		if callback then
			if type(callback) == "function" then
				callback(card, from, to, source)
			elseif type(callback) == "number" then
				sgs.updateIntentions(from, to, callback, card)
			end
		end
	elseif event == sgs.CardLost then
		local move = data:toCardMove()
		local from = move.from
		local place = move.from_place
		local card = sgs.Sanguosha:getCard(move.card_id)
		if sgs.ai_snat_disma_effect then
			sgs.ai_snat_disma_effect = false
			local intention = 70
			if place == sgs.Player_Judging then
				if not card:inherits("Disaster") then intention = -intention else intention = 0 end
			elseif place == sgs.Player_Equip then
				if player:getLostHp() > 1 and card:inherits("SilverLion") then intention = -intention end
				if self:hasSkills(sgs.lose_equip_skill, player) or card:inherits("GaleShell") or card:inherits("JiaoLiao") or card:inherits("JiaSuo") then intention = 0 end
			end
			sgs.updateIntention(sgs.ai_snat_dism_from, from, intention)
		end
	elseif event == sgs.StartJudge then
		local judge = data:toJudge()
		local reason = judge.reason
		if reason == "beige" then
			local caiwenji = self.room:findPlayerBySkillName("beige")
			local intention = sgs.ai_card_intention.general(player, -60)
			if player:objectName() == caiwenji:objectName() then intention = 0 end
			sgs.refreshLoyalty(caiwenji, intention)
		end
	elseif event == sgs.PhaseChange and player:isLord() and player:getPhase()== sgs.Player_Finish then
		sgs.turncount = sgs.turncount + 1
	elseif event == sgs.GameStart then
		sgs.turncount = 0
	end
end

function SmartAI:askForDiscard(reason, discard_num, optional, include_equip)
	local callback = sgs.ai_skill_discard[reason]
	if callback and type(callback) == "function" and callback(self, discard_num, optional, include_equip) then
		return callback(self, discard_num, optional, include_equip)
	end
	if optional then return {} end

	local flag = "h"
	if include_equip and (self.player:getEquips():isEmpty() or not self.player:isJilei(self.player:getEquips():first())) then flag = flag .. "e" end
	local cards = self.player:getCards(flag)
	local to_discard = {}
	cards = sgs.QList2Table(cards)
	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getEffectiveId())
		if place == sgs.Player_Equip then
			if card:inherits("GaleShell") then return -2
			elseif card:inherits("JiaoLiao") then return -2
			elseif card:inherits("JiaSuo") then return -2
			elseif card:inherits("SilverLion") and self.player:isWounded() then return -2
			elseif card:inherits("YitianSword") then return -1
			elseif card:inherits("OffensiveHorse") then return 1
			elseif card:inherits("Weapon") then return 2
			elseif card:inherits("DefensiveHorse") then return 3
			elseif card:inherits("Armor") then return 4 end
		elseif self:hasSkills(sgs.lose_equip_skill) then return 5
		else return 0 end
	end
	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then return aux_func(a) < aux_func(b) end
		return self:getKeepValue(a) < self:getKeepValue(b)
	end

	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		if not self.player:isJilei(card) then table.insert(to_discard, card:getId()) end
	end
	
	return to_discard
end

function SmartAI:askForCardChosen(who, flags, reason)
	self.room:output(reason)
	local cardchosen = sgs.ai_skill_cardchosen[string.gsub(reason,"%-","_")]
	local card
	if type(cardchosen) == "function" then
		card = cardchosen(self, who, flags)
	end
	if card then
		return card:getId()
	end

	if self:isFriend(who) then
		if flags:match("j") then
			local tricks = who:getCards("j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if trick:inherits("Lightning") then
					lightning = trick:getId()
				elseif trick:inherits("Indulgence") or trick:getSuit() == sgs.Card_Diamond then
					indulgence = trick:getId()
				elseif not trick:inherits("Disaster") then
					supply_shortage = trick:getId()
				end
			end


			if self:hasWizard(self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if who:getHp() < who:getHandcardNum() then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if flags:match("e") then
			local zhangjiao = self.room:findPlayerBySkillName("leiji")
			if who:isWounded() and self:isEquip("SilverLion", who) and (not zhangjiao or self:isFriend(zhangjiao))
				and not self:hasSkills("qixi|duanliang", who) then return who:getArmor():getId() end
			if self:isEquip("GaleShell", who) then return who:getArmor():getId() end
			if self:isEquip("JiaoLiao", who) then return who:getArmor():getId() end
			if self:isEquip("JiaSuo", who) then return who:getWeapon():getId() end
			if self:hasSkills(sgs.lose_equip_skill, who) then
				local equips = who:getEquips()
				if not equips:isEmpty() then
					return equips:at(0):getId()
				end
			end
		end
	else
		if flags:match("e") then
			if who:getWeapon() and who:getWeapon():inherits("Crossbow") then
				for _, friend in ipairs(self.friends) do
					if who:distanceTo(friend) <= 1 then return who:getWeapon():getId() end
				end
			end

			self:sort(self.friends, "hp")
			local friend = self.friends[1]
			if self:isWeak(friend) and who:inMyAttackRange(friend) then
				if who:getWeapon() and who:distanceTo(friend) > 1 then return who:getWeapon():getId() end
				if who:getOffensiveHorse() and who:distanceTo(friend) > 1 then return who:getOffensiveHorse():getId() end
			end

			if who:getDefensiveHorse() then
				for _,friend in ipairs(self.friends) do
					if friend:distanceTo(who) == friend:getAttackRange()+1 then
						return who:getDefensiveHorse():getId()
					end
				end
			end

			if who:getArmor() and self:evaluateArmor(who:getArmor(),who)>3 then
				return who:getArmor():getId()
			end

			if self:isEquip("Monkey", who) then
				return who:getOffensiveHorse():getId()
			end
		end

		if flags:match("j") then
			local tricks = who:getCards("j")
			local lightning
			for _, trick in sgs.qlist(tricks) do
				if trick:inherits("Lightning") then
					lightning = trick:getId()
				end
			end
			if self:hasWizard(self.enemies,true) and lightning then
				return lightning
			end
		end

		if flags:match("e") then
			if who:getArmor() and self:evaluateArmor(who:getArmor(), who)>0
				and not (who:getArmor():inherits("SilverLion") and self:isWeak(who)) then
				return who:getArmor():getId()
			end

			if who:getWeapon() then
				if not (who:hasSkill("xiaoji") and (who:getHandcardNum() >= who:getHp())) and not self:isEquip("YitianSword",who) then
					for _,friend in ipairs(self.friends) do
						if (who:distanceTo(friend) <= who:getAttackRange()) and (who:distanceTo(friend) > 1) then
							return who:getWeapon():getId()
						end
					end
				end
			end

			if who:getOffensiveHorse() then
				if who:hasSkill("xiaoji") and who:getHandcardNum() >= who:getHp() then
				else
					for _,friend in ipairs(self.friends) do
						if who:distanceTo(friend) == who:getAttackRange() and
						who:getAttackRange() > 1 then
							return who:getOffensiveHorse():getId()
						end
					end
				end
			end
		end
		if flags:match("h") then
			if not who:isKongcheng() then
				return -1
			end
		end
	end
	local new_flag = ""
	if flags:match("h") then new_flag = "h" end
	if flags:match("e") then new_flag = new_flag.."e" end
	return self:getCardRandomly(who, new_flag) or who:getCards(flags):first():getEffectiveId()
end