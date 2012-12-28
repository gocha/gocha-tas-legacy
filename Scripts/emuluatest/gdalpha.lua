local gd = require("gd")
local gdImage = gd.createFromGdStr(gui.gdscreenshot())

local totalAlpha = 0
for y = 0, gdImage:sizeY() - 1 do
	for x = 0, gdImage:sizeX() - 1 do
		local color = gdImage:getPixel(x, y)
		local alpha = gdImage:alpha(color)
		if alpha ~= 0 then
			print("alpha test failed! A(" .. x .. "," .. y .. ")=" .. alpha)
			gdImage:saveAlpha(true)
			gdImage:png("gdalpha.png") -- must be opaque!
			return
		end
	end
end
print("alpha test passed!")
