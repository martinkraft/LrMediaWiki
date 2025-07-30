-- Access the Lightroom SDK namespaces.
local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
--local LrLogger = import 'LrLogger'
--local LrView = import 'LrView'
local LrTasks = import 'LrTasks'
--local LrFileUtils = import 'LrFileUtils'
--local LrFunctionContext = import 'LrFunctionContext'
--local LrBinding = import 'LrBinding'

-- Other Libaries
--local MetadataProvider = require 'MediaWikiMetadataProvider'
--local MediaWikiUtils = require 'MediaWikiUtils'
--local Info = require 'Info'
local u = require 'utils'

local catalog = LrApplication.activeCatalog()
--local photo = catalog:getTargetPhoto()
local photos = catalog:getTargetPhotos()

local data = LrTasks.startAsyncTask(function()
    local data = ''
    --u.log(title);

    catalog:withWriteAccessDo('Set MetaData', function()
    
        for key,photo in pairs(photos) do 
            --u.log( photo:getFormattedMetadata('fileName') )
            
            local fname = u.getNameParts(photo)
            local headline = photo:getFormattedMetadata('headline')
            local title = photo:getFormattedMetadata('title')

            --u.log('headline:'..headline)            
            headline = (headline and headline:gsub("^%s*(.-)%s*$", " %1")) or ''

            if headline ~= '' then
                title = fname.preName..headline
                --u.renameFile(catalog, photo, fname.preName..headline..'.'..fname.ext)
            end

            -- remove whitspaces, underscores and minuses at the end of the title
            title = (title and title:gsub("[-_ ]*$", "")) or ''

            if title ~= '' then
                photo:setRawMetadata('title', title)
            end          
            
        end

    end)
    --utils.log(tostring(data))

    return data
end)