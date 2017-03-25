-- This file is part of the LrMediaWiki project and distributed under the terms
-- of the MIT license (see LICENSE.txt file in the project root directory or
-- [0]).  See [1] for more information about LrMediaWiki.
--
-- Copyright (C) 2015 by the LrMediaWiki team (see CREDITS.txt file in the
-- project root directory or [2])
--
-- [0]  <https://raw.githubusercontent.com/robinkrahl/LrMediaWiki/master/LICENSE.txt>
-- [1]  <https://commons.wikimedia.org/wiki/Commons:LrMediaWiki>
-- [2]  <https://raw.githubusercontent.com/robinkrahl/LrMediaWiki/master/CREDITS.txt>

-- Code status:
-- doc:   missing
-- i18n:  complete

local LrView = import 'LrView'

local MediaWikiUtils = require 'MediaWikiUtils'

local bind = LrView.bind

local MediaWikiPluginInfoProvider = {}

MediaWikiPluginInfoProvider.startDialog = function(propertyTable)
  propertyTable.create_snapshots = MediaWikiUtils.getCreateSnapshots()
  propertyTable.export_keyword = MediaWikiUtils.getExportKeyword()
  propertyTable.check_version = MediaWikiUtils.getCheckVersion()
  propertyTable.logging = MediaWikiUtils.getLogging()
end

MediaWikiPluginInfoProvider.endDialog = function(propertyTable)
  MediaWikiUtils.setCreateSnapshots(propertyTable.create_snapshots)
  MediaWikiUtils.setExportKeyword(propertyTable.export_keyword)
  MediaWikiUtils.setCheckVersion(propertyTable.check_version)
  MediaWikiUtils.setLogging(propertyTable.logging)
end

MediaWikiPluginInfoProvider.sectionsForTopOfDialog = function(viewFactory, propertyTable)
	local labelAlignment = 'right'
	local exportKeywordTooltip = LOC "$$$/LrMediaWiki/Section/Config/ExportKeywordTooltip=If set, this keyword is added after successful export."

	return {
		{
			title = LOC "$$$/LrMediaWiki/Section/Config/Title=LrMediaWiki Configuration",
			synopsis = bind 'export_keyword',
			bind_to_object = propertyTable,

			viewFactory:row {
				spacing = viewFactory:control_spacing(),
				viewFactory:static_text {
					width = LrView.share 'label_width',
					title = LOC "$$$/LrMediaWiki/Section/Config/ExportKeyword=Export Keyword" .. ':',
					alignment = labelAlignment,
					tooltip = exportKeywordTooltip,
				},

				viewFactory:edit_field {
					value = bind 'export_keyword',
					immediate = true,
					width = 222,
					tooltip = exportKeywordTooltip,
				},
			},

			viewFactory:row {
				viewFactory:checkbox {
					value = bind 'create_snapshots',
					title = LOC "$$$/LrMediaWiki/Section/Config/Snapshots=Create snapshots on export",
					tooltip = LOC "$$$/LrMediaWiki/Section/Config/SnapshotsTooltip=If set, a snapshot is created after successful export.",
				},
			},

			viewFactory:row {
				viewFactory:checkbox {
					value = bind 'check_version',
					title = LOC "$$$/LrMediaWiki/Section/Config/Version=Check for new plug-in version after Lightroom starts",
					tooltip = LOC "$$$/LrMediaWiki/Section/Config/VersionTooltip=If set, a call to GitHub is performed to determine the latest version number, which is then compared to the installed version.",
				},
			},

			viewFactory:separator {
				fill_horizontal = 1,
			},

			viewFactory:row {
				viewFactory:checkbox {
					value = bind 'logging',
					title = LOC "$$$/LrMediaWiki/Section/Config/Logging=Enable logging",
				},
			},

			viewFactory:row {
				viewFactory:static_text {
					title = LOC "$$$/LrMediaWiki/Section/Config/Logging/Description=If logging is enabled, all API requests are logged to “Documents/LrMediaWikiLogger.log”.",
					wrap = true,
				},
			},

			viewFactory:row {
				viewFactory:static_text {
					title = LOC "$$$/LrMediaWiki/Section/Config/Logging/Warning=Warning" .. ':',
					font = '<system/bold>',
				},

				viewFactory:static_text {
					title = LOC "$$$/LrMediaWiki/Section/Config/Logging/Password=The log file contains your password!",
				},
			},
		},
	}
end

return MediaWikiPluginInfoProvider
