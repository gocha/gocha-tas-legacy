-- print(gui.popup("gui.popup test", "abortretryignore", "error"))
-- error("foo")

if gui.parsecolor then
	print(gui.parsecolor("#01020304"))
else
	print("gui.parsecolor", "nil")
end

print(gui.transparency)
gui.register(function()
	gui.opacity(0.5)
	gui.text(20, 20, "GUI test")
	gui.opacity(1.0)
	gui.pixel(40, 40, "red")
	gui.line(40, 40, 80, 60, "#00ff0080")
	gui.box(20, 100, 60, 120, "#ffff00", "#00ffff")
end)

-- TODO gui.getpixel
