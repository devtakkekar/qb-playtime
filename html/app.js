const appEl = document.getElementById('app');
const tbody = document.querySelector('#leaderboard tbody');
const playerNameEl = document.getElementById('player-name');
const playerRankEl = document.getElementById('player-rank');
const playerTimeEl = document.getElementById('player-time');
const playerJoinEl = document.getElementById('player-join');
const closeBtn = document.getElementById('close-btn');

function formatTime(seconds) {
	const s = Math.max(0, Math.floor(seconds || 0));
	const d = Math.floor(s / 86400);
	const h = Math.floor((s % 86400) / 3600);
	const m = Math.floor((s % 3600) / 60);

	if (d > 0) {
		return `${d}d ${h}h ${m}m`;
	}
	if (h > 0) {
		return `${h}h ${m}m`;
	}
	return `${m}m`;
}

function formatJoinDate(input) {
	if (input == null || input === '') return '-';

	// Helper to format a Date as dd/mm/yyyy
	const fmt = (d) => {
		if (isNaN(d.getTime())) return '-';
		const day = String(d.getDate()).padStart(2, '0');
		const month = String(d.getMonth() + 1).padStart(2, '0');
		const year = d.getFullYear();
		return `${day}/${month}/${year}`;
	};

	// If it's a number or numeric string, treat as epoch (ms or s)
	if (typeof input === 'number' || (typeof input === 'string' && /^\d+$/.test(input))) {
		const n = typeof input === 'number' ? input : parseInt(input, 10);
		const ms = n > 1e12 ? n : n * 1000; // 13-digit ms vs 10-digit s
		return fmt(new Date(ms));
	}

	// If it's a MySQL DATETIME string 'YYYY-MM-DD HH:MM:SS'
	if (typeof input === 'string' && input.includes('-')) {
		const parts = input.split(' ')[0].split('-');
		if (parts.length === 3) {
			const [y, m, d] = parts;
			return `${d.padStart(2, '0')}/${m.padStart(2, '0')}/${y}`;
		}
		return fmt(new Date(input.replace(' ', 'T')));
	}

	// Fallback
	return String(input);
}

function populate(data) {
	if (!data) return;
	playerNameEl.textContent = data.player.name;
	playerRankEl.textContent = `#${data.player.rank}`;
	playerRankEl.classList.remove('rank-gold', 'rank-red');
	if (data.player.rank === 1) {
		playerRankEl.classList.add('rank-gold');
	} else if (data.player.rank === 2 || data.player.rank === 3) {
		playerRankEl.classList.add('rank-red');
	}
	playerTimeEl.textContent = formatTime(data.player.seconds);
	playerJoinEl.textContent = `Joined: ${formatJoinDate(data.player.join_date)}`;

	tbody.innerHTML = '';
	(data.leaderboard || []).forEach((row) => {
		const tr = document.createElement('tr');
		const rank = document.createElement('td');
		rank.textContent = row.rank;
		rank.classList.remove('rank-gold', 'rank-red');
		if (row.rank === 1) {
			rank.classList.add('rank-gold');
		} else if (row.rank === 2 || row.rank === 3) {
			rank.classList.add('rank-red');
		}
		const name = document.createElement('td');
		name.textContent = row.name;
		const time = document.createElement('td');
		time.textContent = formatTime(row.seconds);
		tr.appendChild(rank);
		tr.appendChild(name);
		tr.appendChild(time);
		tbody.appendChild(tr);
	});
}

window.addEventListener('message', (event) => {
	const msg = event.data || {};
	if (msg.action === 'qb_playtime_open') {
		populate(msg.data);
		appEl.classList.remove('hidden');
		appEl.style.display = 'flex';
	} else if (msg.action === 'qb_playtime_close') {
		appEl.classList.add('hidden');
		appEl.style.display = 'none';
	}
});

closeBtn.addEventListener('click', () => {
	appEl.classList.add('hidden');
	appEl.style.display = 'none';
	fetch(`https://${GetParentResourceName()}/close`, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: '{}'
	});
});

document.addEventListener('keydown', (e) => {
	if (e.key === 'Escape') {
		appEl.classList.add('hidden');
		appEl.style.display = 'none';
		fetch(`https://${GetParentResourceName()}/close`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: '{}'
		});
	}
});

// Safety: ensure hidden on initial load
window.addEventListener('DOMContentLoaded', () => {
	appEl.classList.add('hidden');
	appEl.style.display = 'none';
});


