local NextcloudGenerator = {}

---Encode a string into HTML
---@param str string
---@return string str HTML encoded string
local function urlEncode(str)
  -- Convert the input string into its percent-encoded equivalent
  if str then
    str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
  end
  return str
end

--- Creates a direct download link based on a public Nextcloud folder share link
--- @param baseUrl string The folder URL
--- @param fileName string The file to be retrieved
--- @return string url The direct download link
--- @throws If the generated download link cannot be requested
function NextcloudGenerator.getUrl(baseUrl, fileName)
  assert(baseUrl ~= nil, "baseUrl cannot be nil!")
  assert(fileName ~= nil, "fileName cannot be nil!")

  local url = ""

  if string.sub(baseUrl, -1) ~= "/" then
    url = baseUrl .. "/"
  else url = baseUrl end

  url = url:gsub("/s/", "/public.php/dav/files/")  .. urlEncode(fileName)

  if not http.checkURL(url) then
    error(baseUrl .. "\nThe generated url cannot be requested!")
  end

  return url
end

return NextcloudGenerator
