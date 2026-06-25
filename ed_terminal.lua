local SERVER_ID = 1
local PROTOCOL = "ed_epr"
local SECRET = "ed123"
local CURRENT_AREA = "ALL"

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
 
local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end
 
local function pause()
    print("")
    print("Press Enter to continue...")
    read()
end
 
local function selectArea()
    while true do
        clear()
        print("=== Select Terminal Area ===")
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
            CURRENT_AREA = areas[choice]
            return
        elseif choice == "10" then
            write("Enter custom area: ")
            local customArea = read()
 
            if customArea ~= "" then
                CURRENT_AREA = customArea
                return
            end
        else
            print("Invalid choice.")
            sleep(1)
        end
    end
end
 
local function sendRequest(request)
    request.secret = SECRET
 
    rednet.send(SERVER_ID, request, PROTOCOL)
 
    local senderId, response = rednet.receive(PROTOCOL, 5)
 
    if senderId ~= SERVER_ID then
        return nil, "No response from server"
    end
 
    if type(response) ~= "table" then
        return nil, "Invalid response from server"
    end
 
    return response, nil
end
 
local function getBoard()
    local response, err = sendRequest({
        action = "get_board"
    })
 
    if not response then
        return nil, err
    end
 
    if not response.ok then
        return nil, response.error or "Server returned an error"
    end
 
    return response.patients or {}, nil
end
 
local function pad(text, length)
    text = tostring(text or "")
 
    if #text > length then
        return string.sub(text, 1, length)
    end
 
    return text .. string.rep(" ", length - #text)
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
 
local function showPatients(areaFilter)
    clear()
 
    areaFilter = areaFilter or CURRENT_AREA
 
    if areaFilter == "ALL" then
        print("=== Current ED Patients ===")
    else
        print("=== " .. areaFilter .. " Patients ===")
    end
 
    print("")
 
    local patients, err = getBoard()
 
    if not patients then
        print("Could not load patient board.")
        print(err or "Unknown error")
        pause()
        return nil
    end
 
    patients = filterPatientsByArea(patients, areaFilter)
 
    if #patients == 0 then
        if areaFilter == "ALL" then
            print("No current ED patients.")
        else
            print("No current patients in " .. areaFilter .. ".")
        end
 
        pause()
        return patients
    end
 
    print(
        pad("No", 4) ..
        pad("HN", 16) ..
        pad("Bed", 7) ..
        pad("Name", 14) ..
        pad("Area", 10) ..
        pad("Acuity", 9) ..
        pad("Status", 18)
    )
 
    print(string.rep("-", 78))
 
    for i, patient in ipairs(patients) do
        print(
            pad(i, 4) ..
            pad(patient.hospitalNo, 16) ..
            pad(patient.bed, 7) ..
            pad(patient.name, 14) ..
            pad(patient.area, 10) ..
            pad(patient.acuity, 9) ..
            pad(patient.status, 18)
        )
    end
 
    return patients
end
 
local function choosePatient(areaFilter)
    local patients = showPatients(areaFilter or CURRENT_AREA)
 
    if not patients or #patients == 0 then
        return nil
    end
 
    print("")
    write("Choose patient number: ")
    local choice = tonumber(read())
 
    if not choice or not patients[choice] then
        print("Invalid choice.")
        pause()
        return nil
    end
 
    return patients[choice]
end
 
local function addPatient()
    clear()
    print("=== Add ED Patient ===")
    print("")
 
    write("Name: ")
    local name = read()
 
    write("Age: ")
    local age = read()
 
    write("Presenting complaint: ")
    local complaint = read()
 
    print("")
    print("Suggested areas:")
    print("1. Waiting")
    print("2. RAT Bay")
    print("3. Resus")
    print("4. Majors")
    print("5. Minors")
    print("6. Paeds")
    print("7. MH")
    print("8. Custom")
    print("")
 
    write("Choose area: ")
    local areaChoice = read()
 
    local areas = {
        ["1"] = "Waiting",
        ["2"] = "RAT Bay",
        ["3"] = "Resus",
        ["4"] = "Majors",
        ["5"] = "Minors",
        ["6"] = "Paeds",
        ["7"] = "MH"
    }
 
    local area = areas[areaChoice]
 
    if areaChoice == "8" then
        write("Enter custom area: ")
        area = read()
    end
 
    if not area or area == "" then
        area = "Waiting"
    end
 
    write("Bed number: ")
    local bed = read()
 
    print("")
    print("Suggested acuity:")
    print("1. Resus")
    print("2. High")
    print("3. Medium")
    print("4. Low")
    print("5. Minor")
    print("6. Custom")
    print("")
 
    write("Choose acuity: ")
    local acuityChoice = read()
 
    local acuities = {
        ["1"] = "Resus",
        ["2"] = "High",
        ["3"] = "Medium",
        ["4"] = "Low",
        ["5"] = "Minor"
    }
 
    local acuity = acuities[acuityChoice]
 
    if acuityChoice == "6" then
        write("Enter custom acuity: ")
        acuity = read()
    end
 
    if not acuity or acuity == "" then
        acuity = "Medium"
    end
 
    print("")
    print("Suggested statuses:")
    print("1. Awaiting triage")
    print("2. Triaged")
    print("3. Awaiting nurse")
    print("4. Awaiting doctor")
    print("5. Awaiting review")
    print("6. Custom")
    print("")
 
    write("Choose status: ")
    local statusChoice = read()
 
    local statuses = {
        ["1"] = "Awaiting triage",
        ["2"] = "Triaged",
        ["3"] = "Awaiting nurse",
        ["4"] = "Awaiting doctor",
        ["5"] = "Awaiting review"
    }
 
    local status = statuses[statusChoice]
 
    if statusChoice == "6" then
        write("Enter custom status: ")
        status = read()
    end
 
    if not status or status == "" then
        status = "Awaiting triage"
    end
 
    write("Assigned nurse, optional: ")
    local nurse = read()
 
    write("Assigned doctor, optional: ")
    local doctor = read()
 
    write("Notes, optional: ")
    local notes = read()
 
    local response, err = sendRequest({
        action = "add_patient",
        patient = {
            name = name,
            age = age,
            complaint = complaint,
            area = area,
            bed = bed,
            acuity = acuity,
            status = status,
            nurse = nurse,
            doctor = doctor,
            notes = notes
        }
    })
 
    print("")
 
    if response and response.ok then
        print("Patient added.")
        print("Hospital No: " .. tostring(response.patient.hospitalNo or ""))
    else
        print("Failed to add patient.")
 
        if response and response.error then
            print(response.error)
        else
            print(err or "Unknown error")
        end
    end
 
    pause()
end
 
local function viewPatientDetails()
    local patient = choosePatient()
 
    if not patient then
        return
    end
 
    clear()
    print("=== Patient Details ===")
    print("")
    print("Hospital No: " .. tostring(patient.hospitalNo or ""))
    print("Name: " .. tostring(patient.name or ""))
    print("Age: " .. tostring(patient.age or ""))
    print("Complaint: " .. tostring(patient.complaint or ""))
    print("Area: " .. tostring(patient.area or ""))
    print("Bed: " .. tostring(patient.bed or ""))
    print("Acuity: " .. tostring(patient.acuity or ""))
    print("Status: " .. tostring(patient.status or ""))
    print("Nurse: " .. tostring(patient.nurse or ""))
    print("Doctor: " .. tostring(patient.doctor or ""))
    print("Notes: " .. tostring(patient.notes or ""))
    print("Created: " .. tostring(patient.createdAt or ""))
    print("Updated: " .. tostring(patient.updatedAt or ""))
 
    pause()
end
 
local function updateStatus()
    local patient = choosePatient()
 
    if not patient then
        return
    end
 
    clear()
    print("=== Update Patient Status ===")
    print("")
    print("Patient: " .. tostring(patient.name or ""))
    print("Current status: " .. tostring(patient.status or ""))
    print("")
 
    print("Suggested statuses:")
    print("1. Awaiting triage")
    print("2. Triaged")
    print("3. Awaiting nurse")
    print("4. Awaiting doctor")
    print("5. Awaiting bloods")
    print("6. Awaiting X-ray")
    print("7. Awaiting CT")
    print("8. Awaiting review")
    print("9. Awaiting bed")
    print("10. Admitted")
    print("11. Discharged")
    print("12. Custom")
    print("")
 
    write("Choose option: ")
    local choice = read()
 
    local statuses = {
        ["1"] = "Awaiting triage",
        ["2"] = "Triaged",
        ["3"] = "Awaiting nurse",
        ["4"] = "Awaiting doctor",
        ["5"] = "Awaiting bloods",
        ["6"] = "Awaiting X-ray",
        ["7"] = "Awaiting CT",
        ["8"] = "Awaiting review",
        ["9"] = "Awaiting bed",
        ["10"] = "Admitted",
        ["11"] = "Discharged"
    }
 
    local newStatus = statuses[choice]
 
    if choice == "12" then
        write("Enter custom status: ")
        newStatus = read()
    end
 
    if not newStatus or newStatus == "" then
        print("No status entered.")
        pause()
        return
    end
 
    local response, err = sendRequest({
        action = "update_patient",
        hospitalNo = patient.hospitalNo,
        updates = {
            status = newStatus
        }
    })
 
    print("")
 
    if response and response.ok then
        print("Status updated.")
    else
        print("Failed to update status.")
 
        if response and response.error then
            print(response.error)
        else
            print(err or "Unknown error")
        end
    end
 
    pause()
end
 
local function movePatient()
    local patient = choosePatient()
 
    if not patient then
        return
    end
 
    clear()
    print("=== Move Patient ===")
    print("")
    print("Patient: " .. tostring(patient.name or ""))
    print("Current area: " .. tostring(patient.area or ""))
    print("Current bed: " .. tostring(patient.bed or ""))
    print("")
 
    print("Suggested areas:")
    print("1. Waiting")
    print("2. RAT Bay")
    print("3. Resus")
    print("4. Majors")
    print("5. Minors")
    print("6. Paeds")
    print("7. MH")
    print("8. Discharge")
    print("9. Custom")
    print("")
 
    write("Choose area: ")
    local choice = read()
 
    local areas = {
        ["1"] = "Waiting",
        ["2"] = "RAT Bay",
        ["3"] = "Resus",
        ["4"] = "Majors",
        ["5"] = "Minors",
        ["6"] = "Paeds",
        ["7"] = "MH",
        ["8"] = "Discharge"
    }
 
    local newArea = areas[choice]
 
    if choice == "9" then
        write("Enter custom area: ")
        newArea = read()
    end
 
    if not newArea or newArea == "" then
        print("No area entered.")
        pause()
        return
    end
 
    write("New bed number: ")
    local newBed = read()
 
    local response, err = sendRequest({
        action = "update_patient",
        hospitalNo = patient.hospitalNo,
        updates = {
            area = newArea,
            bed = newBed
        }
    })
 
    print("")
 
    if response and response.ok then
        print("Patient moved.")
    else
        print("Failed to move patient.")
 
        if response and response.error then
            print(response.error)
        else
            print(err or "Unknown error")
        end
    end
 
    pause()
end
 
local function assignStaff()
    local patient = choosePatient()
 
    if not patient then
        return
    end
 
    clear()
    print("=== Assign Staff ===")
    print("")
    print("Patient: " .. tostring(patient.name or ""))
    print("Current nurse: " .. tostring(patient.nurse or ""))
    print("Current doctor: " .. tostring(patient.doctor or ""))
    print("")
 
    write("New nurse, leave blank to keep current: ")
    local nurse = read()
 
    write("New doctor, leave blank to keep current: ")
    local doctor = read()
 
    local updates = {}
 
    if nurse ~= "" then
        updates.nurse = nurse
    end
 
    if doctor ~= "" then
        updates.doctor = doctor
    end
 
    if not next(updates) then
        print("No changes made.")
        pause()
        return
    end
 
    local response, err = sendRequest({
        action = "update_patient",
        hospitalNo = patient.hospitalNo,
        updates = updates
    })
 
    print("")
 
    if response and response.ok then
        print("Staff assignment updated.")
    else
        print("Failed to update staff.")
 
        if response and response.error then
            print(response.error)
        else
            print(err or "Unknown error")
        end
    end
 
    pause()
end
 
local function addNotes()
    local patient = choosePatient()
 
    if not patient then
        return
    end
 
    clear()
    print("=== Add / Update Notes ===")
    print("")
    print("Patient: " .. tostring(patient.name or ""))
    print("Current notes:")
    print(tostring(patient.notes or ""))
    print("")
 
    print("Enter new notes.")
    write("> ")
    local notes = read()
 
    local response, err = sendRequest({
        action = "update_patient",
        hospitalNo = patient.hospitalNo,
        updates = {
            notes = notes
        }
    })
 
    print("")
 
    if response and response.ok then
        print("Notes updated.")
    else
        print("Failed to update notes.")
 
        if response and response.error then
            print(response.error)
        else
            print(err or "Unknown error")
        end
    end
 
    pause()
end
 
local function dischargePatient()
    local patient = choosePatient()
 
    if not patient then
        return
    end
 
    clear()
    print("=== Discharge / Remove Patient ===")
    print("")
    print("Patient: " .. tostring(patient.name or ""))
    print("Hospital No: " .. tostring(patient.hospitalNo or ""))
    print("Bed: " .. tostring(patient.bed or ""))
    print("")
    write("Type YES to discharge/remove this patient: ")
    local confirm = read()
 
    if confirm ~= "YES" then
        print("Cancelled.")
        pause()
        return
    end
 
    local response, err = sendRequest({
        action = "discharge_patient",
        hospitalNo = patient.hospitalNo
    })
 
    print("")
 
    if response and response.ok then
        print("Patient discharged/removed.")
    else
        print("Failed to remove patient.")
 
        if response and response.error then
            print(response.error)
        else
            print(err or "Unknown error")
        end
    end
 
    pause()
end
 
selectArea()
 
while true do
    clear()
 
    if CURRENT_AREA == "ALL" then
        print("=== ED Clinical Terminal: All ED ===")
    else
        print("=== ED Clinical Terminal: " .. CURRENT_AREA .. " ===")
    end
 
    print("")
    print("1. View patients in selected area")
    print("2. View all ED patients")
    print("3. Change selected area")
    print("4. Add patient")
    print("5. View patient details")
    print("6. Update patient status")
    print("7. Move patient area/bed")
    print("8. Assign nurse/doctor")
    print("9. Add/update notes")
    print("10. Discharge/remove patient")
    print("11. Exit")
    print("")
 
    write("Choose option: ")
    local choice = read()
 
    if choice == "1" then
        showPatients(CURRENT_AREA)
        pause()
    elseif choice == "2" then
        showPatients("ALL")
        pause()
    elseif choice == "3" then
        selectArea()
    elseif choice == "4" then
        addPatient()
    elseif choice == "5" then
        viewPatientDetails()
    elseif choice == "6" then
        updateStatus()
    elseif choice == "7" then
        movePatient()
    elseif choice == "8" then
        assignStaff()
    elseif choice == "9" then
        addNotes()
    elseif choice == "10" then
        dischargePatient()
    elseif choice == "11" then
        clear()
        return
    else
        print("Invalid option.")
        sleep(1)
    end
end
