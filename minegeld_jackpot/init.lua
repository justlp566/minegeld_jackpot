-- minegeld_jackpot/init.lua
-- Handheld lottery ticket:
--   - Normal use: +10 Minegeld
--   - Jackpot: 1% chance to win 1,000,000 Minegeld (broadcasted)
--   - Admins can set a player's "luck" (numeric). Effective jackpot chance = JACKPOT_CHANCE * (1 + luck)
--     Setting very large luck (e.g., 1e10) will make jackpot effectively guaranteed.
-- Requires the 'minegeld' mod.

local SMALL_AWARD = 10
local JACKPOT_AWARD = 1000000
local JACKPOT_CHANCE = 0.01 -- 1%

math.randomseed(os.time() + (os.clock() * 1000))

local mod_storage = minetest.get_mod_storage()

local function get_balance(name)
    if minegeld and minegeld.get then
        return minegeld.get(name) or 0
    end
    return 0
end

local function add_money(name, amount)
    if minegeld and minegeld.add then
        minegeld.add(name, amount)
    else
        if minegeld and minegeld.set then
            local cur = get_balance(name)
            minegeld.set(name, cur + amount)
        end
    end
end

-- Luck is stored either on the online player's attributes or in mod_storage for offline players
local function get_luck(name)
    local player = minetest.get_player_by_name(name)
    if player then
        local attr = player:get_attribute("minegeld_jackpot:luck")
        if attr then
            return tonumber(attr) or 0
        end
    end
    -- fallback to mod storage
    return tonumber(mod_storage:get_int("luck:" .. name)) or 0
end

local function set_luck(target_name, value)
    local player = minetest.get_player_by_name(target_name)
    if player then
        player:set_attribute("minegeld_jackpot:luck", tostring(value))
    end
    mod_storage:set_int("luck:" .. target_name, math.floor(value))
end

minetest.register_craftitem("minegeld_jackpot:ticket", {
    description = "Lottery Ticket (1% jackpot)",
    inventory_image = "minegeld_jackpot_ticket.png",
    stack_max = 64,

    on_use = function(itemstack, user, pointed_thing)
        if not user or not user:is_player() then
            return itemstack
        end

        local pname = user:get_player_name()
        local luck = get_luck(pname)

        -- compute effective chance, cap at 1
        local effective_chance = JACKPOT_CHANCE * (1 + (tonumber(luck) or 0))
        if effective_chance > 1 then
            effective_chance = 1
        end

        -- roll
        local jackpot = false
        if effective_chance >= 1 then
            jackpot = true
        else
            if math.random() < effective_chance then
                jackpot = true
            end
        end

        if jackpot then
            add_money(pname, JACKPOT_AWARD)
            minetest.chat_send_player(pname, "JACKPOT! You won " .. JACKPOT_AWARD .. " Minegeld!")
            minetest.chat_send_all("*** " .. pname .. " just WON the lottery jackpot: " .. JACKPOT_AWARD .. " Minegeld! ***")
        else
            add_money(pname, SMALL_AWARD)
            local newbal = get_balance(pname)
            minetest.chat_send_player(pname, "You received " .. SMALL_AWARD .. " Minegeld. Balance: " .. newbal)
        end

        itemstack:take_item()
        return itemstack
    end,
})

-- Admin commands to set/get/clear luck
minetest.register_chatcommand("mj_setluck", {
    params = "<player> <value>",
    description = "[admin] Set minegeld_jackpot luck for player (numeric)",
    privs = {server = true},
    func = function(name, param)
        local target, val = param:match("^(%S+)%s+(%S+)$")
        if not target or not val then
            return false, "Usage: /mj_setluck <player> <value>"
        end
        local nval = tonumber(val)
        if not nval then
            return false, "Value must be a number"
        end
        set_luck(target, nval)
        return true, "Set luck for " .. target .. " to " .. nval
    end,
})

minetest.register_chatcommand("mj_getluck", {
    params = "<player>",
    description = "Get minegeld_jackpot luck for player",
    privs = {server = true},
    func = function(name, param)
        if param == "" then
            return false, "Usage: /mj_getluck <player>"
        end
        local val = get_luck(param)
        return true, param .. " has luck = " .. (tonumber(val) or 0)
    end,
})

minetest.register_chatcommand("mj_clearluck", {
    params = "<player>",
    description = "Clear minegeld_jackpot luck for player",
    privs = {server = true},
    func = function(name, param)
        if param == "" then
            return false, "Usage: /mj_clearluck <player>"
        end
        set_luck(param, 0)
        return true, "Cleared luck for " .. param
    end,
})
