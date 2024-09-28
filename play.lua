local player = require("lib.Player")

---@alias playlistTypes
---| "Nextcloud"
local playlistTypes = {
  Nextcloud = true,
}
local function isPlaylistTypeSupported(playlistType)
  return playlistTypes[playlistType] or false
end

---Shuffles a given table
---@param t table
---@return table t
local function shuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]  -- Swap
    end
    return t
end

--Prints out help information
local function printHelp()
  print("Usage: play <playlist.cctpl> [options]")
  print("Options:")
  print("  -s, --shuffle       Shuffle the playlist before playing.")
  print("Description:")
  print("  The play command takes a .cctpl file as an argument, which is a ccTunes playlist.")
  print("  Use the -s or --shuffle option to play the playlist in a random order.")
  print("Example:")
  print("  play my_playlist.cctpl -s")
end

---@return string playlist Path to a cctpl playlist
---@return boolean shuffle Whether to shuffle the playlist
local function parseArgs()
  local filename = nil
  local shuffle = false

  -- Iterate through the provided arguments
  for _, arg in ipairs(arg) do
    if arg == "-s" then
      shuffle = true
    elseif arg == "-h" or arg = "--help" then
      printHelp()
      return "-1", false
    elseif arg:match("%.cctpl$") then
      filename = arg
    end
  end

  -- Check if a valid filename was provided
  if not filename then
    error("Error: No valid .cctpl playlist file provided.")
  end

  return filename, shuffle
end

---Parses a cctpl playlist
---@param file string
---@return playlistTypes playlistType
---@return string baseUrl
---@return table files
local function parsePlaylist(file)
  if file:match("^.+(%..+)$") ~= ".cctpl" then
    error("Unknown file extension `" .. file:match("^.+(%..+)$") .. "`!\nExpected `.cctpl`")
  end

  local playlist = fs.open(file, "r")
  if playlist == nil then error("Couldn't open file `" .. file .. "`!") end

  local playlistType = playlist.readLine():match("^@type%s+(%S+)")
  local baseUrl = playlist.readLine():match("^@baseUrl%s+(.+)")

  if playlistType == "" or playlistType == nil then error("Wrong playlist format!") end
  if not isPlaylistTypeSupported(playlistType) then error("Playlist type `" .. playlistType .. "` isn't supported!") end

  local files = {}

  while true do
    local line = playlist.readLine()
    if not line then break end
    if line:match("%S+") then
      table.insert(files, line)
    end
  end

  return playlistType, baseUrl, files
end

function Main()
  local filename, shuffle = parseArgs()

  local type, baseUrl, files = parsePlaylist(filename)
  if type == "-1" then return end

  if shuffle then shuffleTable(files) end

  local linkBuilder = require("lib.linkBuilders." .. type)

  for _, file in ipairs(files) do
    local url = linkBuilder.getUrl(baseUrl, file)
    player.play(url)
  end
end

Main()
