-- Config: every tuning number for Warung Rot in one place. The server and
-- the client both require it, so it holds data only, never services or state.

local Config = {}

Config.GAME_NAME = "Warung Rot"
Config.GAME_TAGLINE = "Beli brainrot. Isi warungmu. Lari dari banjir!"

Config.START_CASH = 150
Config.BASE_COUNT = 8
Config.SLOTS_PER_BASE = 10

-- The conveyor belt that carries brainrots past the bases.
Config.BELT_SPAWN_SECONDS = 4
Config.BELT_SPEED = 6
Config.BELT_START_X = -90
Config.BELT_END_X = 90
Config.BELT_Z = 0
Config.BELT_TOP_Y = 1
Config.MAX_BELT_ITEMS = 12

-- Carrying, stealing and locks.
Config.BASE_CARRY_CAPACITY = 1
Config.BASE_LOCK_SECONDS = 30
Config.STEAL_COOLDOWN_SECONDS = 20
Config.INTERACT_RANGE = 12

-- The flood wave.
Config.WAVE_EVERY_SECONDS = 180
Config.WAVE_FIRST_SECONDS = 90
Config.WAVE_WARN_SECONDS = 20
Config.WAVE_SPEED = 45
Config.WAVE_START_X = -175
Config.WAVE_END_X = 175

-- Pity timers: a dry spell guarantees a better spawn.
Config.PITY_LEGENDARY_SECONDS = 240
Config.PITY_MYTHIC_SECONDS = 600

-- The NPC thief and random events.
Config.THIEF_EVERY_SECONDS = 75
Config.EVENT_EVERY_SECONDS = 150
Config.AUTOSAVE_SECONDS = 60

-- Upgrades: each list is the price of the next level, in order.
Config.UPGRADES = {
	speed = {
		label = "Sepatu Lari",
		detail = "+2 kecepatan jalan tiap level",
		costs = { 500, 1500, 4000, 10000, 25000 },
	},
	carry = {
		label = "Keranjang Besar",
		detail = "+1 bawaan tiap level",
		costs = { 1000, 5000, 20000 },
	},
	lock = {
		label = "Gembok Warung",
		detail = "+15 detik kunci tiap level",
		costs = { 750, 2500, 8000, 20000 },
	},
}

-- Rebirths: cash cost, minimum rarity owned, and the permanent multiplier
-- the level grants (the ladder value itself, not a running product).
Config.REBIRTHS = {
	{ cash = 20000, needRarity = 3, multiplier = 2 },
	{ cash = 200000, needRarity = 4, multiplier = 3 },
	{ cash = 2000000, needRarity = 5, multiplier = 5 },
	{ cash = 20000000, needRarity = 6, multiplier = 8 },
	{ cash = 200000000, needRarity = 6, multiplier = 12 },
}

Config.BASE_WALK_SPEED = 16
Config.REBIRTH_WALK_BONUS = 2
Config.REBIRTH_LOCK_BONUS = 10

return Config
