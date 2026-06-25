local SERVER_ID = 1
local MODEM_SIDE = "left"
local PROTOCOL = "ed_epr"
local SECRET = "ed123"
 
local REFRESH_SECONDS = 5
local TEXT_SCALE = 0.5
local DISPLAY_AREA = "ALL"
 
local monitor = peripheral.find("monitor")
 
if not monitor then
    print("No monitor found.")
    return
end
 
local function findModemSide()
    local sides = peripheral.getNames()

    for _, side in ipairs(sides) do
        if peripheral.getType(side) == "modem" then
            return side
        end
    end

    return nil
end

local MODEM_SIDE = findModemSide()

if not MODEM_SIDE then
    print("No modem found.")
    return
end

rednet.open(MODEM_SIDE)


monitor.setTextScale(TEXT_SCALE)
 
local function clearTerm()
    term.clear()
    term.setCursorPos(1, 1)
end
 
local function pause()
    print("")
    print("Press Enter to continue...")
    read()
end
 
local function selectDisplayArea()
    while true do
        clearTerm()
        print("=== Select Display Area ===")
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
        print("")
 
        write("Choose area for display: ")
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
            return
        elseif choice == "10" then
            write("Enter custom area: ")
            local customArea = read()
 
            if customArea ~= "" then
                DISPLAY_AREA = customArea
                return
            end
        else
            print("Invalid choice.")
            sleep(1)
        end
    end
end
 
local function selectTextScale()
    while true do
        clearTerm()
        print("=== Select Monitor Text Size ===")
        print("")
        print("Smaller text = more columns fit")
        print("Larger text = easier to read")
        print("")
        print("1. 0.5 - Best for big ED board")
        print("2. 1.0 - Medium")
        print("3. 1.5 - Large")
        print("4. 2.0 - Very large")
        print("5. Custom")
        print("")
 
        write("Choose text scale: ")
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
            return
        elseif choice == "5" then
            write("Enter scale, e.g. 0.5, 1, 1.5: ")
            local customScale = tonumber(read())
 
            if customScale and customScale >= 0.5 and customScale <= 5 then
                TEXT_SCALE = customScale
                monitor.setTextScale(TEXT_SCALE)
                return
            else
                print("Invalid scale.")
                sleep(1)
            end
        else
            print("Invalid choice.")
            sleep(1)
        end
    end
end
 
local function requestBoard()
    rednet.send(SERVER_ID, {
        secret = SECRET,
        action = "get_board"
    }, PROTOCOL)
 
    local senderId, response = rednet.receive(PROTOCOL, 3)
 
    if senderId ~= SERVER_ID or type(response) ~= "table" or not response.ok then
        return nil
    end
 
    return response.patients or {}
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
 
local function pad(text, length)
    text = tostring(text or "")
 
    if #text > length then
        return string.sub(text, 1, length)
    end
 
    return text .. string.rep(" ", length - #text)
end
 
local function fitText(text, width)
    text = tostring(text or "")
 
    if #text > width then
        if width <= 3 then
            return string.sub(text, 1, width)
        end
 
        return string.sub(text, 1, width - 3) .. "..."
    end
 
    return text .. string.rep(" ", width - #text)
end
 
local function drawSmallBoard(patients, width, height)
    local title = "ED TRACKER"
 
    if DISPLAY_AREA ~= "ALL" then
        title = DISPLAY_AREA .. " TRACKER"
    end
 
    monitor.setCursorPos(1, 1)
    monitor.write(fitText(title, width))
 
    monitor.setCursorPos(1, 2)
    monitor.write(fitText("Updated: " .. os.date("%H:%M:%S"), width))
 
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
end
 
local function drawMediumBoard(patients, width, height)
    local title = "ED TRACKER"
 
    if DISPLAY_AREA ~= "ALL" then
        title = DISPLAY_AREA .. " TRACKER"
    end
 
    monitor.setCursorPos(1, 1)
    monitor.write(fitText(title, width))
 
    monitor.setCursorPos(1, 2)
    monitor.write(fitText("Updated: " .. os.date("%H:%M:%S"), width))
 
    monitor.setCursorPos(1, 4)
    monitor.write(
        fitText("BED", 5) ..
        fitText("NAME", 12) ..
        fitText("AREA", 10) ..
        fitText("STATUS", width - 27)
    )
 
    monitor.setCursorPos(1, 5)
    monitor.write(string.rep("-", width))
 
    local y = 6
 
    for _, patient in ipairs(patients) do
        if y > height then
            break
        end
 
        monitor.setCursorPos(1, y)
        monitor.write(
            fitText(patient.bed, 5) ..
            fitText(patient.name, 12) ..
            fitText(patient.area, 10) ..
            fitText(patient.status, width - 27)
        )
 
        y = y + 1
    end
end
 
local function drawLargeBoard(patients, width, height)
    local title = "BROOMFIELD ED TRACKER"
 
    if DISPLAY_AREA ~= "ALL" then
        title = "BROOMFIELD ED - " .. DISPLAY_AREA
    end
 
    monitor.setCursorPos(1, 1)
    monitor.write(fitText(title, width))
 
    monitor.setCursorPos(1, 2)
    monitor.write(fitText("Updated: " .. os.date("%H:%M:%S") .. " | Patients: " .. #patients, width))
 
    monitor.setCursorPos(1, 4)
    monitor.write(
        fitText("HN", 14) ..
        fitText("BED", 6) ..
        fitText("NAME", 14) ..
        fitText("AGE", 5) ..
        fitText("AREA", 10) ..
        fitText("ACUITY", 9) ..
        fitText("STATUS", width - 58)
    )
 
    monitor.setCursorPos(1, 5)
    monitor.write(string.rep("-", width))
 
    local y = 6
 
    for _, patient in ipairs(patients) do
        if y > height then
            break
        end
 
        monitor.setCursorPos(1, y)
        monitor.write(
            fitText(patient.hospitalNo, 14) ..
            fitText(patient.bed, 6) ..
            fitText(patient.name, 14) ..
            fitText(patient.age, 5) ..
            fitText(patient.area, 10) ..
            fitText(patient.acuity, 9) ..
            fitText(patient.status, width - 58)
        )
 
        y = y + 1
    end
end
 
local function drawBoard(patients)
    monitor.clear()
    monitor.setCursorPos(1, 1)
 
    local width, height = monitor.getSize()
 
    patients = filterPatientsByArea(patients, DISPLAY_AREA)
 
    if #patients == 0 then
        local title = "No current ED patients"
 
        if DISPLAY_AREA ~= "ALL" then
            title = "No current patients in " .. DISPLAY_AREA
        end
 
        monitor.setCursorPos(1, 1)
        monitor.write(fitText("ED TRACKER", width))
 
        monitor.setCursorPos(1, 3)
        monitor.write(fitText(title, width))
 
        monitor.setCursorPos(1, 5)
        monitor.write(fitText("Updated: " .. os.date("%H:%M:%S"), width))
 
        return
    end
 
    if width < 45 then
        drawSmallBoard(patients, width, height)
    elseif width < 75 then
        drawMediumBoard(patients, width, height)
    else
        drawLargeBoard(patients, width, height)
    end
end
 
local function drawOffline()
    monitor.clear()
    local width, height = monitor.getSize()
 
    monitor.setCursorPos(1, 1)
    monitor.write(fitText("ED TRACKER OFFLINE", width))
 
    monitor.setCursorPos(1, 3)
    monitor.write(fitText("Cannot contact server.", width))
 
    monitor.setCursorPos(1, 5)
    monitor.write(fitText("Check server/modem/range.", width))
end
 
selectDisplayArea()
selectTextScale()
 
clearTerm()
print("ED display running.")
print("")
print("Area: " .. DISPLAY_AREA)
print("Text scale: " .. tostring(TEXT_SCALE))
print("Server ID: " .. tostring(SERVER_ID))
print("")
print("Press Ctrl+T to stop.")
 
while true do
    local patients = requestBoard()
 
    if patients then
        drawBoard(patients)
    else
        drawOffline()
    end
 
    sleep(REFRESH_SECONDS)
end
