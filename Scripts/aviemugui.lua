-- wrapper for emulua gui functions for aviutl
-- the easiest way to draw emulua overlays in avi

-- a script to specify what to draw for each frame
local drawcodefname = "drawcode.lua"
-- example script:
--[[
	gui.pixel(50, 50) -- frame #1: draw a pixel
	gui.pixel(50, 50) gui.box(20,20,80,80) -- frame #2: draw a pixel and a box
	gui.pixel(51, 51) -- frame #3: draw a pixel
	-- frame #4+: draw nothing
]]

if not aviutl then
	error("This script runs under lua for aviutl.")
end

-- emulua compatible gui functions
gui = {
opacityValue = 1.0,
opacity = function(level)
	gui.opacityValue = math.max(0.0, tonumber(level))
end;
transparency = function(trans)
	gui.opacityValue = (4.0 - trans) / 4.0
end;
parsecolor = function(color)
	if type(color) == "nil" then
		return nil
	elseif type(color) == "string" then
		local name = color:lower()
		if color:sub(1,1) == "#" then
			local val = tonumber(color:sub(2), 16)
			local missing = math.max(0, 9 - #color)
			val = val * math.pow(2, missing * 4)
			if missing >= 2 then val = val - (val%256) + 255 end
			return math.floor(val/0x1000000)%256, math.floor(val/0x10000)%256, math.floor(val/0x100)%256, val%256
		elseif name == "rand" then
			return math.random(0,255), math.random(0,255), math.random(0,255), 255
		else
			local s_colorMapping = {
				{ "white",     255, 255, 255, 255 },
				{ "black",       0,   0,   0, 255 },
				{ "clear",       0,   0,   0,   0 },
				{ "gray",      127, 127, 127, 255 },
				{ "grey",      127, 127, 127, 255 },
				{ "red",       255,   0,   0, 255 },
				{ "orange",    255, 127,   0, 255 },
				{ "yellow",    255, 255,   0, 255 },
				{ "chartreuse",127, 255,   0, 255 },
				{ "green",       0, 255,   0, 255 },
				{ "teal",        0, 255, 127, 255 },
				{ "cyan" ,       0, 255, 255, 255 },
				{ "blue",        0,   0, 255, 255 },
				{ "purple",    127,   0, 255, 255 },
				{ "magenta",   255,   0, 255, 255 }
			}
			for i, e in ipairs(s_colorMapping) do
				if name == e[1] then
					return e[2], e[3], e[4], e[5]
				end
			end
			error("unknown color " .. color)
		end
	elseif type(color) == "number" then
		return math.floor(color/0x1000000)%256, math.floor(color/0x10000)%256, math.floor(color/0x100)%256, color%256
	elseif type(color) == "table" then
		local r, g, b, a = 0, 0, 0, 255
		for k, v in pairs(color) do
			if k == 1 or k == "r" then
				r = v
			elseif k == 2 or k == "g" then
				g = v
			elseif k == 3 or k == "b" then
				b = v
			elseif k == 4 or k == "a" then
				a = v
			end
		end
		return r, g, b, a
	elseif type(color) == "function" then
		error("color function is not supported")
	else
		error("unknown color " .. tostring(color))
	end
end;
getpixel = function(x,y)
	local yv, cb, cr = aviutl.get_pixel(aviutl.get_ycp_edit(), x, y)
	return aviutl.yc2rgb(yv, cb, cr)
end;
text = function(x,y,str,color,outlinecolor)
	if color == nil then color = "white" end
	if outlinecolor == nil then outlinecolor = "black" end
	local drawtext = function(x,y,str,color)
		local r, g, b, a = gui.parsecolor(color)
		local yv, cb, cr = aviutl.rgb2yc(r, g, b)
		local av = math.floor((1.0-(a/255.0 * gui.opacityValue)) * 4096)
		av = math.max(0, math.min(4096, av))
		aviutl.draw_text(aviutl.get_ycp_edit(), x, y, str, r, g, b, av, "Arial", 12)
	end
	-- FIXME: transparent text
	drawtext(x-1,y-1,str,outlinecolor)
	drawtext(x+1,y-1,str,outlinecolor)
	drawtext(x-1,y+1,str,outlinecolor)
	drawtext(x+1,y+1,str,outlinecolor)
	drawtext(x,y,str,color)
end;
box = function(x1,y1,x2,y2,fillcolor,outlinecolor)
	if x1 > x2 then x1, x2 = x2, x1 end
	if y1 > y2 then y1, y2 = y2, y1 end

	if fillcolor == nil then fillcolor = { 255, 255, 255, 63 } end
	local rf, gf, bf, af = gui.parsecolor(fillcolor)
	local yvf, cbf, crf = aviutl.rgb2yc(rf, gf, bf)
	local avf = math.floor((1.0-(af/255.0 * gui.opacityValue)) * 4096)
	avf = math.max(0, math.min(4096, avf))
	if outlinecolor == nil then outlinecolor = { rf, gf, bf, 255 } end
	local ro, go, bo, ao = gui.parsecolor(outlinecolor)
	local yvo, cbo, cro = aviutl.rgb2yc(ro, go, bo)
	local avo = math.floor((1.0-(ao/255.0 * gui.opacityValue)) * 4096)
	avo = math.max(0, math.min(4096, avo))

	local ycp_edit = aviutl.get_ycp_edit()
	aviutl.line(ycp_edit, x1, y1, x2, y1, yvo, cbo, cro, avo)
	if y1 ~= y2 then
		aviutl.line(ycp_edit, x1, y1+1, x1, y2, yvo, cbo, cro, avo)
		if x1 ~= x2 then
			aviutl.line(ycp_edit, x2, y1+1, x2, y2, yvo, cbo, cro, avo)
			aviutl.line(ycp_edit, x1+1, y2, x2-1, y2, yvo, cbo, cro, avo)
		end
	end
	if (x2 - x1 >= 2) and (y2 - y1 >= 2) then
		aviutl.box(ycp_edit, x1+1, y1+1, x2-1, y2-1, yvf, cbf, crf, avf)
	end
end;
line = function(x1,y1,x2,y2,color,skipfirst) -- NYI: skipfirst
	if color == nil then color = "white" end
	local r, g, b, a = gui.parsecolor(color)
	local yv, cb, cr = aviutl.rgb2yc(r, g, b)
	local av = math.floor((1.0-(a/255.0 * gui.opacityValue)) * 4096)
	av = math.max(0, math.min(4096, av))
	aviutl.line(aviutl.get_ycp_edit(), x1, y1, x2, y2, yv, cb, cr, av)
end;
pixel = function(x,y,color)
	if color == nil then color = "white" end
	local r, g, b, a = gui.parsecolor(color)
	local yv, cb, cr = aviutl.rgb2yc(r, g, b)
	local av = math.floor((1.0-(a/255.0 * gui.opacityValue)) * 4096)
	av = math.max(0, math.min(4096, av))
	aviutl.set_pixel(aviutl.get_ycp_edit(), x, y, yv, cb, cr, av)
end;
gdoverlay = function(...)
	local arg = {...}
	local index = 1
	local x, y = 0, 0
	if type(arg[index]) == "number" then
		x, y = arg[index], arg[index+1]
		index = index + 2
	end
	local gdStr = arg[index]
	index = index + 1
	local hasSrcRect = ((#arg - index + 1) > 1)
	local sx, sy, sw, sh = 0, 0, 0, 0
	if hasSrcRect then
		sx, sy, sw, sh = arg[index], arg[index+1], arg[index+2], arg[index+3]
		index = index + 4
	end
	local av = ((arg[index] ~= nil) and arg[index] or 1.0)
	av = math.floor((1.0-(av * gui.opacityValue)) * 4096)
	av = math.max(0, math.min(4096, av))
	if hasSrcRect then
		aviutl.gdoverlay(aviutl.get_ycp_edit(), x, y, gdStr, sx, sy, sw, sh, av)
	else
		aviutl.gdoverlay(aviutl.get_ycp_edit(), x, y, gdStr, av)
	end
end
}
-- alternative names
gui.readpixel = gui.getpixel
gui.drawtext = gui.text
gui.drawbox = gui.box
gui.rect = gui.box
gui.drawrect = gui.box
gui.drawline = gui.line
gui.setpixel = gui.pixel
gui.drawpixel = gui.pixel
gui.writepixel = gui.pixel
gui.drawimage = gui.gdoverlay
gui.image = gui.gdoverlay

-- load draw script
function load_drawcode(filename)
	local f = 1
	local drawcode = {}

	-- compile each line
	for line in io.lines(filename) do
		drawcode[f] = assert(loadstring(line))
		f = f + 1
	end

	return drawcode
end
drawcode = load_drawcode(drawcodefname)

-- aviutl: process a frame
function func_proc()
	local f = aviutl.get_frame() + 1
	if drawcode[f] then drawcode[f]() end
end

-- aviutl: finalize script
function func_exit()
end
