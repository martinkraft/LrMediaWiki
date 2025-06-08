local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrXml = import 'LrXml'
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrStringUtils = import 'LrStringUtils'
local json = require 'JSON'

local u = {}

--------------------------------------------------------------------------------
-- Write trace information to the logger.


local logFilePath = _PLUGIN.path .. "utils.log"

function u.log( message )
	-- myLogger:trace( message )
    --LrDialogs.message( "FixFilename", message, "info" )

    local logFile = io.open(logFilePath, "a")
    if logFile then
        logFile:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. message .. "\n")
        logFile:close()
    --else
        -- Zeige eine Fehlermeldung an, wenn die Datei nicht geöffnet werden kann
        --LrDialogs.message("Fehler", "Die Logdatei konnte nicht geöffnet werden: " .. logFilePath, "critical")
    end
end


function u.split(inputoptions, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for options in string.gmatch(inputoptions, "([^"..sep.."]+)") do
            table.insert(t, options)
    end
    return t
end

-- Functions -------------------------------------------------------------------

--- Joins the elements of a table into a string using a specified delimiter.
--- 
--- @param a table The table containing the elements to be joined.
--- @param limiter string The delimiter to be used for joining the elements.
--- @param prefix string (optional) A prefix to be added before each joined element.
--- @param suffix string (optional) A suffix to be added after each joined element.
--- @param lastlimiter string (optional) A delimiter to be used before the last element.
--- @return string The joined string.
function u.join( a, limiter, prefix, suffix, lastlimiter )
    --log(a)
    local l = #a

    if not a or (l <= 1) then
        return a[0] or ''
    end

    a = {table.unpack(a)}

    local options = lastlimiter and (lastlimiter .. table.remove( a, l-1)) or '' 

    return table.concat( persons, limiter ) .. options;
end

function u.print_r(arr, indentLevel)
    local options = ""
    local indentStr = "#"

    if(indentLevel == nil) then
        print(print_r(arr, 0))
        return
    end

    for i = 0, indentLevel do
        indentStr = indentStr.."\t"
    end

    for index,value in pairs(arr) do
        if type(value) == "table" then
            options = options..indentStr..index..": \n"..print_r(value, (indentLevel + 1))
        else 
            options = options..indentStr..index..": "..value.."\n"
        end
    end

    return options
end

-- Function to iterate through a map and set nil or empty values to the values of another map
function u.setDefaults(map, defaults)
    for key, value in pairs(defaults) do
        if map[key] == nil or map[key] == '' then
            map[key] = defaults[key]
        end
    end
end

--[[
function u.getTitle( photo, label )
    local filename = string.sub( tostring(photo:getFormattedMetadata('fileName')),  0, -5)
    underscore, num, oldlabel = string.match(filename, 'MJK(_*)(%d*)(.*)')

    local title = filename

    if num then
        if not label then 
            --label = ''
            title = 'MJK'.. underscore .. num 
        else
            --label = label:gsub(" ", "_")   
            title = 'MJK'.. underscore .. num .. ' ' .. label
        end     
    end

    return title
end
]]--

--- Extracts various parts of a photo's file name.
-- @param photo The photo object.
-- @return A table containing the extracted parts of the file name.
function u.getNameParts(photo)
    local fn = tostring(photo:getFormattedMetadata('fileName'))
    local r = {
        fullName = fn,
        name = fn:match("^(.+)%..+$"),
        ext = fn:match("^.+%.(.+)$"),
    }
    r.extLower = string.lower( r.ext )
    r.number = r.name:match("%d%d%d+%-?%d*") --Find number pattern
    r.preName = r.name:match("^(.*" .. r.number:gsub("([^%w])", "%%%1") .. ')') --number with leading text
    
    return r
end

function u.searchAndReplaceTitle( photo, searchStr, replaceStr )
    local filename = string.sub( tostring(photo:getFormattedMetadata('fileName')),  0, -5)
    --underscore, num, oldlabel = string.match(filename, 'MJK(_*)(%d*)(.*)')

    local title = filename
    title = title:gsub(searchStr, replaceStr)

    return title
end


-- XML ------------------------

function u.findNodeByName( node, name )  
    --u.log( tostring(node) )

    if (node ~= nil and string.lower( node:type() ) == 'element') then

        
        if ( tostring(node:name()) == name) then 
            return node
        else  
            

            local count = node:childCount()
        
            while (count > 0) do
                local childNode = node:childAtIndex(count)
                
                if (childNode ~= nil) then
                    local value = u.findNodeByName(childNode, name)
            
                    if (value ~= nil) then
                        return value
                    end
                end
        
                count = count - 1
            end

            return nil
        end
    else 
        return nil
    end
end

function u.nodeAttributes( node )  
    return node.attributes()
end

function u.getAttributes(node, map)
    local attributes = node:attributes()
    if ( type(map) ~= 'table') then 
        map = {}
    end

    local value, num
    for key, attribute in pairs(attributes) do
        value = attribute['value']
        num = tonumber(value)
        map[ string.lower(attribute['name']) ] = (num ~= nil) and num or value
    end

    return map
end

-- PHOTO ------------------------

-- Function: checkXmp
-- Description: Checks if the given photo has an XMP metadata file associated with it. If not, it reads the XMP file and stores it in the photo object.
-- Parameters:
--   - photo: The photo object to check.
-- Returns:
--   - The parsed XMP data as an XML object.
function u.checkXmp(photo)

    if (photo.xmp == nil) then


        local filePath = photo:getRawMetadata('path')
        local fileExtension = string.lower(LrPathUtils.extension(photo:getRawMetadata('path')))
    
        if fileExtension ~= "jpg" and fileExtension ~= "jpeg" then
            -- Check if the XMP file exists
            local xmpPath = LrPathUtils.replaceExtension(filePath, 'xmp')
            if not LrFileUtils.exists(xmpPath) then
                return nil, "The XMP file does not exist."
            end
            photo.xmp = LrXml.parseXml( LrFileUtils.readFile(xmpPath) )
        else
            -- Read the JPEG file and extract the XMP data
            if not LrFileUtils.exists(filePath) then
                return nil, "The JPG file does not exist."
            end
            local content = LrFileUtils.readFile(filePath)

            -- Search for the XMP metadata block
            local xmpStart = content:find("<x:xmpmeta")
            local xmpEnd = content:find("</x:xmpmeta>")
            if xmpStart and xmpEnd then
                local xmpData = content:sub(xmpStart, xmpEnd + 12)
                photo.xmp = LrXml.parseXml(xmpData)
            else
                return nil, "No XMP metadata found in the JPEG file."
            end
        end
    end

    return photo.xmp
end

--[[ --DevSettings

Version="14.1",
ProcessVersion="11.0",
WhiteBalance="Custom",
Temperature="2849",
Tint="0",
Exposure2012="+1.42",
Contrast2012="0",
Highlights2012="+43",
Shadows2012="0",
Whites2012="-21",
Blacks2012="0",
Texture="+8",
Clarity2012="-4",
Dehaze="0",
Vibrance="0",
Saturation="0",
ParametricShadows="0",
ParametricDarks="0",
ParametricLights="0",
ParametricHighlights="0",
ParametricShadowSplit="25",
ParametricMidtoneSplit="50",
ParametricHighlightSplit="75",
Sharpness="65",
SharpenRadius="+1.0",
SharpenDetail="25",
SharpenEdgeMasking="10",
LuminanceSmoothing="0",
ColorNoiseReduction="25",
ColorNoiseReductionDetail="50",
ColorNoiseReductionSmoothness="50",
HueAdjustmentRed="0",
HueAdjustmentOrange="-2",
HueAdjustmentYellow="0",
HueAdjustmentGreen="0",
HueAdjustmentAqua="0",
HueAdjustmentBlue="0",
HueAdjustmentPurple="0",
HueAdjustmentMagenta="0",
SaturationAdjustmentRed="0",
SaturationAdjustmentOrange="0",
SaturationAdjustmentYellow="0",
SaturationAdjustmentGreen="0",
SaturationAdjustmentAqua="0",
SaturationAdjustmentBlue="0",
SaturationAdjustmentPurple="0",
SaturationAdjustmentMagenta="0",
LuminanceAdjustmentRed="-7",
LuminanceAdjustmentOrange="+2",
LuminanceAdjustmentYellow="0",
LuminanceAdjustmentGreen="0",
LuminanceAdjustmentAqua="0",
LuminanceAdjustmentBlue="0",
LuminanceAdjustmentPurple="0",
LuminanceAdjustmentMagenta="0",
SplitToningShadowHue="0",
SplitToningShadowSaturation="0",
SplitToningHighlightHue="0",
SplitToningHighlightSaturation="0",
SplitToningBalance="0",
ColorGradeMidtoneHue="0",
ColorGradeMidtoneSat="0",
ColorGradeShadowLum="0",
ColorGradeMidtoneLum="0",
ColorGradeHighlightLum="0",
ColorGradeBlending="50",
ColorGradeGlobalHue="0",
ColorGradeGlobalSat="0",
ColorGradeGlobalLum="0",
AutoLateralCA="1",
LensProfileEnable="0",
LensManualDistortionAmount="0",
VignetteAmount="0",
DefringePurpleAmount="0",
DefringePurpleHueLo="30",
DefringePurpleHueHi="70",
DefringeGreenAmount="0",
DefringeGreenHueLo="40",
DefringeGreenHueHi="60",
PerspectiveUpright="0",
PerspectiveVertical="0",
PerspectiveHorizontal="0",
PerspectiveRotate="0.0", -10.0 - 10.0
PerspectiveAspect="0",
PerspectiveScale="79", 0  -100
PerspectiveX="0.00", -100.0 - 100.0
PerspectiveY="0.00", -100.0 - 100.0
GrainAmount="0",
PostCropVignetteAmount="0",
ShadowTint="0",
RedHue="0",
RedSaturation="0",
GreenHue="0",
GreenSaturation="0",
BlueHue="0",
BlueSaturation="0",
OverrideLookVignette="False",
ToneCurveName2012="Linear",
CameraProfile="Adobe Standard",
CameraProfileDigest="661433344C8532AFA5A1E9091401E43C",
HasSettings="True",
CropTop="0.173141",
CropLeft="0.116759",
CropBottom="0.863113",
CropRight="0.806731",
CropAngle="0",
CropConstrainToWarp="1",
HasCrop="True",
AlreadyApplied="False",
RawFileName="MJK_68174 Anna Maria Mühe and Hannah Herzsprung (Berlinale 2020).CR2"

]]--

function u.getRegions(photo)

    local xmp = u.checkXmp(photo)
    local regions = {}
    
    --u.log( photo:getFormattedMetadata('sidecars') )
    local nRegionsList = u.findNodeByName(xmp, "RegionList")

    if (nRegionsList ~= nil) then 

        nRegionsList = nRegionsList:childAtIndex(1) 
        
        local devSettings = photo:getDevelopSettings()

        local d = parseDimensions(photo:getFormattedMetadata("croppedDimensions"))
        local devSettings = photo:getDevelopSettings()
        local cropRegion = {
            x = devSettings['CropLeft'],
            y = devSettings['CropTop'],
            h = devSettings['CropBottom'] - devSettings['CropTop'],
            w = devSettings['CropRight'] - devSettings['CropLeft'],
        }

        local region
        local i = 1
        local ci = nRegionsList:childCount()
        while i<=ci do 
            region = nRegionsList:childAtIndex(i)

            local nArea = u.findNodeByName( region, "Area" )   
            local nDescription = u.findNodeByName( region, "Description" )

            region = u.getAttributes( nDescription, u.getAttributes( nArea ) )            

            --u.log('check flipped' .. json:encode(region) )
            --flip when flipped
            if region["rotation"] == 1.5708 then
                local x = region["y"]
                local w = region["h"]
                region["y"] = 1 - region["x"]
                region["h"] = region["w"]
                region["x"] = x
                region["w"] = w
            end

            region.x = (region.x - cropRegion.x) / cropRegion.w
            region.w = region.w / cropRegion.w
            region.y = (region.y - cropRegion.y) / cropRegion.h
            region.h = region.h / cropRegion.h

            if (region.x >= 0) and (region.x <= 1) and (region.y >= 0) and (region.y <= 1) then
                regions[#regions+1] = region
            end

            i = i + 1
        end

        table.sort( regions, function( a, b )
            return tonumber(a["x"]) < tonumber(b["x"])
        end )
    end

    photo.regions = regions

    return regions
end


function u.getNames(regions, options)
    if regions == nil or #regions == 0 then return "" end

    options = options or {}
    options.inter = options.inter or ', '
    options.lang = options.lang or nil
    options.last = options.last or options.inter
    options.before = options.before or ''
    options.after = options.after or ''
    
    local resultStr = ''

    if options.unknown == nil then
        local nameRegions = {}

        for i, region in pairs(regions) do
            if region.name ~= nil then nameRegions[#nameRegions + 1] = region end
        end

        regions = nameRegions
    end
    
    for i, region in pairs(regions) do

        if string.find(region.name, " %((WMDE|WMAT|WMCH|WMF)%)") then
            region.name = ":" .. region.name
        end

        if region.name ~= nil then
            -- resultStr = resultStr .. options.before .. region.name .. options.after

            if(options.lang ~= nil) then
                resultStr = resultStr .. '[[:' .. options.lang..':' .. region.link .. '|'.. region.name .. ']]'
            elseif(options.returnLink == true) then
                resultStr = resultStr .. options.before .. region.link .. options.after
            else
                resultStr = resultStr .. options.before .. region.name .. options.after
            end
        else 
            resultStr = resultStr .. options.unknown
        end

        if (i < #regions-1) then
            resultStr = resultStr .. options.inter
        elseif i ~= #regions then            
            resultStr = resultStr .. options.last
        end
    end

    return resultStr
end

function parseDimensions(str)
    local i = string.find(str, "x")
    if i == nil then return nil end
    return {
        width = tonumber( LrStringUtils.trimWhitespace(string.sub(str, 0, i-1))),
        height = tonumber( LrStringUtils.trimWhitespace(string.sub(str, i+1)))
    }
end

function u.getImageNotes(regions, photo)

    local resultStr = ''   
    local d = parseDimensions(photo:getFormattedMetadata("croppedDimensions"))
    
    for i, region in pairs(regions) do
        if region.name ~= nil then
            resultStr = resultStr .. '{{ImageNote|id='.. i .. '|x=' .. math.ceil(region.x * d.width) .. '|y=' .. math.ceil(region.y * d.height) .. '|w=' .. math.ceil(region.w*d.width) .. '|h=' .. math.ceil(region.h * d.height) .. '|dimx='..d.width..'|dimy='..d.height..'|style=1}}' .. region.name .. '{{ImageNoteEnd|id='.. i ..'}}\n'
        end
    end
    
    return resultStr
end

function u.copyProps( fromOb, toOb, options )
    toOb = toOb or {}
    options = options or {}
    options.stringsOnly = (options.stringsOnly == true) or false
    options.excludeKeys = options.excludeKeys or {}
    
    for key,value in pairs(fromOb) do 
        if (type(key) ~= 'table') and (type(value) == 'string' or options.stringsOnly ~= true) and (options.excludeKeys[key] ~= true) then
            toOb[key] = value
        end
    end

    return toOb
end

-- Mimic Mustache-style templating with default parameters
function u.renderMustache(template, data)
    return u.renderHandlebars(template, data)
    --[[
    return template:gsub("{{(.-)}}", function(key)
        -- Support multiple pipes for defaults: {{key|default1|default2}}
        local parts = {}
        for part in key:gmatch("[^|]+") do
            table.insert(parts, part:match("^%s*(.-)%s*$")) -- trim whitespace
        end
        local k = parts[1]
        -- Try data[k], else try each default in order
        if data[k] ~= nil and data[k] ~= '' then
            return data[k]
        else
            for i = 2, #parts do
                if parts[i] ~= nil and parts[i] ~= '' then
                    return parts[i]
                end
            end
            return ''
        end
    end)
    ]]
end

-- Minimal Handlebars-style templating engine for Lua
-- Supports: variables, dot notation, sections (#/), inverted sections (^), and basic if/each helpers

local function getValue(data, key)
    -- Dot notation: "a.b.c"
    local val = data
    for part in string.gmatch(key, "[^%.]+") do
        if type(val) == "table" then
            val = val[part]
        else
            return nil
        end
    end
    return val
end
u.getValue = getValue

local function renderSection(section, data, context, inverted)
    local value = getValue(data, section.name)
    local result = ""
    if (not inverted and value) or (inverted and not value) then
        if type(value) == "table" and not inverted then
            if #value > 0 then
                -- Array: iterate
                for _, item in ipairs(value) do
                    result = result .. u.renderHandlebars(section.content, item)
                end
            else
                -- Object: use as context
                result = result .. u.renderHandlebars(section.content, value)
            end
        elseif not inverted then
            -- Truthy value: render section with current context
            result = result .. u.renderHandlebars(section.content, data)
        elseif inverted then
            -- Inverted section: render if falsy
            result = result .. u.renderHandlebars(section.content, data)
        end
    end
    return result
end

function u.renderHandlebars(template, data)
    -- Parse sections (supports nested)
    local function parseSections(tpl)
        local stack = {}
        local sections = {}
        local i = 1
        while i <= #tpl do
            local s, e, tag, name = tpl:find("{{#([%w%.%_]+)}}", i)
            local s_inv, e_inv, tag_inv, name_inv = tpl:find("{{%^(%w[%w%.%_]*)}}", i)
            if s and (not s_inv or s < s_inv) then
                table.insert(stack, {name=name, start=e+1, inverted=false, tagStart=s, tagEnd=e})
                i = e+1
            elseif s_inv then
                table.insert(stack, {name=name_inv, start=e_inv+1, inverted=true, tagStart=s_inv, tagEnd=e_inv})
                i = e_inv+1
            else
                local s_end, e_end, end_name = tpl:find("{{/(%w[%w%.%_]*)}}", i)
                if s_end and #stack > 0 then
                    local last = table.remove(stack)
                    if last.name == end_name then
                        -- Section found
                        local section = {
                            name = last.name,
                            content = tpl:sub(last.start, s_end-1),
                            inverted = last.inverted,
                            tagStart = last.tagStart,
                            tagEnd = e_end
                        }
                        table.insert(sections, section)
                        -- Replace section in template with a marker
                        tpl = tpl:sub(1, last.tagStart-1) ..
                              "{{{__section_"..#sections.."}}}" ..
                              tpl:sub(e_end+1)
                        i = last.tagStart + #("{{{__section_"..#sections.."}}}")
                    else
                        -- Malformed template
                        i = e_end+1
                    end
                else
                    break
                end
            end
        end
        return tpl, sections
    end

    -- Recursively render template with sections
    local function render(tpl, data)
        local parsed_tpl, sections = parseSections(tpl)
        -- Render sections first
        for idx, section in ipairs(sections) do
            local rendered = renderSection(section, data, data, section.inverted)
            parsed_tpl = parsed_tpl:gsub("{{{__section_"..idx.."}}}", rendered)
        end
        -- Render variables and helpers
        parsed_tpl = parsed_tpl:gsub("{{([%w%._| ]+)}}", function(key)
            -- Support default values with pipes
            local parts = {}
            for part in key:gmatch("[^|]+") do
                table.insert(parts, part:match("^%s*(.-)%s*$"))
            end
            local k = parts[1]
            local val = getValue(data, k)
            if val ~= nil and val ~= '' then
                return tostring(val)
            else
                for i = 2, #parts do
                    if parts[i] ~= nil and parts[i] ~= '' then
                        return parts[i]
                    end
                end
                return ''
            end
        end)
        return parsed_tpl
    end

    return render(template, data)
end

-- strip the text from WikiText-Links
--- Strips wiki links from the given input string.
--- 
--- This function removes the wiki link syntax from the input string and returns the modified string.
--- The wiki link syntax is in the format [[link|display text]], where 'link' is the target link and 'display text' is the text to be displayed.
--- If the 'display text' is not provided, the function will attempt to extract it from the 'link' itself.
--- 
--- @param input The input string containing wiki links.
--- @return The modified string with wiki links stripped.
function u.stripWikiLinks(input)

    local function innerReplaceFunc(v1, v2, v3, v4)        
        --u.log(v1..' | '..(v2 or '')..' | '..(v3 or '')..' | '..(v4 or ''))
        return v2:match'^%s*(.*%S)' or '' --trim parts
    end

    local function replaceFunc(v1, v2)
        --u.log(v1..' | '..(v2 or ''))
        if v2 ~= "" then 
            --u.log('return 2 '..v2)
            return v2 
        else        
            --u.log('return 1 '..v1)
            local innerOutput = v1:gsub("(:%a%a?:?)([^%(]*)%s*%(?(.-)%)?$", innerReplaceFunc)
            return innerOutput
        end        
    end

    -- Perform the replacement
    local output = input:gsub("%[%[([^%|%]]+)%|?([^%|%]]*)%]%]", replaceFunc)
    --u.log('output: '..output)
    return output
end


local LrFileUtils = import 'LrFileUtils'
local LrTasks = import 'LrTasks'
local LrApplication = import 'LrApplication'
local LrPathUtils = import 'LrPathUtils'

--TODO: Funktioniert nicht, weil XMP und Katalog nicht mit verschoben werden

function u.renameFile(catalog, photo, newName)

    LrTasks.startAsyncTask(function()
        local catalog = LrApplication.activeCatalog()
        local photo = catalog:getTargetPhoto()

        -- Get the current photo path
        local oldPath = photo:getRawMetadata('path')

        -- Get the directory of the current photo
        local dir = LrPathUtils.parent(oldPath)

        -- Create the new path
        local newPath = LrPathUtils.child(dir, newName)

        -- Move the file to the new path (i.e., rename it)
        local success, reason = LrFileUtils.move(oldPath, newPath)

        if success then
            -- Update the catalog to reflect the new file location
            catalog:withWriteAccessDo("Update Photo Path", function()
                local newPhoto = catalog:findPhotoByPath(newPath)
                if newPhoto then
                    catalog:setSelectedPhotos(newPhoto, {newPhoto})
                end
            end)
        else
            -- Handle the error
            LrDialogs.showError("Could not rename file: " .. reason)
        end
    end)

end

-- RETURN ------------------------

return u