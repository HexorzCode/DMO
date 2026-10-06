-- ==========================================

-- SCRIPT AUTO SKILL: NORMAL vs SEMI vs BURST

-- ==========================================

-- SCRIPT_VERSION = "1.1.0"



-- @config TARGET_MAP_ID:int:3:Map ID tempat script otomatis berhenti (misal 3 = kota utama)

-- @config TARGET_MONSTER_TYPES:list:52228,52213:ID Monster pemicu FULL BURST - semua skill aktif. Pisahkan dengan koma

-- @config SEMI_BURST_MONSTER_TYPES:list:52198:ID Monster pemicu SEMI BURST - hanya skill terpilih. Pisahkan dengan koma

-- @config NORMAL_SKILL_SLOTS:slots:3:Skill yang dipakai saat mode NORMAL (centang slotnya):0:5

-- @config SEMI_BURST_SKILL_SLOTS:slots:0,3:Skill yang dipakai saat mode SEMI BURST (centang slotnya):0:5



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

local TARGET_MONSTER_TYPES = { 52215, 52212, 52211, 52214, 52216, 52221, 52218, 52219, 52217, 52220, 52225, 52224, 52224, 52222, 52223, 52226, 52227, 52228, 52229, 52230, 52231, 52232, 52234, 52233, 52235, 52236, 52239, 52240, 52237, 52238 }



-- ★★★ DAFTAR MONSTER SEMI BURST (Prioritas Menengah) ★★★

-- Masukkan Type monster di sini (Contoh: Elite monster)

local SEMI_BURST_MONSTER_TYPES = { 52200, 52197, 52198, 52196, 52199, 52201, 52206, 52203, 52204, 52202, 52205, 52210, 52209, 52207, 52208 }



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

