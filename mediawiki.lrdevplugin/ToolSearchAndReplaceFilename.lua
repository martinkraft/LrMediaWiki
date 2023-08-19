-- Access the Lightroom SDK namespaces.
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local utils = require("utils")

-- Functions -------------------------------------------------------------------

local function join( a, limiter, prefix, suffix, lastlimiter )
    --utils.log(a)
    local l = #a

    if not a or (l <= 1) then
        return a[0] or ''
    end

    a = {table.unpack(a)}

    local str = lastlimiter and (lastlimiter .. table.remove( a, l-1)) or '' 

    return table.concat( persons, limiter ) .. str;
end

function print_r(arr, indentLevel)
    local str = ""
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
            str = str..indentStr..index..": \n"..print_r(value, (indentLevel + 1))
        else 
            str = str..indentStr..index..": "..value.."\n"
        end
    end
    return str
end

local function getTitle( photo, label )
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

local function searchAndReplaceTitle( photo, searchStr, replaceStr )
    local filename = string.sub( tostring(photo:getFormattedMetadata('fileName')),  0, -5)
    --underscore, num, oldlabel = string.match(filename, 'MJK(_*)(%d*)(.*)')

    local title = filename
    title = title:gsub(searchStr, replaceStr)

    return title
end

local LrView = import "LrView"

LrFunctionContext.callWithContext( 'dialogExample', function( context )
    local properties = LrBinding.makePropertyTable( context )
    properties.str = '_'
    properties.replacStr = ''

    local f = LrView.osFactory()
    local contents = f:view { 
        bind_to_object = properties,
        f:row { 
            f:static_text {
                title = "Search for",
            },
        },
        f:row { 
            f:edit_field { 
                fill_horizonal = 1,
                width_in_chars = 40,
                height_in_lines = 3,
                immediate = true,
                placeholder_string = 'string to search for',
                value = LrView.bind( 'str' ),
                wraps = true,
            },
        },
        f:row { 
            margin_top = 10,
            f:static_text {
                title = "and replace with",
            },
        },
        f:row { 
            f:edit_field { 
                fill_horizonal = 1,
                width_in_chars = 40, 
                height_in_lines = 3,
                immediate = true,
                placeholder_string = 'replace string',
                value = LrView.bind( 'replaceStr' ),
            },
        }
    }

    local inputOk = LrDialogs.presentModalDialog(  -- invoke a dialog box
        {
            resizable = true,
            title = "Adjust file title with Search and Replace", 
            contents = contents,   -- with the UI element
            actionVerb = "Adjust title",   -- label for the action button
        }
    )

    if inputOk ~= "cancel" then

        local catalog = LrApplication.activeCatalog()
        local photo = catalog:getTargetPhoto()
        local photos = catalog:getTargetPhotos()
        local data = LrTasks.startAsyncTask(function()
            local data = ''

            for key,photo in pairs(photos) do 
                -- local persons = getPersons(photo)
                local title = searchAndReplaceTitle(photo, properties.str, properties.replaceStr)
                --text = text:gsub(", ", " and ")

                catalog:withWriteAccessDo('Set Filename', function()
                    photo:setRawMetadata( 'title', title )        
                    --photo:setRawMetadata( 'copyName', title .. '.CR2') 
                end)
            end
            --utils.log(tostring(data))

            return data
        end )
    end

end )