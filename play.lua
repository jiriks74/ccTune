local player = require("lib.Player")
local basalt = require("lib.basalt")
local playlist

local currentSongUrl
local playThread
local songFinished = false

local exit = false

local type, baseUrl, files, shuffle

local selectSong
local playSong

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
    t[i], t[j] = t[j], t[i] -- Swap
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
  local shuffleArg = false

  -- Iterate through the provided arguments
  for _, arg in ipairs(arg) do
    if arg == "-s" then
      shuffleArg = true
    elseif arg == "-h" or arg == "--help" then
      printHelp()
      return "-1", false
    elseif arg:match("%.cctpl$") then
      filename = arg
    else
      error("No playlist file was provided!")
    end
  end

  -- Check if a valid filename was provided
  if not filename then
    error("Error: No valid .cctpl file was provided.")
  end

  return filename, shuffleArg
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

  local playlistFile = fs.open(file, "r")
  if playlistFile == nil then error("Couldn't open file `" .. file .. "`!") end

  local playlistType = playlistFile.readLine():match("^@type%s+(%S+)")
  local playlistBaseUrl = playlistFile.readLine():match("^@baseUrl%s+(.+)")

  if playlistType == "" or playlistType == nil then error("Wrong playlist format!") end
  if not isPlaylistTypeSupported(playlistType) then error("Playlist type `" .. playlistType .. "` isn't supported!") end

  local parsed_files = {}

  while true do
    local line = playlistFile.readLine()
    if not line then break end
    if line:match("%S+") then
      table.insert(parsed_files, line)
    end
  end

  return playlistType, playlistBaseUrl, parsed_files
end

local function refreshPlaylist()
  playlist:clear()
  if shuffle then shuffleTable(files) end
  for _, song in ipairs(files) do
    playlist:addItem(song:gsub("%.dfpwm$", ""))
  end
  playlist:setOffset(playlist:getItemIndex() - 2)
end

function playSong()
  player.play(currentSongUrl)
  songFinished = true
end

local function watchdog()
  while true do
    if playThread:getStatus() == "dead" and songFinished then
      if playlist:getItemIndex() ~= playlist:getItemCount() then
        playlist:selectItem(playlist:getItemIndex() + 1)
        local item = playlist:getItem(playlist:getItemIndex())
        songFinished = false
        selectSong(item)
      else
        refreshPlaylist()
      end
    end
    if exit then
      playThread.stop()
      return
    end
    sleep(1)
  end
end

function selectSong(item)
  playThread:stop()
  songFinished = false
  local linkBuilder = require("lib.linkBuilders." .. type)
  currentSongUrl = linkBuilder.getUrl(baseUrl, item.text .. ".dfpwm")
  playlist:setOffset(playlist:getItemIndex() - 2)
  playThread:start(playSong)
  -- player.play(url)
  -- if playlist:getItemIndex() == playlist:getItemCount() then
  --   refreshPlaylist()
  -- end
end

function Main()
  local filename
  filename, shuffle = parseArgs()
  if filename == "-1" then return end

  type, baseUrl, files = parsePlaylist(filename)
  if type == "-1" then return end

  local mainFrame = basalt.createFrame()

  if not mainFrame then error("Error creating main frame!") end

  playlist = mainFrame:addList()
  playlist:setSelectionColor(colors.green)
  playlist:onSelect(function(_, _, item)
    selectSong(item)
  end)
  local exitButton = mainFrame:addButton()
  exitButton:setText("Quit")

  local termW, termH = term.getSize()

  playlist:setSize(termW, termH - (exitButton:getHeight() + 2))
  exitButton:setPosition(termW / 2 - exitButton:getWidth() / 2, termH - exitButton:getHeight())

  refreshPlaylist()
  playlist:setOffset(playlist:getItemIndex() - 2)
  local item = playlist:getItem(1)
  playThread = mainFrame:addThread()
  local watchThread = mainFrame:addThread()
  selectSong(item)
  watchThread:start(watchdog)

  exitButton:onClick(function(self, event, button, _, _)
    if (event == "mouse_click") and (button == 1) then
      exit = true
      while watchThread:getStatus() == "running" do
      end
      basalt.stopUpdate()
    end
  end)

  basalt.autoUpdate()
end

Main()
