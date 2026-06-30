-- =====================================
-- Chad.Net v4.2 SERVER (FINAL)
-- =====================================

local PROTOCOL = "chadnet"

-- Open modem
for _, side in ipairs({"left","right","top","bottom","front","back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
        rednet.open(side)
        break
    end
end

-------------------------------------------------
-- DATA
-------------------------------------------------
local users = {}        -- username -> passhash
local sessions = {}     -- id -> username
local clients = {}      -- id -> username (active)
local lastSeen = {}     -- heartbeat tracking

local bots = {}
local ttt = {}

-------------------------------------------------
-- HASH
-------------------------------------------------
local function hash(str)
    local h = 0
    for i = 1, #str do
        h = (h * 31 + string.byte(str, i)) % 1000000007
    end
    return tostring(h)
end

local function send(id, msg)
    rednet.send(id, msg, PROTOCOL)
end

local function broadcast(msg)
    rednet.broadcast(msg, PROTOCOL)
end

-------------------------------------------------
-- TIC TAC TOE WIN CHECK
-------------------------------------------------
local wins = {
    {1,2,3},{4,5,6},{7,8,9},
    {1,4,7},{2,5,8},{3,6,9},
    {1,5,9},{3,5,7}
}

local function checkWin(b, s)
    for _, w in ipairs(wins) do
        if b[w[1]]==s and b[w[2]]==s and b[w[3]]==s then
            return true
        end
    end
    return false
end

-------------------------------------------------
-- SERVER STATUS UI
-------------------------------------------------
local function drawStatus()
    term.clear()
    term.setCursorPos(1,1)

    local count = 0
    for _ in pairs(clients) do count = count + 1 end

    print("===================================")
    print(" Chad.Net SERVER v4.2")
    print(" Connected Clients: "..count)
    print(" Active Sessions: "..count)
    print("===================================")
end

drawStatus()

-------------------------------------------------
-- MAIN LOOP
-------------------------------------------------
while true do
    local id, msg = rednet.receive(PROTOCOL)
    if type(msg) ~= "table" then goto continue end

    -------------------------------------------------
    -- PING / HEARTBEAT
    -------------------------------------------------
    if msg.type == "ping" then
        lastSeen[id] = os.clock()
        send(id, {type="pong"})
    end

    -------------------------------------------------
    -- REGISTER
    -------------------------------------------------
    if msg.type == "register" then
        if users[msg.user] then
            send(id, {type="error", text="User exists"})
        else
            users[msg.user] = hash(msg.pass)
            send(id, {type="ok", text="Account created"})
        end

    -------------------------------------------------
    -- LOGIN
    -------------------------------------------------
    elseif msg.type == "login" then
        if not users[msg.user] then
            send(id, {type="error", text="No user"})
        elseif users[msg.user] ~= hash(msg.pass) then
            send(id, {type="error", text="Wrong password"})
        else
            sessions[id] = msg.user
            clients[id] = msg.user
            lastSeen[id] = os.clock()

            send(id, {type="ok", text="Logged in as "..msg.user})
            broadcast({type="system", text=msg.user.." joined Chad.Net"})
        end

    -------------------------------------------------
    -- CHAT
    -------------------------------------------------
    elseif msg.type == "chat" then
        local user = sessions[id]
        if not user then goto continue end

        broadcast({type="chat", text="["..user.."]: "..msg.text})

    -------------------------------------------------
    -- DM
    -------------------------------------------------
    elseif msg.type == "dm" then
        local from = sessions[id]
        if not from then goto continue end

        for cid, uname in pairs(sessions) do
            if uname == from or uname == msg.to then
                send(cid, {type="dm", text="(DM) "..from.." -> "..msg.to..": "..msg.text})
            end
        end

    -------------------------------------------------
    -- BOT STATUS UPDATE
    -------------------------------------------------
    elseif msg.type == "bot_status" then
        bots[msg.id] = {
            slice = msg.slice,
            fuel = msg.fuel,
            inv = msg.inv,
            state = msg.state,
            last = os.clock()
        }

    -------------------------------------------------
    -- BOT QUERY
    -------------------------------------------------
    elseif msg.type == "bot_query" then
        local b = bots[msg.id]

        if not b then
            send(id, {type="bot", text="No data for bot "..msg.id})
        else
            send(id, {
                type="bot",
                text=string.format(
                    "[BOT %s]\nSlice:%d Fuel:%d Inv:%d%% State:%s",
                    msg.id, b.slice, b.fuel, b.inv, b.state
                )
            })
        end

    -------------------------------------------------
    -- TIC TAC TOE
    -------------------------------------------------
    elseif msg.type == "ttt_challenge" then
        local p1 = sessions[id]
        local p2 = msg.target

        if not users[p2] then goto continue end

        ttt[p2] = {
            p1 = p1,
            p2 = p2,
            board = {" "," "," "," "," "," "," "," "," "},
            turn = p1,
            active = true
        }

        broadcast({type="system", text=p1.." challenged "..p2.." to TicTacToe"})

    elseif msg.type == "ttt_move" then
        local player = sessions[id]
        local game = ttt[player]

        if not game or not game.active then goto continue end
        if game.turn ~= player then goto continue end

        local pos = msg.pos
        if not pos or game.board[pos] ~= " " then goto continue end

        local sym = (player == game.p1) and "X" or "O"
        game.board[pos] = sym

        if checkWin(game.board, sym) then
            broadcast({type="ttt", text=player.." wins TicTacToe!"})
            game.active = false
            goto continue
        end

        game.turn = (game.turn == game.p1) and game.p2 or game.p1
        send(id, {type="ttt", text="Turn: "..game.turn})
    end

    ::continue::

    -------------------------------------------------
    -- CLEANUP DEAD CLIENTS
    -------------------------------------------------
    for cid, t in pairs(lastSeen) do
        if os.clock() - t > 15 then
            lastSeen[cid] = nil
            sessions[cid] = nil
            clients[cid] = nil
        end
    end

    drawStatus()
end
