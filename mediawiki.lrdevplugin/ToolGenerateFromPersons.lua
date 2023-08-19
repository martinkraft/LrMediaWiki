-- Access the Lightroom SDK namespaces.
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrApplication = import 'LrApplication'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrTasks = import 'LrTasks'
local LrXml = import 'LrXml'
local LrPrefs = import 'LrPrefs'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'

-- Other Libaries
local Info = require 'Info'
local MediaWikiUtils = require 'MediaWikiUtils'
local json = require 'JSON'
local u = require 'utils'

LrFunctionContext.callWithContext('dialogExample', function(context)

    local prefs = import'LrPrefs'.prefsForPlugin()

    prefs.generatorPresets = prefs.generatorPresets or {
        -- prefs.generatorPresets = {
        {
            title = "empty",
            value = {
                title = '{{f}} {{p}}',
                description_de = '{{p}}',
                description_en = '{{p}}',
                categories = '{{p}}',
                title_de = false
            }
        }
    }

    prefs.generator = prefs.generator or prefs.generatorPresets[0]

    local props = u.copyProps(prefs.generator,
                              LrBinding.makePropertyTable(context))
    local catalog = LrApplication.activeCatalog()
    local photo = catalog:getTargetPhoto()
    local photos = catalog:getTargetPhotos()

    local f = LrView.osFactory()
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
            f:static_text{width = LrView.share "label_width", title = "Title"},
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 36,
                height_in_lines = 1,
                immediate = true,
                placeholder_string = 'filename prefix (incl. no) = {{f}}, fileumber = {{n}} persons = {{p}}',
                value = LrView.bind('title'),
                wraps = true
            },
            f:checkbox{
                title = 'de, ',
                value = LrView.bind('title_de'),
                checked_value = false
            },
            f:checkbox{
                title = '',
                value = LrView.bind('title_change'),
                checked_value = true
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
                checked_value = true
            }
        },
        f:row{
            margin_top = 10,
            f:static_text{
                width = LrView.share "label_width",
                title = "Description (en)"
            },
            f:edit_field{
                fill_horizonal = 1,
                width_in_chars = 40,
                height_in_lines = 5,
                immediate = true,
                placeholder_string = 'type {{p}} to insert person names',
                value = LrView.bind('description_en')
            },
            f:checkbox{
                title = '',
                value = LrView.bind('description_en_change'),
                checked_value = true
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
                value = LrView.bind('categories')
            },
            f:checkbox{
                title = '',
                value = LrView.bind('categories_change'),
                checked_value = true
            }
        },
        f:separator{fill_horizontal = 1},
        f:row{
            margin_top = 20,
            f:static_text{width = LrView.share "label_width", title = "Preset"},
            f:popup_menu{
                width_in_chars = 30,
                value = LrView.bind('preset'),
                items = prefs.generatorPresets
            },
            f:push_button{
                title = 'load',
                action = function(args)
                    u.copyProps(props.preset, props, {stringsOnly = true})
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
                        requiredFileType = 'json',
                        fileName = 'test.json',
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

        local data = LrTasks.startAsyncTask(function()
            local data = ''

            for key, photo in pairs(photos) do

                local regions = u.getRegions(photo)
                local fname = u.getNameParts(photo)

                -- filter "_" names

                for i = #regions, 1, -1 do
                    local firstChar = string.sub(regions[i].name or '_', 1, 1)
                    if not firstChar:match("[%w]") then
                        table.remove(regions, i)
                    end
                end

                -- u.log( json:encode( regions ) )

                -- u.log( nDescription:attributes() )

                -- local data = json.encode( u.findNodeByName(regionsList, "Area"):attributes() )

                -- if regionsList then u.log( regionsList )

                -- u.log( tostring( xmpData:childAtIndex(xmpData:childCount() - 1):name() == "Regions" ));

                catalog:withWriteAccessDo('Set Filename', function()
                    -- catalog:withPrivateWriteAccessDo('Set Filename', function()

                    local des

                    if props.title then
                        photo:setRawMetadata('title',
                                             string.gsub(
                                                 string.gsub(props.title,
                                                             '{{f}}',
                                                             fname.preName),
                                                 '{{p}}', u.getNames(regions, {
                                last = (props.title_de and " und ") or " and ",
                                inter = ", "
                            })))
                    end

                    if props.description_de then
                        --[[
                        --caption
                        
                        des = string.gsub(props.description_de, '{{p}}', u.getNames(regions, {
                            last = " und ",
                            inter = ", ",
                        }) )

                        des = string.gsub( string.gsub(des, '%[%[:de:', ''), '|%]%]', '')

                        photo:setPropertyForPlugin( _PLUGIN, 'caption_de', des )
                        ]] --

                        -- description

                        des = string.gsub(props.description_de, '{{p}}',
                                          u.getNames(regions, {
                            last = " und ",
                            inter = ", ",
                            before = "[[:de:",
                            after = "|]]"
                        }))
                        photo:setPropertyForPlugin(_PLUGIN, 'description_de',
                                                   des)
                    end

                    if props.description_en then

                        -- caption

                        des = string.gsub(props.description_en, '{{p}}',
                                          u.getNames(regions, {
                            last = " and ",
                            inter = ", "
                        }))

                        des = string.gsub(string.gsub(des, '%[%[:en:', ''),
                                          '|%]%]', '')

                        photo:setPropertyForPlugin(_PLUGIN, 'caption_en', des)

                        -- description

                        des = string.gsub(props.description_en, '{{p}}',
                                          u.getNames(regions, {
                            last = " and ",
                            inter = ", ",
                            before = "[[:en:",
                            after = "|]]"
                        }))
                        photo:setPropertyForPlugin(_PLUGIN, 'description_en',
                                                   des)
                    end

                    if props.categories then
                        local des = string.gsub(props.categories, '{{p}}',
                                                u.getNames(regions, {
                            inter = "",
                            after = ";"
                        }))
                        photo:setPropertyForPlugin(_PLUGIN, 'categories', des)
                    end

                    if regions[2] then
                        photo:setPropertyForPlugin(_PLUGIN, 'otherFields',
                                                   u.getImageNotes(regions,
                                                                   photo))
                    end

                end)
            end

            return data
        end)
    end
end)
