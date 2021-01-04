kpse.set_program_name "luatex"
local lustache = require "lustache.lustache"
local sort = require "sort"


local citace = arg[1]
local soubor = arg[2]



local function load_tpl(file)
  local f = io.open("tpl/"..file, "r")
  local c = f:read("*all")
  f:close()
  return c
end


local function save_file(filename, content)
  local f = io.open(filename, "w")
  f:write(content)
  f:close()
end

local function save_records(records)
  local t = {}
  for k, v in ipairs(records) do
    t[#t+1] = string.format("%i\t%s", k, v)
  end
  return table.concat(t, "\n")
end

local function table_reverse(r)
  local t = {}
  for i= #r, 1, -1 do
    t[#t+1] = r[i]
  end
  return t
end

local function make_tables(records)
  local abece = {}
  local nasl = {}
  local index = {}
  for k, v in ipairs(records) do
    local nazev = v:match("<i>(.-)</i>")
    index[#index+1] = {nazev=nazev, number = k}
    local citace = v:gsub("(<i>.-</i>)",'<a href="handi/'..k..'/index.html">%1</a>')
    abece[#abece+1] = citace
    nasl[#nasl+1] = {citace = citace, number = k }
    print(nazev, citace)
  end
  print "Sort abece"
  table.sort(abece, function(a,b) 
    local a = a:gsub("<.->", "")
    local b = b:gsub("<.->", "")
    return sort.compare(a,b)
  end)
  print "sort index"
  
  table.sort(index, function(a,b) return sort.compare(a.nazev, b.nazev) end)
  return abece, table_reverse(nasl), index
end

local function load_tsv(filename)
	local t = {}
	local i = 0
	for line in io.lines(filename) do
		local number, citace = line:match("([0-9]+)%s+(.+)")
		t[tonumber(number)] = citace
		i = i + 1
	end
	return t,i
end

local function save_with_template(filename, template, vars)
  print("Save page ".. filename)
  local tpl = load_tpl(template)
  local content = lustache:render(tpl, vars)
  save_file(filename, content)
end

local records, newno = load_tsv "publikace.tsv"

-- neuploadovat soubory, pokud nepřidáváme soubor
-- jenom aktualizujeme soubory se seznamem citací.
-- užitečné pokud změníme šablony.
if citace and soubor and citace~="" and soubor~="" then
  table.insert(records, citace)
  save_file("publikace.tsv",save_records(records))

  newno = newno + 1
  print("Building dir ".. newno)
  lfs.mkdir(newno)
  os.execute("cp ".. soubor .." ".. newno)

  local indexpar = {citace = citace, zip = soubor}
  local index_tpl = load_tpl("index.html")
  local index = lustache:render(index_tpl, indexpar)

  save_file(newno.."/index.html",index) 
  os.execute("cp -r " .. newno .. " ../pedf-web-navrh/backup/handi/")
  -- os.execute("scp -r ".. newno.." knihovna-new:/home/hoftich/nginx/html/handi/")
end

local abece, nasl, handindex = make_tables(records)

local date = os.date("%d.%m. %Y")

save_with_template("handiscn_b.htm", "handiscn_b.htm", {datum = date, records = nasl})
save_with_template("handiscn.htm","handiscn.htm", {datum=date, records = abece})
save_with_template("index.html", "hanindex.html", {records = handindex})
