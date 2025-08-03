-- Access the Lightroom SDK namespaces.
local LrApplication = import 'LrApplication'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrFunctionContext = import 'LrFunctionContext'
local LrLogger = import 'LrLogger'
local LrPathUtils = import 'LrPathUtils'
local LrPrefs = import 'LrPrefs'
local LrTasks = import 'LrTasks'
local LrView = import 'LrView'
local LrXml = import 'LrXml'
local LrHttp = import 'LrHttp'
local LrProgressScope = import 'LrProgressScope'

-- Other Libraries
local Info = require 'Info'
local MediaWikiUtils = require 'MediaWikiUtils'
local json = require 'JSON'
local u = require 'utils'


LrFunctionContext.callWithContext('DescriptionFromPersonsDialog',
                                  function(context)
    local u = require 'utils'
    local LrBinding = import 'LrBinding'

    u.registerHelper('p', function(data, lastJoint, lang, interJoint)
        local props = context.propertyTable
        --local regions = props.regions or {}

        lang = lang or data._pParams.lang or nil
        lastJoint = lastJoint or data._pParams.lastJoint or 'and'

        -- Check if andWord is punctuation (only non-word characters)
        if lastJoint and lastJoint:match("^%p+$") then
            -- leave as is
            interJoint = interJoint or lastJoint
        else
            lastJoint = ' ' .. (lastJoint or '') .. ' '
            interJoint = interJoint or ', '
        end

        u.log('u.getNames: ' .. (lang or 'nil') .. ' ' .. lastJoint .. ' ' ..
                  json:encode(data) or 'nil');

        local names = u.getNames(data._regions, {
            last = lastJoint,
            inter = interJoint,
            lang = lang,
            before = (lang and '[[:'..lang..':') or '',
            after = (lang and '|]]') or '',
            returnLink = data._pParams.returnLink or false
        })
        return names
    end);

    local prefs = import'LrPrefs'.prefsForPlugin()
    prefs.generatorPreset = {
        title = "empty",
        value = {
            _version = 0.11,
            title = '{{f}} {{p}}',
            title_sans = '{{f}}',
            title_de = true,
            title_change = true,
            description_de = '{{p}}',
            description_de_change = true,
            description_en = '{{p}}',
            description_en_change = true,
            description_other = '{{p}}',
            description_other_change = true,
            categories = '{{p}}',
            categories_change = true,
            v1 = '',
            v2 = '',
            v3 = '',
            v4 = '',
            useNicknames = false
        }
    }

    prefs.generatorPresets = prefs.generatorPresets or {prefs.generatorPreset}
    prefs.nicknameList = prefs.nicknameList or {}
    prefs.generator = prefs.generator or prefs.generatorPresets[1].value

    -- check if the generator is up to date
    if not prefs.generator._version or prefs.generator._version < prefs.generatorPreset.value._version then
        prefs.generator = prefs.generatorPreset.value
    else
        u.setDefaults(prefs.generator, prefs.generatorPreset.value)
    end

    local props = u.copyProps(prefs.generator, LrBinding.makePropertyTable(context))
    local catalog = LrApplication.activeCatalog()
    local photos = catalog:getTargetPhotos()
    -- local photo = catalog:getTargetPhoto()

    local varInfo =
        "Use {{f}} for filename, \n{{p}} for person name(s), \n{{n}} for file number, \n{{y}} for year, \n{{m}} for month, \n{{d}} for day, \n{{hl}} for metadata headline, \n{{cap}} for metadata caption"

    local f = LrView.osFactory()
    local bind = LrView.bind
    local contents = f:view{
        bind_to_object = props,
        f:row{
            margin_bottom = 10,
            f:static_text{
                title = "Generate filename und description for " ..
                    ((#photos == 1) and "one photo" or (#photos .. " photos")) ..
                    " from face recognition data."
            }
        },
        f:separator{fill_horizontal = 1},
        f:row{
            margin_top = 20,
            f:static_text{
                width = LrView.share "label_width",
                title = "Title",
                tooltip = varInfo
            },
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 40,
                height_in_lines = 1,
                immediate = true,
                placeholder_string = 'filename prefix (incl. no) = {{f}}, fileumber = {{n}}, persons = {{p}}',
                value = bind 'title',
                wraps = false,
                tooltip = varInfo
            },
            f:checkbox{title = '', value = bind 'title_change'}
        },
        f:row{
            margin_top = 20,
            f:static_text{
                width = LrView.share "label_width",
                title = "Title without names",
                tooltip = varInfo
            },
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 40,
                height_in_lines = 1,
                immediate = true,
                value = bind 'title_sans',
                wraps = false,
                tooltip = "The title that is used if there aren't any names found"
            },
            f:checkbox{title = '', value = bind 'title_sans_change'}
        },
        f:row{
            margin_top = 10,
            f:static_text{
                width = LrView.share "label_width",
                title = "Description (en)"
            },
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 38,
                height_in_lines = 5,
                immediate = true,
                placeholder_string = 'type {{p}} to insert person names',
                value = LrView.bind('description_en'),
                tooltip = "The english description is also used as caption with striped WikiLinks\n" ..
                    varInfo
            },
            f:checkbox{
                title = '',
                value = LrView.bind('description_en_change'),
                checked_value = true,
                unchecked_value = false,
                immediate = true
            },
            f:push_button{
                width_in_chars = 1,
                title = '⥦',
                action = function(args)
                    local des = props.description_en or ''
                    des = u.encode_uri(des)
                    -- open browser with Use {{f}} for filename, \n{{p}} for person name(s), \n{{n}} for file number, \n{{y}} for year, \n{{m}} for month, \n{{d}} for day, \n{{hl}} for metadata headline, \n{{cap}} for metadata caption
                    LrHttp.openUrlInBrowser('https://www.deepl.com/de/translator#en/de/' .. des)
                end
            }
        },
        f:row{
            margin_top = 10,
            f:static_text{
                width = LrView.share "label_width",
                title = "Description (de)"
            },
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 40,
                height_in_lines = 5,
                immediate = true,
                placeholder_string = 'type {{p}} to insert person names',
                value = LrView.bind('description_de'),
                wraps = true
            },
            f:checkbox{
                title = '',
                value = LrView.bind('description_de_change'),
                checked_value = true,
                unchecked_value = false,
                immediate = true
            }
        },
        f:row{
            margin_top = 10,
            f:static_text{
                width = LrView.share "label_width",
                title = "Description (other)"
            },
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 40,
                height_in_lines = 7,
                multiline = true,
                immediate = true,
                placeholder_string = 'type {{p}} to insert person names',
                value = LrView.bind('description_other'),
                wraps = true
            },
            f:checkbox{
                title = '',
                value = LrView.bind('description_other_change'),
                checked_value = true,
                unchecked_value = false,
                immediate = true
            }
        },
        f:row{
            margin_top = 10,
            margin_bottom = 20,
            f:static_text{
                width = LrView.share "label_width",
                title = "Category"
            },
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 40,
                immediate = true,
                placeholder_string = 'Categories seperated with ";", type {{p}} to insert person categories',
                value = LrView.bind('categories'),
                tooltip = "Categories seperated by ;"
            },
            f:checkbox{
                title = '',
                value = LrView.bind('categories_change'),
                checked_value = true,
                unchecked_value = false,
                immediate = true
            }
        },
        f:row{
            margin_top = 10,
            margin_bottom = 0,
            f:static_text{
                width = LrView.share "label_width",
                title = "Custom variables"
            },
            f:static_text{width = 14, title = "v1"},
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 18,
                immediate = true,
                placeholder_string = '{{v1}}',
                value = LrView.bind('v1'),
                tooltip = "Text to replace {{v1}} in the fields above"
            },
            f:static_text{width = 14, title = "v2"},
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 19,
                immediate = true,
                placeholder_string = '{{v2}}',
                value = LrView.bind('v2'),
                tooltip = "Text to replace {{v2}} in the fields above"
            }
        },
        f:row{
            margin_top = 0,
            margin_bottom = 20,
            f:static_text{
                width = LrView.share "label_width",
                title = " "
            },
            f:static_text{width = 14, title = "v3"},
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 18,
                immediate = true,
                placeholder_string = '{{v3}}',
                value = LrView.bind('v3'),
                tooltip = "Text to replace {{v3}} in the fields above"
            },
            f:static_text{width = 14, title = "v4"},
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 19,
                immediate = true,
                placeholder_string = '{{v4}}',
                value = LrView.bind('v4'),
                tooltip = "Text to replace {{v4}} in the fields above"
            }
        },
        f:separator{fill_horizontal = 1},
        f:row{
            margin_top = 20,
            f:static_text{width = LrView.share "label_width", title = "Preset"},
            f:popup_menu{
                width_in_chars = 30,
                value = LrView.bind('preset'),
                items = prefs.generatorPresets,
                action = function()
                    local selectedPreset = props.preset
                    if selectedPreset then
                        u.copyProps(selectedPreset, props, {stringsOnly = false})
                    end
                end
            },
            f:push_button{
                title = 'load',
                action = function(args)
                    u.copyProps(props.preset, props, {stringsOnly = false})
                    -- u.log( json:encode(props.preset))
                end
            },
            f:push_button{
                title = 'update',
                action = function(args)
                    for key, value in pairs(prefs.generator) do
                        props.preset[key] = props[key]
                    end
                    -- u.log( json:encode(props.preset))
                end
            }
        },
        f:row{
            margin_top = 10,
            margin_bottom = 10,
            f:static_text{
                width = LrView.share "label_width",
                title = "New preset name"
            },
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 37,
                height_in_lines = 1,
                immediate = true,
                placeholder_string = 'Preset name',
                value = LrView.bind('preset_name'),
                wraps = true
            },
            f:push_button{
                title = 'save',
                action = function()

                    -- prefs.generatorPresets[ #prefs.generatorPresets ] 
                    -- u.log('a')

                    local v = {}
                    for key, value in pairs(prefs.generator) do
                        v[key] = props[key]
                    end

                    local ob = {
                        title = props.preset_name,
                        value = v -- u.copyProps(props, {}, { stringsOnly = true }),
                    }

                    -- u.log( json:encode(ob) )
                    table.insert(prefs.generatorPresets, ob);
                    -- u.log( json:encode(prefs.generatorPresets) )
                end
            }
        },
        f:row{
            margin_top = 10,
            margin_bottom = 20,
            f:push_button{
                title = 'export all Presets',
                action = function(args)

                    local file = LrDialogs.runSavePanel({
                        title = 'Export Presets as JSON file to..',
                        prompt = 'Save Presets',
                        fileName = 'LrMediaWiki_PersonPresets_' ..
                            os.date('%y%m%d') .. '.json',
                        requiredFileType = 'json',
                        canCreateDirectories = true
                    })

                    local f = io.open(file, "w")
                    f:write(json:encode(prefs.generatorPresets))
                    io.close(f)

                end
            },
            f:push_button{
                title = 'import new Presets',
                action = function(args)

                    local file = LrDialogs.runOpenPanel({
                        title = 'Import new Presets as JSON file from..',
                        prompt = 'Open Presets',
                        canChooseFiles = true,
                        allowsMultipleSelection = false,
                        fileTypes = 'json'
                    })

                    local str = LrFileUtils.readFile(file[1])
                    local data = json:decode(str)

                    if data then

                        -- empty table
                        for k, v in pairs(prefs.generatorPresets) do
                            prefs.generatorPresets[k] = nil
                        end

                        for k, v in pairs(data) do
                            table.insert(prefs.generatorPresets, v)
                        end
                        -- u.log(json:encode(prefs.generatorPresets))
                    end
                end
            },
            f:separator{fill_vertical = 1},
            f:push_button{
                title = 'import Nicknames',
                action = function(args)

                    local file = LrDialogs.runOpenPanel({
                        title = 'Import Nickname List as JSON file from..',
                        prompt = 'Open Nickname List',
                        canChooseFiles = true,
                        allowsMultipleSelection = false,
                        fileTypes = 'json'
                    })

                    local str = LrFileUtils.readFile(file[1])
                    local data = json:decode(str)

                    if data then prefs.nicknameList = data end
                end
            },
            f:checkbox{
                title = 'use Nicknames',
                value = bind 'useNicknames',
                checked_value = true,
                unchecked_value = false
            }
        },
        f:separator{fill_horizontal = 1}
    }

    local inputOk = LrDialogs.presentModalDialog( -- invoke a dialog box
    {
        resizable = true,
        title = "Generator",
        contents = contents, -- with the UI element
        actionVerb = "Generate titel and Metadata", -- label for the action button
        cancelVerb = "Cancel"
    })

    if inputOk ~= "cancel" then

        for key, str in pairs(prefs.generator) do
            prefs.generator[key] = props[key]
        end

        -- generate json string of a prefs.generator
        local generatorJson = json:encode(prefs.generator)

        local progress = LrProgressScope({
            title = "Generating Texts for Photos...",
            functionContext = context
        })

        -- Cleanup-Handler hinzufügen
        context:addCleanupHandler(function()
            if progress then
                progress:done()
            end
        end)

        local data = LrTasks.startAsyncTask( function()
            local data = ''

            for key, photo in pairs(photos) do

                local regions = u.getRegions(photo)
                local fname = u.getNameParts(photo)
                local regionsSkipped = 0
                -- TODO: Remove metadata of regions while uploading

                -- filter "_" names

                progress:setPortionComplete(key - 1, #photos)
                progress:setCaption("Processing Photo " .. key .. " of " .. #photos .. ": " .. fname.name)

                for i = #regions, 1, -1 do
                    local namePreset
                    local region = regions[i]
                    local firstChar = string.sub(region.name or '_', 1, 1)

                    if firstChar:match("%:") then
                        region.name = string.sub(region.name, 2) -- remove first char        
                        region.link = 'User:' .. region.name
                        firstChar = 'User'
                    end

                    if not firstChar:match("[%w]") then
                        table.remove(regions, i)
                        regionsSkipped = regionsSkipped + 1
                    else
                        region.link = region.link or region.name
                        region.paratheses = region.name:match(" %(([^)]+)%)")

                        if region.paratheses then
                            if string.match(region.paratheses, "^:") then
                                region.paratheses = 'User' .. region.paratheses
                            end
                            -- region.link = 'test>' .. region.paratheses
                            if string.match(region.paratheses, "^(User:)") or
                                string.match(region.paratheses, "^(Benutzerin:") or
                                string.match(region.paratheses, "^(Benutzer:)") then
                                region.link = region.paratheses
                            end
                        end
                        region.name = string.gsub(region.name, " %b()", "")

                        if props.useNicknames == true then
                            namePreset = prefs.nicknameList[region.name]
                            if namePreset then
                                region.name = namePreset.nickname or region.name
                            end
                        end

                    end
                end

                -- u.log( json:encode( regions ) )
                -- u.log( nDescription:attributes() )
                -- local data = json.encode( u.findNodeByName(regionsList, "Area"):attributes() )
                -- if regionsList then u.log( regionsList )
                -- u.log( tostring( xmpData:childAtIndex(xmpData:childCount() - 1):name() == "Regions" ));

                catalog:withWriteAccessDo('Set Filename', function()
                    -- catalog:withPrivateWriteAccessDo('Set Filename', function()

                    local data = {
                        _regions = regions,
                        _pParams = {
                            lastJoint = nil,
                            lang = nil
                        },
                        v1 = props.v1 or '',
                        v2 = props.v2 or '',
                        v3 = props.v3 or '',
                        v4 = props.v4 or '',
                        f = fname.preName or '',
                        y = '',
                        m = '',
                        d = '',
                        hl = photo:getFormattedMetadata('headline') or '',
                        cap = photo:getFormattedMetadata('caption') or ''
                    }

                    local timestamp = photo:getRawMetadata('dateTimeOriginal') +
                                          978307200 -- Unix epoch in Mac epoch time
                    u.log("Timestamp: " .. tostring(timestamp))
                    if timestamp then
                        data.y = tostring(os.date('%Y', timestamp)) or ''
                        data.m = tostring(os.date('%m', timestamp)) or ''
                        data.d = tostring(os.date('%d', timestamp)) or ''
                    end

                    local des

                    -- TODO: Filter Regions
                    local titleNames
                    local baseNames = u.getNames(regions, {
                            last = " ++ ",
                            inter = ", ",
                            lang = "en",
                            before = "[[:en:",
                            after = "|]]"
                        })

                    if props.title_change then

                        data._pParams = {
                            lastJoint = 'and',
                            lang = nil
                        }
                        des = '{{f}}'

                        if (#regions > 0) and (#regions < 6) and props.title then
                            des = props.title;
                        elseif props.title_sans then
                            des = props.title_sans
                        end

                        des = u.renderMustache(des, data)

                        photo:setRawMetadata('title', des);
                        photo:setRawMetadata('caption', des:gsub(fname.preName, '')
                                                :match('^%s*(.*%S)') or '');

                        --[[if fname.name ~= des then
                            photo:setRawMetadata('fileName', des)
                        end]]--
                    end

                    if props.description_de_change and props.description_de then

                        data._pParams = {
                            lastJoint = 'und',
                            lang = 'de'
                        }

                        des = u.renderMustache(props.description_de, data)
                        photo:setPropertyForPlugin(_PLUGIN, 'description_de',
                                                   des)
                    end

                    if props.description_en_change and props.description_en then

                        data._pParams = {
                            lastJoint = 'and',
                            lang = 'en'
                        }

                        des = u.renderMustache(props.description_en, data)
                        photo:setPropertyForPlugin(_PLUGIN, 'caption_en',
                                                   u.stripWikiLinks(des))
                        
                        data._pParams = {
                            lastJoint = 'and'
                        }
                        des = u.renderMustache(props.description_en, data)
                        photo:setPropertyForPlugin(_PLUGIN, 'description_en',
                                                   des)
                    end

                    if props.description_other_change and props.description_other then

                        data._pParams = {
                            lastJoint = 'et',
                            lang = 'fr'
                        }

                        des = u.renderMustache(props.description_other, data)
                        photo:setPropertyForPlugin(_PLUGIN, 'description_other',
                                                   des)
                    end

                    if props.categories_change and props.categories then
                        
                        data._pParams = {
                            lastJoint = ';',
                            returnLink = true
                        }

                        des = u.renderMustache(props.categories, data)
                        photo:setPropertyForPlugin(_PLUGIN, 'categories', des)
                    end

                    photo:setPropertyForPlugin(_PLUGIN, 'textGeneratorTemplate', generatorJson);

                    --[[
                    if regions[2] then
                        photo:setPropertyForPlugin(_PLUGIN, 
                            'otherFields',
                            u.getImageNotes(regions, photo)
                        )
                    end
                    ]]

                end)

                if progress:isCanceled() then
                    break
                end
            end
            
            progress:done()
            progress = nil -- Verhindert doppelten Cleanup

            return data
        end)
    end
end)