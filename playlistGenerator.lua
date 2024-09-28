local lfs = require("lfs")

local function printHelp()
  print("Generate a .cctpl playlist")
  print("Usage: lua playlistGenerator.lua new_playlist.cctpl [options]")
  print("Options:")
  print("  -b, --base-url <url>    Specify the base URL for the playlist.")
  print("  -d, --directory <path>  Specify the directory containing the dfpwm files.")
  print("  -t, --type <type>       Specify the type of the playlist (e.g., nextcloud).")
  print("  -h, --help              Show this help message.")
  print("\nExample:")
  print(
    "  lua playlistGenerator.lua -b \"https://nextcloud.example.com/s/MyMinecraftSongs\" -d \"/path/to/files\" -t \"nextcloud\"")
end

local function parseArgs()
  local args = {} -- Table to hold parsed arguments
  local i = 1     -- Index for the global arg table

  while i <= #arg do
    local key = arg[i]

    if key == "-b" or key == "--base-url" then
      i = i + 1
      if arg[i] then
        args.baseUrl = arg[i]
      else
        error("Error: Base URL not provided after " .. key)
      end
    elseif key == "-d" or key == "--directory" then
      i = i + 1
      if arg[i] then
        args.directory = arg[i]
      else
        error("Error: Directory not provided after " .. key)
      end
    elseif key == "-t" or key == "--type" then
      i = i + 1
      if arg[i] then
        args.type = arg[i]
      else
        error("Error: Type not provided after " .. key)
      end
    elseif key == "-h" or key == "--help" then
      printHelp()
      os.exit(0)
    else
      if not args.targetFile then
        if arg[i]:match("^.+(%..+)$") ~= ".cctpl" then
          print("Wrong playlist file extension: " .. arg[i]:match("^.+(%..+)$"))
          print()
          printHelp()
          os.exit(1)
        end
        args.targetFile = arg[i]
      else
        print("Error: Unknown argument " .. key)
        print()
        printHelp()
        os.exit(1)
      end
    end

    i = i + 1 -- Move to the next argument
  end

  if not args.baseUrl then
    print("BaseUrl wasn't specified!")
    print()
    printHelp()
    os.exit(1)
  elseif not args.directory then
    print("No directory was specified!")
    print()
    printHelp()
    os.exit(1)
  elseif not args.type then
    print("A playlist type wasn't specified!")
    print()
    printHelp()
    os.exit(1)
  elseif not args.targetFile then
    print("A target playlist file wasn't specified!")
    print()
    printHelp()
    os.exit(1)
  end

  return args
end

local function getFiles(directory)
  local files = {}

  -- Check if the directory exists
  local attr = lfs.attributes(directory)
  if not attr or attr.mode ~= "directory" then
    return nil, "Directory does not exist"
  end

  -- Iterate through the directory
  for file in lfs.dir(directory) do
    if file:match("%.dfpwm$") then     -- Check for .dfpwm extension
      table.insert(files, file)
    end
  end

  return files
end

local function writePlaylist(filename, type, baseUrl, files)
    local file, err = io.open(filename, "w")  -- Open file for writing
    if not file then
        return nil, "Error opening file: " .. err
    end

    -- Write the @type and @baseUrl tags
    file:write("@type " .. type .. "\n")
    file:write("@baseUrl " .. baseUrl .. "\n")

    -- Write each file in the files table
    for _, fileName in ipairs(files) do
        file:write(fileName .. "\n")
    end

    file:close()  -- Close the file
end

local function Main()
  local parsedArgs = parseArgs()
  local files = getFiles(parsedArgs.directory)
  writePlaylist(parsedArgs.targetFile, parsedArgs.type, parsedArgs.baseUrl, files)
end

Main()
