-- GUI for R+ --
-- Koga --

-- Init --
if not term.isColor() then return printError("Advanced Computer Required.") end
if not http then return printError("Http is not enabled.") end
local wi,hi = term.getSize()
local t = term

local clr, cp, st, sb = t.clear, t.setCursorPos, t.setTextColor, t.setBackgroundColor
local w, p, pe = write, print, printError


-- Variables --
local cols = {
	["fg_0"] = colors.cyan,
	["tx_0"] = colors.gray,
	["tx_1"] = colors.lightGray,
	["tx_2"] = colors.white,
	["tx_3"] = colors.white,
}

local install_dir = "/usr/etc/" -- Important
local github_link = "https://raw.githubusercontent.com/JustDoesGames/RecipesPlus/main/packs/"

local web = http.get("https://raw.githubusercontent.com/JustDoesGames/RecipesPlus/main/packlist.lua")
if not web then return pe("Failed to obtain packlist from Github.") end
nav = textutils.unserialize(web.readAll()) web.close()
nav.items = (hi-1)/3 -- max options on screen
nav.scroll = 0
nav.active = nav

local loaded_pack, loaded_pack_raw, loaded_pack_recipes
local pack_scroll = 0


-- R+ API --
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
	--w("Installed '"..a.recipes.name.."'!")
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
		--w("Installing pack...")
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
--[[
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
--]]
local drawBase = function()
	sb(cols["fg_0"]) clr() cp((wi/2)-("Press 'Q' to exit"):len()/2,1) st(cols["tx_0"]) w("Press 'Q' to exit") cp(1,1) st(cols["tx_2"]) w(string.char(17))
end

local drawUpdate = true
local draw = function(screen, ...)
	local args = {...}
	if drawUpdate then drawUpdate = false drawBase() end
	if screen == "doNav" then
		local t, t2= {colors.gray, colors.lightGray}, 1
		for i=1, math.min(#nav.active, nav.items) do
			paintutils.drawLine(wi-1,((i-1)*3)+2,wi-1,((i-1)*3)+4, t[t2]) t2=t2+1 if t2 > #t then t2=1 end
			paintutils.drawFilledBox(1,((i-1)*3)+2,wi-2,((i-1)*3)+4, colors.black)
			cp(1,((i-1)*3)+3,wi-2) st(cols["tx_1"]) w(nav.active[i+nav.scroll].name)
		end
	elseif screen == "viewPack" then
		if args[2] then -- update whole screen
			sb(cols["fg_0"]) cp(1,hi-2) st(colors.orange) p(args[1].name)
			st(colors.white) p("Size: "..textutils.serialize(loaded_pack_raw):len()/(1000).." kb | Recipes: "..loaded_pack_recipes)
			st(cols["tx_3"]) sb(colors.black) cp(1,2)
			if fs.exists(install_dir.."names/"..args[1].fs_name..".db") then
				paintutils.drawFilledBox(wi-11,hi-2,wi-1,hi-1,colors.gray)
				cp(wi-10,hi-1) w("Uninstall")
			else
				paintutils.drawFilledBox(wi-11,hi-2,wi-1,hi-1,colors.green)
				cp(wi-9,hi-1) w("Install")
			end
			-- Storage Space on PC --
			local total = fs.getCapacity("")
			local used = fs.getFreeSpace("")
			paintutils.drawLine(1,hi,wi,hi,colors.gray) cp(1,hi)
			st(colors.yellow) for i=1, math.min(math.ceil(wi/(total/(used+textutils.serialize(loaded_pack_raw):len()))),wi-1) do w(string.char(127)) end cp(1,hi)
			st(colors.lightGray) for i=1, math.min(math.ceil(wi/(total/used)),wi-1) do w(string.char(127)) end
		end
		paintutils.drawFilledBox(1,2,wi-1,hi-3,colors.black) cp(1,2)
		for i=1, math.min(hi-4, #loaded_pack) do
			p(loaded_pack[i+pack_scroll].name)
		end
	elseif screen == "doInstallScreen" then
		--
	elseif screen == "doInstall" then
		--
	end
end

local loadPack = function(link)
	pack_scroll = 0
	loaded_pack_recipes = 0
	local web = http.get(link)
	if web then
		loaded_pack_raw = textutils.unserialize(web.readAll()) web.close()
		loaded_pack = textutils.serialize(loaded_pack_raw.names)
		local filtered_names = {}
		local t1 = false
		paintutils.drawLine(1,2,wi-1,2,colors.gray)
		for ww in string.gmatch(loaded_pack, '%b""', "") do
			loaded_pack_recipes = loaded_pack_recipes+1
			ww = string.sub(ww, 2,ww:len()-1)
			if t1 then
				filtered_names[#filtered_names].name = ww t1=false
			else
				filtered_names[#filtered_names+1] = {item_id=ww} t1=true
			end
		end
		loaded_pack = filtered_names
		loaded_pack_recipes = loaded_pack_recipes/2
		return true
	else
		return false
	end
end

local viewPack = function(pack)
	local update = true
	drawBase() paintutils.drawFilledBox(1,2,wi-1,hi-3,colors.black)
	if not loadPack(github_link..pack.link..".lua") then
		paintutils.drawFilledBox(1,2,wi-1,hi,colors.black) cp(1,2) pe("Failed to obtain pack info.") sleep(3)
	else
		drawUpdate = true 
		while true do
			draw("viewPack", pack, update) update = false
			a,b,x,y = os.pullEvent()
			if a == "mouse_scroll" then
				pack_scroll = math.max(0,math.min(pack_scroll+b, loaded_pack_recipes-(hi-4)))
			elseif a == "mouse_click" then
				if x == 1 and y == 1 then
					break
				elseif x >= wi-11 and x <= wi-1 and y >= hi-2 and y <= hi-1 then
					if fs.exists(install_dir.."names/"..pack.fs_name..".db") then -- uninstall
						fs.delete(install_dir.."names/"..pack.fs_name..".db")
						fs.delete(install_dir.."recipes/"..pack.fs_name..".db") update = true
					else -- install
						install(loaded_pack_raw) update = true
					end
				end
			elseif a == "key" then
				if b == keys.q then break end
			end
		end
	end
end

local doInstall = function()
	--
end

local doInstallScreen = function()
	--
end



-- Start --

local start = function()
	st(colors.white) sb(colors.black) clr() cp(1,1) write("R++ initiating...") sleep(.1)
	while true do
		draw("doNav")
		a,b,x,y = os.pullEvent()
		if a == "mouse_scroll" then
			nav.scroll = math.max(0,math.min((nav.scroll+b), #nav.active-nav.items))
		elseif a == "mouse_click" then
			if x < wi and y > 1 and (y-1)/3 <= #nav.active then
				if nav.active[math.ceil((y-1)/3)+nav.scroll].view then
					nav.active, nav.scroll = nav.active[math.ceil((y-1)/3)+nav.scroll].view,0 drawUpdate = true
				elseif nav.active[math.ceil((y-1)/3)+nav.scroll].link then
					viewPack(nav.active[math.ceil((y-1)/3)+nav.scroll]) drawUpdate = true
				end
			elseif x == 1 and y == 1 then
				nav.active = nav drawUpdate = true
			end
		elseif a == "key" then
			if b == keys.q then
				break
			end
		end
	end
end
start()

sleep(.1) st(colors.white) sb(colors.black) clr() cp(1,1) p("Exited without error.")
