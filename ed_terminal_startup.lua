local PROGRAM_URL = "https://raw.githubusercontent.com/lechrisved/mc-ed-tracker/refs/heads/main/ed_terminal.lua"
local PROGRAM_NAME = "ed_terminal"

local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

local function runProgram()
    if fs.exists(PROGRAM_NAME) then
        shell.run(PROGRAM_NAME)
    else
        print("No local copy found.")
        print("Cannot start ED terminal.")
    end
end

clear()
print("ED Terminal Auto-Updater")
print("")
print("Downloading latest version from GitHub...")
print("")

if fs.exists(PROGRAM_NAME) then
    fs.delete(PROGRAM_NAME)
end

shell.run("wget", PROGRAM_URL, PROGRAM_NAME)

if fs.exists(PROGRAM_NAME) then
    print("")
    print("Update complete.")
    sleep(1)
    runProgram()
else
    print("")
    print("Update failed.")
    print("Trying to run existing local copy...")

    sleep(2)
    runProgram()
end
