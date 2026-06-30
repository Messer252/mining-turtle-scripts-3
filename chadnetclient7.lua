-- =====================================
-- Chad.Net v6.3 CLIENT (ESC REMOVED SAFELY)
-- =====================================

local PROTOCOL = "chadnet"

-------------------------------------------------
-- NETWORK
-------------------------------------------------
for _, side in ipairs({"left","right","top","bottom","front","back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
        rednet.open(side)
        break
    end
end

-------------------------------------------------
-- STATE
-------------------------------------------------
local user
local chat = {}
local input = ""
local status = "CONNECTING..."

local screen = "chat"

-------------------------------------------------
local function send(msg)
    rednet.broadcast(msg, PROTOCOL)
end

-------------------------------------------------
-- LOGIN
-------------------------------------------------
term.clear()
term.setCursorPos(1,1)

print("Chad.Net v6.3")
write("Username: ")
user = read()

send({type="login", user=user})

-------------------------------------------------
-- HELP
-------------------------------------------------
local helpText = {
"Chad.Net v6.3 Commands:",
"",
"/help        - show help",
"/chat        - return to chat view",
"/users       - list users",
"/dm u msg    - private message",
"/bot id      - check mining bot",
"/ttt user    - challenge player",
"",
"NOTE: No ESC used (safe mode)"
}

-------------------------------------------------
-- DRAW UI
-------------------------------------------------
local function draw()
    term.clear()
    term.setCursorPos(1,1)

    print("Chad.Net | "..user.." | "..status)
    print("--------------------------------")

    if screen == "chat" then
        for i = math.max(1,#chat-12), #chat do
            print(chat[i])
        end

        print("--------------------------------")
        write("> "..input)

    elseif screen == "help" then
        for _, l in ipairs(helpText) do
            print(l)
        end

    elseif screen == "users" then
        print("Requesting user list...")
    end

    local w,h = term.getSize()
    term.setCursorPos(1,h)
    term.clearLine()
    term.write("[CHAT] [HELP] [USERS]   "..status)
end

-------------------------------------------------
-- RECEIVE
-------------------------------------------------
local function recv()
    while true do
        local _, msg = rednet.receive(PROTOCOL)

        if msg.type == "chat" then
            table.insert(chat, msg.text)

        elseif msg.type == "dm" then
            table.insert(chat, "(DM) "..msg.from..": "..msg.text)

        elseif msg.type == "system" then
            table.insert(chat, msg.text)

        elseif msg.type == "bot_info" then
            table.insert(chat, textutils.serialize(msg.data))

        elseif msg.type == "user_list" then
            table.insert(chat, "Online: "..table.concat(msg.users, ", "))

        elseif msg.type == "login_ok" or msg.type == "pong" then
            status = "ONLINE 🟢"
        end

        draw()
    end
end

-------------------------------------------------
-- INPUT (NO ESC AT ALL)
-------------------------------------------------
local function inputLoop()
    draw()

    while true do
        local e,a = os.pullEvent()

        if e == "char" then
            input = input .. a

        elseif e == "key" then

            if a == keys.backspace then
                input = input:sub(1,-2)

            elseif a == keys.enter then

                local msg = input
                input = ""

                -------------------------------------------------
                -- NAVIGATION (SAFE)
                -------------------------------------------------
                if msg == "/help" then
                    screen = "help"

                elseif msg == "/chat" then
                    screen = "chat"

                elseif msg == "/users" then
                    send({type="user_list"})
                    screen = "chat"

                -------------------------------------------------
                -- DM
                -------------------------------------------------
                elseif msg:sub(1,4) == "/dm " then
                    local _,_,to,text = msg:find("/dm (%S+) (.+)")
                    if to and text then
                        send({type="dm", to=to, text=text})
                    end

                -------------------------------------------------
                -- BOT
                -------------------------------------------------
                elseif msg:sub(1,5) == "/bot " then
                    send({type="bot_query", id=tonumber(msg:sub(6))})

                -------------------------------------------------
                -- TTT
                -------------------------------------------------
                elseif msg:sub(1,5) == "/ttt " then
                    send({type="ttt_challenge", target=msg:sub(6)})

                -------------------------------------------------
                -- CHAT
                -------------------------------------------------
                else
                    send({type="chat", text=msg})
                end
            end
        end

        draw()
    end
end

-------------------------------------------------
-- HEARTBEAT
-------------------------------------------------
local function ping()
    while true do
        send({type="ping"})
        sleep(2)
    end
end

-------------------------------------------------
-- RUN
-------------------------------------------------
parallel.waitForAny(recv, inputLoop, ping)
