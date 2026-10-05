-- ==========================================
-- SCRIPT AUTO SKILL: NORMAL vs SEMI vs BURST
-- ==========================================
-- SCRIPT_VERSION = "1.0.0"

-- @config TARGET_MAP_ID:int:3:Map ID untuk menghentikan script (Stop Script)
-- @config TARGET_MONSTER_TYPES:list:52228,52213:Daftar ID Monster untuk memicu mode Full Burst (Prioritas Tertinggi)
-- @config SEMI_BURST_MONSTER_TYPES:list:52198:Daftar ID Monster untuk memicu mode Semi Burst (Prioritas Menengah)
-- @config NORMAL_SKILL_SLOTS:list:3:Slot skill yang aktif pada mode Normal (pisahkan dengan koma, misal: 0,3)
-- @config SEMI_BURST_SKILL_SLOTS:list:0,3:Slot skill yang aktif pada mode Semi Burst (pisahkan dengan koma, misal: 0,3)

-- 1. HELPER FUNCTION (Aman untuk baca objek C++)
local function getProp(obj, name)
    local ok, v = pcall(function() return obj[name] end)
    if not ok then return nil end

    if type(v) == "function" or type(v) == "userdata" then
        local ok2, res = pcall(v, obj)
        if ok2 then return res end
        local ok3, res2 = pcall(v)
        if ok3 then return res2 end
    end
    return v
end

-- 2. KONFIGURASI MONSTER
local TARGET_MAP_ID = 3

-- ★★★ DAFTAR MONSTER FULL BURST (Prioritas Tertinggi) ★★★
local TARGET_MONSTER_TYPES = {
    52228,
    52213
}

-- ★★★ DAFTAR MONSTER SEMI BURST (Prioritas Menengah) ★★★
-- Masukkan Type monster di sini (Contoh: Elite monster)
local SEMI_BURST_MONSTER_TYPES = {
    52198
}

-- 3. KONFIGURASI SKILL
-- Skill untuk Mode Normal
local NORMAL_SKILL_SLOTS = { 3 }

-- Skill untuk Mode Semi Burst
local SEMI_BURST_SKILL_SLOTS = { 0, 3 }

-- Variabel pelacak
local currentMode = "NONE"

-- Fungsi Helper untuk cek array
local function isTargetType(mobType, targetList)
    for _, targetType in ipairs(targetList) do
        if tonumber(mobType) == targetType then
            return true
        end
    end
    return false
end

-- Fungsi untuk menerapkan konfigurasi skill
local function applySkillConfig(mode)
    -- LANGKAH 1: Matikan SEMUA slot terlebih dahulu (tanpa parameter status)
    for i = 0, 5 do
        pcall(AutoFarmSetUseSkill, i)
    end

    -- LANGKAH 2: Nyalakan skill sesuai mode
    if mode == "BURST" then
        -- Nyalakan SEMUA slot 0 sampai 5
        for i = 0, 5 do
            pcall(AutoFarmSetUseSkill, i, 1)
        end
    elseif mode == "SEMI_BURST" then
        -- Nyalakan HANYA slot Semi Burst
        for _, slot in ipairs(SEMI_BURST_SKILL_SLOTS) do
            pcall(AutoFarmSetUseSkill, slot, 1)
        end
    elseif mode == "NORMAL" then
        -- Nyalakan HANYA slot Normal
        for _, slot in ipairs(NORMAL_SKILL_SLOTS) do
            pcall(AutoFarmSetUseSkill, slot, 1)
        end
    end

    currentMode = mode
end

logInfo("=== MEMULAI SCRIPT AUTO SKILL (3 MODE) ===")
logInfo("Target Full Burst: " .. table.concat(TARGET_MONSTER_TYPES, ", "))
logInfo("Target Semi Burst: " .. table.concat(SEMI_BURST_MONSTER_TYPES, ", "))

-- Terapkan mode normal di awal script
applySkillConfig("NORMAL")

-- 4. MAIN LOOP
while true do
    -- A. CEK MAP ID
    local okMap, mapID = pcall(GetMapID)
    local currentMapID = okMap and mapID or "Unknown"

    if currentMapID == TARGET_MAP_ID then
        logInfo("[BREAK] Terdeteksi berada di Map ID " .. TARGET_MAP_ID .. "! Script dihentikan.")
        applySkillConfig("NORMAL")
        break
    end

    -- B. DETEKSI MONSTER TERDEKAT
    local mob = GetNearestMonster()
    local nextMode = "NORMAL" -- Default ke normal

    if mob ~= nil then
        local mobType = getProp(mob, "Type")
        local mobDead = getProp(mob, "Dead")

        -- Cek kondisi monster jika masih hidup
        if mobDead == false then
            -- Prioritas 1: Full Burst
            if isTargetType(mobType, TARGET_MONSTER_TYPES) then
                nextMode = "BURST"
                -- Prioritas 2: Semi Burst
            elseif isTargetType(mobType, SEMI_BURST_MONSTER_TYPES) then
                nextMode = "SEMI_BURST"
            end
        end
    end

    -- C. TERAPKAN MODE JIKA BERUBAH
    if nextMode ~= currentMode then
        applySkillConfig(nextMode)

        if nextMode == "BURST" then
            logInfo("[SKILL] >>> FULL BURST MODE! Mengaktifkan SEMUA Skill (0-5).")
        elseif nextMode == "SEMI_BURST" then
            logInfo("[SKILL] >> SEMI BURST MODE! Mengaktifkan Skill: " .. table.concat(SEMI_BURST_SKILL_SLOTS, ","))
        else
            logInfo("[SKILL] Kembali ke Normal. Mengaktifkan Skill: " .. table.concat(NORMAL_SKILL_SLOTS, ","))
        end
    end

    -- D. JEDA
    Sleep(1)
end

logInfo("=== SCRIPT SELESAI ===")
