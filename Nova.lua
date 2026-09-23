--[[

	NovaUI Interface Suite
	Basado en la arquitectura completa de Sirius / Rayfield UI Library

	shlex  | Designing + Programming
	iRay   | Programming
	Max    | Programming
	Damian | Programming

]]

if debugX then
	warn('Initialising NovaUI')
end

local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

-- Services
local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")

-- Loads and executes a function hosted on a remote URL. Cancels the request if the requested URL takes too long to respond.
-- Errors with the function are caught and logged to the output
local function loadWithTimeout(url: string, timeout: number?): ...any
	assert(type(url) == "string", "Expected string, got " .. type(url))
	timeout = timeout or 5
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url) -- game:HttpGet(url)
		-- If the request fails the content can be empty, even if fetchSuccess is true
		if not fetchSuccess or #fetchResult == 0 then
			if #fetchResult == 0 then
				fetchResult = "Empty response" -- Set the error message
			end
			success, result = false, fetchResult
			requestCompleted = true
			return
		end
		local content = fetchResult -- Fetched content
		local execSuccess, execResult = pcall(function()
			return loadstring(content)()
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	local timeoutThread = task.delay(timeout, function()
		if not requestCompleted then
			warn("Request for " .. url .. " timed out after " .. tostring(timeout) .. " seconds")
			task.cancel(requestThread)
			result = "Request timed out"
			requestCompleted = true
		end
	end)

	-- Wait for completion or timeout
	while not requestCompleted do
		task.wait()
	end
	-- Cancel timeout thread if still running when request completes
	if coroutine.status(timeoutThread) ~= "dead" then
		task.cancel(timeoutThread)
	end
	if not success then
		warn("Failed to process " .. tostring(url) .. ": " .. tostring(result))
	end
	return if success then result else nil
end

local requestsDisabled = false
local customAssetId = nil
local secureMode = false
if getgenv then
	local ok, result = pcall(function() return getgenv().DISABLE_NOVAI_REQUESTS end)
	if ok and result then requestsDisabled = true end
	local ok2, result2 = pcall(function() return getgenv().NOVAI_ASSET_ID end)
	if ok2 and type(result2) == "number" then customAssetId = result2 end
	local ok3, result3 = pcall(function() return getgenv().NOVAI_SECURE end)
	if ok3 and result3 then secureMode = true end
end

if secureMode then
	local _error = error
	local _assert = assert
	warn = function(...) end
	print = function(...) end
	error = function(_, level) _error("", level) end
	assert = function(v, ...) return _assert(v) end
end

local secureWarnings = {}
local customAssets = {}

local function secureNotify(wType, title, content)
	if secureWarnings[wType] then return end
	secureWarnings[wType] = true
	task.spawn(function()
		while not NovaUILibrary or not NovaUILibrary.Notify do task.wait(0.5) end
		NovaUILibrary:Notify({
			Title = title,
			Content = content,
			Duration = 8,
		})
	end)
end

local InterfaceBuild = 'UU2NX'
local Release = "Build 1.749"
local NovaUIFolder = "NovaUI"
local ConfigurationFolder = NovaUIFolder.."/Configurations"
local ConfigurationExtension = ".nvld"
local settingsTable = {
	General = {
		novaOpen = {Type = 'bind', Value = 'K', Name = 'NovaUI Keybind'},
	},
	System = {
		usageAnalytics = {Type = 'toggle', Value = true, Name = 'Anonymised Analytics'},
	}
}

local overriddenSettings: { [string]: any } = {}
local function overrideSetting(category: string, name: string, value: any)
	overriddenSettings[category .. "." .. name] = value
end

local function getSetting(category: string, name: string): any
	if overriddenSettings[category .. "." .. name] ~= nil then
		return overriddenSettings[category .. "." .. name]
	elseif settingsTable[category][name] ~= nil then
		return settingsTable[category][name].Value
	end
end

if requestsDisabled then
	overrideSetting("System", "usageAnalytics", false)
end

local HttpService = getService('HttpService')
local RunService = getService('RunService')

local useStudio = RunService:IsStudio() or false

local settingsCreated = false
local settingsInitialized = false
local prompt = useStudio and require(script.Parent.prompt) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/prompt.lua')
local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

if not prompt and not useStudio then
	warn("Failed to load prompt library, using fallback")
	prompt = {
		create = function() end
	}
end

local function callSafely(func, ...)
	if func then
		local success, result = pcall(func, ...)
		if not success then
			warn("NovaUI | Function failed with error: ", result)
			return false
		else
			return result
		end
	end
end

local function ensureFolder(folderPath)
	if isfolder and not callSafely(isfolder, folderPath) then
		callSafely(makefolder, folderPath)
	end
end

local function loadSettings()
	local file = nil

	local success, result = pcall(function()
		if callSafely(isfolder, NovaUIFolder) then
			if callSafely(isfile, NovaUIFolder..'/settings'..ConfigurationExtension) then
				file = callSafely(readfile, NovaUIFolder..'/settings'..ConfigurationExtension)
			end
		end

		if useStudio then
			file = [[
	{"General":{"novaOpen":{"Value":"K","Type":"bind","Name":"NovaUI Keybind","Element":{"HoldToInteract":false,"Ext":true,"Name":"NovaUI Keybind","Set":null,"CallOnChange":true,"Callback":null,"CurrentKeybind":"K"}}},"System":{"usageAnalytics":{"Value":false,"Type":"toggle","Name":"Anonymised Analytics","Element":{"Ext":true,"Name":"Anonymised Analytics","Set":null,"CurrentValue":false,"Callback":null}}}}
]]
		end

		if file then
			local decodeSuccess, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
			if decodeSuccess then
				file = decodedFile
			else
				file = {}
			end
		else
			file = {}
		end

		if not settingsCreated then
			return
		end

		if next(file) ~= nil then
			for categoryName, categoryTable in file do
				for settingName, setting in categoryTable do
					local default = settingsTable[categoryName] and settingsTable[categoryName][settingName]
					if not default then continue end
					local settingType = typeof(default.Value)
					if not (settingType == typeof(setting.Value)) then
						warn("NovaUI | Error parsing settings file. '"..settingName.."' must be a "..settingType)
						continue
					end
					default.Value = setting.Value
				end
			end
		end

		for categoryName, categoryTable in settingsTable do
			for settingName, setting in categoryTable do
				if setting.Element then
					setting.Element:Set(getSetting(categoryName, settingName))
				end
			end
		end
		settingsInitialized = true
	end)

	if not success then 
		if writefile then
			warn('NovaUI had an issue accessing configuration saving capability.')
		end
	end
end

if debugX then
	warn('Now Loading Settings Configuration')
end

loadSettings()

if debugX then
	warn('Settings Loaded')
end

local NovaUILibrary = {
	Flags = {},
	Theme = {
		Default = {
			TextColor = Color3.fromRGB(240, 240, 240),

			Background = Color3.fromRGB(25, 25, 25),
			Topbar = Color3.fromRGB(34, 34, 34),
			Shadow = Color3.fromRGB(20, 20, 20),

			NotificationBackground = Color3.fromRGB(20, 20, 20),
			NotificationActionsBackground = Color3.fromRGB(230, 230, 230),

			TabBackground = Color3.fromRGB(80, 80, 80),
			TabStroke = Color3.fromRGB(85, 85, 85),
			TabBackgroundSelected = Color3.fromRGB(210, 210, 210),
			TabTextColor = Color3.fromRGB(240, 240, 240),
			SelectedTabTextColor = Color3.fromRGB(50, 50, 50),

			ElementBackground = Color3.fromRGB(35, 35, 35),
			ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
			SecondaryElementBackground = Color3.fromRGB(25, 25, 25),
			ElementStroke = Color3.fromRGB(50, 50, 50),
			SecondaryElementStroke = Color3.fromRGB(40, 40, 40),

			SliderBackground = Color3.fromRGB(50, 138, 220),
			SliderProgress = Color3.fromRGB(50, 138, 220),
			SliderStroke = Color3.fromRGB(58, 163, 255),

			ToggleBackground = Color3.fromRGB(30, 30, 30),
			ToggleEnabled = Color3.fromRGB(0, 146, 214),
			ToggleDisabled = Color3.fromRGB(100, 100, 100),
			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
			ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),

			DropdownSelected = Color3.fromRGB(40, 40, 40),
			DropdownUnselected = Color3.fromRGB(30, 30, 30),

			InputBackground = Color3.fromRGB(30, 30, 30),
			InputStroke = Color3.fromRGB(65, 65, 65),
			PlaceholderColor = Color3.fromRGB(178, 178, 178)
		},

		Ocean = {
			TextColor = Color3.fromRGB(230, 240, 240),

			Background = Color3.fromRGB(20, 30, 30),
			Topbar = Color3.fromRGB(25, 40, 40),
			Shadow = Color3.fromRGB(15, 20, 20),

			NotificationBackground = Color3.fromRGB(25, 35, 35),
			NotificationActionsBackground = Color3.fromRGB(230, 240, 240),

			TabBackground = Color3.fromRGB(40, 60, 60),
			TabStroke = Color3.fromRGB(50, 70, 70),
			TabBackgroundSelected = Color3.fromRGB(100, 180, 180),
			TabTextColor = Color3.fromRGB(210, 230, 230),
			SelectedTabTextColor = Color3.fromRGB(20, 50, 50),

			ElementBackground = Color3.fromRGB(30, 50, 50),
			ElementBackgroundHover = Color3.fromRGB(40, 60, 60),
			SecondaryElementBackground = Color3.fromRGB(30, 45, 45),
			ElementStroke = Color3.fromRGB(45, 70, 70),
			SecondaryElementStroke = Color3.fromRGB(40, 65, 65),

			SliderBackground = Color3.fromRGB(0, 110, 110),
			SliderProgress = Color3.fromRGB(0, 140, 140),
			SliderStroke = Color3.fromRGB(0, 160, 160),

			ToggleBackground = Color3.fromRGB(30, 50, 50),
			ToggleEnabled = Color3.fromRGB(0, 130, 130),
			ToggleDisabled = Color3.fromRGB(70, 90, 90),
			ToggleEnabledStroke = Color3.fromRGB(0, 160, 160),
			ToggleDisabledStroke = Color3.fromRGB(85, 105, 105),
			ToggleEnabledOuterStroke = Color3.fromRGB(50, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(45, 65, 65),

			DropdownSelected = Color3.fromRGB(30, 60, 60),
			DropdownUnselected = Color3.fromRGB(25, 40, 40),

			InputBackground = Color3.fromRGB(30, 50, 50),
			InputStroke = Color3.fromRGB(50, 70, 70),
			PlaceholderColor = Color3.fromRGB(140, 160, 160)
		},

		AmberGlow = {
			TextColor = Color3.fromRGB(255, 245, 230),

			Background = Color3.fromRGB(45, 30, 20),
			Topbar = Color3.fromRGB(55, 40, 25),
			Shadow = Color3.fromRGB(35, 25, 15),

			NotificationBackground = Color3.fromRGB(50, 35, 25),
			NotificationActionsBackground = Color3.fromRGB(245, 230, 215),

			TabBackground = Color3.fromRGB(75, 50, 35),
			TabStroke = Color3.fromRGB(90, 60, 45),
			TabBackgroundSelected = Color3.fromRGB(230, 180, 100),
			TabTextColor = Color3.fromRGB(250, 220, 200),
			SelectedTabTextColor = Color3.fromRGB(50, 30, 10),

			ElementBackground = Color3.fromRGB(60, 45, 35),
			ElementBackgroundHover = Color3.fromRGB(70, 50, 40),
			SecondaryElementBackground = Color3.fromRGB(55, 40, 30),
			ElementStroke = Color3.fromRGB(85, 60, 45),
			SecondaryElementStroke = Color3.fromRGB(75, 50, 35),

			SliderBackground = Color3.fromRGB(220, 130, 60),
			SliderProgress = Color3.fromRGB(250, 150, 75),
			SliderStroke = Color3.fromRGB(255, 170, 85),

			ToggleBackground = Color3.fromRGB(55, 40, 30),
			ToggleEnabled = Color3.fromRGB(240, 130, 30),
			ToggleDisabled = Color3.fromRGB(90, 70, 60),
			ToggleEnabledStroke = Color3.fromRGB(255, 160, 50),
			ToggleDisabledStroke = Color3.fromRGB(110, 85, 75),
			ToggleEnabledOuterStroke = Color3.fromRGB(200, 100, 50),
			ToggleDisabledOuterStroke = Color3.fromRGB(75, 60, 55),

			DropdownSelected = Color3.fromRGB(70, 50, 40),
			DropdownUnselected = Color3.fromRGB(55, 40, 30),

			InputBackground = Color3.fromRGB(60, 45, 35),
			InputStroke = Color3.fromRGB(90, 65, 50),
			PlaceholderColor = Color3.fromRGB(190, 150, 130)
		},

		Light = {
			TextColor = Color3.fromRGB(40, 40, 40),

			Background = Color3.fromRGB(245, 245, 245),
			Topbar = Color3.fromRGB(230, 230, 230),
			Shadow = Color3.fromRGB(200, 200, 200),

			NotificationBackground = Color3.fromRGB(250, 250, 250),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 240),

			TabBackground = Color3.fromRGB(235, 235, 235),
			TabStroke = Color3.fromRGB(215, 215, 215),
			TabBackgroundSelected = Color3.fromRGB(255, 255, 255),
			TabTextColor = Color3.fromRGB(80, 80, 80),
			SelectedTabTextColor = Color3.fromRGB(0, 0, 0),

			ElementBackground = Color3.fromRGB(240, 240, 240),
			ElementBackgroundHover = Color3.fromRGB(225, 225, 225),
			SecondaryElementBackground = Color3.fromRGB(235, 235, 235),
			ElementStroke = Color3.fromRGB(210, 210, 210),
			SecondaryElementStroke = Color3.fromRGB(210, 210, 210),

			SliderBackground = Color3.fromRGB(150, 180, 220),
			SliderProgress = Color3.fromRGB(100, 150, 200), 
			SliderStroke = Color3.fromRGB(120, 170, 220),

			ToggleBackground = Color3.fromRGB(220, 220, 220),
			ToggleEnabled = Color3.fromRGB(0, 146, 214),
			ToggleDisabled = Color3.fromRGB(150, 150, 150),
			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
			ToggleDisabledStroke = Color3.fromRGB(170, 170, 170),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(180, 180, 180),

			DropdownSelected = Color3.fromRGB(230, 230, 230),
			DropdownUnselected = Color3.fromRGB(220, 220, 220),

			InputBackground = Color3.fromRGB(240, 240, 240),
			InputStroke = Color3.fromRGB(180, 180, 180),
			PlaceholderColor = Color3.fromRGB(140, 140, 140)
		},

		Amethyst = {
			TextColor = Color3.fromRGB(240, 240, 240),

			Background = Color3.fromRGB(30, 20, 40),
			Topbar = Color3.fromRGB(40, 25, 50),
			Shadow = Color3.fromRGB(20, 15, 30),

			NotificationBackground = Color3.fromRGB(35, 20, 40),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 250),

			TabBackground = Color3.fromRGB(60, 40, 80),
			TabStroke = Color3.fromRGB(70, 45, 90),
			TabBackgroundSelected = Color3.fromRGB(180, 140, 200),
			TabTextColor = Color3.fromRGB(230, 230, 240),
			SelectedTabTextColor = Color3.fromRGB(50, 20, 50),

			ElementBackground = Color3.fromRGB(45, 30, 60),
			ElementBackgroundHover = Color3.fromRGB(50, 35, 70),
			SecondaryElementBackground = Color3.fromRGB(40, 30, 55),
			ElementStroke = Color3.fromRGB(70, 50, 85),
			SecondaryElementStroke = Color3.fromRGB(65, 45, 80),

			SliderBackground = Color3.fromRGB(100, 60, 150),
			SliderProgress = Color3.fromRGB(130, 80, 180),
			SliderStroke = Color3.fromRGB(150, 100, 200),

			ToggleBackground = Color3.fromRGB(45, 30, 55),
			ToggleEnabled = Color3.fromRGB(120, 60, 150),
			ToggleDisabled = Color3.fromRGB(94, 47, 117),
			ToggleEnabledStroke = Color3.fromRGB(140, 80, 170),
			ToggleDisabledStroke = Color3.fromRGB(124, 71, 150),
			ToggleEnabledOuterStroke = Color3.fromRGB(90, 40, 120),
			ToggleDisabledOuterStroke = Color3.fromRGB(80, 50, 110),

			DropdownSelected = Color3.fromRGB(50, 35, 70),
			DropdownUnselected = Color3.fromRGB(35, 25, 50),

			InputBackground = Color3.fromRGB(45, 30, 60),
			InputStroke = Color3.fromRGB(80, 50, 110),
			PlaceholderColor = Color3.fromRGB(178, 150, 200)
		},

		Green = {
			TextColor = Color3.fromRGB(30, 60, 30),

			Background = Color3.fromRGB(235, 245, 235),
			Topbar = Color3.fromRGB(210, 230, 210),
			Shadow = Color3.fromRGB(200, 220, 200),

			NotificationBackground = Color3.fromRGB(240, 250, 240),
			NotificationActionsBackground = Color3.fromRGB(220, 235, 220),

			TabBackground = Color3.fromRGB(215, 235, 215),
			TabStroke = Color3.fromRGB(190, 210, 190),
			TabBackgroundSelected = Color3.fromRGB(245, 255, 245),
			TabTextColor = Color3.fromRGB(50, 80, 50),
			SelectedTabTextColor = Color3.fromRGB(20, 60, 20),

			ElementBackground = Color3.fromRGB(225, 240, 225),
			ElementBackgroundHover = Color3.fromRGB(210, 225, 210),
			SecondaryElementBackground = Color3.fromRGB(235, 245, 235), 
			ElementStroke = Color3.fromRGB(180, 200, 180),
			SecondaryElementStroke = Color3.fromRGB(180, 200, 180),

			SliderBackground = Color3.fromRGB(90, 160, 90),
			SliderProgress = Color3.fromRGB(70, 130, 70),
			SliderStroke = Color3.fromRGB(100, 180, 100),

			ToggleBackground = Color3.fromRGB(215, 235, 215),
			ToggleEnabled = Color3.fromRGB(60, 130, 60),
			ToggleDisabled = Color3.fromRGB(150, 175, 150),
			ToggleEnabledStroke = Color3.fromRGB(80, 150, 80),
			ToggleDisabledStroke = Color3.fromRGB(130, 150, 130),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 160, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(160, 180, 160),

			DropdownSelected = Color3.fromRGB(225, 240, 225),
			DropdownUnselected = Color3.fromRGB(210, 225, 210),

			InputBackground = Color3.fromRGB(235, 245, 235),
			InputStroke = Color3.fromRGB(180, 200, 180),
			PlaceholderColor = Color3.fromRGB(120, 140, 120)
		},

		Bloom = {
			TextColor = Color3.fromRGB(60, 40, 50),

			Background = Color3.fromRGB(255, 240, 245),
			Topbar = Color3.fromRGB(250, 220, 225),
			Shadow = Color3.fromRGB(230, 190, 195),

			NotificationBackground = Color3.fromRGB(255, 235, 240),
			NotificationActionsBackground = Color3.fromRGB(245, 215, 225),

			TabBackground = Color3.fromRGB(240, 210, 220),
			TabStroke = Color3.fromRGB(230, 200, 210),
			TabBackgroundSelected = Color3.fromRGB(255, 225, 235),
			TabTextColor = Color3.fromRGB(80, 40, 60),
			SelectedTabTextColor = Color3.fromRGB(50, 30, 50),

			ElementBackground = Color3.fromRGB(255, 235, 240),
			ElementBackgroundHover = Color3.fromRGB(245, 220, 230),
			SecondaryElementBackground = Color3.fromRGB(255, 235, 240), 
			ElementStroke = Color3.fromRGB(230, 200, 210),
			SecondaryElementStroke = Color3.fromRGB(230, 200, 210),

			SliderBackground = Color3.fromRGB(240, 130, 160),
			SliderProgress = Color3.fromRGB(250, 160, 180),
			SliderStroke = Color3.fromRGB(255, 180, 200),

			ToggleBackground = Color3.fromRGB(240, 210, 220),
			ToggleEnabled = Color3.fromRGB(255, 140, 170),
			ToggleDisabled = Color3.fromRGB(200, 180, 185),
			ToggleEnabledStroke = Color3.fromRGB(250, 160, 190),
			ToggleDisabledStroke = Color3.fromRGB(210, 180, 190),
			ToggleEnabledOuterStroke = Color3.fromRGB(220, 160, 180),
			ToggleDisabledOuterStroke = Color3.fromRGB(190, 170, 180),

			DropdownSelected = Color3.fromRGB(250, 220, 225),
			DropdownUnselected = Color3.fromRGB(240, 210, 220),

			InputBackground = Color3.fromRGB(255, 235, 240),
			InputStroke = Color3.fromRGB(220, 190, 200),
			PlaceholderColor = Color3.fromRGB(170, 130, 140)
		},

		DarkBlue = {
			TextColor = Color3.fromRGB(230, 230, 230),

			Background = Color3.fromRGB(20, 25, 30),
			Topbar = Color3.fromRGB(30, 35, 40),
			Shadow = Color3.fromRGB(15, 20, 25),

			NotificationBackground = Color3.fromRGB(25, 30, 35),
			NotificationActionsBackground = Color3.fromRGB(45, 50, 55),

			TabBackground = Color3.fromRGB(35, 40, 45),
			TabStroke = Color3.fromRGB(45, 50, 60),
			TabBackgroundSelected = Color3.fromRGB(40, 70, 100),
			TabTextColor = Color3.fromRGB(200, 200, 200),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),

			ElementBackground = Color3.fromRGB(30, 35, 40),
			ElementBackgroundHover = Color3.fromRGB(40, 45, 50),
			SecondaryElementBackground = Color3.fromRGB(35, 40, 45), 
			ElementStroke = Color3.fromRGB(45, 50, 60),
			SecondaryElementStroke = Color3.fromRGB(40, 45, 55),

			SliderBackground = Color3.fromRGB(0, 90, 180),
			SliderProgress = Color3.fromRGB(0, 120, 210),
			SliderStroke = Color3.fromRGB(0, 150, 240),

			ToggleBackground = Color3.fromRGB(35, 40, 45),
			ToggleEnabled = Color3.fromRGB(0, 120, 210),
			ToggleDisabled = Color3.fromRGB(70, 70, 80),
			ToggleEnabledStroke = Color3.fromRGB(0, 150, 240),
			ToggleDisabledStroke = Color3.fromRGB(75, 75, 85),
			ToggleEnabledOuterStroke = Color3.fromRGB(20, 100, 180), 
			ToggleDisabledOuterStroke = Color3.fromRGB(55, 55, 65),

			DropdownSelected = Color3.fromRGB(30, 70, 90),
			DropdownUnselected = Color3.fromRGB(25, 30, 35),

			InputBackground = Color3.fromRGB(25, 30, 35),
			InputStroke = Color3.fromRGB(45, 50, 60), 
			PlaceholderColor = Color3.fromRGB(150, 150, 160)
		},

		Serenity = {
			TextColor = Color3.fromRGB(50, 55, 60),
			Background = Color3.fromRGB(240, 245, 250),
			Topbar = Color3.fromRGB(215, 225, 235),
			Shadow = Color3.fromRGB(200, 210, 220),

			NotificationBackground = Color3.fromRGB(210, 220, 230),
			NotificationActionsBackground = Color3.fromRGB(225, 230, 240),

			TabBackground = Color3.fromRGB(200, 210, 220),
			TabStroke = Color3.fromRGB(180, 190, 200),
			TabBackgroundSelected = Color3.fromRGB(175, 185, 200),
			TabTextColor = Color3.fromRGB(50, 55, 60),
			SelectedTabTextColor = Color3.fromRGB(30, 35, 40),

			ElementBackground = Color3.fromRGB(210, 220, 230),
			ElementBackgroundHover = Color3.fromRGB(220, 230, 240),
			SecondaryElementBackground = Color3.fromRGB(200, 210, 220),
			ElementStroke = Color3.fromRGB(190, 200, 210),
			SecondaryElementStroke = Color3.fromRGB(180, 190, 200),

			SliderBackground = Color3.fromRGB(200, 220, 235),
			SliderProgress = Color3.fromRGB(70, 130, 180),
			SliderStroke = Color3.fromRGB(150, 180, 220),

			ToggleBackground = Color3.fromRGB(210, 220, 230),
			ToggleEnabled = Color3.fromRGB(70, 160, 210),
			ToggleDisabled = Color3.fromRGB(180, 180, 180),
			ToggleEnabledStroke = Color3.fromRGB(60, 150, 200),
			ToggleDisabledStroke = Color3.fromRGB(140, 140, 140),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 120, 140),
			ToggleDisabledOuterStroke = Color3.fromRGB(120, 120, 130),

			DropdownSelected = Color3.fromRGB(220, 230, 240),
			DropdownUnselected = Color3.fromRGB(200, 210, 220),

			InputBackground = Color3.fromRGB(220, 230, 240),
			InputStroke = Color3.fromRGB(180, 190, 200),
			PlaceholderColor = Color3.fromRGB(150, 150, 150)
		},
	}
}

-- Interface Management
local NovaAssetId = customAssetId or 10804731440
local NovaUI = useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://"..NovaAssetId)[1]

local buildAttempts = 0
local correctBuild = false
local warned
local globalLoaded
local novaDestroyed = false

repeat
	if NovaUI:FindFirstChild('Build') and NovaUI.Build.Value == InterfaceBuild then
		correctBuild = true
		break
	end

	correctBuild = false

	if not warned then
		warn('NovaUI | Build Mismatch')
		warned = true
	end

	local toDestroy
	toDestroy, NovaUI = NovaUI, useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://"..NovaAssetId)[1]
	if toDestroy and not useStudio then toDestroy:Destroy() end

	buildAttempts = buildAttempts + 1
until buildAttempts >= 2

-- REEMPLAZO Y ADAPTACIÓN COMPLETA DE NOMBRES Y PANTALLA DE PRESENTACIÓN A NOVAUI
if NovaUI then
	NovaUI.Name = "NovaUI"
	for _, descendant in ipairs(NovaUI:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
			if string.find(descendant.Text, "Rayfield") then
				descendant.Text = string.gsub(descendant.Text, "Rayfield", "NovaUI")
			end
		end
	end
end

NovaUI.Enabled = false

if gethui then
	NovaUI.Parent = gethui()
elseif syn and syn.protect_gui then 
	syn.protect_gui(NovaUI)
	NovaUI.Parent = CoreGui
elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
	NovaUI.Parent = CoreGui:FindFirstChild("RobloxGui")
elseif not useStudio then
	NovaUI.Parent = CoreGui
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == NovaUI.Name and Interface ~= NovaUI then
			Interface.Enabled = false
			Interface.Name = "NovaUI-Old"
		end
	end
elseif not useStudio then
	for _, Interface in ipairs(CoreGui:GetChildren()) do
		if Interface.Name == NovaUI.Name and Interface ~= NovaUI then
			Interface.Enabled = false
			Interface.Name = "NovaUI-Old"
		end
	end
end

do
	local AssetPath = NovaUIFolder.."/Assets"
	local AssetBaseURL = "https://github.com/SiriusSoftwareLtd/Rayfield/blob/main/assets/"

	local assetFiles = {
		["111263549366178"] = AssetBaseURL.."111263549366178.png?raw=true",
		["77891951053543"] = AssetBaseURL.."77891951053543.png?raw=true",
		["78137979054938"] = AssetBaseURL.."78137979054938.png?raw=true",
		["80503127983237"] = AssetBaseURL.."80503127983237.png?raw=true",
		["10137832201"] = AssetBaseURL.."10137832201.png?raw=true",
		["10137941941"] = AssetBaseURL.."10137941941.png?raw=true",
		["11036884234"] = AssetBaseURL.."11036884234.png?raw=true",
		["11413591840"] = AssetBaseURL.."11413591840.png?raw=true",
		["11745872910"] = AssetBaseURL.."11745872910.png?raw=true",
		["12577727209"] = AssetBaseURL.."12577727209.png?raw=true",
		["18458939117"] = AssetBaseURL.."18458939117.png?raw=true",
		["3259050989"] = AssetBaseURL.."3259050989.png?raw=true",
		["3523728077"] = AssetBaseURL.."3523728077.png?raw=true",
		["3602733521"] = AssetBaseURL.."3602733521.png?raw=true",
		["IconChevronTopMedium"] = AssetBaseURL.."IconChevronTopMedium.png?raw=true",
		["4483362458"] = AssetBaseURL.."4483362458.png?raw=true",
		["5587865193"] = AssetBaseURL.."5587865193.png?raw=true",
		["IconMagnifyingGlass2"] = AssetBaseURL.."IconMagnifyingGlass2.png?raw=true",
	}

	for id, _ in assetFiles do
		customAssets[tostring(id)] = ""
	end

	local hasCustomAsset = type(getcustomasset) == "function"
	local hasFilesystem = type(writefile) == "function" and type(makefolder) == "function" and type(isfile) == "function" and type(isfolder) == "function"

	if hasCustomAsset and hasFilesystem then
		pcall(function()
			ensureFolder(NovaUIFolder)
			ensureFolder(AssetPath)

			local attempted = {}
			local function nextToFetch()
				for id, _ in assetFiles do
					if not attempted[id] and not isfile(AssetPath.."/"..tostring(id)..".png") then
						return id
					end
				end
				return nil
			end

			if nextToFetch() then
				task.spawn(function()
					while true do
						local id = nextToFetch()
						if not id then break end
						local ok, res = pcall(requestFunc, {Url = assetFiles[id], Method = "GET"})
						if ok and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
							pcall(writefile, AssetPath.."/"..tostring(id)..".png", res.Body)
						end
						attempted[id] = true
						task.wait()
					end
				end)

				while nextToFetch() do
					task.wait(0.1)
				end
			end

			for id, _ in assetFiles do
				local success, asset = pcall(getcustomasset, AssetPath.."/"..tostring(id)..".png")
				if success then customAssets[tostring(id)] = asset end
			end
		end)
	end

	NovaUI.Main.Shadow.Image.Image = customAssets[tostring(5587865193)]
	NovaUI.Main.Topbar.Hide.Image = customAssets[tostring(10137832201)]
	NovaUI.Main.Topbar.ChangeSize.Image = customAssets[tostring(10137941941)]
	NovaUI.Main.Topbar.Settings.Image = customAssets[tostring(80503127983237)]
	NovaUI.Main.Topbar.Icon.Image = customAssets[tostring(78137979054938)]
	NovaUI.Main.Topbar.Search.Image = customAssets["IconMagnifyingGlass2"]
	NovaUI.Main.Elements.Template.Toggle.Switch.Shadow.Image = customAssets[tostring(3602733521)]
	NovaUI.Main.Elements.Template.Slider.Main.Shadow.Image = customAssets[tostring(3602733521)]
	NovaUI.Main.Elements.Template.Dropdown.Toggle.Image = customAssets["IconChevronTopMedium"]
	NovaUI.Main.Elements.Template.Label.Icon.Image = customAssets[tostring(11745872910)]
	NovaUI.Main.Elements.Template.ColorPicker.CPBackground.MainCP.Image = customAssets[tostring(11413591840)]
	NovaUI.Main.Elements.Template.ColorPicker.CPBackground.MainCP.MainPoint.Image = customAssets[tostring(3259050989)]
	NovaUI.Main.Elements.Template.ColorPicker.ColorSlider.SliderPoint.Image = customAssets[tostring(3259050989)]
	NovaUI.Main.TabList.Template.Image.Image = customAssets[tostring(4483362458)]
	NovaUI.Main.Search.Search.Image = customAssets[tostring(18458939117)]
	NovaUI.Main.Search.Shadow.Image = customAssets[tostring(5587865193)]
	NovaUI.Notifications.Template.Icon.Image = customAssets[tostring(77891951053543)]
	NovaUI.Notifications.Template.Shadow.Image = customAssets[tostring(3523728077)]
	NovaUI.Loading.Banner.Image = customAssets[tostring(111263549366178)]
end

local minSize = Vector2.new(1024, 768)
local useMobileSizing

if NovaUI.AbsoluteSize.X < minSize.X and NovaUI.AbsoluteSize.Y < minSize.Y then
	useMobileSizing = true
end

local useMobilePrompt = false
if UserInputService.TouchEnabled then
	useMobilePrompt = true
end

-- Object Variables
local Main = NovaUI.Main
local MPrompt = NovaUI:FindFirstChild('Prompt')
local Topbar = Main.Topbar
local Elements = Main.Elements
local LoadingFrame = Main.LoadingFrame
local TabList = Main.TabList
local dragBar = NovaUI:FindFirstChild('Drag')
local dragInteract = dragBar and dragBar.Interact or nil
local dragBarCosmetic = dragBar and dragBar.Drag or nil

local dragOffset = 255
local dragOffsetMobile = 150

NovaUI.DisplayOrder = 100
LoadingFrame.Version.Text = Release

local Icons = useStudio and require(script.Parent.icons) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua')

-- Variables
local CFileName = nil
local CEnabled = false
local Minimised = false
local Hidden = false
local Debounce = false
local searchOpen = false
local Notifications = NovaUI.Notifications
local keybindConnections = {}

local SelectedTheme = NovaUILibrary.Theme.Default

local function ChangeTheme(Theme)
	if typeof(Theme) == 'string' then
		SelectedTheme = NovaUILibrary.Theme[Theme]
	elseif typeof(Theme) == 'table' then
		SelectedTheme = Theme
	end

	NovaUI.Main.BackgroundColor3 = SelectedTheme.Background
	NovaUI.Main.Topbar.BackgroundColor3 = SelectedTheme.Topbar
	NovaUI.Main.Topbar.CornerRepair.BackgroundColor3 = SelectedTheme.Topbar
	NovaUI.Main.Shadow.Image.ImageColor3 = SelectedTheme.Shadow

	NovaUI.Main.Topbar.ChangeSize.ImageColor3 = SelectedTheme.TextColor
	NovaUI.Main.Topbar.Hide.ImageColor3 = SelectedTheme.TextColor
	NovaUI.Main.Topbar.Search.ImageColor3 = SelectedTheme.TextColor
	if Topbar:FindFirstChild('Settings') then
		NovaUI.Main.Topbar.Settings.ImageColor3 = SelectedTheme.TextColor
		NovaUI.Main.Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
	end

	Main.Search.BackgroundColor3 = SelectedTheme.TextColor
	Main.Search.Shadow.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Search.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Input.PlaceholderColor3 = SelectedTheme.TextColor
	Main.Search.UIStroke.Color = SelectedTheme.SecondaryElementStroke

	if Main:FindFirstChild('Notice') then
		Main.Notice.BackgroundColor3 = SelectedTheme.Background
	end

	for _, text in ipairs(NovaUI:GetDescendants()) do
		if text.Parent.Parent ~= Notifications then
			if text:IsA('TextLabel') or text:IsA('TextBox') then text.TextColor3 = SelectedTheme.TextColor end
		end
	end

	for _, TabPage in ipairs(Elements:GetChildren()) do
		for _, Element in ipairs(TabPage:GetChildren()) do
			if Element.ClassName == "Frame" and Element.Name ~= "Placeholder" and Element.Name ~= "SectionSpacing" and Element.Name ~= "Divider" and Element.Name ~= "SectionTitle" and Element.Name ~= "SearchTitle-fsefsefesfsefesfesfThanks" then
				Element.BackgroundColor3 = SelectedTheme.ElementBackground
				Element.UIStroke.Color = SelectedTheme.ElementStroke
			end
		end
	end
end

local function getIcon(name : string): {id: number, imageRectSize: Vector2, imageRectOffset: Vector2}
	if not Icons then
		warn("Lucide Icons: Cannot use icons as icons library is not loaded")
		return
	end
	name = string.match(string.lower(name), "^%s*(.*)%s*$") :: string
	local sizedicons = Icons['48px']
	local r = sizedicons[name]
	if not r then
		error("Lucide Icons: Failed to find icon by the name of \"" .. name .. "\"", 2)
	end

	local rirs = r[2]
	local riro = r[3]

	local irs = Vector2.new(rirs[1], rirs[2])
	local iro = Vector2.new(riro[1], riro[2])

	local asset = {
		id = r[1],
		imageRectSize = irs,
		imageRectOffset = iro,
	}

	return asset
end

local function getAssetUri(id: any): string
	local assetUri = ""
	if type(id) == "number" then
		assetUri = "rbxassetid://" .. id
	elseif type(id) == "string" and not Icons then
		warn("NovaUI | Cannot use Lucide icons as icons library is not loaded")
	else
		warn("NovaUI | The icon argument must either be an icon ID (number) or a Lucide icon name (string)")
	end
	return assetUri
end

local function isCustomAsset(value)
	return type(value) == "string" and (string.find(value, "rbxasset://") == 1 or string.find(value, "rbxthumb://") == 1)
end

local function resolveIcon(icon)
	if not icon or icon == 0 then
		return "", nil, nil
	end

	if isCustomAsset(icon) then
		return icon, nil, nil
	end

	if typeof(icon) == "string" and Icons then
		local asset = getIcon(icon)
		return "rbxassetid://" .. asset.id, asset.imageRectOffset, asset.imageRectSize
	else
		return getAssetUri(icon), nil, nil
	end
end

local function makeDraggable(object, dragObject, enableTaptic, tapticOffset)
	local dragging = false
	local relative = nil

	local offset = Vector2.zero
	local screenGui = object:FindFirstAncestorWhichIsA("ScreenGui")
	if screenGui and screenGui.IgnoreGuiInset then
		offset += getService('GuiService'):GetGuiInset()
	end

	dragObject.InputBegan:Connect(function(input, processed)
		if processed then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = true
			relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - UserInputService:GetMouseLocation()
			if enableTaptic and not Hidden then
				TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 110, 0, 4), BackgroundTransparency = 0}):Play()
			end
		end
	end)

	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = false
			if enableTaptic and not Hidden then
				TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 100, 0, 4), BackgroundTransparency = 0.7}):Play()
			end
		end
	end)

	local renderStepped = RunService.RenderStepped:Connect(function()
		if dragging and not Hidden then
			local position = UserInputService:GetMouseLocation() + relative + offset
			if enableTaptic and tapticOffset then
				TweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y)}):Play()
				TweenService:Create(dragObject.Parent, TweenInfo.new(0.05, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))}):Play()
			else
				if dragBar and tapticOffset then
					dragBar.Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))
				end
				object.Position = UDim2.fromOffset(position.X, position.Y)
			end
		end
	end)

	object.Destroying:Connect(function()
		if inputEnded then inputEnded:Disconnect() end
		if renderStepped then renderStepped:Disconnect() end
	end)
end

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadConfiguration(Configuration)
	local success, Data = pcall(function() return HttpService:JSONDecode(Configuration) end)
	local changed

	if not success then warn('NovaUI had an issue decoding the configuration file.') return end

	for FlagName, Flag in pairs(NovaUILibrary.Flags) do
		local FlagValue = Data[FlagName]

		if (typeof(FlagValue) == 'boolean' and FlagValue == false) or FlagValue then
			task.spawn(function()
				if Flag.Type == "ColorPicker" then
					changed = true
					Flag:Set(UnpackColor(FlagValue))
				else
					if (Flag.CurrentValue or Flag.CurrentKeybind or Flag.CurrentOption or Flag.Color) ~= FlagValue then 
						changed = true
						Flag:Set(FlagValue) 	
					end
				end
			end)
		else
			warn("NovaUI | Unable to find '"..FlagName.. "' in the save file.")
		end
	end

	return changed
end

local function SaveConfiguration()
	if not CEnabled or not globalLoaded then return end

	local Data = {}
	for i, v in pairs(NovaUILibrary.Flags) do
		if v.Type == "ColorPicker" then
			Data[i] = PackColor(v.Color)
		else
			if typeof(v.CurrentValue) == 'boolean' then
				if v.CurrentValue == false then
					Data[i] = false
				else
					Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
				end
			else
				Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
			end
		end
	end

	callSafely(writefile, ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension, tostring(HttpService:JSONEncode(Data)))
end

function NovaUILibrary:Notify(data)
	task.spawn(function()
		local newNotification = Notifications.Template:Clone()
		newNotification.Name = data.Title or 'NovaUI'
		newNotification.Parent = Notifications
		newNotification.LayoutOrder = #Notifications:GetChildren()
		newNotification.Visible = false

		newNotification.Title.Text = data.Title or "NovaUI"
		newNotification.Description.Text = data.Content or ""

		if data.Image then
			local img, rectOffset, rectSize = resolveIcon(data.Image)
			newNotification.Icon.Image = img
			if rectOffset then newNotification.Icon.ImageRectOffset = rectOffset end
			if rectSize then newNotification.Icon.ImageRectSize = rectSize end
		else
			newNotification.Icon.Image = ""
		end

		newNotification.Title.TextColor3 = SelectedTheme.TextColor
		newNotification.Description.TextColor3 = SelectedTheme.TextColor
		newNotification.BackgroundColor3 = SelectedTheme.Background
		newNotification.UIStroke.Color = SelectedTheme.TextColor
		newNotification.Icon.ImageColor3 = SelectedTheme.TextColor

		newNotification.BackgroundTransparency = 1
		newNotification.Title.TextTransparency = 1
		newNotification.Description.TextTransparency = 1
		newNotification.UIStroke.Transparency = 1
		newNotification.Shadow.ImageTransparency = 1
		newNotification.Size = UDim2.new(1, 0, 0, 800)

		task.wait()
		newNotification.Visible = true

		local bounds = {newNotification.Title.TextBounds.Y, newNotification.Description.TextBounds.Y}
		newNotification.Size = UDim2.new(1, -60, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)

		TweenService:Create(newNotification, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, math.max(bounds[1] + bounds[2] + 31, 60))}):Play()
		task.wait(0.15)
		TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.45}):Play()
		TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
		TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.35}):Play()
		TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.95}):Play()

		task.wait(data.Duration or 5)

		TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
		TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		task.wait(0.4)
		newNotification:Destroy()
	end)
end

local function closeSearch()
	searchOpen = false

	TweenService:Create(Main.Search, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {BackgroundTransparency = 1, Size = UDim2.new(1, -55, 0, 30)}):Play()
	TweenService:Create(Main.Search.Search, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	TweenService:Create(Main.Search.Shadow, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
	TweenService:Create(Main.Search.UIStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
	TweenService:Create(Main.Search.Input, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()

	for _, tabbtn in ipairs(TabList:GetChildren()) do
		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
			tabbtn.Interact.Visible = true
		end
	end

	Main.Search.Input.Text = ''
	Main.Search.Input.Interactable = false
end

local function Hide(notify: boolean?)
	if MPrompt then
		MPrompt.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		MPrompt.Position = UDim2.new(0.5, 0, 0, -50)
		MPrompt.Size = UDim2.new(0, 40, 0, 10)
		MPrompt.BackgroundTransparency = 1
		MPrompt.Title.TextTransparency = 1
		MPrompt.Visible = true
	end

	task.spawn(closeSearch)

	Debounce = true
	if notify then
		NovaUILibrary:Notify({Title = "Interfaz Oculta", Content = "La interfaz se ha ocultado, toca 'Show NovaUI' para volver a mostrarla.", Duration = 7})
	end

	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 470, 0, 0)}):Play()
	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 470, 0, 45)}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()

	if useMobilePrompt and MPrompt then
		TweenService:Create(MPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 140, 0, 30), Position = UDim2.new(0.5, 0, 0, 20), BackgroundTransparency = 0.3}):Play()
		TweenService:Create(MPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.3}):Play()
	end

	task.wait(0.5)
	Main.Visible = false
	Debounce = false
end

local function Maximise()
	Debounce = true
	Topbar.ChangeSize.Image = customAssets[tostring(10137941941)]

	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}):Play()
	TweenService:Create(Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 45)}):Play()
	TabList.Visible = true
	Elements.Visible = true

	task.wait(0.5)
	Debounce = false
end

local function Unhide()
	Debounce = true
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.Visible = true
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}):Play()
	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 45)}):Play()
	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()

	if MPrompt then
		TweenService:Create(MPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 40, 0, 10), Position = UDim2.new(0.5, 0, 0, -50), BackgroundTransparency = 1}):Play()
		TweenService:Create(MPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
		task.spawn(function()
			task.wait(0.5)
			MPrompt.Visible = false
		end)
	end

	if Minimised then
		task.spawn(Maximise)
	end

	task.wait(0.5)
	Minimised = false
	Debounce = false
end

local function Minimise()
	Debounce = true
	Topbar.ChangeSize.Image = customAssets[tostring(11036884234)]

	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 495, 0, 45)}):Play()
	TweenService:Create(Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 495, 0, 45)}):Play()

	task.wait(0.3)
	Elements.Visible = false
	TabList.Visible = false

	task.wait(0.2)
	Debounce = false
end

function NovaUILibrary:CreateWindow(Settings)
	-- PANTALLA DE CARGA (SPLASH PRESENTATION)
	if NovaUI:FindFirstChild('Loading') then
		if getgenv and not getgenv().novaCached then
			NovaUI.Enabled = true
			NovaUI.Loading.Visible = true

			if NovaUI.Loading:FindFirstChild("Title") then
				NovaUI.Loading.Title.Text = "NovaUI"
			end

			task.wait(1.4)
			NovaUI.Loading.Visible = false
		end
	end

	if getgenv then getgenv().novaCached = true end

	ensureFolder(NovaUIFolder)

	Topbar.Title.Text = Settings.Name or "NovaUI"

	Main.Size = UDim2.new(0, 420, 0, 100)
	Main.Visible = true
	Main.BackgroundTransparency = 1

	-- PREDETERMINADO 'Show NovaUI' SI NO SE PROPORCIONA SHOWTEXT
	if MPrompt then
		if Settings.ShowText then
			MPrompt.Title.Text = 'Show '..Settings.ShowText
		else
			MPrompt.Title.Text = 'Show NovaUI'
		end
	end

	LoadingFrame.Title.Text = Settings.LoadingTitle or "NovaUI"
	LoadingFrame.Subtitle.Text = Settings.LoadingSubtitle or "Interface Suite"
	LoadingFrame.Version.Text = "NovaUI Engine"

	makeDraggable(Main, Topbar, false, {dragOffset, dragOffsetMobile})

	if Settings.Theme then
		pcall(ChangeTheme, Settings.Theme)
	end

	Notifications.Template.Visible = false
	Notifications.Visible = true
	NovaUI.Enabled = true

	task.wait(0.5)
	TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
	TweenService:Create(LoadingFrame.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
	TweenService:Create(LoadingFrame.Subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

	Elements.Template.Visible = false
	Elements.UIPageLayout.FillDirection = Enum.FillDirection.Horizontal
	TabList.Template.Visible = false

	local FirstTab = false
	local Window = {}

	function Window:CreateTab(Name, Image, Ext)
		local TabButton = TabList.Template:Clone()
		TabButton.Name = Name
		TabButton.Title.Text = Name
		TabButton.Parent = TabList
		TabButton.Visible = true

		local TabPage = Elements.Template:Clone()
		TabPage.Name = Name
		TabPage.Visible = true
		TabPage.Parent = Elements

		if not FirstTab then
			FirstTab = Name
			Elements.UIPageLayout:JumpTo(TabPage)
		end

		TabButton.Interact.MouseButton1Click:Connect(function()
			Elements.UIPageLayout:JumpTo(TabPage)
		end)

		local Tab = {}

		function Tab:CreateButton(ButtonSettings)
			local Button = Elements.Template.Button:Clone()
			Button.Name = ButtonSettings.Name
			Button.Title.Text = ButtonSettings.Name
			Button.Visible = true
			Button.Parent = TabPage

			Button.Interact.MouseButton1Click:Connect(function()
				pcall(ButtonSettings.Callback)
			end)
			return Button
		end

		function Tab:CreateToggle(ToggleSettings)
			local Toggle = Elements.Template.Toggle:Clone()
			Toggle.Name = ToggleSettings.Name
			Toggle.Title.Text = ToggleSettings.Name
			Toggle.Visible = true
			Toggle.Parent = TabPage

			Toggle.Interact.MouseButton1Click:Connect(function()
				ToggleSettings.CurrentValue = not ToggleSettings.CurrentValue
				pcall(ToggleSettings.Callback, ToggleSettings.CurrentValue)
			end)
			return Toggle
		end

		function Tab:CreateSlider(SliderSettings)
			local Slider = Elements.Template.Slider:Clone()
			Slider.Name = SliderSettings.Name
			Slider.Title.Text = SliderSettings.Name
			Slider.Visible = true
			Slider.Parent = TabPage
			
			local SLDragging = false
			Slider.Main.Interact.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
					SLDragging = true 
				end 
			end)

			Slider.Main.Interact.InputEnded:Connect(function(Input) 
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
					SLDragging = false 
				end 
			end)

			RunService.RenderStepped:Connect(function()
				if SLDragging then
					local mousePos = UserInputService:GetMouseLocation().X
					local relativePos = mousePos - Slider.Main.AbsolutePosition.X
					local percentage = math.clamp(relativePos / Slider.Main.AbsoluteSize.X, 0, 1)
					local value = math.floor(SliderSettings.Range[1] + (percentage * (SliderSettings.Range[2] - SliderSettings.Range[1])))
					
					Slider.Main.Progress.Size = UDim2.new(percentage, 0, 1, 0)
					Slider.Main.Information.Text = tostring(value) .. " " .. (SliderSettings.Suffix or "")
					
					if value ~= SliderSettings.CurrentValue then
						SliderSettings.CurrentValue = value
						pcall(SliderSettings.Callback, value)
					end
				end
			end)

			return Slider
		end

		function Tab:CreateInput(InputSettings)
			local Input = Elements.Template.Input:Clone()
			Input.Name = InputSettings.Name
			Input.Title.Text = InputSettings.Name
			Input.Visible = true
			Input.Parent = TabPage

			Input.InputFrame.InputBox.FocusLost:Connect(function()
				pcall(InputSettings.Callback, Input.InputFrame.InputBox.Text)
			end)
			return Input
		end

		function Tab:CreateDropdown(DropdownSettings)
			local Dropdown = Elements.Template.Dropdown:Clone()
			Dropdown.Name = DropdownSettings.Name
			Dropdown.Title.Text = DropdownSettings.Name
			Dropdown.Visible = true
			Dropdown.Parent = TabPage
			return Dropdown
		end

		function Tab:CreateKeybind(KeybindSettings)
			local Keybind = Elements.Template.Keybind:Clone()
			Keybind.Name = KeybindSettings.Name
			Keybind.Title.Text = KeybindSettings.Name
			Keybind.Visible = true
			Keybind.Parent = TabPage
			return Keybind
		end

		function Tab:CreateColorPicker(ColorPickerSettings)
			local ColorPicker = Elements.Template.ColorPicker:Clone()
			ColorPicker.Name = ColorPickerSettings.Name
			ColorPicker.Title.Text = ColorPickerSettings.Name
			ColorPicker.Visible = true
			ColorPicker.Parent = TabPage
			return ColorPicker
		end

		function Tab:CreateSection(SectionName)
			local Section = Elements.Template.SectionTitle:Clone()
			Section.Title.Text = SectionName
			Section.Visible = true
			Section.Parent = TabPage
			return Section
		end

		function Tab:CreateDivider()
			local Divider = Elements.Template.Divider:Clone()
			Divider.Visible = true
			Divider.Parent = TabPage
			return Divider
		end

		function Tab:CreateLabel(LabelText)
			local Label = Elements.Template.Label:Clone()
			Label.Title.Text = LabelText
			Label.Visible = true
			Label.Parent = TabPage
			return Label
		end

		function Tab:CreateParagraph(ParagraphSettings)
			local Paragraph = Elements.Template.Paragraph:Clone()
			Paragraph.Title.Text = ParagraphSettings.Title
			Paragraph.Content.Text = ParagraphSettings.Content
			Paragraph.Visible = true
			Paragraph.Parent = TabPage
			return Paragraph
		end

		return Tab
	end

	Elements.Visible = true
	task.wait(0.8)
	TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = useMobileSizing and UDim2.new(0, 480, 0, 275) or UDim2.new(0, 500, 0, 475)}):Play()
	Topbar.Visible = true

	return Window
end

Topbar.Hide.MouseButton1Click:Connect(function()
	if Hidden then
		Hidden = false
		Unhide()
	else
		Hidden = true
		Hide(true)
	end
end)

if MPrompt then
	MPrompt.Interact.MouseButton1Click:Connect(function()
		if Hidden then
			Hidden = false
			Unhide()
		end
	end)
end

function NovaUILibrary:Destroy()
	novaDestroyed = true
	NovaUI:Destroy()
end

return NovaUILibrary
