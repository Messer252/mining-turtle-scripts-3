-- =====================================
-- Chad.Net v4.1 CLIENT (GUI + MONITOR)
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
-- MONITOR SUPPORT
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
local username = nil
local chat = ""
local input = ""

local sendBtn = {x=1, y=1}

-------------------------------------------------
-- NETWORK
-------------------------------------------------
local function send(msg)
    rednet.broadcast(msg, PROTOCOL)
end

-------------------------------------------------
-- LOGIN
-------------------------------------------------
term.clear()
term.setCursorPos(1,1)

print("Chad.Net v4.1")
write("Username: ")
local u = read()

write("Password: ")
local p = read("*")

send({type="login", user=u, pass=p})
username = u

sleep(1)

-------------------------------------------------
-- DRAW
-------------------------------------------------
local function draw()
    term.clear()
    term.setCursorPos(1,1)

    print("Chad.Net | "..username)
    print("----------------------")
    print(chat)
    print("----------------------")

    write("> "..input)

    -- send button (simple)
    local w,h = term.getSize()
    term.setCursorPos(w-6, h)
    write("[SEND]")
end

-------------------------------------------------
-- RECEIVE
-------------------------------------------------
local function recv()
    while true do
        local _, msg = rednet.receive(PROTOCOL)

        if msg.type == "chat" or msg.type == "dm" or msg.type == "system" then
            chat = chat .. "\n" .. msg.text
            draw()

        elseif msg.type == "ttt" then
            chat = chat .. "\n[TTT] "..msg.text
            draw()

        elseif msg.type == "bot" then
            chat = chat .. "\n"..msg.text
            draw()

        elseif msg.type == "ok" or msg.type == "error" then
            chat = chat .. "\n["..msg.type.."] "..msg.text
            draw()
        end
    end
end

-------------------------------------------------
-- INPUT + CONTROLS
-------------------------------------------------
local function ui()
    draw()

    while true do
        local event, a, b, c = os.pullEvent()

        if event == "char" then
            input = input .. a
            draw()

        elseif event == "key" then
            if a == keys.backspace then
                input = input:sub(1,-2)
                draw()

            elseif a == keys.enter then
                if input ~= "" then
                    send({type="chat", text=input})
                    input = ""
                    draw()
                end
            end

        elseif event == "mouse_click" then
            local w,h = term.getSize()

            -- send button click
            if b == h then
                send({type="chat", text=input})
                input = ""
                draw()
            end
        end

        -------------------------------------------------
        -- COMMANDS
        -------------------------------------------------
        if event == "char" and input:sub(1,1) == "/" then
            -- handled on enter
        elseif event == "key" and a == keys.enter then
            if input:sub(1,5) == "/msg " then
                local _,_,to,msg = input:find("/msg (%S+) (.+)")
                send({type="dm", to=to, text=msg})

            elseif input:sub(1,5) == "/ttt " then
                send({type="ttt_challenge", target=input:sub(6)})

            elseif input:sub(1,6) == "/move " then
                send({type="ttt_move", pos=tonumber(input:sub(7))})

            elseif input:sub(1,5) == "/bot " then
                send({type="bot_query", id=tonumber(input:sub(6))})
            end
        end
    end
end

parallel.waitForAny(recv, ui)
