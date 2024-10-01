local ManualGenerator = {}

---Returns a download url
---This version only joins baseURl and fileName
--- @param baseUrl string The folder URL
--- @param fileName string The file to be retrieved
--- @return string url The direct download link
--- @throws If the generated download link cannot be requested
function ManualGenerator.getUrl(baseUrl, fileName)
  local url = baseUrl .. fileName
  if not http.checkURL(url) then
    error(baseUrl .. "\nThe generated url cannot be requested!")

  end

  return url
end

return ManualGenerator
