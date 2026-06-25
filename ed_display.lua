-- ED Tracker Display
-- Starts automatically showing all ED patients
-- Press A to change area, S to change text size, R to refresh, Q to quit

local SERVER_ID = 1
local PROTOCOL = "ed_epr"
local SECRET = "ed123"

local REFRESH_SECONDS = 5
local TEXT_SCALE = 0.5
local DISPLAY_AREA = "ALL"

local running = true
local lastStatus = "Starting..."

local function clearTerm()
    term.clear()
    term.setCursorPos(1, 1)
end

local function findModemSide()
    local names = peripheral.getNames()

    for _, name in ipairs(names) do
        if peripheral.getType(name) == "modem" then
            return name
        end
    end

    return nil
end

local function findMonitor()
    return peripheral.find("monitor")
end

local MODEM_SIDE = findModemSide()

if not MODEM_SIDE then
    clearTerm()
    print("No modem found.")
    print("")
    print("Attach a wireless or ender modem to this computer.")
    return
end

rednet.open(MODEM_SIDE)

local monitor = findMonitor()

if not monitor then
    clearTerm()
    print("No monitor found.")
    print("")
    print("Attach a monitor to this computer.")
    return
end

monitor.setTextScale(TEXT_SCALE)

local function fitText(text, width)
    text = tostring(text or "")

    if width <= 0 then
        return ""
    end

    if #text > width then
        if width <= 3 then
            return string.sub(text, 1, width)
        end

        return string.sub(text, 1, width - 3) .. "..."
    end

    return text .. string.rep(" ", width - #text)
end

local function requestBoard()
    rednet.send(SERVER_ID, {
        secret = SECRET,
        action = "get_board"
    }, PROTOCOL)

    local senderId, response = rednet.receive(PROTOCOL, 3)

    if senderId ~= SERVER_ID then
        return nil, "No response from server"
    end

    if type(response) ~= "table" then
        return nil, "Invalid response from server"
    end

    if not response.ok then
        return nil, response.error or "Server returned an error"
    end

    return response.patients or {}, nil
end

local function filterPatientsByArea(patients, area)
    if area == "ALL" then
        return patients
    end

    local filtered = {}

    for _, patient in ipairs(patients) do
        if patient.area == area then
            table.insert(filtered, patient)
        end
    end

    return filtered
end

local function getTitle()
    if DISPLAY_AREA == "ALL" then
        return "BROOMFIELD ED TRACKER"
    end

    return "BROOMFIELD ED - " .. DISPLAY_AREA
end

local function drawNoPatients(width)
    monitor.setCursorPos(1, 1)
    monitor.write(fitText(getTitle(), width))

    monitor.setCursorPos(1, 3)

    if DISPLAY_AREA == "ALL" then
        monitor.write(fitText("No current ED patients.", width))
    else
        monitor.write(fitText("No current patients in " .. DISPLAY_AREA .. ".", width))
    end

    monitor.setCursorPos(1, 5)
    monitor.write(fitText("Updated: " .. os.date("%H:%M:%S"), width))
end

local function drawSmallBoard(patients, width, height)
    monitor.setCursorPos(1, 1)
    monitor.write(fitText(getTitle(), width))

    monitor.setCursorPos(1, 2)
    monitor.write(fitText("Updated: " .. os.date("%H:%M:%S") .. " | Pt: " .. #patients, width))

    monitor.setCursorPos(1, 4)
    monitor.write(fitText("BED NAME STATUS", width))

    monitor.setCursorPos(1, 5)
    monitor.write(string.rep("-", width))

    local y = 6

    for _, patient in ipairs(patients) do
        if y > height then
            break
        end

        local line =
            tostring(patient.bed or "") ..
            " " ..
            tostring(patient.name or "") ..
            " " ..
            tostring(patient.status or "")

        monitor.setCursorPos(1, y)
        monitor.write(fitText(line, width))

        y = y + 1
    end

    if #patients > height - 5 then
        monitor.setCursorPos(1, height)
        monitor.write(fitText("+" .. tostring(#patients - (height - 5)) .. " more...", width))
    end
end

local function drawMediumBoard(patients, width, height)
    monitor.setCursorPos(1, 1)
    monitor.write(fitText(getTitle(), width))

    monitor.setCursorPos(1, 2)
    monitor.write(fitText("Updated: " .. os.date("%H:%M:%S") .. " | Patients: " .. #patients, width))

    monitor.setCursorPos(1, 4)
    monitor.write(
        fitText("BED", 6) ..
        fitText("NAME", 14) ..
        fitText("AREA", 11) ..
        fitText("ACUITY", 9) ..
        fitText("STATUS", width - 40)
    )

    monitor.setCursorPos(1, 5)
    monitor.write(string.rep("-", width))

    local y = 6
    local rowsShown = 0

    for _, patient in ipairs(patients) do
        if y > height then
            break
        end

        monitor.setCursorPos(1, y)
        monitor.write(
            fitText(patient.bed, 6) ..
            fitText(patient.name, 14) ..
            fitText(patient.area, 11) ..
            fitText(patient.acuity, 9) ..
            fitText(patient.status, width - 40)
        )

        y = y + 1
        rowsShown = rowsShown + 1
    end

    if #patients > rowsShown then
        monitor.setCursorPos(1, height)
        monitor.write(fitText("+" .. tostring(#patients - rowsShown) .. " more patients not shown.", width))
    end
end

local function drawLargeBoard(patients, width, height)
    monitor.setCursorPos(1, 1)
    monitor.write(fitText(getTitle(), width))

    monitor.setCursorPos(1, 2)
    monitor.write(fitText(
        "Area: " .. DISPLAY_AREA ..
        " | Updated: " .. os.date("%H:%M:%S") ..
        " | Patients: " .. #patients,
        width
    ))

    monitor.setCursorPos(1, 4)
    monitor.write(
        fitText("HN", 15) ..
        fitText("BED", 7) ..
        fitText("NAME", 16) ..
        fitText("AGE", 5) ..
        fitText("AREA", 12) ..
        fitText("ACUITY", 9) ..
        fitText("STATUS", width - 64)
    )

    monitor.setCursorPos(1, 5)
    monitor.write(string.rep("-", width))

    local y = 6
    local rowsShown = 0

    for _, patient in ipairs(patients) do
        if y > height then
            break
        end

        monitor.setCursorPos(1, y)
        monitor.write(
            fitText(patient.hospitalNo, 15) ..
            fitText(patient.bed, 7) ..
            fitText(patient.name, 16) ..
            fitText(patient.age, 5) ..
            fitText(patient.area, 12) ..
            fitText(patient.acuity, 9) ..
            fitText(patient.status, width - 64)
        )

        y = y + 1
        rowsShown = rowsShown + 1
    end

    if #patients > rowsShown then
        monitor.setCursorPos(1, height)
        monitor.write(fitText("+" .. tostring(#patients - rowsShown) .. " more patients not shown.", width))
    end
end

local function drawBoard()
    local patients, err = requestBoard()

    monitor.clear()
    monitor.setCursorPos(1, 1)

    local width, height = monitor.getSize()

    if not patients then
        monitor.setCursorPos(1, 1)
        monitor.write(fitText("ED TRACKER OFFLINE", width))

        monitor.setCursorPos(1, 3)
        monitor.write(fitText(err or "Cannot contact server.", width))

        monitor.setCursorPos(1, 5)
        monitor.write(fitText("Check server, modem, range or SERVER_ID.", width))

        lastStatus = "Offline: " .. tostring(err or "unknown error")
        return
    end

    patients = filterPatientsByArea(patients, DISPLAY_AREA)

    if #patients == 0 then
        drawNoPatients(width)
        lastStatus = "Online. No patients shown."
        return
    end

    if width < 45 then
        drawSmallBoard(patients, width, height)
    elseif width < 75 then
        drawMediumBoard(patients, width, height)
    else
        drawLargeBoard(patients, width, height)
    end

    lastStatus = "Online. Displaying " .. tostring(#patients) .. " patient(s)."
end

local function selectArea()
    while true do
        clearTerm()
        print("=== Change Display Area ===")
        print("")
        print("Current area: " .. DISPLAY_AREA)
        print("")
        print("1. All ED")
        print("2. Waiting")
        print("3. RAT Bay")
        print("4. Resus")
        print("5. Majors")
        print("6. Minors")
        print("7. Paeds")
        print("8. MH")
        print("9. Discharge")
        print("10. Custom")
        print("11. Cancel")
        print("")

        write("Choose area: ")
        local choice = read()

        local areas = {
            ["1"] = "ALL",
            ["2"] = "Waiting",
            ["3"] = "RAT Bay",
            ["4"] = "Resus",
            ["5"] = "Majors",
            ["6"] = "Minors",
            ["7"] = "Paeds",
            ["8"] = "MH",
            ["9"] = "Discharge"
        }

        if areas[choice] then
            DISPLAY_AREA = areas[choice]
            drawBoard()
            return
        elseif choice == "10" then
            write("Enter custom area: ")
            local customArea = read()

            if customArea ~= "" then
                DISPLAY_AREA = customArea
                drawBoard()
                return
            end
        elseif choice == "11" then
            return
        else
            print("Invalid choice.")
            sleep(1)
        end
    end
end

local function selectTextScale()
    while true do
        clearTerm()
        print("=== Change Monitor Text Size ===")
        print("")
        print("Current text scale: " .. tostring(TEXT_SCALE))
        print("")
        print("Smaller text = more information fits")
        print("Larger text = easier to read")
        print("")
        print("1. 0.5 - default / most information")
        print("2. 1.0 - medium")
        print("3. 1.5 - large")
        print("4. 2.0 - very large")
        print("5. Custom")
        print("6. Cancel")
        print("")

        write("Choose text size: ")
        local choice = read()

        local scales = {
            ["1"] = 0.5,
            ["2"] = 1.0,
            ["3"] = 1.5,
            ["4"] = 2.0
        }

        if scales[choice] then
            TEXT_SCALE = scales[choice]
            monitor.setTextScale(TEXT_SCALE)
            drawBoard()
            return
        elseif choice == "5" then
            write("Enter scale, e.g. 0.5, 1, 1.5: ")
            local customScale = tonumber(read())

            if customScale and customScale >= 0.5 and customScale <= 5 then
                TEXT_SCALE = customScale
                monitor.setTextScale(TEXT_SCALE)
                drawBoard()
                return
            else
                print("Invalid scale.")
                sleep(1)
            end
        elseif choice == "6" then
            return
        else
            print("Invalid choice.")
            sleep(1)
        end
    end
end

local function drawComputerStatus()
    clearTerm()
    print("=== ED Display Computer ===")
    print("")
    print("Status: " .. lastStatus)
    print("Area: " .. DISPLAY_AREA)
    print("Text scale: " .. tostring(TEXT_SCALE))
    print("Server ID: " .. tostring(SERVER_ID))
    print("Modem side: " .. tostring(MODEM_SIDE))
    print("")
    print("Controls:")
    print("A = change display area")
    print("S = change text size")
    print("R = refresh now")
    print("Q = quit display")
    print("")
    print("The monitor is refreshing automatically.")
end

local function refreshLoop()
    while running do
        drawBoard()
        drawComputerStatus()

        local timer = os.startTimer(REFRESH_SECONDS)

        while running do
            local event, p1 = os.pullEvent()

            if event == "timer" and p1 == timer then
                break
            elseif event == "key" then
                if p1 == keys.a then
                    selectArea()
                    drawComputerStatus()
                elseif p1 == keys.s then
                    selectTextScale()
                    drawComputerStatus()
                elseif p1 == keys.r then
                    drawBoard()
                    drawComputerStatus()
                    os.cancelTimer(timer)
                    break
                elseif p1 == keys.q then
                    running = false
                    os.cancelTimer(timer)
                    break
                end
            end
        end
    end
end

clearTerm()
print("Starting ED display...")
print("Default area: All ED")
print("Default text scale: 0.5")
sleep(1)

refreshLoop()

monitor.clear()
clearTerm()
print("ED display stopped.")
