-- Settings
local owner = "jiriks74"
local repo = "ccTune"
local baseUrl = "https://raw.githubusercontent.com/" .. owner .. "/" .. repo .. "/refs/heads/main/"
local baseLibUrl = "https://raw.githubusercontent.com/Pyroxenium/Basalt/8dd8e63d21752f2fe621b04b9db0aeb155fedf0d/"
-- ^Settings

local installed = false
local forceUpdate = false
local currVersion

---Compares 2 version strings in the 1.2.3 format
---@param localVersion string
---@param upstreamVersion string
---@return boolean true If upstreamVersion > localVersion
local function isUpdateAvailable(localVersion, upstreamVersion)
  local localTable = {}
  for part in localVersion:gmatch("([^" .. '.' .. "]+)") do
      table.insert(localTable, part)
  end

  local upstreamTable = {}
  for part in upstreamVersion:gmatch("([^" .. '.' .. "]+)") do
      table.insert(upstreamTable, part)
  end

  for i = 1, 3, 1 do
    if localTable[i] < upstreamTable[i] then
      return true
    end
  end

  return false
end

for _, arg in ipairs(arg) do
  if arg == "-h" then
    print("[-h] help")
    print("[-f] force update (reinstall)")
    return
  elseif arg == "-f" then
    forceUpdate = true
  end
end

print("Fetching upstream version info...")
local versionResponse = http.get(baseUrl .. "version.txt")
if versionResponse == nil then error("Error fetching upstream version info!") end

if fs.exists("version.txt") then
  local vf = fs.open("version.txt", "r") -- vf as in version file
  if vf == nil then error("Error opening file `version.txt`!") end
  currVersion = vf.readLine():match("^@version%s+(.+)")
  vf.close()
  installed = true
  if isUpdateAvailable(currVersion, versionResponse.readLine():match("^@version%s+(.+)")) then
    print("A new version is available! Installing...")
  elseif forceUpdate then
    print("Reinstalling")
    installed = true
  else
    print("Up to date.")
    return
  end
else
  versionResponse.readLine()
  print("Installing...")
end

local files = {}
local libFiles = {}

while true do
  local line = versionResponse.readLine()
  if not line then break end
  if line:match("%S+") then
    table.insert(files, line)
  end
end

local libResponse = http.get(baseUrl .. "libFiles.txt")
if libResponse == nil then error("Error fetching lib info!") end

while true do
  local line = libResponse.readLine()
  if not line then break end
  if line:match("%S+") then
    table.insert(libFiles, line)
  end
end

if installed then
  print("Removing old files...")

  for _, file in ipairs(files) do
    print("  Deleting `" .. file .. "`...")
    fs.delete(file)
  end
  for _, file in ipairs(libFiles) do
    print("  Deleting `" .. file .. "`...")
    fs.delete(file)
  end
end

if not fs.isDir("lib") then
  print("Creating lib/ directory")
  fs.makeDir("lib")
  if not fs.isDir("lib/linkBuilders") then
    print("Creating lib/linkBuilders directory")
    fs.makeDir("lib/linkBuilders")
  end
  if not fs.isDir("lib/basalt") then
    print("Creating lib/basalt directory")
    fs.makeDir("lib/basalt")
    if not fs.isDir("lib/basalt/Basalt") then
      print("Creating lib/basalt/Basalt directory")
      fs.makeDir("lib/basalt/Basalt")
    end
  end
end

print("Pulling files...")

for _, file in ipairs(files) do
  print("  Downloading `" .. file .. "`...")

  local fp = fs.open(file, "w")
  if fp == nil then error("Error creating file `" .. file .. "`!") end

  local downloadResponse = http.get(baseUrl .. file)
  if downloadResponse == nil then error("Error downloading " .. baseUrl .. file .. "!") end

  fp.write(downloadResponse.readAll())
  fp.close()
end

for _, file in ipairs(libFiles) do
  print("  Downloading `" .. file .. "`...")

  local fp = fs.open(file, "w")
  if fp == nil then error("Error creating file `" .. file .. "`!") end

  local downloadResponse = http.get(baseLibUrl .. file:gsub("^lib/basalt/", ""))
  if downloadResponse == nil then error("Error downloading " .. baseLibUrl .. file:gsub("^lib/basalt/", "") .. "!") end

  fp.write(downloadResponse.readAll())
  fp.close()
end

print("Finished installing.")
print("The computer will reboot in 5 seconds...")
print()
print("Tip!")
print("Run `install` again to update!")
sleep(5)
shell.run("reboot")
