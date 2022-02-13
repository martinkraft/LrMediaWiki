-- This file is part of the LrMediaWiki project and distributed under the terms
-- of the MIT license (see LICENSE.txt file in the project root directory or
-- [0]).  See [1] for more information about LrMediaWiki.
--
-- Copyright (C) 2014 by the LrMediaWiki team (see CREDITS.txt file in the
-- project root directory or [2])
--
-- [0]  <https://raw.githubusercontent.com/ireas/LrMediaWiki/master/LICENSE.txt>
-- [1]  <https://commons.wikimedia.org/wiki/Commons:LrMediaWiki>
-- [2]  <https://raw.githubusercontent.com/ireas/LrMediaWiki/master/CREDITS.txt>

-- Code status:
-- doc:   missing
-- i18n:  complete

local LrApplication = import 'LrApplication'
local LrLogger = import 'LrLogger'
local LrPasswords = import 'LrPasswords'
local LrPrefs = import 'LrPrefs'
local LrDate = import 'LrDate'

local Info = require 'Info'

local MediaWikiUtils = {}
local myLogger = LrLogger('LrMediaWikiLogger')

local prefs = LrPrefs.prefsForPlugin(nil)
if prefs.logging then
	myLogger:enable('logfile')
end

-- Allows formatting of strings like "${test} one two three ${test2}"
-- Based on a solution by http://lua-users.org/wiki/RiciLake shown here:
-- http://lua-users.org/wiki/StringInterpolation
MediaWikiUtils.formatString = function(str, arguments)
	return (str:gsub('($%b{})', function(w) return arguments[w:sub(3, -2)] or w end))
end

-- Substitute placeholders of format "<var>" – similar to function "formatString"
MediaWikiUtils.substitutePlaceholders = function(str, arguments)
	return (str:gsub('(%b<>)', function(w) return arguments[w:sub(2, -2)] or w end))
end

MediaWikiUtils.isStringEmpty = function(str)
	return str == nil or string.match(str, '^%s*$') ~= nil
	-- see e.g. http://stackoverflow.com/questions/10328211/how-to-check-if-a-value-is-empty-in-lua
end

MediaWikiUtils.isStringFilled = function(str)
	return not MediaWikiUtils.isStringEmpty(str)
end

MediaWikiUtils.trim = function(str)
	return string.match(str, '^%s*(.-)%s*$')
	-- see e.g. http://lua-users.org/wiki/StringTrim
	--- or http://lua-users.org/wiki/CommonFunctions
end

MediaWikiUtils.getFirstKey = function(table)
	for key, value in pairs(table) do -- luacheck: ignore ("loop is executed at most once")
		return key
	end
	return nil
end

MediaWikiUtils.getInstalledVersion = function()
	local str = Info.VERSION.major .. '.' .. Info.VERSION.minor .. '.' .. Info.VERSION.revision
	return str
end

MediaWikiUtils.getVersionString = function()
	local installedVersion = Info.VERSION.major .. '.' .. Info.VERSION.minor .. '.' .. Info.VERSION.revision
	local platform = '?'
	-- Boolean global variables WIN_ENV and MAC_ENV are documented at LR SDK programmers guide
	if WIN_ENV == true then
		platform = 'Win'
	elseif MAC_ENV == true then
		platform = 'Mac' -- OS name has been changed in 2016 from "OS X" to "macOS"
	else
		error 'Unsupported platform – neither Windows nor macOS' -- unlikely case
	end
	return installedVersion .. ', LR ' .. LrApplication.versionString() .. ' ' .. platform
end

MediaWikiUtils.storePassword = function(apiPath, username, password)
	-- passwordKey needs to be the same as at "retrievePassword"
	local passwordKey = 'LrMediaWiki#' .. apiPath .. '#' .. username
	LrPasswords.store(passwordKey, password)
end

MediaWikiUtils.retrievePassword = function(apiPath, username)
	-- passwordKey needs to be the same as at "storePassword"
	local passwordKey = 'LrMediaWiki#' .. apiPath .. '#' .. username
	local password = LrPasswords.retrieve(passwordKey)
	if password == nil then
		password = ''
	end
	return password
end

-- configuration

MediaWikiUtils.getCreateSnapshots = function()
	return prefs.create_snapshot or false
end

MediaWikiUtils.setCreateSnapshots = function(create_snapshot)
	prefs.create_snapshot = create_snapshot
end

MediaWikiUtils.getExportKeyword = function()
	return prefs.export_keyword or nil
end

MediaWikiUtils.setExportKeyword = function(tag)
	prefs.export_keyword = tag
end

MediaWikiUtils.getExportColor = function()
	return prefs.export_color or nil
end

MediaWikiUtils.setExportColor = function(color)
	prefs.export_color = color
end

MediaWikiUtils.getCheckVersion = function()
	return prefs.check_version or false
end

MediaWikiUtils.setCheckVersion = function(check_version)
	prefs.check_version = check_version
end

MediaWikiUtils.getStructuredData = function()
	if prefs.structured_data == nil then -- first call
		prefs.structured_data = true -- default
	end
	return prefs.structured_data
end

MediaWikiUtils.setStructuredData = function(structured_data)
	prefs.structured_data = structured_data
end

MediaWikiUtils.getLogging = function()
	return prefs.logging or false
end

MediaWikiUtils.setLogging = function(logging)
	prefs.logging = logging
	if logging then
		myLogger:enable('logfile')
	else
		myLogger:disable()
	end
end

MediaWikiUtils.getPreviewWikitextFontName = function()
	return prefs.preview_wikitext_font_name or '' -- no default value
end

MediaWikiUtils.setPreviewWikitextFontName = function(tag)
	prefs.preview_wikitext_font_name = tag
end

MediaWikiUtils.getPreviewWikitextFontSize = function()
	return prefs.preview_wikitext_font_size or 12 -- 12 = default value
end

MediaWikiUtils.setPreviewWikitextFontSize = function(tag)
	prefs.preview_wikitext_font_size = tonumber(tag)
end

MediaWikiUtils.trace = function(message)
	myLogger:trace(message)
end

MediaWikiUtils.tracef = function(format, message)
	myLogger:tracef(format, message)
end

MediaWikiUtils.currentDate = function(arguments) -- returns list of date related placeholders
	local currentTime = LrDate.currentTime() -- number of seconds since midnight UTC on January 1, 2001
	arguments.currentIsoDate = LrDate.timeToIsoDate(currentTime) -- 2021-01-09
	arguments.currentLongDate = LrDate.formatLongDate(currentTime) -- 9. Januar 2021
	arguments.currentMediumDate = LrDate.formatMediumDate(currentTime) -- 09.01.2021
	arguments.currentShortDate = LrDate.formatShortDate(currentTime) -- 09.01.21
	arguments.currentYear = LrDate.timeToUserFormat(currentTime, '%Y') -- 2021
	arguments.currentYearXX = LrDate.timeToUserFormat(currentTime, '%y') -- 21
	arguments.currentMonthXX = LrDate.timeToUserFormat(currentTime, '%m') -- 01
	arguments.currentMonth = tonumber(arguments.currentMonthXX) -- 1
	arguments.currentMonthName = LrDate.timeToUserFormat(currentTime, '%B') -- January
	arguments.currentDayXX = LrDate.timeToUserFormat(currentTime, '%d') -- 09
	arguments.currentDay = LrDate.timeToUserFormat(currentTime, '%e') -- 9
	arguments.currentDayName = LrDate.timeToUserFormat(currentTime, '%A') -- Saturday
	arguments.currentTime = LrDate.timeToUserFormat(currentTime, '%H:%M:%S') -- 20:40:15
	arguments.currentHour = LrDate.timeToUserFormat(currentTime, '%H') -- 20
	arguments.currentMinute = LrDate.timeToUserFormat(currentTime, '%M') -- 40
	arguments.currentSecond = LrDate.timeToUserFormat(currentTime, '%S') -- 15
	return arguments
end

return MediaWikiUtils
