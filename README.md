#  $\color{Orange}\huge{\textbf{QB-Core PLAYTIME SCRIPT}}$
Track player playtime with a clean NUI, personal stats, and a top-100 leaderboard for QBCore. Open the UI in-game with /ptime.

## Preview
<img width="627" height="265" alt="Screenshot_1" src="https://github.com/user-attachments/assets/05020ad4-6c4b-4ab3-ace6-516ddd67c317" />

## Features
- Personal stats: total playtime, rank, and first join date.  
- Leaderboard: top 100 players by total seconds played.  
- Accurate accounting: buffers per-minute playtime and persists every 5 minutes and on disconnect.  
- Non-intrusive UI: opens only on /ptime, closes with Escape or the close button.  
- Zero-config schema: auto-adds join_date if missing.  

## Requirements
- Framework: qb-core  
- Database: oxmysql  
- Server: FiveM (fxserver), Lua 5.4 enabled  

## Installation
1) Place the resource in your server:  
Put this folder into resources\[custom]\qb-playtime  
2) Ensure dependencies are started before this resource:  
qb-core  
oxmysql  
3) Import the SQL (optional; the resource will also create/alter on first run):
```
CREATE TABLE IF NOT EXISTS `playtime` (
  `citizenid` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `seconds` int NOT NULL DEFAULT 0,
  `join_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`),
  KEY `seconds_idx` (`seconds`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```
4) Start the resource in your server.cfg:
```
ensure qb-core
ensure oxmysql
ensure qb-playtime
```

## Usage  
Open UI: type /ptime in chat.  
Close UI: press Esc or click the X button.  
Relevant client command:  
```
RegisterCommand('ptime', function()
	QBCore.Functions.TriggerCallback('qb-playtime:getData', function(response)
		if not response then
			QBCore.Functions.Notify('Unable to load playtime data', 'error')
			return
		end
		openUI(response)
	end)
end)
```

## How it works  
- Tracking: Every minute, each connected player's session buffer increments by 60 seconds. Every 5 minutes and on player drop, the buffer is persisted to MySQL.   
- Leaderboard: Ranks are computed by total persisted seconds, with your current session buffer visually added to your entry.    
- Join date: A join_date column is ensured at startup and displayed in the UI.    
Server persistence and callback:    
```
-- Increase playtime every 60 seconds for connected players
CreateThread(function()
	while true do
		Wait(60 * 1000)
		for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
			playerPlaytimeSeconds[playerId] = (playerPlaytimeSeconds[playerId] or 0) + 60
		end
	end
end)
```
```
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
```
## Configuration  
No explicit config file. The resource uses qb-core/oxmysql defaults.  
UI opens only via /ptime (no keybind by default).  
fxmanifest:  
```
fx_version 'cerulean'
game 'gta5'

name 'qb-playtime'
author 'devtakkekar'
description 'Playtime tracker with /time UI and leaderboard for QBCore'
version '1.0.0'
```

## Performance
Tracking runs once per minute and writes every 5 minutes.   
This is very lightweight.    
Leaderboard query is limited to top 100.  

## Troubleshooting  
- UI doesn’t open: Ensure qb-core and oxmysql are running and this resource is started after them.  
- No data shown: Confirm the playtime table exists and the server can write to the database. Check your oxmysql connection in your core resources.  
- Join date is “-”: The column is added automatically; if you imported an older schema, restart the resource/server so the migration runs. 

## License
This project is licensed under the MIT License.  

## Credits  
devtakkekar - Initial work  
QBCore Framework Team  
