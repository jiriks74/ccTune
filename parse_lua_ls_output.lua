local json = require("json")

local function parse_lua_ls_output(file_path)
  local output_file = io.open(file_path, "r")
  if not output_file then
    error("Failed to open " .. file_path)
  end

  local output_data = output_file:read("*a")
  output_file:close()

  local parsed_data = json.decode(output_data)
  if not parsed_data then
    error("Failed to parse JSON data")
  end

  local has_issues = false

  for _, diagnostic in ipairs(parsed_data) do
    print(string.format("File: %s", diagnostic.uri))
    for _, issue in ipairs(diagnostic.diagnostics) do
      print(string.format("  Line: %d, Column: %d", issue.range.start.line, issue.range.start.character))
      print(string.format("  Message: %s", issue.message))
      print()
      has_issues = true
    end
  end

  if has_issues then
    os.exit(1)
  else
    os.exit(0)
  end
end

local file_path = arg[1]
if not file_path then
  error("No file path provided")
end

parse_lua_ls_output(file_path)
