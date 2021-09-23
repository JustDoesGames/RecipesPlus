-- GUI for R++ --
-- Koga --

-- Init --
if not term.isColor() then return printError("Advanced Computer Required.") end
local wi,hi = term.getSize()
local t = term

local clr, cp, st, sb = t.clear, t.setCursorPos, t.setTextColor, t.setBackgroundColor
local w, p, pe = write, print, printError


-- Variables --
local install_dir = "/usr/etc/" -- Important
local list = {
	{
		name = "mekanism",
		link = "mekanism/mekanism",
	},
	{
		name = "mekanismgenerators",
		link = "mekanism/mekanismgenerators",
	},
	{
		name = "minecraft_1-12",
		link = "minecraft/1-12",
	},
	{
		name = "cc-tweaked",
		link = "computercraft/cc-tweaked",
	},
}

-- R++ API --
local function getFile(dir)
	if not fs.exists(dir) then pe("file doesn't exist: "..dir) error("") end
	local f = fs.open(dir, "r")
	if not f then pe("failed to read file '"..dir.."'") error("") end
	local a = f.readAll() f.close() return a
end

local function install(a)
	a = a or {}
	if not a.names or not a.recipes then return pe("invalid pack") end
	if not a.recipes.name or not a.recipes.version then return pe("invalid pack: name/version") end
	if fs.exists(install_dir.."/names/"..a.recipes.name:lower()..".db") or fs.exists(install_dir.."/recipes/"..a.recipes.name:lower()..".db") then return pe("pack already exists") end
	local f = fs.open(install_dir.."/names/"..a.recipes.name:lower():gsub(" ","")..".db", "w") f.write(textutils.serialize(a.names)) f.close()
	local f = fs.open(install_dir.."/recipes/"..a.recipes.name:lower():gsub(" ","")..".db", "w") f.write(textutils.serialize(a.recipes)) f.close()
	w("Installed '"..a.recipes.name.."'!")
end

local i = {}
local cmd = {
	["get"] = function()
		if not i[2] then return pe("[RBP] usage: get <raw pack url>") end
		w("Getting pack...")
		if not http then return pe("[RBP] http is disabled") end
		local h = http.get(i[2])
		if not h then return pe("link failed") end
		local a = textutils.unserialize(h.readAll()) or {} h.close()
		install(a)
	end,
	["grab"] = function()
		if not i[2] then return pe("[RBP] usage: grab <pack name>") end
		i[2] = i[2]:lower():gsub(" ","")
		if not http then return pe("[RBP] http is disabled") end
		local h = http.get("https://raw.githubusercontent.com/JustDoesGames/RecipesPlus/main/packs/"..i[2]..".lua")
		if not h then return pe("[RBP] unable to find '"..i[2].."'.") end
		local a = textutils.unserialize(h.readAll()) or {} h.close()
		install(a)
	end,
	["create"] = function()
		if not i[2] then return pe("[RBP] usage: create <name>") end
		w("Creating pack...")
		local tbl = {}
		tbl.names = textutils.unserialize(getFile(install_dir.."/names/"..i[2]..".db"))
		tbl.recipes = textutils.unserialize(getFile(install_dir.."/recipes/"..i[2]..".db", "r"))
		local f = fs.open("rbp/packs/"..i[2].."/"..i[2]..".lua", "w") f.write(textutils.serialize(tbl)) f.close()
		w("Created pack.")
	end,
	["autocreate"] = function()
		if not i[2] then return pe("[RBM] usage: autocreate <modfilter>") end
		local tbl = {}
		w("Exporting names...")
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
		w("Exported names ("..d..")")
		tbl.names = a
		
		w("Exporting recipes...")
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
		w("Exported recipes ("..a..")")
		tbl.recipes = {recipes=data_o}
		tbl.recipes.name = i[2]
		tbl.recipes.version = i[3] or "MC 1.12"
		w("Creating pack...")
		local f = fs.open("rbp/packs/"..i[2].."/"..i[2]..".lua", "w") f.write(textutils.serialize(tbl)) f.close()
		w("Created pack.")
	end,
	["install"] = function()
		if not i[2] then return pe("[RBM] usage: install <pack>") end
		w("Installing pack...")
		install(textutils.unserialize(getFile(i[2])))
	end,
	["exportn"] = function()
		if not i[2] then return pe("[RBM] usage: exportn <modfilter>") end
		w("Exporting names...")
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
		w("Complete! ("..d.." names exported)")
	end,
	["exportr"] = function()
		if not i[2] then return pe("[RBM] usage: exportr <modfilter>") end
		w("Exporting recipes...")
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
		w("Complete! ("..a.." recipes exported)")
	end,
	["clear"] = term.clear,
	["clr"] = term.clear,
	["exit"] = function() run = false end,
}



-- Functions --
local doInstall = function(a)
	paintutils.drawFilledBox(1,2,wi-1,hi-1,colors.black)
	cp(1,2)
	if fs.exists(install_dir.."names/"..a.name..".db") or fs.exists(install_dir.."recipes/"..a.name..".db") then
		p("Removing...") sleep(.1)
		fs.delete(install_dir.."names/"..a.name..".db") fs.delete(install_dir.."recipes/"..a.name..".db")
		p("Removed.")
	else
		p("Grabbing...")
		i[2] = a.link cmd["grab"]()
	end
	sleep(1) cp(1,4) w("Press any key to continue.") os.pullEvent("key") sleep(.2)
end

local display = function()
	local new, cursor = true, 1
	local dis = function()
		if new then new = false
			sb(colors.cyan) clr() cp((wi/2)-("Press 'Q' to exit"):len()/2,hi) st(colors.black) w("Press 'Q' to exit")
			paintutils.drawLine(1,1,wi,1,colors.white)
			paintutils.drawFilledBox(1,2,wi-1,hi-1, colors.black)
			st(colors.white) sb(colors.black)
		end
		cp(1,2) p("R++") st(colors.gray) p(install_dir.."\n") st(colors.white) for i=1, #list do if fs.exists(install_dir.."names/"..list[i].name..".db") then write(string.char(7).." ") else write("- ") end p(i==cursor and string.char(16).." "..list[i].name.."  " or list[i].name.."  ") end
	end
	while true do
		dis()
		a,b = os.pullEvent("key")
		if b == keys.up or b == keys.w then
			if cursor == 1 then cursor = #list else cursor = cursor-1 end
		elseif b == keys.down or b == keys.s then
			if cursor == #list then cursor = 1 else cursor = cursor+1 end
		elseif b == keys.enter or b == keys.e then
			doInstall(list[cursor]) new = true
		elseif b == keys.q then
			break
		end
	end
end



-- Start --

local start = function()
	st(colors.white) sb(colors.black) clr() cp(1,1) write("R++ initiating...") sleep(.1)
	display()
end
start()

sleep(.1) st(colors.white) sb(colors.black) clr() cp(1,1) p("Exited without error.")
