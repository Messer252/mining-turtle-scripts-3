-- =====================================
-- Chad.Net v4.2 CLIENT (FINAL UI)
-- =====================================

local PROTOCOL = "chadnet"

-------------------------------------------------
-- MODEM
-------------------------------------------------
for _, side in ipairs({"left","right","top","bottom","front","back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
        rednet.open(side)
        break
    end
end

-------------------------------------------------
-- MONITOR
-------------------------------------------------
local monitor
for _, side in ipairs({"left","right","top","bottom","front","back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "monitor" then
        monitor = peripheral.wrap(side)
        monitor.setTextScale(0.5)
        break
    end
end

if monitor then term.redirect(monitor) end

-------------------------------------------------
-- STATE
-------------------------------------------------
local username
local chat = {}
local input = ""
local status = "Connecting..."

-------------------------------------------------
-- SEND
-------------------------------------------------
local function send(msg)
    rednet.broadcast(msg, PROTOCOL)
end

-------------------------------------------------
-- LOGIN
-------------------------------------------------
term.clear()
term.setCursorPos(1,1)

print("Chad.Net v4.2")
write("Username: ")
username = read()

write("Password: ")
local pass = read("*")

send({type="login", user=username, pass=pass})

-------------------------------------------------
-- DRAW UI
-------------------------------------------------
local function draw()
    term.clear()
    term.setCursorPos(1,1)

    print("Chad.Net | "..username)
    print("----------------------")

    for i = math.max(1,#chat-12), #chat do
        print(chat[i])
    end

    print("----------------------")
    write("> "..input)

    -- bottom-right status
    local w,h = term.getSize()
    term.setCursorPos(w-20, h)
    write("Server: "..status)
end

-------------------------------------------------
-- RECEIVE
-------------------------------------------------
local function recv()
    while true do
        local _, msg = rednet.receive(PROTOCOL)

        if msg.type == "chat" or msg.type == "dm" or msg.type == "system" then
            table.insert(chat, msg.text)

        elseif msg.type == "bot" then
            table.insert(chat, msg.text)

        elseif msg.type == "ttt" then
            table.insert(chat, "[TTT] "..msg.text)

        elseif msg.type == "pong" then
            status = "Online"
        elseif msg.type == "ok" then
            table.insert(chat, "[OK] "..msg.text)
        elseif msg.type == "error" then
            table.insert(chat, "[ERR] "..msg.text)
        end

        draw()
    end
end

-------------------------------------------------
-- HEARTBEAT
-------------------------------------------------
local function heartbeat()
    while true do
        send({type="ping"})
        sleep(2)
    end
end

-------------------------------------------------
-- INPUT
-------------------------------------------------
local function ui()
    draw()

    while true do
        local e,a = os.pullEvent()

        if e == "char" then
            input = input .. a
        elseif e == "key" and a == keys.backspace then
            input = input:sub(1,-2)

        elseif e == "key" and a == keys.enter then
            if input ~= "" then
                send({type="chat", text=input})
                input = ""
            end
        end

        draw()
    end
end

parallel.waitForAny(recv, ui, heartbeat)
