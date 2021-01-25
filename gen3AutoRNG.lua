-- Author: Samuel Peters
-- Github: speters217/pokemonGen3AutoRNG
-- Date: January 24, 2021

-- Thanks to:
-- zaksabeast for the inspiration and basis for this script: https://github.com/zaksabeast/rngLuaScripts/blob/master/autoFrLgRNG.lua
-- FractalFusion and Kaphotics for the base of this script. Their work on the hex locations and the pokemonstats script were vital.
-- red-the-dev for his code that can detect the version of the game: https://github.com/red-the-dev/gen3-pokemonstatsdisplay
-- http://stackoverflow.com/a/5032014 for string:split
-- http://stackoverflow.com/a/21287623 for newAutotable
-- https://scriptinghelpers.org/questions/27221/how-do-i-check-if-something-is-a-number for addCommas



-- If method=1, then 1.csv will be read, any other value will use h2.csv and h4.csv
-- Works with RNG Reporter 10.3.4
-- If using another version, you may have to change pid and/or frame column

-- MAKE EDITS HERE
local isPartyPkmn = false -- true for party, false for encounters
local partyIndex = 6 -- location in party (1-6) of pokemon to rng; ignored if isPartyPkmn is true
local method = 1 -- 1 for method 1 encounter
local button = 0 -- leave 0 to press "A" on target frame, otherwise "up" will be pressed
-- DON'T EDIT PAST HERE

-- Returns the number that is closest to the goal
function closestTo(goal, num1, num2)
    local temp1 = goal-num1
    local temp2 = goal-num2
    if(temp1<0) then
        temp1=temp1*-1
    end
    if(temp2<0) then
        temp2=temp2*-1
    end
    print("temp1 = "..temp1.." temp2 = "..temp2)
    if(temp1<temp2) then
        return num1
    else
        return num2
    end
end

-- Converts a CSV to an array
function csvToArray(fileName, method)
    local keysTxt = io.open(fileName, "r")
    local targetList = newAutotable(2)
    local line = 1
    local row = 1
    local pidCol = 5
    
    for keyLine in keysTxt:lines() do
        local tempShine=keyLine:split("\t")
        if(string.match(tempShine[1],"%d")) then
            targetList[row][0] = tempShine[1]
            targetList[row][1] = tempShine[pidCol]
            row = row + 1
        end
        line = line + 1
    end
    keysTxt:close()
    return targetList
end

-- Splits a string based on the passed delimeter
-- Thanks to http://stackoverflow.com/a/5032014

function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

-- Creates a new autotable with the given dimensions
-- Thanks to http://stackoverflow.com/a/2128762
function newAutotable(dim)
    local MT = {};
    for i=1, dim do
        MT[i] = {__index = function(t, k)
            if i < dim then
                t[k] = setmetatable({}, MT[i+1])
                return t[k];
            end
        end}
    end
    return setmetatable({}, MT[1]);
end

-- Returns the frame corresponding to the passed in PID
function pid2frame(needle, haystack, wantedFrame)
	print("Pokemon encountered")
	print("Looking for PID: "..needle)
    local i = 1
    -- Iterate through table, looking for PID
    while (i < table.getn(haystack)) do
    	-- Returns frame corresponding to PID if found
        if(haystack[i][1]==needle)then
	    	print("PID located")
	    	return(haystack[i][0])
        end
        i = i + 1
    end
    -- Returns 0 if PID was not found
    return(0)
end

-- Returns index of a savestate belonging to the highest frame that is less than frame
-- Returns -1 if no valid savestate is found
function findClosestSave(frame, saves, currSave)
	local i = currSave
	-- Iterates over all saves
	while (i >= 0) do
		-- Check if savestate's frame is earlier than the desired frame
		if (saves[i][1] < frame) then
			-- Returns closest savestate
			return i
		end
		i = i - 1
	end
	-- No valid save could be found
	return -1
end

-- Inserts commas into a number
-- Thanks to https://scriptinghelpers.org/questions/27221/how-do-i-check-if-something-is-a-number for addCommas
function addCommas(str)
	if type(str) ~= "string" then
		str = ""..str
	end
	return #str % 3 == 0 and str:reverse():gsub("(%d%d%d)", "%1,"):reverse():sub(2) or str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

-- Converts seconds to "h:m:s"
function secondsToString(time)
	local seconds = math.floor(time % 60)
	local minutes = math.floor(time / 60)
	local hours = math.floor(minutes / 60)
	minutes = minutes % 60
	return ""..hours..":"..minutes..":"..seconds
end


-- An array of saves
local saveArray = {}
local currSave = -1

-- Creates a savestate at the current frame
function createSave()
	currSave = currSave + 1
	saveArray[currSave] = {}
	saveArray[currSave][1] = emu.framecount()
	saveArray[currSave][2] = savestate.create()
	savestate.save(saveArray[currSave][2])
	print("Savestate "..currSave.." made on frame "..addCommas(saveArray[currSave][1]))
end

-- Loads the closest savestate before frame
-- An argument of nil will load the most recent save
-- An argument less than 0 will load the earliest save
-- Returns whether or not such a save could be found and loaded
local power
local originalPower
local potentialOffset
function loadSave(frame)
	if (frame == nil) then
		currSave = currSave-- Do nothing so the most recent save will be loaded
	elseif (frame < 0) then
		currSave = 0
	else
		local index = findClosestSave(frame, saveArray, currSave)
		if (index == -1) then
			return false
		end
		currSave = index
	end
	savestate.load(saveArray[currSave][2])
	print("Savestate "..currSave.." loaded on frame "..addCommas(saveArray[currSave][1]))
	power = originalPower
	potentialOffset = math.pow(10, power)
	return true
end

local natureorder={"Atk","Def","Spd","SpAtk","SpDef"}
local naturename={
 "Hardy","Lonely","Brave","Adamant","Naughty",
 "Bold","Docile","Relaxed","Impish","Lax",
 "Timid","Hasty","Serious","Jolly","Naive",
 "Modest","Mild","Quiet","Bashful","Rash",
 "Calm","Gentle","Sassy","Careful","Quirky"}
local typeorder={
 "Fighting","Flying","Poison","Ground",
 "Rock","Bug","Ghost","Steel",
 "Fire","Water","Grass","Electric",
 "Psychic","Ice","Dragon","Dark"}

versions = {"POKEMON RUBY",
            "POKEMON SAPP",
            "POKEMON FIRE",
            "POKEMON LEAF",
            "POKEMON EMER"}

languages = {"Unknown",
	     "Deutsch",
             "French",
             "Italian",
             "Spanish",
             "English",
             "Japanese"}
			 
function checkversion(version)
	for i,v in pairs(versions) do
		if comparebytetostring(version,v) then
			return i
		end
	end
end

function comparebytetostring(b, s)
	local isequal = true
	local blen = table.getn(b)
	local slen = string.len(s)
	local x,y
	if blen ~= slen then
		isequal = false
    else
    	for i=1,blen do
    		x = b[i]
    		y = string.byte(s, i)
    		if(x~=y) then
    			isequal = false
    			break
    		end
    	end
    end
	return isequal
end

local rshift, lshift=bit.rshift, bit.lshift

--a 32-bit, b bit position bottom, d size
function getbits(a,b,d)
 return rshift(a,b)%lshift(1,d)
end
			 
local vbytes = memory.readbyterange(0x080000A0, 12)
local vindex = checkversion(vbytes)
if vindex==nil then
	print("Unknown version. Stopping script.")
	return
end

print(string.format("Version: %s", versions[vindex]))
local lan = memory.readbyte(0x080000AF)
local lindex = 1
local language

if (lan == 0x44) then
	lindex = 2
elseif (lan == 0x46) then
	lindex = 3
elseif (lan == 0x49) then
	lindex = 4
elseif (lan == 0x53) then
	lindex = 5
elseif (lan == 0x45) then
	lindex = 6
elseif (lan == 0x4A) then
	lindex = 7
end

print(string.format("Language: %s", languages[lindex]))

if lindex == 1 then
	print("This language is not currently supported")
	print("Stopping script")
	return
end

--for different game versions
--1: Ruby/Sapphire U
--2: Emerald U
--3: FireRed/LeafGreen U
--4: Ruby/Sapphire J
--5: Emerald J
--6: FireRed/LeafGreen J (1360)
--7: Ruby/Sapphire I
--8: FireRed/LeafGreen S

local game=1 --see below
local startSeed
local dynamicStartSeed = false

-- Auto-setting game variable

if ((vindex == 1) or (vindex == 2)) then  -- Ruby/Sapphire
	startSeed = "5A0"
	if (lindex == 4) then
		game = 7
	elseif (lindex == 6) then
		game = 1
	elseif (lindex == 7) then
		game = 4
	end
end

if ((vindex == 3) or (vindex == 4)) then  -- FireRed/LeafGreen
	dynamicStartSeed = true
	if ((lindex == 4) or (lindex == 6)) then
		game = 3
	elseif (lindex == 7) then
		game = 6
	elseif (lindex == 5) then
		game = 8
	end
end

if (vindex == 5) then  -- Emerald
	startSeed = "0"
	if ((lindex == 4) or (lindex == 6)) then
		game = 2
	elseif (lindex == 7) then
		game = 5
	end
end

local startvalue=0x83ED --insert the first value of RNG

local gamename={"Ruby/Sapphire U", "Emerald U", "FireRed/LeafGreen U", "Ruby/Sapphire J", "Emerald J", "FireRed/LeafGreen J (1360)", "Ruby/Sapphire I"}

local pstats={0x3004360, 0x20244EC, 0x2024284, 0x3004290, 0x2024190, 0x20241E4, 0x3004370, 0x2024284}
local estats={0x30045C0, 0x2024744, 0x202402C, 0x30044F0, 0x0000000, 0x2023F8C, 0x30045D0, 0x202402C}
local rng   ={0x3004818, 0x3005D80, 0x3005000, 0x3004748, 0x0000000, 0x3005040, 0} --0X3004FA0
local rng2  ={0x0000000, 0x0000000, 0x20386D0, 0x0000000, 0x0000000, 0x203861C, 0}


if (isPartyPkmn) then
	start = pstats[game] + 100 * (partyIndex - 1)
else
	start = estats[game] + 100 * (0) -- hardcoded as 0 since we will only RNG one wild pokemon
end


local tempFrame1, tempFrame2
local personality -- PID of pokemon observed
local trainerid
local magicword
local growthoffset, miscoffset

local species
local ivs, hpiv, atkiv, defiv, spdiv, spatkiv, spdefiv
local nature, natinc, natdec
local hidpowbase, hidpowtype
local index
local h2List
local h4List
local method1List
local targetList


-- Some powershell commands that will change the encoding of the .txt files
local convertTarget = [[
powershell -c "Get-Content target.txt | Set-Content -Encoding utf8 target_utf8.txt"
]]

local convertM1 = [[
powershell -c "Get-Content 1.txt | Set-Content -Encoding utf8 1_utf8.txt"
]]

local convertH2 = [[
powershell -c "Get-Content h2.txt | Set-Content -Encoding utf8 h2_utf8.txt"
]]

local convertH4 = [[
powershell -c "Get-Content h4.txt | Set-Content -Encoding utf8 h4_utf8.txt"
]]

-- Processes text files and stores them in tables
local pipe = io.popen("powershell -command -", "w")
pipe:write(convertTarget)
if(method~=1) then
	pipe:write(convertH2)
	pipe:write(convertH4)
else
	pipe:write(convertM1)
end
pipe:close()

if(method~=1) then
    h2List = csvToArray("h2_utf8.txt", 2)
    h4List = csvToArray("h4_utf8.txt", 4)
    targetList = csvToArray("target_utf8.txt", 2)
else
    method1List = csvToArray("1_utf8.txt", 1)
    targetList = csvToArray("target_utf8.txt", 1)
end



-- Adjusts the button to press
local joyPress={}
if (button == 0) then
	joyPress["A"] = 1
else
	joyPress["up"] = 1
end

local tid, sid
local offset=0
local wantedFrame=tonumber(targetList[1][0])


power = 0
while (wantedFrame >= math.pow(10, power)) do
	power = power + 1
end

power = power - 2

if (power < 0) then
	power = 0
	
end
potentialOffset = math.pow(10, power)

originalPower = power -- used to reset power on load of savestate

local targetPID=targetList[1][1]
local targetFrame=wantedFrame

if (wantedFrame < emu.framecount()) then
	print("The starting frame is higher than the desired frame!")
	print("Try starting the script on an earlier frame")
	print("Pausing...")
	emu.pause()
end

local hitFrame
local infoString, memo
memo = "Attempting to hit frame "..addCommas(wantedFrame)
print(memo)


local found = 0 -- Is 0 until target is found, script pauses after 60 frames advance and found == 60
local frameNum = emu.framecount() -- Current frame
local prevTime = os.time() --Used to calculate eta


-- This is the main loop that drives the whole program. Each iteration corresponds to one frame in the game.
createSave() -- Create initial save
collectgarbage()
while true do
    if (dynamicStartSeed) then
    	startSeed = string.format("%04X", memory.readword(0x02020000)) -- FireRed/LeafGreen
    	gui.text(0, 120, "Starting Seed = "..startSeed)
    end
    
    frameNum = emu.framecount()
    if ((frameNum % potentialOffset == 0) and (found == 0)) then
    	createSave()
    elseif (((targetFrame - frameNum) < potentialOffset) and (found == 0)) then
    	if (power > 3) then
    		potentialOffset = potentialOffset / 10
    		power = power - 1
   		end
    end
    
    personality=memory.readdwordunsigned(start)	
    
    if (frameNum == targetFrame) then
        joypad.set(1,joyPress)
    end
    
    
    --gui.text(0,105,"Frames To Go: "..(targetFrame - frameNum))
    
    if (personality ~= 0) then
    	
    	trainerid=memory.readdwordunsigned(start+4)
    	magicword=bit.bxor(personality, trainerid)

    	index = personality%24

    	if (index <= 5) then
    	    growthoffset = 0
    	elseif (index % 6 <= 1) then
       		growthoffset = 12
    	elseif (index % 2 == 0) then
        	growthoffset = 24
    	else
        	growthoffset = 36
    	end

    	if (index >= 18) then
        	miscoffset = 0
    	elseif (index % 6 >= 4) then
        	miscoffset=12
    	elseif (index % 2 == 1) then
        	miscoffset = 24
    	else
        	miscoffset = 36
    	end

    	species = bit.band(bit.bxor(memory.readdwordunsigned(start + 32 + growthoffset), magicword), 0xFFF)
    	ivs = bit.bxor(memory.readdwordunsigned(start + 32 + miscoffset + 4), magicword)
 
    	hpiv = getbits(ivs, 0, 5)
    	atkiv = getbits(ivs, 5 , 5)
    	defiv = getbits(ivs, 10, 5)
    	spdiv = getbits(ivs, 15, 5)
    	spatkiv = getbits(ivs, 20, 5)
    	spdefiv = getbits(ivs, 25, 5)
 
    	nature = personality % 25
    	natinc = math.floor(nature / 5)
    	natdec = nature % 5
 
    	hidpowtype = math.floor((((hpiv % 2) + 2 *(atkiv % 2) + 4 * (defiv % 2) + 8 * (spdiv % 2) + 16 * (spatkiv % 2) + 32 * (spdefiv % 2)) * 15) /63)
    	hidpowbase=math.floor(((bit.band(hpiv,2)/2 + bit.band(atkiv,2) + 2*bit.band(defiv,2) + 4*bit.band(spdiv,2) + 8*bit.band(spatkiv,2) + 16*bit.band(spdefiv,2))*40)/63 + 30)
 
    	gui.text(0, 0, "Stats")
    	gui.text(30, 0, "HP  "..memory.readwordunsigned(start + 86), "red")
    	gui.text(65, 0, "Atk "..memory.readwordunsigned(start + 90), "orange")
    	gui.text(99, 0, "Def "..memory.readwordunsigned(start + 92), "yellow")
    	gui.text(133, 0, "SpA "..memory.readwordunsigned(start + 96), "green")
    	gui.text(167, 0, "SpD "..memory.readwordunsigned(start + 98), "cyan")
    	gui.text(201, 0, "Spe "..memory.readwordunsigned(start + 94), "magenta")

    	gui.text(0, 8, "IVs")
    	gui.text(30, 8, "HP  "..hpiv, "red")
    	gui.text(65, 8, "Atk "..atkiv, "orange")
    	gui.text(99, 8, "Def "..defiv, "yellow")
    	gui.text(133, 8, "SpA "..spatkiv, "green")
    	gui.text(167, 8, "SpD "..spdefiv, "cyan")
    	gui.text(201, 8, "Spe "..spdiv, "magenta")

    	gui.text(0, 40,"PID:  "..string.format("%08X", personality))
    	gui.text(60, 40,"IVs: "..string.format("%08X", ivs))
    	gui.text(0, 50, "Nature: "..naturename[nature + 1])
    	gui.text(0, 60, natureorder[natinc + 1].."+ "..natureorder[natdec + 1].."-")
    	gui.text(167, 15, "HP "..typeorder[hidpowtype + 1].." "..hidpowbase)
    
		if (string.upper(string.format("%08x", personality)) ~= targetPID) then
        	if (method ~= 1) then
            	tempFrame1 = tonumber(pid2frame(string.upper(string.format("%08x", personality)), h2List, wantedFrame))
                tempFrame2 = tonumber(pid2frame(string.upper(string.format("%08x", personality)), h4List, wantedFrame))
               	hitFrame = closestTo(wantedFrame, tempFrame1, tempFrame2)
            else
                hitFrame = tonumber(pid2frame(string.upper(string.format("%08x", personality)), method1List, wantedFrame))
            end
           	if (hitFrame ~= 0) then
                offset = (hitFrame - wantedFrame) * (-1)
            else
            	print("PID not found")
                print("Pausing...")
                emu.pause()
                print("Loading last save")
                loadSave()
            end
            targetFrame = targetFrame + offset
            memo = "Adjusted target is frame "..addCommas(targetFrame)
            print(memo)
            print("Set offset = "..offset)
            print("Loading closest savestate...")
            -- Attempts to load save and handles if it fails
			if not(loadSave(targetFrame)) then
				print("Offset was too large - Start script on earlier frame if possible")
                print("Pausing...")
                emu.pause()
                print("Loading earliest save...")
                loadSave(-1)
			end
        else
        	found = found + 1
        	memo = "Target Pokemon Hit!"
        	if (found == 1) then
        		print(memo)
        	end
		end
    end
    --calculates the time elapsed between every 1000 frames and then makes an eta
    if (frameNum % 1000 == 0) then
    	if (found > 59) then
    		print("Pausing...")
    		emu.pause()
    	end
		local diff = os.difftime(os.time(), prevTime)
		prevTime = os.time()
		local fps = 1000 / diff
		local eta = (targetFrame - frameNum) / fps
		
		memo2 = "Time remaining: "..secondsToString(eta)
		-- Garbage collects every million frames to prevent memory overflow. Doing this every frame will make the program crash.
		if (frameNum % 1000000 == 0) then
			collectgarbage()
		end
	end
	gui.text(0, 130, memo2)
    gui.text(0, 140, "Current Frame: "..addCommas(frameNum))
    gui.text(0, 150, memo)
    emu.frameadvance()
    
end