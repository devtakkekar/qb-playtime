local QBCore = exports['qb-core']:GetCoreObject()

local playerPlaytimeSeconds = {}

-- Ensure schema has join_date for first-join tracking
CreateThread(function()
	-- Add join_date if it doesn't exist; default is the first time the row is created
	MySQL.query.await([[ALTER TABLE playtime ADD COLUMN IF NOT EXISTS join_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP]])
end)

-- Increase playtime every 60 seconds for connected players
CreateThread(function()
	while true do
		Wait(60 * 1000)
		for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
			playerPlaytimeSeconds[playerId] = (playerPlaytimeSeconds[playerId] or 0) + 60
		end
	end
end)

-- Persist playtime to database periodically (every 5 minutes)
CreateThread(function()
	while true do
		Wait(5 * 60 * 1000)
		for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
			local src = tonumber(playerId)
			local Player = QBCore.Functions.GetPlayer(src)
			if Player then
				local citizenid = Player.PlayerData.citizenid
				local name = (Player.PlayerData.charinfo and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname)) or Player.PlayerData.name or ('Player ' .. tostring(src))
				local seconds = playerPlaytimeSeconds[src] or 0
				if seconds > 0 then
					MySQL.prepare.await(
						'INSERT INTO playtime (citizenid, name, seconds) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), seconds = seconds + VALUES(seconds)',
						{ citizenid, name, seconds }
					)
					playerPlaytimeSeconds[src] = 0
				end
			end
		end
	end
end)

-- Save on player dropped
AddEventHandler('playerDropped', function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if not Player then return end
	local citizenid = Player.PlayerData.citizenid
	local name = (Player.PlayerData.charinfo and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname)) or Player.PlayerData.name or ('Player ' .. tostring(src))
	local seconds = playerPlaytimeSeconds[src] or 0
	if seconds > 0 then
		MySQL.prepare(
			'INSERT INTO playtime (citizenid, name, seconds) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), seconds = seconds + VALUES(seconds)',
			{ citizenid, name, seconds },
			function()
				playerPlaytimeSeconds[src] = 0
			end
		)
	end
end)

-- Load personal and leaderboard data for UI
QBCore.Functions.CreateCallback('qb-playtime:getData', function(source, cb)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if not Player then cb(nil) return end
	local citizenid = Player.PlayerData.citizenid
	local name = (Player.PlayerData.charinfo and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname)) or Player.PlayerData.name or ('Player ' .. tostring(src))

	-- Fetch total seconds (persisted + current session buffer)
	local row = MySQL.single.await('SELECT seconds, join_date FROM playtime WHERE citizenid = ? LIMIT 1', { citizenid })
	local persisted = (row and row.seconds) or 0
	local current = playerPlaytimeSeconds[src] or 0
	local totalSeconds = persisted + current

	-- Rank is based on total seconds vs leaderboard
	local leaderboard = MySQL.query.await('SELECT name, citizenid, seconds FROM playtime ORDER BY seconds DESC LIMIT 100', {}) or {}

	-- Make the player's leaderboard entry reflect current session buffer too (visual consistency)
	for _, r in ipairs(leaderboard) do
		if r.citizenid == citizenid then
			r.seconds = (r.seconds or 0) + current
			break
		end
	end

	-- Determine rank (1-indexed)
	local rank = nil
	for i, r in ipairs(leaderboard) do
		if r.citizenid == citizenid then rank = i break end
	end
	-- If not in top 100, compute rank position using a count query
	if not rank then
		local cntRow = MySQL.single.await('SELECT COUNT(*) as cnt FROM playtime WHERE seconds > ?', { totalSeconds })
		rank = ((cntRow and cntRow.cnt) or 0) + 1
	end

	-- Convert leaderboard to include rank numbers
	for i, r in ipairs(leaderboard) do
		r.rank = i
	end

	cb({
		player = {
			name = name,
			citizenid = citizenid,
			seconds = totalSeconds,
			rank = rank,
			join_date = row and row.join_date or nil
		},
		leaderboard = leaderboard
	})
end)


