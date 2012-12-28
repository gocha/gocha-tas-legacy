-- small utility functions for lua-gd

if not gd then
	gd = require("gd")
end

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
	im:alphaBlending(true)
	im:saveAlpha(true)
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
	im:alphaBlending(true)
	im:saveAlpha(true)

	return im
end
-- flip an image about the vertical axis
gd.flipVertical = function(im)
	if im == nil then return nil end
	im:alphaBlending(false)
	for x = 0, im:sizeX() do
		for y = 0, math.floor(im:sizeY()/2) - 1 do
			local c1, c2 = im:getPixel(x, y), im:getPixel(x, im:sizeY()-1-y)
			im:setPixel(x, y, c2)
			im:setPixel(im:sizeX()-1-x, y, c1)
		end
	end
	im:alphaBlending(true) -- TODO: restore the mode
	return im
end
-- flip an image about the horizontal axis
gd.flipHorizontal = function(im)
	if im == nil then return nil end
	im:alphaBlending(false)
	for y = 0, im:sizeY() do
		for x = 0, math.floor(im:sizeX()/2) - 1 do
			local c1, c2 = im:getPixel(x, y), im:getPixel(im:sizeX()-1-x, y)
			im:setPixel(x, y, c2)
			im:setPixel(im:sizeX()-1-x, y, c1)
		end
	end
	im:alphaBlending(true) -- TODO: restore the mode
	return im
end
-- applies vertical and horizontal flip
gd.flipBoth = function(im)
	gd.flipVertical(im)
	gd.flipHorizontal(im)
	return im
end
-- compare two images and extract only different pixels between two images
-- return value is a truecolor gd image with alpha channel
gd.createDiff = function(imFG, imBG, ...)
	local arg = { ... }
	local xOffsetFG, yOffsetFG = 0, 0
	local xOffsetBG, yOffsetBG = 0, 0
	local width, height = math.min(imFG:sizeX(), imBG:sizeX()), math.min(imFG:sizeY(), imBG:sizeY())

	-- parse argument array
	if #arg == 4 then
		-- xOffset, yOffset, width, height
		xOffsetFG, yOffsetFG = arg[1], arg[2]
		xOffsetBG, yOffsetBG = xOffsetFG, yOffsetFG
		width, height = arg[3], arg[4]
	elseif #arg == 6 then
		-- xOffsetFG, yOffsetFG, xOffsetBG, yOffsetBG, width, height
		xOffsetFG, yOffsetFG = arg[1], arg[2]
		xOffsetBG, yOffsetBG = arg[3], arg[4]
		width, height = arg[5], arg[6]
	elseif #arg > 0 then
		error("too few/much arguments")
	end

	-- range check
	if (xOffsetFG + width > imFG:sizeX()) or (yOffsetFG + height > imFG:sizeY()) then
		error("foreground image (argument #1) is too small, or illegal offset. " .. width .. "x" .. height .. " from (" .. xOffsetFG .. "," .. yOffsetFG .. ")")
	end
	if (xOffsetBG + width > imBG:sizeX()) or (yOffsetBG + height > imBG:sizeY()) then
		error("background image (argument #2) is too small, or illegal offset. " .. width .. "x" .. height .. " from (" .. xOffsetBG .. "," .. yOffsetBG .. ")")
	end

	-- create new gd image
	local imDiff = gd.createTrueColorBlank(width, height)
	imDiff:alphaBlending(false)
	imDiff:copy(imFG, 0, 0, xOffsetFG, yOffsetFG, width, height)

	-- pixel-by-pixel processing
	local colTrans = imDiff:colorAllocateAlpha(255, 255, 255, 127)
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local colFG = imFG:getPixel(x + xOffsetFG, y + yOffsetFG)
			local colBG = imBG:getPixel(x + xOffsetBG, y + yOffsetBG)
			if imFG:red(colFG) == imBG:red(colBG) and
			   imFG:green(colFG) == imBG:green(colBG) and
			   imFG:blue(colFG) == imBG:blue(colBG)
			then
				imDiff:setPixel(x, y, colTrans)
			end
		end
	end
	imDiff:alphaBlending(true)
	imDiff:saveAlpha(true)
	return imDiff
end
