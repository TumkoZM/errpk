local REPOSITOTY = "https://raw.githubusercontent.com/Tumkov/bleb/main"

local shell = require("shell")
shell.execute("wget -f " .. REPOSITOTY .. "/launcher.lua /home/1.lua")
shell.execute("wget -f " .. REPOSITOTY .. "/libs/casino.lua /lib/casino.lua")
shell.execute("wget -f " .. REPOSITOTY .. "/config/settings.lua /lib/settings.lua")
shell.execute("edit /lib/settings.lua")
