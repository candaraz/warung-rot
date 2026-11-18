-- BrainrotCatalog: every fact about the cast of Warung Rot. All 24
-- characters are original inventions for this game: absurd Indonesian
-- street-food characters with funny names. Pure data plus small lookups; it
-- holds no services and no state, so the server and the client both require it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarities = require(Shared:WaitForChild("Rarities"))
local Mutations = require(Shared:WaitForChild("Mutations"))

local BrainrotCatalog = {}

-- A part recipe is { shape, size, offset, colourRole } with an optional
-- fifth entry, transparency. Roles are "body", "accent" and "detail" and map
-- to the character's three colours. Shapes: "Ball", "Block", "Cylinder"
-- (built vertical) and "Wedge". Offsets are relative to the body centre,
-- front facing +Z. The factory scales every size and offset by the scale.

BrainrotCatalog.CHARACTERS = {
	{
		id = "bakso", name = "Bakso Beranak", rarity = 1, price = 25, income = 1,
		quip = "Kenyalnya bikin nagih.", scale = 1,
		body = { 0.85, 0.6, 0.45 }, accent = { 0.95, 0.85, 0.6 }, detail = { 0.4, 0.25, 0.15 },
		parts = {
			{ "Ball", { 2.6, 2.6, 2.6 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 1.1, 1.1, 1.1 }, { -1.1, 0.9, 0.7 }, "accent" },
			{ "Ball", { 1.1, 1.1, 1.1 }, { 1.1, 0.9, 0.7 }, "accent" },
			{ "Ball", { 0.9, 0.9, 0.9 }, { 0, 1.2, -0.6 }, "detail" },
		},
	},
	{
		id = "tahu", name = "Tahu Bulat Sakti", rarity = 1, price = 50, income = 2,
		quip = "Digoreng dadakan, laris manisan.", scale = 1,
		body = { 0.95, 0.9, 0.7 }, accent = { 0.9, 0.6, 0.2 }, detail = { 0.3, 0.5, 0.2 },
		parts = {
			{ "Block", { 2.4, 2.4, 2.4 }, { 0, 0, 0 }, "body" },
			{ "Block", { 2.6, 0.5, 2.6 }, { 0, 1.1, 0 }, "accent" },
			{ "Ball", { 0.7, 0.7, 0.7 }, { -0.7, 0.2, 1.3 }, "detail" },
			{ "Ball", { 0.7, 0.7, 0.7 }, { 0.7, 0.2, 1.3 }, "detail" },
		},
	},
	{
		id = "esteh", name = "Es Teh Manis Ceria", rarity = 1, price = 75, income = 3,
		quip = "Manisnya pas, esnya banyak.", scale = 1.05,
		body = { 0.85, 0.4, 0.15 }, accent = { 0.95, 0.95, 0.95 }, detail = { 0.2, 0.6, 0.9 },
		parts = {
			{ "Cylinder", { 2.4, 2.2, 2.2 }, { 0, 0, 0 }, "body" },
			{ "Cylinder", { 0.4, 2.5, 2.5 }, { 0, 1.3, 0 }, "accent" },
			{ "Block", { 0.3, 1.6, 0.3 }, { 0.6, 1.9, 0 }, "detail" },
			{ "Ball", { 0.8, 0.8, 0.8 }, { 0, 0.4, 1.2 }, "accent", 0.3 },
		},
	},
	{
		id = "krupuk", name = "Krupuk Udang Renyah", rarity = 1, price = 100, income = 4,
		quip = "Kriuknya kedengeran sampai ujung gang.", scale = 1,
		body = { 1, 0.75, 0.5 }, accent = { 1, 0.5, 0.3 }, detail = { 0.9, 0.9, 0.9 },
		parts = {
			{ "Ball", { 3, 1.2, 3 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 2.2, 0.8, 2.2 }, { 0, 0.7, 0 }, "accent" },
			{ "Ball", { 0.6, 0.6, 0.6 }, { -0.8, 0.8, 0.8 }, "detail" },
			{ "Ball", { 0.6, 0.6, 0.6 }, { 0.8, 0.8, 0.8 }, "detail" },
		},
	},
	{
		id = "nasgor", name = "Nasi Goreng Gila", rarity = 2, price = 200, income = 8,
		quip = "Pedasnya bikin melek seminggu.", scale = 1.1,
		body = { 0.9, 0.6, 0.3 }, accent = { 0.9, 0.2, 0.15 }, detail = { 0.95, 0.9, 0.6 },
		parts = {
			{ "Ball", { 2.8, 2.2, 2.8 }, { 0, 0, 0 }, "body" },
			{ "Wedge", { 1.4, 0.9, 1 }, { 0, 0.4, 1.3 }, "accent" },
			{ "Ball", { 1.6, 0.5, 1.6 }, { 0, 1.3, 0 }, "detail" },
			{ "Block", { 0.5, 1, 0.5 }, { -1.2, -0.6, 0.8 }, "accent" },
			{ "Block", { 0.5, 1, 0.5 }, { 1.2, -0.6, 0.8 }, "accent" },
		},
	},
	{
		id = "sate", name = "Sate Ayam Sakti", rarity = 2, price = 350, income = 12,
		quip = "Tusuknya tiga, bumbunya rahasia.", scale = 1.1,
		body = { 0.8, 0.5, 0.25 }, accent = { 0.95, 0.75, 0.3 }, detail = { 0.4, 0.3, 0.2 },
		parts = {
			{ "Ball", { 1.6, 1.6, 1.6 }, { 0, -0.8, 0 }, "body" },
			{ "Ball", { 1.6, 1.6, 1.6 }, { 0, 0.8, 0 }, "body" },
			{ "Ball", { 1.6, 1.6, 1.6 }, { 0, 2.2, 0 }, "body" },
			{ "Cylinder", { 4.4, 0.25, 0.25 }, { 0, 0.7, 0 }, "detail" },
			{ "Block", { 1.4, 0.4, 0.6 }, { 0, 3.2, 0 }, "accent" },
		},
	},
	{
		id = "gadogado", name = "Gado-Gado Galak", rarity = 2, price = 500, income = 16,
		quip = "Sayurnya segar, sambalnya galak.", scale = 1.15,
		body = { 0.3, 0.7, 0.3 }, accent = { 0.9, 0.85, 0.4 }, detail = { 0.9, 0.3, 0.2 },
		parts = {
			{ "Ball", { 2.8, 2.4, 2.8 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 1.2, 1.2, 1.2 }, { -1, 1.2, 0.5 }, "accent" },
			{ "Ball", { 1.2, 1.2, 1.2 }, { 1, 1.2, 0.5 }, "accent" },
			{ "Wedge", { 1.2, 0.8, 1 }, { 0, 0.2, 1.4 }, "detail" },
			{ "Block", { 2, 0.4, 1 }, { 0, -1.3, 0 }, "detail" },
		},
	},
	{
		id = "mieayam", name = "Mie Ayam Misterius", rarity = 2, price = 600, income = 20,
		quip = "Abangnya hilang tiap Jumat.", scale = 1.15,
		body = { 0.95, 0.8, 0.35 }, accent = { 0.85, 0.55, 0.2 }, detail = { 0.2, 0.35, 0.2 },
		parts = {
			{ "Cylinder", { 1.8, 2.6, 2.6 }, { 0, -0.4, 0 }, "accent" },
			{ "Ball", { 2.8, 1.6, 2.8 }, { 0, 0.8, 0 }, "body" },
			{ "Cylinder", { 1.4, 0.3, 0.3 }, { -0.8, 1.8, 0.4 }, "detail" },
			{ "Cylinder", { 1.4, 0.3, 0.3 }, { 0.8, 1.8, -0.4 }, "detail" },
			{ "Ball", { 0.7, 0.7, 0.7 }, { 0, 1, 1.4 }, "detail" },
		},
	},
	{
		id = "rendang", name = "Rendang Raksasa", rarity = 3, price = 1500, income = 40,
		quip = "Dimasak 8 jam, habis 8 detik.", scale = 1.25,
		body = { 0.45, 0.25, 0.12 }, accent = { 0.8, 0.4, 0.15 }, detail = { 0.95, 0.85, 0.5 },
		parts = {
			{ "Block", { 2.8, 2.4, 2.8 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 1.4, 1.4, 1.4 }, { -1.2, 1.4, 0.4 }, "accent" },
			{ "Ball", { 1.4, 1.4, 1.4 }, { 1.2, 1.4, 0.4 }, "accent" },
			{ "Block", { 1.6, 0.5, 0.8 }, { 0, 0.2, 1.5 }, "detail" },
			{ "Wedge", { 1.2, 1, 1 }, { 0, -1.4, 0 }, "accent" },
		},
	},
	{
		id = "soto", name = "Soto Ayam Sejati", rarity = 3, price = 2200, income = 55,
		quip = "Kaldunya bening, rasanya juara.", scale = 1.2,
		body = { 0.95, 0.85, 0.45 }, accent = { 0.95, 0.95, 0.9 }, detail = { 0.9, 0.6, 0.15 },
		parts = {
			{ "Cylinder", { 2.2, 2.6, 2.6 }, { 0, -0.3, 0 }, "accent" },
			{ "Ball", { 2.6, 1.4, 2.6 }, { 0, 0.9, 0 }, "body" },
			{ "Block", { 1.8, 0.3, 0.8 }, { -1.4, 0.4, 0.6 }, "detail" },
			{ "Block", { 1.8, 0.3, 0.8 }, { 1.4, 0.4, -0.6 }, "detail" },
			{ "Ball", { 0.9, 0.9, 0.9 }, { 0, 1.8, 0 }, "detail" },
		},
	},
	{
		id = "geprek", name = "Ayam Geprek Petir", rarity = 3, price = 3000, income = 70,
		quip = "Sekali geprek, lidah bergetar.", scale = 1.3,
		body = { 0.9, 0.65, 0.3 }, accent = { 1, 0.9, 0.2 }, detail = { 0.9, 0.2, 0.2 },
		parts = {
			{ "Ball", { 2.8, 2.6, 2.8 }, { 0, 0, 0 }, "body" },
			{ "Wedge", { 1, 1.4, 0.6 }, { -1, 1.6, 0 }, "accent" },
			{ "Wedge", { 1, 1.4, 0.6 }, { 1, 1.6, 0 }, "accent" },
			{ "Block", { 2.2, 0.4, 1 }, { 0, 0.3, 1.5 }, "detail" },
			{ "Ball", { 0.8, 0.8, 0.8 }, { 0, -1.5, 0.8 }, "accent" },
		},
	},
	{
		id = "martabak", name = "Martabak Manis Magis", rarity = 3, price = 4000, income = 90,
		quip = "Keju coklatnya melimpah ruah.", scale = 1.25,
		body = { 0.85, 0.6, 0.3 }, accent = { 0.4, 0.2, 0.1 }, detail = { 1, 0.9, 0.4 },
		parts = {
			{ "Cylinder", { 1.6, 3, 3 }, { 0, 0, 0 }, "body" },
			{ "Cylinder", { 0.5, 2.6, 2.6 }, { 0, 1, 0 }, "accent" },
			{ "Ball", { 0.8, 0.8, 0.8 }, { -0.9, 1.4, 0.5 }, "detail" },
			{ "Ball", { 0.8, 0.8, 0.8 }, { 0.9, 1.4, -0.5 }, "detail" },
			{ "Block", { 1.2, 0.4, 1.2 }, { 0, -1, 0 }, "detail" },
		},
	},
	{
		id = "sambal", name = "Raja Sambal Terasi", rarity = 4, price = 10000, income = 200,
		quip = "Sekali cocol, keringat bercucuran.", scale = 1.4,
		body = { 0.85, 0.15, 0.1 }, accent = { 1, 0.85, 0.25 }, detail = { 0.4, 0.1, 0.1 },
		parts = {
			{ "Ball", { 3, 2.8, 3 }, { 0, 0, 0 }, "body" },
			{ "Block", { 0.5, 0.9, 0.5 }, { -0.7, 1.8, 0 }, "accent" },
			{ "Block", { 0.5, 1.1, 0.5 }, { 0, 1.9, 0 }, "accent" },
			{ "Block", { 0.5, 0.9, 0.5 }, { 0.7, 1.8, 0 }, "accent" },
			{ "Cylinder", { 1, 1.4, 1.4 }, { 1.9, 0.2, 0.5 }, "detail" },
			{ "Ball", { 1, 1, 1 }, { 0, 0.4, 1.6 }, "detail" },
		},
	},
	{
		id = "nasikuning", name = "Ratu Nasi Kuning", rarity = 4, price = 16000, income = 280,
		quip = "Kuningnya cerah, harinya ceria.", scale = 1.4,
		body = { 1, 0.85, 0.25 }, accent = { 0.95, 0.95, 0.9 }, detail = { 0.2, 0.6, 0.3 },
		parts = {
			{ "Cylinder", { 2.8, 1.2, 1.2 }, { 0, 0.6, 0 }, "body" },
			{ "Ball", { 3, 1.8, 3 }, { 0, -1, 0 }, "body" },
			{ "Ball", { 1, 1, 1 }, { 0, 2.4, 0 }, "accent" },
			{ "Block", { 2, 0.4, 0.6 }, { -1.8, -0.4, 0.4 }, "detail" },
			{ "Block", { 2, 0.4, 0.6 }, { 1.8, -0.4, -0.4 }, "detail" },
		},
	},
	{
		id = "miedewa", name = "Dewa Mie Kuah", rarity = 4, price = 22000, income = 360,
		quip = "KUAHNYA TIDAK PERNAH HABIS.", scale = 1.45,
		body = { 0.9, 0.7, 0.35 }, accent = { 0.95, 0.95, 0.95 }, detail = { 0.85, 0.25, 0.1 },
		parts = {
			{ "Cylinder", { 2.4, 2.8, 2.8 }, { 0, -0.4, 0 }, "accent" },
			{ "Ball", { 3, 1.8, 3 }, { 0, 1, 0 }, "body" },
			{ "Cylinder", { 1.8, 0.35, 0.35 }, { -1, 2.2, 0.5 }, "detail" },
			{ "Cylinder", { 1.8, 0.35, 0.35 }, { 1, 2.2, -0.5 }, "detail" },
			{ "Ball", { 1.1, 1.1, 1.1 }, { 0, 2.6, 0 }, "detail" },
			{ "Wedge", { 1.2, 1, 1 }, { 0, 0.4, 1.6 }, "detail" },
		},
	},
	{
		id = "gorengan", name = "Kaisar Gorengan", rarity = 4, price = 30000, income = 450,
		quip = "Semua gorengan tunduk padanya.", scale = 1.5,
		body = { 0.9, 0.6, 0.25 }, accent = { 1, 0.85, 0.3 }, detail = { 0.5, 0.3, 0.1 },
		parts = {
			{ "Ball", { 3.2, 2.6, 3.2 }, { 0, 0, 0 }, "body" },
			{ "Block", { 3.6, 0.6, 1.4 }, { 0, 1.7, 0 }, "accent" },
			{ "Ball", { 1, 1, 1 }, { -1.4, 0.6, 1.2 }, "detail" },
			{ "Ball", { 1, 1, 1 }, { 1.4, 0.6, 1.2 }, "detail" },
			{ "Block", { 1, 0.5, 1.6 }, { 0, -1.4, 0 }, "detail" },
		},
	},
	{
		id = "nagapadang", name = "Naga Nasi Padang", rarity = 5, price = 80000, income = 1200,
		quip = "Lauknya dua belas, nasinya sejuta.", scale = 1.6,
		body = { 0.2, 0.6, 0.3 }, accent = { 1, 0.85, 0.3 }, detail = { 0.9, 0.2, 0.15 },
		parts = {
			{ "Ball", { 3, 2.6, 3.6 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 1.6, 1.6, 1.6 }, { 0, 1.8, 1.2 }, "body" },
			{ "Wedge", { 1, 1.4, 1 }, { -0.8, 2.8, 1.2 }, "accent" },
			{ "Wedge", { 1, 1.4, 1 }, { 0.8, 2.8, 1.2 }, "accent" },
			{ "Block", { 2.4, 0.5, 1 }, { 0, -0.4, -2.2 }, "detail" },
			{ "Ball", { 1.2, 1.2, 1.2 }, { 0, 0.6, -2.6 }, "accent" },
		},
	},
	{
		id = "satepadang", name = "Siluman Sate Padang", rarity = 5, price = 120000, income = 1600,
		quip = "KUAH KUNINGNYA BERSINAR.", scale = 1.6,
		body = { 0.95, 0.8, 0.2 }, accent = { 0.6, 0.35, 0.15 }, detail = { 0.95, 0.95, 0.9 },
		parts = {
			{ "Ball", { 1.8, 1.8, 1.8 }, { 0, -1, 0 }, "body" },
			{ "Ball", { 1.8, 1.8, 1.8 }, { 0, 0.8, 0 }, "body" },
			{ "Ball", { 1.8, 1.8, 1.8 }, { 0, 2.6, 0 }, "body" },
			{ "Cylinder", { 5.2, 0.3, 0.3 }, { 0, 0.8, 0 }, "accent" },
			{ "Ball", { 2.4, 1, 2.4 }, { 0, 3.6, 0 }, "detail", 0.3 },
			{ "Block", { 1.6, 0.4, 0.8 }, { 0, -2, 0 }, "accent" },
		},
	},
	{
		id = "kopitubruk", name = "Hantu Kopi Tubruk", rarity = 5, price = 160000, income = 2000,
		quip = "Ampasnya bisa meramal masa depan.", scale = 1.6,
		body = { 0.25, 0.15, 0.1 }, accent = { 0.95, 0.95, 0.95 }, detail = { 0.6, 0.4, 0.2 },
		parts = {
			{ "Cylinder", { 2.6, 2.6, 2.6 }, { 0, -0.4, 0 }, "accent" },
			{ "Ball", { 2.8, 1.6, 2.8 }, { 0, 1, 0 }, "body" },
			{ "Ball", { 1, 1.6, 1 }, { -0.9, 2.4, 0 }, "body", 0.4 },
			{ "Ball", { 1, 1.6, 1 }, { 0.9, 2.4, 0 }, "body", 0.4 },
			{ "Block", { 1.6, 0.4, 0.6 }, { 1.7, -0.2, 0.4 }, "detail" },
			{ "Ball", { 0.8, 0.8, 0.8 }, { 0, 1.4, 1.4 }, "detail" },
		},
	},
	{
		id = "penunggu", name = "Penunggu Warung Tua", rarity = 5, price = 200000, income = 2500,
		quip = "Sudah jualan sejak zaman Belanda.", scale = 1.7,
		body = { 0.5, 0.45, 0.4 }, accent = { 0.8, 0.7, 0.5 }, detail = { 0.15, 0.15, 0.2 },
		parts = {
			{ "Block", { 3, 3.4, 2.6 }, { 0, 0, 0 }, "body" },
			{ "Block", { 3.4, 0.6, 3 }, { 0, 2, 0 }, "accent" },
			{ "Ball", { 1.2, 1.2, 1.2 }, { -0.9, 0.6, 1.4 }, "detail" },
			{ "Ball", { 1.2, 1.2, 1.2 }, { 0.9, 0.6, 1.4 }, "detail" },
			{ "Block", { 0.6, 1.6, 0.6 }, { -1.8, -0.6, 0.6 }, "accent" },
			{ "Block", { 0.6, 1.6, 0.6 }, { 1.8, -0.6, 0.6 }, "accent" },
		},
	},
	{
		id = "mbok", name = "Mbok Darmi Abadi", rarity = 6, price = 1000000, income = 12000,
		quip = "Resepnya turun-temurun, umurnya juga.", scale = 1.8,
		body = { 0.7, 0.4, 0.5 }, accent = { 0.95, 0.9, 0.7 }, detail = { 0.3, 0.2, 0.2 },
		parts = {
			{ "Ball", { 3.2, 3, 3.2 }, { 0, 0, 0 }, "body" },
			{ "Cylinder", { 1, 2.6, 2.6 }, { 0, 2, 0 }, "accent" },
			{ "Ball", { 1.2, 1.2, 1.2 }, { -1.2, 0.5, 1.5 }, "detail" },
			{ "Ball", { 1.2, 1.2, 1.2 }, { 1.2, 0.5, 1.5 }, "detail" },
			{ "Block", { 2, 0.5, 0.8 }, { 0, -1.2, 1.4 }, "accent" },
			{ "Ball", { 0.9, 0.9, 0.9 }, { 0, 2.8, 0 }, "detail" },
		},
	},
	{
		id = "klepon", name = "Kanjeng Ratu Klepon", rarity = 6, price = 5000000, income = 50000,
		quip = "Gula merahnya meledak di mulut.", scale = 1.9,
		body = { 0.25, 0.7, 0.3 }, accent = { 0.95, 0.95, 0.9 }, detail = { 0.6, 0.25, 0.1 },
		parts = {
			{ "Ball", { 3.4, 3, 3.4 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 2.4, 1.2, 2.4 }, { 0, 1.6, 0 }, "accent" },
			{ "Block", { 0.6, 1, 0.6 }, { -0.8, 2.6, 0 }, "detail" },
			{ "Block", { 0.6, 1.3, 0.6 }, { 0, 2.7, 0 }, "detail" },
			{ "Block", { 0.6, 1, 0.6 }, { 0.8, 2.6, 0 }, "detail" },
			{ "Ball", { 1.3, 1.3, 1.3 }, { 0, 0.3, 1.8 }, "detail" },
		},
	},
	{
		id = "pecel", name = "Sang Purnama Pecel", rarity = 6, price = 12000000, income = 100000,
		quip = "Hanya muncul saat bulan purnama.", scale = 2,
		body = { 0.9, 0.9, 0.7 }, accent = { 0.3, 0.7, 0.3 }, detail = { 0.9, 0.5, 0.15 },
		parts = {
			{ "Ball", { 3.6, 3.6, 3.6 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 2, 1, 2 }, { 0, 1.9, 0 }, "accent" },
			{ "Ball", { 1.4, 1.4, 1.4 }, { -1.4, 0.4, 1.6 }, "detail" },
			{ "Ball", { 1.4, 1.4, 1.4 }, { 1.4, 0.4, 1.6 }, "detail" },
			{ "Cylinder", { 1.2, 3.8, 3.8 }, { 0, -2.4, 0 }, "accent" },
			{ "Ball", { 1, 1, 1 }, { 0, 2.8, 0 }, "detail" },
		},
	},
	{
		id = "eyang", name = "Eyang Warung Seribu Tahun", rarity = 6, price = 25000000, income = 250000,
		quip = "Warung pertama. Warung terakhir.", scale = 2.1,
		body = { 0.55, 0.4, 0.28 }, accent = { 0.85, 0.7, 0.45 }, detail = { 1, 0.85, 0.4 },
		parts = {
			{ "Block", { 3.4, 3, 4 }, { 0, 0, 0 }, "body" },
			{ "Block", { 3.8, 0.7, 4.4 }, { 0, 1.9, 0 }, "accent" },
			{ "Wedge", { 1.6, 1.1, 2.4 }, { -1.4, -1.7, 0 }, "accent" },
			{ "Wedge", { 1.6, 1.1, 2.4 }, { 1.4, -1.7, 0 }, "accent" },
			{ "Cylinder", { 1.8, 0.3, 0.3 }, { 1.4, 0.5, 1.8 }, "detail" },
			{ "Ball", { 1.1, 1.1, 1.1 }, { -1.3, 0.4, 1.9 }, "detail" },
		},
	},
}

local charactersById = {}
for _, character in ipairs(BrainrotCatalog.CHARACTERS) do
	charactersById[character.id] = character
end

function BrainrotCatalog.GetCharacter(characterId)
	return charactersById[characterId]
end

function BrainrotCatalog.GetRandomCharacterOfRarity(rarityIndex)
	local pool = {}
	for _, character in ipairs(BrainrotCatalog.CHARACTERS) do
		if character.rarity == rarityIndex then
			table.insert(pool, character)
		end
	end
	if #pool == 0 then
		return BrainrotCatalog.CHARACTERS[1]
	end
	return pool[math.random(#pool)]
end

function BrainrotCatalog.RollRarityWithPity(pityLegendary, pityMythic)
	local minRarity = 1
	if pityMythic then
		minRarity = 5
	elseif pityLegendary then
		minRarity = 4
	end
	local total = 0
	for index = minRarity, Rarities.GetCount() do
		total = total + Rarities.LIST[index].weight
	end
	local roll = math.random() * total
	for index = minRarity, Rarities.GetCount() do
		roll = roll - Rarities.LIST[index].weight
		if roll <= 0 then
			return index
		end
	end
	return minRarity
end

function BrainrotCatalog.RollMutation()
	return Mutations.Roll()
end

function BrainrotCatalog.GetIncomeWithMutation(character, mutationName)
	return character.income * Mutations.GetMultiplier(mutationName)
end

function BrainrotCatalog.FormatMoney(amount)
	amount = math.floor(amount + 0.5)
	local text = tostring(amount)
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. out
end

return BrainrotCatalog
