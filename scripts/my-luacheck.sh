clear
echo "*** luac -v ***"
luac -v
echo
echo "*** luac -p ***"
luac -p mediawiki.lrdevplugin/*.lua
echo "Exitcode: $?"
echo
echo "*** luacheck -v ***"
luacheck -v
echo
echo "*** luacheck ***"
luacheck mediawiki.lrdevplugin/*.lua --globals LOC WIN_ENV MAC_ENV import _PLUGIN -a --ignore 512 --max-line-length=500
echo
