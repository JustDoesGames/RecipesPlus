local USER_DIR = "/disk2/usr/etc/"

local i = {}

local run = true
local c = function(t) print("[RBM] "..t) end
local failed = function(reason) printError("failed to get/create pack. ("..reason..")") error() end

local function getFile(dir)
	if not fs.exists(dir) then return failed("pack doesn't exist: "..dir) end
	local f = fs.open(dir, "r")
	if not f then return failed("failed to read file '"..dir.."'") end
	local a = f.readAll() f.close() return a
end

local function install(a)
	a = a or {}
	if not a.names or not a.recipes then return failed("invalid pack") end
	if not a.recipes.name or not a.recipes.version then return failed("invalid pack: name/version") end
	if fs.exists(USER_DIR.."/names/"..a.recipes.name:lower()..".db") or fs.exists(USER_DIR.."/recipes/"..a.recipes.name:lower()..".db") then return failed("pack already exists") end
	local f = fs.open(USER_DIR.."/names/"..a.recipes.name:lower()..".db", "w") f.write(textutils.serialize(a.names)) f.close()
	local f = fs.open(USER_DIR.."/recipes/"..a.recipes.name:lower()..".db", "w") f.write(textutils.serialize(a.recipes)) f.close()
	c("Installed '"..a.recipes.name.."'!")
end

local cmd = {
	["get"] = function()
		if not i[2] then return printError("[RBM] usage: get <raw pack url>") end
		c("Getting pack...")
		if not http then return failed("http is disabled") end
		local h = http.get(i[2])
		if not h then return failed("link failed") end
		local a = textutils.unserialize(h.readAll()) or {} h.close()
		install(a)
	end,
	["create"] = function()
		if not i[2] then return printError("[RBM] usage: create <name>") end
		c("Creating pack...")
		local tbl = {}
		tbl.names = textutils.unserialize(getFile(USER_DIR.."/names/"..i[2]..".db"))
		tbl.recipes = textutils.unserialize(getFile(USER_DIR.."/recipes/"..i[2]..".db", "r"))
		local f = fs.open("rbm/packs/"..i[2].."/"..i[2]..".lua", "w") f.write(textutils.serialize(tbl)) f.close()
		c("Created pack.")
	end,
	["install"] = function()
		if not i[2] then return printError("[RBM] usage: install <pack>") end
		c("Installing pack...")
		install(textutils.unserialize(getFile(i[2])))
	end,
	["exportnames"] = function()
		if not i[2] then return printError("[RBM] usage: exportnames <modfilter>") end
		c("Exporting names...")
		data = getFile("/usr/config/items.db", "r")
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
		local f = fs.open("/data/out.lua", "w") f.write(textutils.serialize(a)) f.close()
		c("Complete! ("..d.." names exported)")
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
	if not cmd[i[1]] then print("no such command.") else cmd[i[1]]() end
end
