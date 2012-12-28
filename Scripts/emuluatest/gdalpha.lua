local gd = require("gd")
local gdImage = gd.createFromGdStr(gui.gdscreenshot())
gdImage:saveAlpha(true)
gdImage:png("gdalpha.png") -- must be opaque!
