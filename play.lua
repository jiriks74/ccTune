local player = require("lib.Player")
local basalt = require("lib.basalt")
local mainFrame
local playlist
local exitButton
local upButton
local downButton
local playlistColor

local darkMode = false

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
  print("  -d, --dark-mode     Turn on dark mode.")
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
    elseif arg == "-d" or arg == "--dark-mode" then
      darkMode = true
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
    playlist:addItem(song:gsub("%.dfpwm$", ""), playlistColor)
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
        local item = playlist:getItem(playlist:getItemIndex())
        songFinished = false
        selectSong(item)
      end
    end
    if exit then
      playThread.stop()
      return
    end
    sleep(1)
  end
end

local function setColors()
  if darkMode then
    playlistColor = colors.black
    mainFrame:setBackground(colors.black)
    playlist:setBackground(colors.black)
    playlist:setForeground(colors.white)
    playlist:setSelectionColor(colors.green)
    exitButton:setBackground(colors.green)
    exitButton:setForeground(colors.white)
  else
    playlistColor = colors.lightBlue
    mainFrame:setBackground(colors.blue)
    playlist:setBackground(colors.lightBlue)
    playlist:setSelectionColor(colors.orange)
    exitButton:setBackground(colors.orange)
    exitButton:setForeground(colors.black)
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

  mainFrame = basalt.createFrame()
  if not mainFrame then error("Error creating main frame!") end
  mainFrame:setBackground(colors.blue)

  playlist = mainFrame:addList()
  -- playlist:setSelectionColor(colors.green)
  playlist:setBackground(colors.lightBlue)
  playlist:setSelectionColor(colors.orange)
  playlist:onSelect(function(_, _, item)
    selectSong(item)
  end)
  exitButton = mainFrame:addButton()
  exitButton:setText("Quit")
  exitButton:setBackground(colors.orange)
  exitButton:setForeground(colors.white)

  upButton = mainFrame:addButton()
  upButton:setWidth(5)
  upButton:setText("^")

  downButton = mainFrame:addButton()
  downButton:setWidth(5)
  downButton:setText("v")

  local termW, termH = term.getSize()

  playlist:setSize(termW, termH - (exitButton:getHeight() + 2))
  -- exitButton:setPosition(termW / 2 - exitButton:getWidth() / 2, termH - exitButton:getHeight())

  exitButton:setPosition(termW - exitButton:getWidth() - 1, termH - exitButton:getHeight())
  upButton:setPosition(2, termH - upButton:getHeight())
  downButton:setPosition(upButton:getPosition() + upButton:getWidth() + 1, termH - downButton:getHeight())

  setColors()

  refreshPlaylist()
  playlist:setOffset(playlist:getItemIndex() - 2)
  local item = playlist:getItem(1)
  playThread = mainFrame:addThread()
  local watchThread = mainFrame:addThread()
  selectSong(item)
  watchThread:start(watchdog)

  exitButton:onClick(function(_, event, button, _, _)
    if (event == "mouse_click") and (button == 1) then
      exit = true
      while watchThread:getStatus() == "running" do
      end
      basalt.stopUpdate()
    end
  end)

  upButton:onClick(function(_, event, button, _, _)
    if (event == "mouse_click") and (button == 1) then
      if playlist:getOffset() > -1 then
        playlist:setOffset(playlist:getOffset() - playlist:getHeight() / 2)
      end
    end
  end)

  downButton:onClick(function(_, event, button, _, _)
    if (event == "mouse_click") and (button == 1) then
      if playlist:getOffset() < playlist:getItemCount() - playlist:getHeight() + 1 then
        playlist:setOffset(playlist:getOffset() + playlist:getHeight() / 2)
      end
    end
  end)

  basalt.autoUpdate()
end

Main()
