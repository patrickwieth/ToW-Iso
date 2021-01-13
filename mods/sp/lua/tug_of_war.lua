wavetime = 500
debugging = false

WorldLoadedToW = function()
	neutral = Player.GetPlayer("Neutral")
	mp0 = Player.GetPlayer("Multi0")
	mp1 = Player.GetPlayer("Multi1")
	mp2 = Player.GetPlayer("Multi2")
	mp3 = Player.GetPlayer("Multi3")
	mp4 = Player.GetPlayer("Multi4")
	mp5 = Player.GetPlayer("Multi5")
	mp6 = Player.GetPlayer("Multi6")
	mp7 = Player.GetPlayer("Multi7")
	mp8 = Player.GetPlayer("Multi8")
	mp9 = Player.GetPlayer("Multi9")
	mp10 = Player.GetPlayer("Multi10")
	mp11 = Player.GetPlayer("Multi11")

	players = { mp0, mp1, mp2, mp3, mp4, mp5, mp6, mp7, mp8, mp9, mp10, mp11 }
end

autoproduced = {}
teamAunits = {{}, {}, {}, {}, {}, {}, {}}
teamBunits = {{}, {}, {}, {}, {}, {}, {}}

warpoint0 = Map.NamedActor("warpoint0")
warpointa1 = Map.NamedActor("warpointa1")
warpointa2 = Map.NamedActor("warpointa2")
warpointa3 = Map.NamedActor("warpointa3")
warpointb1 = Map.NamedActor("warpointb1")
warpointb2 = Map.NamedActor("warpointb2")
warpointb3 = Map.NamedActor("warpointb3")

-- here are the checks which warpoints are present
if (warpointa3 ~= nil) then
	if (warpointb3  == nil) then
		Media.DisplayMessage("warpointa3 exists but warpointb3 does not, this is not a good idea...")
		return
	end
	if (warpointa2 == nil or warpointb2 == nil or warpointa1 == nil or warpointb1 == nil or warpoint0 == nil) then
		Media.DisplayMessage("if you use warpointa3 you also need all other warpoints a1,a2,b1,b2 and 0.")
		return
	end
	insertIndex = 1
	startpointa = warpointa3
	startpointb = warpointb3
elseif ( warpointa2 ~= nil ) then
	if (warpointb2  == nil) then
		Media.DisplayMessage("warpointa2 exists but warpointb2 does not, this is not a good idea...")
		return
	end
	if (warpointa1 == nil or warpointb1 == nil or warpoint0 == nil) then
		Media.DisplayMessage("if you use warpointa2 you also need the lower warpoints a1,b1 and 0.")
		return
	end
	insertIndex = 3
	startpointa = warpointa2
	startpointb = warpointb2
else
	if (warpointa1 == nil or warpointb1 == nil or warpoint0 == nil) then
		Media.DisplayMessage("you need at least the warpoints a1,b1 and 0.")
		return
	end
	insertIndex = 5
	startpointa = warpointa1
	startpointb = warpointb1
end


TickTugOfWar = function()
	if DateTime.GameTime == 1 then
		-- game setup, this only happens at the start, first define teams
		teamA = {}
		teamB = {}

		for i,player in next,players do
			if player.IsAlliedWith(mp0) then
				teamA[#teamA+1] = player
			else
				teamB[#teamB+1] = player
			end
		end

		-- calculate team power to give buffs to teams with fewer players
		teamApower = 1
		teamBpower = 1
		if (#teamA > #teamB) then
			teamBpower = #teamA / #teamB
		elseif (#teamA < #teamB) then
			teamApower = #teamB / #teamA
		end

		if debugging then
			Media.DisplayMessage("Team A has " .. tostring(#teamA) .. " members and power of " .. tostring(teamApower) .. ", players:")
			for i,player in next,teamA do
				Media.DisplayMessage(tostring(player))
			end
			Media.DisplayMessage("Team B has " .. tostring(#teamB) .. " members and power of " .. tostring(teamBpower) .. ", players:")
			for i,player in next,teamB do
				Media.DisplayMessage(tostring(player))
			end
		end

		-- then find out which team is closer to which spawning points
		function sqdistance(a, b)
			return math.pow(a.Location.X - b.Location.X, 2) + math.pow(a.Location.Y - b.Location.Y, 2)
		end

		MCV = teamA[1].GetActorsByTypes({"soviet_conyard", "drache", "mcv", "cabmcv", "nodmcv", "mutmcv"})[1]

		if debugging then
			Media.DisplayMessage("Distance to A:", tostring(sqdistance(MCV, startpointa)))
			Media.DisplayMessage("Distance to B:", tostring(sqdistance(MCV, startpointb)))
		end

		teamsSwitched = false
		if sqdistance(MCV, startpointa) > sqdistance(MCV, startpointb) then
			if debugging then Media.DisplayMessage("Switching sides of teams") end
			tempTeam = teamA
			teamA = teamB
			teamB = tempTeam
			teamsSwitched = true
		end

		captureStartPointActorA = Actor.Create("gdie1", true, { Owner = teamA[1], Location = startpointa.Location, SubCell = 1 })
		captureStartPointActorB = Actor.Create("gdie1", true, { Owner = teamB[1], Location = startpointb.Location, SubCell = 1 })
	elseif DateTime.GameTime == 2 then
		captureStartPointActorA.Kill()
		captureStartPointActorB.Destroy()
	elseif DateTime.GameTime % wavetime > 0 then
		-- we only do special tick things every 1000 Ticks, any tick else is skipped
    return
	else
		if debugging then Media.DisplayMessage(tostring(DateTime.GameTime)) end
		-- these are the actions that are done every 1000 ticks
		CheckWinConditions()
		TransferUnitGroups()
		GuardMoveUnits()
  end
end

teamAwinning = false
teamBwinning = false

CheckWinConditions = function ()
	for i,player in next,teamA do
		if startpointb.Owner == player then
			if teamAwinning == true then
				teamXloses(teamB)
			end
			Media.DisplayMessage("Team A has captured the final Checkpoint. Team B needs to take it back or it will lose the game.")
			teamAwinning = true
		elseif teamAwinning == true then
			teamAwinning = false
		end
	end
	for i,player in next,teamB do
		if startpointa.Owner == player then
			if teamBwinning == true then
				teamXloses(teamA)
			end
			Media.DisplayMessage("Team B has captured the final Checkpoint. Team A needs to take it back or it will lose the game.")
			teamBwinning = true
		elseif teamBwinning == true then
			teamBwinning = false
		end
	end
end

teamXloses = function (X)
	for i,player in next,X do
		for j,unit in pairs(player.GetActors()) do
			if unit.HasProperty('Health') then unit.Kill() end
		end
	end
end

GuardUnitsFromTable = function (unittable, GuardTarget)
	for i=1,#unittable do
		if unittable[i].IsDead  then
			--table.remove(unittable, i)			-- crash area
		else
			unittable[i].Guard(GuardTarget)
		end
	end
end

GuardMoveUnits = function()
	ActivityApplyFunction = GuardUnitsFromTable

	if ( warpointa3 ~= nil ) then
		ActivityApplyFunction(teamAunits[1], warpointa3)
		ActivityApplyFunction(teamAunits[2], warpointa2)
		ActivityApplyFunction(teamAunits[3], warpointa1)
		ActivityApplyFunction(teamAunits[4], warpoint0)
		ActivityApplyFunction(teamAunits[5], warpointb1)
		ActivityApplyFunction(teamAunits[6], warpointb2)
		ActivityApplyFunction(teamAunits[7], warpointb3)

		ActivityApplyFunction(teamBunits[1], warpointb3)
		ActivityApplyFunction(teamBunits[2], warpointb2)
		ActivityApplyFunction(teamBunits[3], warpointb1)
		ActivityApplyFunction(teamBunits[4], warpoint0)
		ActivityApplyFunction(teamBunits[5], warpointa1)
		ActivityApplyFunction(teamBunits[6], warpointa2)
		ActivityApplyFunction(teamBunits[7], warpointa3)

	elseif ( warpointa2 ~= nil ) then
		ActivityApplyFunction(teamAunits[3], warpointa2)
		ActivityApplyFunction(teamAunits[4], warpointa1)
		ActivityApplyFunction(teamAunits[5], warpoint0)
		ActivityApplyFunction(teamAunits[6], warpointb1)
		ActivityApplyFunction(teamAunits[7], warpointb2)

		ActivityApplyFunction(teamBunits[3], warpointb2)
		ActivityApplyFunction(teamBunits[4], warpointb1)
		ActivityApplyFunction(teamBunits[5], warpoint0)
		ActivityApplyFunction(teamBunits[6], warpointa1)
		ActivityApplyFunction(teamBunits[7], warpointa2)
	else
		ActivityApplyFunction(teamAunits[5], warpointa1)
		ActivityApplyFunction(teamAunits[6], warpoint0)
		ActivityApplyFunction(teamAunits[7], warpointb1)

		ActivityApplyFunction(teamBunits[5], warpointb1)
		ActivityApplyFunction(teamBunits[6], warpoint0)
		ActivityApplyFunction(teamBunits[7], warpointa1)
	end
end

AttackMoveUnitsFromTable = function (unittable, Location)
	for i=1,#unittable do
		if unittable[i].IsDead  then
			--table.remove(unittable, i)			-- crash area
		else
			unittable[i].AttackMove(Location, 0)
		end
	end
end

AttackMoveUnits = function()
	if ( warpointa3 ~= nil ) then
		AttackMoveUnitsFromTable(teamAunits[1], warpointa3.Location)
		AttackMoveUnitsFromTable(teamAunits[2], warpointa2.Location)
		AttackMoveUnitsFromTable(teamAunits[3], warpointa1.Location)
		AttackMoveUnitsFromTable(teamAunits[4], warpoint0.Location)
		AttackMoveUnitsFromTable(teamAunits[5], warpointb1.Location)
		AttackMoveUnitsFromTable(teamAunits[6], warpointb2.Location)
		AttackMoveUnitsFromTable(teamAunits[7], warpointb3.Location)

		AttackMoveUnitsFromTable(teamBunits[1], warpointb3.Location)
		AttackMoveUnitsFromTable(teamBunits[2], warpointb2.Location)
		AttackMoveUnitsFromTable(teamBunits[3], warpointb1.Location)
		AttackMoveUnitsFromTable(teamBunits[4], warpoint0.Location)
		AttackMoveUnitsFromTable(teamBunits[5], warpointa1.Location)
		AttackMoveUnitsFromTable(teamBunits[6], warpointa2.Location)
		AttackMoveUnitsFromTable(teamBunits[7], warpointa3.Location)

	elseif ( warpointa2 ~= nil ) then
		AttackMoveUnitsFromTable(teamAunits[3], warpointa2.Location)
		AttackMoveUnitsFromTable(teamAunits[4], warpointa1.Location)
		AttackMoveUnitsFromTable(teamAunits[5], warpoint0.Location)
		AttackMoveUnitsFromTable(teamAunits[6], warpointb1.Location)
		AttackMoveUnitsFromTable(teamAunits[7], warpointb2.Location)

		AttackMoveUnitsFromTable(teamBunits[3], warpointb2.Location)
		AttackMoveUnitsFromTable(teamBunits[4], warpointb1.Location)
		AttackMoveUnitsFromTable(teamBunits[5], warpoint0.Location)
		AttackMoveUnitsFromTable(teamBunits[6], warpointa1.Location)
		AttackMoveUnitsFromTable(teamBunits[7], warpointa2.Location)
	else
		AttackMoveUnitsFromTable(teamAunits[5], warpointa1.Location)
		AttackMoveUnitsFromTable(teamAunits[6], warpoint0.Location)
		AttackMoveUnitsFromTable(teamAunits[7], warpointb1.Location)

		AttackMoveUnitsFromTable(teamBunits[5], warpointb1.Location)
		AttackMoveUnitsFromTable(teamBunits[6], warpoint0.Location)
		AttackMoveUnitsFromTable(teamBunits[7], warpointa1.Location)
	end
end

TransferUnitGroups = function()
	-- team A units first go into higher lists
	for i, unit in pairs(teamAunits[6]) do
		table.insert(teamAunits[7], unit)
	end
	teamAunits[6] = teamAunits[5]
	teamAunits[5] = teamAunits[4]
	teamAunits[4] = teamAunits[3]
	teamAunits[3] = teamAunits[2]
	teamAunits[2] = teamAunits[1]
	teamAunits[1] = {}

	-- team B units go into higher lists afterwards
	for i, unit in pairs(teamBunits[6]) do
		table.insert(teamBunits[7], unit)
	end
	teamBunits[6] = teamBunits[5]
	teamBunits[5] = teamBunits[4]
	teamBunits[4] = teamBunits[3]
	teamBunits[3] = teamBunits[2]
	teamBunits[2] = teamBunits[1]
	teamBunits[1] = {}

	-- sort units into specific arrays

	for i=1,#autoproduced do

		--Media.DisplayMessage("sorting unit #" .. tostring( i ))
		-- split new units up depending on team
		if (autoproduced[i].Owner.Team == teamA[1].Team) then
			if teamsSwitched then
				table.insert(teamBunits[insertIndex], autoproduced[i])
			else
				table.insert(teamAunits[insertIndex], autoproduced[i])
			end

			--table.remove(autoproduced, i)
		else
			if teamsSwitched then
				table.insert(teamAunits[insertIndex], autoproduced[i])
			else
				table.insert(teamBunits[insertIndex], autoproduced[i])
			end
			--table.remove(autoproduced, i)
		end
	end
	autoproduced = {}
end


Trigger.OnAnyProduction(
  function(producer, produced, productionType)
    --if producer.Type == 'soviet_factory'
		if productionType == 'Autoproduction'
    then
			if producer.Owner.IsAlliedWith(teamA[1]) and teamApower == 1.5 then
				--Media.DisplayMessage("buffA1")
				producer.GrantCondition("TeamBalance1")
			elseif producer.Owner.IsAlliedWith(teamA[1]) and teamApower == 2 then
				--Media.DisplayMessage("buffA2")
				producer.GrantCondition("TeamBalance2")
			elseif not producer.Owner.IsAlliedWith(teamA[1]) and teamBpower == 1.5 then
				--Media.DisplayMessage("buffB1")
				producer.GrantCondition("TeamBalance1")
			elseif not producer.Owner.IsAlliedWith(teamA[1]) and teamBpower == 2 then
				--Media.DisplayMessage("buffB2")
				producer.GrantCondition("TeamBalance2")
			end

			autoproduced[#autoproduced+1] = produced
    end
	end
)
