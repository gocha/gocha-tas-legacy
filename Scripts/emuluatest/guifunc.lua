-- print(gui.popup("gui.popup test", "abortretryignore", "error"))
-- error("foo")

if gui.parsecolor then
	print("gui.parsecolor", gui.parsecolor("#01020304"))
else
	print("gui.parsecolor is not available")
end

NYIAlert = {}
function showAlert(name)
	if not NYIAlert[name] then
		print(name .. " is not available")
		NYIAlert[name] = true
	end
end

if not gui.transparency then
	showAlert("gui.transparency")
end

gui.register(function()
	if gui.opacity then
		gui.opacity(0.5)
	else
		showAlert("gui.opacity")
	end

	if gui.text then
		local s = ""
		if emu.framecount then
			s = s .. " " .. emu.framecount()
		end
		if gui.getpixel then
			local r, g, b = gui.getpixel(0, 0)
			s = s .. "\n" .. string.format("RGB(%d,%d,%d)", r, g, b)
		end
		gui.text(20, 20, "GUI test" .. s)
	else
		showAlert("gui.text")
	end

	if gui.opacity then
		gui.opacity(1.0)
	end

	if gui.pixel then
		gui.pixel(40, 40, "red")
	else
		showAlert("gui.pixel")
	end

	if gui.line then
		gui.line(40, 40, 80, 60, "#00ff0080")
	else
		showAlert("gui.line")
	end

	if gui.box then
		gui.box(20, 100, 60, 120, "#ffff00", "#00ffff")
	else
		showAlert("gui.box")
	end
end)
