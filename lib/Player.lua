-- Settings
local volume = 1.0
local chunkSize = 4 * 1024

-- Definitions
local Player = {} -- Return object for easy importing
local dfpwm = require("cc.audio.dfpwm")
local speakers = { peripheral.find("speaker") }
local decoder = dfpwm.make_decoder()

--- Plays the chunk on all available speakers
--- @param chunk integer[] The chunk to be played
--- @return boolean success If the fist speaker was able to play the chunk
local function playChunk(chunk)
  local returnValue = false
  local callbacks = {}

  for i, speaker in pairs(speakers) do
    ---@type ccTweaked.peripheral.Speaker
    speaker = speaker -- Explicitly annotate speaker
    if i > 1 then
      table.insert(callbacks, function()
        speaker.playAudio(chunk, volume)
      end)
    else
      table.insert(callbacks, function()
        returnValue = speaker.playAudio(chunk, volume)
      end)
    end
  end

  parallel.waitForAll(table.unpack(callbacks))

  return returnValue
end

--- Play audio from a given URL
--- @param url string
--- @throws If the audio cannot be retrieved
function Player.play(url)
  if speakers == nil then error("Couldn't find any speakers!") end

  local response = http.get(url, nil, true)
  if response then
    local chunk = response.read(chunkSize)

    while chunk ~= nil do
      local buffer = decoder(chunk)

      while not playChunk(buffer) do
        os.pullEvent("speaker_audio_empty")
      end

      chunk = response.read(chunkSize)
    end

  else
    error("Couldn't get " .. url)
  end
end

return Player
