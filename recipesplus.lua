local USER_DIR = "/disk2/usr/etc/"

local i = {}

local run = true
local c = function(t) print("[RBM] "..t) end

local function getFile(dir)
	if not fs.exists(dir) then printError("file doesn't exist: "..dir) error("") end
	local f = fs.open(dir, "r")
	if not f then printError("failed to read file '"..dir.."'") error("") end
	local a = f.readAll() f.close() return a
end

local function install(a)
	a = a or {}
	if not a.names or not a.recipes then return printError("invalid pack") end
	if not a.recipes.name or not a.recipes.version then return printError("invalid pack: name/version") end
	if fs.exists(USER_DIR.."/names/"..a.recipes.name:lower()..".db") or fs.exists(USER_DIR.."/recipes/"..a.recipes.name:lower()..".db") then return printError("pack already exists") end
	local f = fs.open(USER_DIR.."/names/"..a.recipes.name:lower():gsub(" ","")..".db", "w") f.write(textutils.serialize(a.names)) f.close()
	local f = fs.open(USER_DIR.."/recipes/"..a.recipes.name:lower():gsub(" ","")..".db", "w") f.write(textutils.serialize(a.recipes)) f.close()
	c("Installed '"..a.recipes.name.."'!")
end

local cmd = {
	["get"] = function()
		if not i[2] then return printError("[RBP] usage: get <raw pack url>") end
		c("Getting pack...")
		if not http then return printError("[RBP] http is disabled") end
		local h = http.get(i[2])
		if not h then return printError("link failed") end
		local a = textutils.unserialize(h.readAll()) or {} h.close()
		install(a)
	end,
	["grab"] = function()
		if not i[2] then return printError("[RBP] usage: grab <pack name>") end
		i[2] = i[2]:lower():gsub(" ","")
		if not http then return printError("[RBP] http is disabled") end
		local h = http.get("https://raw.githubusercontent.com/JustDoesGames/RecipesPlus/main/packs/"..i[2]..".lua")
		if not h then return printError("[RBP] unable to find '"..i[2].."'.") end
		local a = textutils.unserialize(h.readAll()) or {} h.close()
		install(a)
	end,
	["create"] = function()
		if not i[2] then return printError("[RBP] usage: create <name>") end
		c("Creating pack...")
		local tbl = {}
		tbl.names = textutils.unserialize(getFile(USER_DIR.."/names/"..i[2]..".db"))
		tbl.recipes = textutils.unserialize(getFile(USER_DIR.."/recipes/"..i[2]..".db", "r"))
		local f = fs.open("rbp/packs/"..i[2].."/"..i[2]..".lua", "w") f.write(textutils.serialize(tbl)) f.close()
		c("Created pack.")
	end,
	["autocreate"] = function()
		if not i[2] then return printError("[RBM] usage: autocreate <modfilter>") end
		local tbl = {}
		c("Exporting names...")
		data = getFile("/usr/config/items.db")
		local a, b, d = {}, "", 0
		for w in string.gmatch(data, '%b""', "") do
			if b == "" then
				b = string.gsub(w,'"','')
			else
				if string.find(b, i[2]) ~= nil then
					a[b] = string.gsub(w,'"','') d=d+1
				end
				b = ""
			end
		end
		c("Exported names ("..d..")")
		tbl.names = a
		
		c("Exporting recipes...")
		data = getFile("/usr/config/recipes.db")
		data_o = textutils.unserialize(data)
		local nametable = {}
		data = string.gsub(data, '%[ "', '*')
		data = string.gsub(data, '" %]', '*')
		a = 0
		for w in string.gmatch(data, '%b**', "") do
			w = string.gsub(w, "*","")
			if string.find(w, i[2]) == nil then
				data_o[w] = nil
			else
				a=a+1
			end
		end
		c("Exported recipes ("..a..")")
		tbl.recipes = {recipes=data_o}
		tbl.recipes.name = i[2]
		tbl.recipes.version = i[3] or "MC 1.12"
		c("Creating pack...")
		local f = fs.open("rbp/packs/"..i[2].."/"..i[2]..".lua", "w") f.write(textutils.serialize(tbl)) f.close()
		c("Created pack.")
	end,
	["install"] = function()
		if not i[2] then return printError("[RBM] usage: install <pack>") end
		c("Installing pack...")
		install(textutils.unserialize(getFile(i[2])))
	end,
	["exportn"] = function()
		if not i[2] then return printError("[RBM] usage: exportn <modfilter>") end
		c("Exporting names...")
		data = getFile("/usr/config/items.db")
		local a, b, d = {}, "", 0
		for w in string.gmatch(data, '%b""', "") do
			if b == "" then
				b = string.gsub(w,'"','')
			else
				if string.find(b, i[2]) ~= nil then
					a[b] = string.gsub(w,'"','') d=d+1
				end
				b = ""
			end
		end
		local f = fs.open("/rbp/n-out.lua", "w") f.write(textutils.serialize(a)) f.close()
		c("Complete! ("..d.." names exported)")
	end,
	["exportr"] = function()
		if not i[2] then return printError("[RBM] usage: exportr <modfilter>") end
		c("Exporting recipes...")
		data = getFile("/usr/config/recipes.db")
		data_o = textutils.unserialize(data)
		local nametable = {}
		data = string.gsub(data, '%[ "', '*')
		data = string.gsub(data, '" %]', '*')
		a = 0
		for w in string.gmatch(data, '%b**', "") do
			w = string.gsub(w, "*","")
			if string.find(w, i[2]) == nil then
				data_o[w] = nil
			else
				a=a+1
			end
		end
		local f = fs.open("/rbp/r-out.lua", "w") f.write(textutils.serialize(data_o)) f.close()
		c("Complete! ("..a.." recipes exported)")
	end,
	["clear"] = term.clear,
	["clr"] = term.clear,
	["exit"] = function() run = false end,
}

--cmd[i[1]]()

while run do
	write("rb+> ")
	i = {}
	for w in string.gmatch(read(), '%S+') do
		table.insert(i,w)
	end
	if not cmd[i[1]] then print("no such command.") else pcall(cmd[i[1]]) end
end
