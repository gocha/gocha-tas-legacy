-- Sprite Database Resizer for Lua Ghost Overlays
-- This private script might not be useful for most people ...

srcw, srch = 64, 64
dstw, dsth = 96, 64

srcf = "a.png"
dstf = "b.png"

require "gd"

-- return if an image is a truecolor one
gd.isTrueColor = function(im)
	if im == nil then return nil end
	local gdStr = im:gdStr()
	if gdStr == nil then return nil end
	return (gdStr:byte(2) == 254)
end
-- create a blank truecolor image
gd.createTrueColorBlank = function(x, y)
	local im = gd.createTrueColor(x, y)
	if im == nil then return nil end

	local trans = im:colorAllocateAlpha(255, 255, 255, 127)
	im:alphaBlending(false)
	im:filledRectangle(0, 0, im:sizeX() - 1, im:sizeY() - 1, trans)
	im:alphaBlending(true) -- TODO: restore the blending mode to default
	return im
end
-- return a converted image (source image won't be changed)
gd.convertToTrueColor = function(imsrc)
	if imsrc == nil then return nil end
	if gd.isTrueColor(imsrc) then return imsrc end

	local im = gd.createTrueColor(imsrc:sizeX(), imsrc:sizeY())
	if im == nil then return nil end

	im:alphaBlending(false)
	local trans = im:colorAllocateAlpha(255, 255, 255, 127)
	im:filledRectangle(0, 0, im:sizeX() - 1, im:sizeY() - 1, trans)
	im:copy(imsrc, 0, 0, 0, 0, im:sizeX(), im:sizeY())
	im:alphaBlending(true) -- TODO: set the mode which imsrc uses

	return im
end

-- end definitions

srcim = gd.convertToTrueColor(gd.createFromPng(srcf))
if srcim == nil then error("Unable to load " .. srcf) end
srcim:saveAlpha(true)
dstim = gd.createTrueColorBlank(srcim:sizeX() / srcw * dstw, srcim:sizeY() / srch * dsth)
if dstim == nil then error("Unable to create an image buffer for " .. dstf) end
dstim:saveAlpha(true)

local ox, oy = math.max(0, math.floor((dstw - srcw)/2)), math.max(0, math.floor((dsth - srch)/2))
local osx, osy = math.max(0, math.floor((srcw - dstw)/2)), math.max(0, math.floor((srch - dsth)/2))

for y = 0, (dstim:sizeY() / dsth) - 1 do
	for x = 0, (dstim:sizeX() / dstw) - 1 do
		local csrc = srcim:getPixel(x * srcw, y * srch)
		if srcim:red(csrc) == 128 and srcim:green(csrc) == 128 and srcim:blue(csrc) == 128 then
			dstim:filledRectangle(x * dstw, y * dsth, (x + 1) * dstw - 1, (y + 1) * dsth - 1, csrc)
		else
			-- keep blank
		end
	end
end

dstim:alphaBlending(false)
for y = 0, (dstim:sizeY() / dsth) - 1 do
	for x = 0, (dstim:sizeX() / dstw) - 1 do
		dstim:copy(srcim, x * dstw + ox, y * dsth + oy, x * srcw + osx, y * srch + osy, math.min(dstw, srcw), math.min(dsth, srch))
	end
end

dstim:png(dstf)
