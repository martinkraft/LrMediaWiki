-- Access the Lightroom SDK namespaces.
local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local u = require 'utils'

local catalog = LrApplication.activeCatalog()
local photos = catalog:getTargetPhotos()

local data = LrTasks.startAsyncTask(function()
    local data = ''
    --u.log(title);

    catalog:withWriteAccessDo('Set MetaData', function()
    
        for key,photo in pairs(photos) do 
            --u.log( photo:getFormattedMetadata('fileName') )
            --u.log( photo:getFormattedMetadata('personShown') )
            
            local fname = u.getNameParts(photo)
            local title = photo:getFormattedMetadata('title');

            if title == nil or title == '' then                
                photo:setRawMetadata('title', fname.name)
            end
        end

    end)
    --utils.log(tostring(data))

    return data
end)