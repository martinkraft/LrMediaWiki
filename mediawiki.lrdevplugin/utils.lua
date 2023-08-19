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


function u.log( message )
	-- myLogger:trace( message )
    LrDialogs.message( "FixFilename", message, "info" )
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

function u.getNameParts(photo)
    local fn = tostring(photo:getFormattedMetadata('fileName'))
    local r = {
        fullName = fn,
        name = fn:match("^(.+)%..+$"),
        ext = fn:match("^.+%.(.+)$"),
    }
    r.extLower = string.lower( r.ext )
    r.number = r.name:match("([0-9]+)")
    r.preName = r.name:match("^(.*" .. r.number .. ')')
    

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

function u.checkXmp(photo)
    if (photo.xmp == nil) then
        local xmpPath = LrPathUtils.replaceExtension(photo:getRawMetadata('path'), 'xmp')
        photo.xmp = LrXml.parseXml( LrFileUtils.readFile(xmpPath) )
    end

    return photo.xmp
end

function u.getRegions(photo)

    local xmp = u.checkXmp(photo)
    local regions = {}

    
    --u.log( photo:getFormattedMetadata('sidecars') )

    local nRegionsList = u.findNodeByName(xmp, "RegionList")

    if (nRegionsList ~= nil) then 

        nRegionsList = nRegionsList:childAtIndex(1) 

        
        local d = parseDimensions(photo:getFormattedMetadata("croppedDimensions"))
        local devSettings = photo:getDevelopSettings()
        local cropRegion = {
            x = devSettings['CropLeft'],
            y = devSettings['CropTop'],
            h = devSettings['CropBottom'] - devSettings['CropTop'],
            w = devSettings['CropRight'] - devSettings['CropLeft'],
        }

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

        if region.name ~= nil then
            resultStr = resultStr .. options.before .. region.name .. options.after
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



-- RETURN ------------------------

return u