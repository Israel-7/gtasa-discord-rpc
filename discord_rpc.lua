script_name("SA Discord RPC")

script_properties(
    "work-in-pause",
    "forced-reloading-only"
)

local ffi = require("ffi")

ffi.cdef([[
    typedef struct {
        const char* state;
        const char* details;
        int64_t startTimestamp;
        int64_t endTimestamp;
        const char* largeImageKey;
        const char* largeImageText;
        const char* smallImageKey;
        const char* smallImageText;
        const char* partyId;
        int partySize;
        int partyMax;
        const char* matchSecret;
        const char* joinSecret;
        const char* spectateSecret;
        int8_t instance;
    } DiscordRichPresence;

    void Discord_Initialize(const char* applicationId,
        int handlers,
        int autoRegister,
        const char* optionalSteamId);

    void Discord_UpdatePresence(const DiscordRichPresence* presence);

    typedef struct {
        int type;
        int state;
        int ammoInClip;
        int totalAmmo;
        char field_10[0x0C];
    } CWeapon;

    typedef struct {
        char field_0[0x544];
        float maxHealth;
        char field_548[0x58];
        CWeapon weapons[13];
    } CPed;
]])

local weapons = {
    [0] = "Fist",
    [1] = "Brass Knuckles",
    [2] = "Golf Club",
    [3] = "Night Stick",
    [4] = "Knife",
    [5] = "Bat",
    [6] = "Shovel",
    [7] = "Pool Cue",
    [8] = "Katana",
    [9] = "Chainsaw",
    [10] = "Purple Dildo",
    [11] = "Dildo",
    [12] = "Vibrator",
    [13] = "Silver Vibrator",
    [14] = "Flowers",
    [15] = "Cane",
    [16] = "Grenade",
    [17] = "Teargas",
    [18] = "Molotov",
    [19] = "Unused",
    [20] = "Unused",
    [21] = "Unused",
    [22] = "Colt 45",
    [23] = "Silenced Pistol",
    [24] = "Desert Eagle",
    [25] = "Shotgun",
    [26] = "Sawnoff-Shotgun",
    [27] = "Combat Shotgun",
    [28] = "Uzi",
    [29] = "MP5",
    [30] = "AK-47",
    [31] = "M4",
    [32] = "Tec-9",
    [33] = "Country Rifle",
    [34] = "Sniper Rifle",
    [35] = "Rocket Launcher",
    [36] = "Heat-Seeking RPG",
    [37] = "Flamethrower",
    [38] = "Minigun",
    [39] = "Satchel Charges",
    [40] = "Detonator",
    [41] = "Spray Can",
    [42] = "Fire Extinguisher",
    [43] = "Camera",
    [44] = "Night Vision",
    [45] = "Thermal Goggles",
    [46] = "Parachute",
    [47] = "Fake Pistol",
--  [ID] = "Weapon Name",
}

local drpc = ffi.load("moonloader/lib/discord-rpc.dll")
local rpc = ffi.new("DiscordRichPresence")

function main()
    drpc.Discord_Initialize("542214983115866116", 0, 0, "")
    
    repeat
        wait(0)
    until isPlayerPlaying(playerHandle)
    
    rpc.startTimestamp = os.time()
    
    local stat = getIntStat(121)
    local time = os.time()
    local flag = false
    local samp = 0
    
    if isSampLoaded() then
        if isSampfuncsLoaded() then
            samp = 2
        else
            print("Sampfuncs required to work on samp mode.")
            samp = 1
        end
    end
    
    local cped = ffi.cast("CPed*", getCharPointer(playerPed))

    while true do
        if isCharDead(playerPed) or hasCharBeenArrested(playerPed) then
            rpc.largeImageKey = "game_icon_" .. (isCharDead(playerPed) and "wasted" or "busted")
        else
            rpc.largeImageKey = (samp >= 1 and "samp" or "game") .. "_icon"
        end

        if flag then
            if samp == 2 then
                local gameState = {
                    "None",
                    "Wait Connect",
                    "Await Join",
                    "Connected",
                    "Restarting",
                    "Disconnected"
                }

                local state = sampGetGamestate()
                
                if state == 3 or state == 4 then
                    local ip, port = sampGetCurrentServerAddress()
                    rpc.state = "Address: " .. ip .. ':' .. port
                else
                    rpc.state = "State: " .. gameState[sampGetGamestate()]
                end
                
                rpc.details = "Server: " .. sampGetCurrentServerName()
            elseif samp == 0 then
                local res, wLevel = storeWantedLevel(playerHandle)
                local stars = ""
    
                if wLevel > 0 then
                    for i = 1, wLevel do
                        stars = stars .. "☆"
                    end
                else
                    stars = "Safe"
                end
    
                rpc.state = "Wanted Level: " .. stars
                rpc.details = "Kills: " .. getIntStat(121) - stat
            end
            
            if os.time() > time + 5 then
                flag = false
                time = os.time()
            end
        else
            local zone = getGxtText(getNameOfZone(getCharCoordinates(playerPed)))
            local show = false
            
            if samp == 2 then
                local state = sampGetGamestate()
                
                if state == 3 or state == 4 then
                    show = true
                end
            else 
                show = true
            end
            
            if show then
                if isCharSittingInAnyCar(playerPed) then
                    local currCar = storeCarCharIsInNoSave(playerPed)
                    local gxtModel = getNameOfVehicleModel(getCarModel(currCar))
                    rpc.state = string.format("Driving %s in %s", getGxtText(gxtModel), zone)
                else
                    rpc.state = "Walking in " .. zone
                end

                rpc.details = "Money: $" .. getPlayerMoney(playerHandle)
            end
            
            if os.time() > time + 5 then
                flag = true
                time = os.time()
            end
        end

        local armour = getCharArmour(playerPed)
        local maxArmour = getPlayerMaxArmour(playerHandle)

        local health = getCharHealth(playerPed)
        local maxHealth = cped.maxHealth

        if armour > 0 then
            rpc.largeImageText = string.format("Armour: %.01f / %.01f Health: %.01f / %.01f",
                armour, maxArmour, health, maxHealth)
        else
            rpc.largeImageText = string.format("Health: %.01f / %.01f", health, maxHealth)
        end

        local currWeap = getCurrentCharWeapon(playerPed)
        local wpName = weapons[currWeap] or ""
        
        rpc.smallImageKey = "weap_" .. (wpName ~= "" and currWeap or "added")

        local slot = getWeapontypeSlot(currWeap)
        local clip = cped.weapons[slot].ammoInClip
        local total = cped.weapons[slot].totalAmmo

        if slot <= 1 or slot >= 10 then
            rpc.smallImageText = wpName
        end

        if slot == 3 or slot == 6 or slot == 7 or slot == 8 then
            rpc.smallImageText = string.format("%s %d", wpName, total)
        end

        if slot == 2 or slot == 4 or slot == 5 or slot == 9 then
            rpc.smallImageText = string.format("%s %d / %d", wpName, clip, total - clip)
        end

        drpc.Discord_UpdatePresence(rpc)
        wait(150)
    end
end
