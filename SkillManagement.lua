-- ==========================================
-- 1. SMART AUTO-DETECT PATH & SECURE HEADER
-- ==========================================
local function findNenFolder()
    local user = os.getenv("USERPROFILE")
    if not user then return "." end

    user = user:gsub("\\", "/")

    local possiblePaths = {
        user .. "/OneDrive/Documents/Nen",
        user .. "/Documents/Nen",
        user .. "/OneDrive/Desktop/Nen",
        user .. "/Desktop/Nen"
    }

    for _, path in ipairs(possiblePaths) do
        local f = io.open(path .. "/config/skmanagerconfig.txt", "r")
        if f then
            f:close()
            logInfo("[SYSTEM] Folder Nen ditemukan di: " .. path)
            return path
        end
    end

    logInfo("[SYSTEM] Menggunakan path relatif (folder saat ini).")
    return "."
end

local BASE_PATH = findNenFolder()

local MY_SCRIPT_NAME = "SkillManagement.lua"
local FEEDBACK_PATH = BASE_PATH .. "/config/feedback.txt"

local function writeFeedbackWithRetry(path, content, maxAttempts)
    maxAttempts = maxAttempts or 5
    for attempt = 1, maxAttempts do
        local f = io.open(path, "w")
        if f then
            f:write(content)
            f:close()
            logInfo("[SECURE] Sinyal loaded terkirim untuk: " .. MY_SCRIPT_NAME)
            return true
        else
            SleepMs(300)
        end
    end
    logError("[SECURE] Gagal menulis feedback.txt")
    return false
end

writeFeedbackWithRetry(FEEDBACK_PATH, "loaded:" .. MY_SCRIPT_NAME)


-- ==========================================
-- 2. FUNGSI PARSER CONFIG
-- ==========================================
local function loadTextConfig(filePath)
    local config = {}
    local file = io.open(filePath, "r")
    if not file then return config end

    for line in file:lines() do
        if not line:match("^%s*#") and not line:match("^%s*$") then
            local key, value = line:match("^%s*(.-)%s*=%s*(.-)%s*$")
            if key and value then config[key] = value end
        end
    end
    file:close()
    return config
end

local function parseList(str)
    local result = {}
    if not str or str == "" then return result end
    for val in string.gmatch(str, "([^,]+)") do
        table.insert(result, tonumber(val) or val)
    end
    return result
end


-- ==========================================
-- 3. KONFIGURASI DEFAULT ASLI (FITUR ASLI)
-- ==========================================
local TARGET_MAP_ID = 3

-- ★★★ DAFTAR MONSTER FULL BURST (Prioritas Tertinggi) ★★★
local TARGET_MONSTER_TYPES = { 52215, 52212, 52211, 52214, 52216, 52221, 52218, 52219, 52217, 52220, 52225, 52224, 52224, 52222, 52223, 52226, 52227, 52228, 52229, 52230, 52231, 52232, 52234, 52233, 52235, 52236, 52239, 52240, 52237, 52238 }

-- ★★★ DAFTAR MONSTER SEMI BURST (Prioritas Menengah) ★★★
local SEMI_BURST_MONSTER_TYPES = { 52200, 52197, 52198, 52196, 52199, 52201, 52206, 52203, 52204, 52202, 52205, 52210, 52209, 52207, 52208 }

-- Skill untuk Mode Normal
local NORMAL_SKILL_SLOTS = { 3 }

-- Skill untuk Mode Semi Burst
local SEMI_BURST_SKILL_SLOTS = { 0, 3 }


-- ==========================================
-- 4. TERAPKAN CONFIG DARI FILE TXT (JIKA ADA)
-- ==========================================
local CONFIG_PATH = BASE_PATH .. "/config/skmanagerconfig.txt"
local cfg = loadTextConfig(CONFIG_PATH)

if cfg and next(cfg) ~= nil then
    logInfo("[CONFIG] Berhasil memuat skmanagerconfig.txt")

    -- Override default jika ada di config
    if cfg.TARGET_MAP_ID then TARGET_MAP_ID = tonumber(cfg.TARGET_MAP_ID) end

    local parsedTarget = parseList(cfg.TARGET_MONSTER_TYPES)
    if #parsedTarget > 0 then TARGET_MONSTER_TYPES = parsedTarget end

    local parsedSemi = parseList(cfg.SEMI_BURST_MONSTER_TYPES)
    if #parsedSemi > 0 then SEMI_BURST_MONSTER_TYPES = parsedSemi end

    local parsedNormal = parseList(cfg.NORMAL_SKILL_SLOTS)
    if #parsedNormal > 0 then NORMAL_SKILL_SLOTS = parsedNormal end

    local parsedSemiSlot = parseList(cfg.SEMI_BURST_SKILL_SLOTS)
    if #parsedSemiSlot > 0 then SEMI_BURST_SKILL_SLOTS = parsedSemiSlot end
else
    logInfo("[CONFIG] File config tidak ditemukan, menggunakan default script.")
end

-- Log detail config (Fitur asli yang Anda minta)
logInfo("[CONFIG] Target Map ID: " .. TARGET_MAP_ID)
logInfo("[CONFIG] Normal Slots: " .. table.concat(NORMAL_SKILL_SLOTS, ","))
logInfo("[CONFIG] Semi Burst Slots: " .. table.concat(SEMI_BURST_SKILL_SLOTS, ","))


-- ==========================================
-- 5. HELPER FUNCTION (Aman untuk baca objek C++)
-- ==========================================
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

local function isTargetType(mobType, targetList)
    for _, targetType in ipairs(targetList) do
        if tonumber(mobType) == targetType then
            return true
        end
    end
    return false
end

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


-- ==========================================
-- 6. MAIN LOOP (FITUR ASLI DIPERTAHANKAN)
-- ==========================================
logInfo("=== MEMULAI SCRIPT AUTO SKILL (3 MODE) ===")
logInfo("Target Full Burst: " .. table.concat(TARGET_MONSTER_TYPES, ", "))
logInfo("Target Semi Burst: " .. table.concat(SEMI_BURST_MONSTER_TYPES, ", "))

local currentMode = "NONE"
applySkillConfig("NORMAL")

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


-- ==========================================
-- 7. BAGIAN AKHIR: KEMBALI KE MODE MONITOR
-- ==========================================
logInfo("=== SCRIPT SELESAI ===")
Sleep(1)