
-- [ begin iup common routines ] -----------------------------------------------

-- allow loading ?51.dll files
function AddPostfixToPackagePath(postfix)
	local function split(str, sep)
		local sep, fields = sep or ":", {}
		local pattern = string.format("([^%s]+)", sep)
		str:gsub(pattern, function(c) fields[#fields+1] = c end)
		return fields
	end
	local function endsWith(str, pat)
		if #str < #pat then
			return false
		end
		return str:sub(-#pat) == pat
	end

	local additionalpath = ""
	for i, v in ipairs(split(package.cpath, ";")) do
		local newpath = nil
		if endsWith(v, "?.dll") then
			newpath = v:gsub("%?.dll", "") .. "?" .. postfix .. ".dll"
		elseif endsWith(v, "?.so") then
			newpath = v:gsub("%?.so", "") .. "?" .. postfix .. ".so"
		end
		if newpath then
			local duplicated = false
			for i2, v2 in ipairs(split(package.cpath, ";")) do
				if v2 == newpath then
					duplicated = true
					break
				end
			end
			if not duplicated then
				additionalpath = additionalpath .. ";" .. newpath
			end
		end
	end
	package.cpath = package.cpath .. additionalpath
end
AddPostfixToPackagePath("51")

local IupHandleManager = {
	handles = {};

	AddHandle = function(self, handle)
		if handle and handle.destroy then
			table.insert(self.handles, handle)
		end
	end;

	DestroyHandle = function(self, handle)
		for handleIndex, handleCmp in ipairs(self.handles) do
			if handle == handleCmp then
				table.remove(self.handles, handleIndex)
				break
			end
		end
		if handle and handle.destroy then
			handle:destroy()
		end
	end;

	Dispose = function(self)
		for handleIndex, handle in ipairs(self.handles) do
			if handle and handle.destroy then
				handle:destroy()
			end
		end
		self.handles = {}
	end;
}

-- [ end iup common routines ] -------------------------------------------------

local iuplua = require("iuplua")

-- a script must destroy iup handles on exit
if emu then
	emu.registerexit(function()
		IupHandleManager:Dispose()
	end)
end

idle_cb_called = false
function testiup()
	-- Our callback function
	local function someAction(self, a) print("My button is pressed!"); end;

	-- Create a button
	myButton = iup.button{title="Press me", size="60x16"};

	-- Set the callback
	myButton.action = someAction;

	-- Create the dialog
	local dlg = iup.dialog{ myButton, title="IupDialog", resize = "NO" }

	-- Register iup handle for finalization
	IupHandleManager:AddHandle(dlg)

	-- Idle function test
	iup.SetIdle(function()
		if not idle_cb_called then
			print("Idle function is called.")
			idle_cb_called = true
		end
		return iup.DEFAULT
	end)

	-- Show the dialog
	dlg:show()
end

testiup()

if emu then
	-- We cannot use iup.MainLoop()
	-- because it never returns until all windows get closed.
	-- 
	-- iup.LoopStep() can dispatch a message and return immediately,
	-- but it seems to affect the message loop of an emulator.
	-- (for instance, a shortcut key can be sometimes ignored in VBA.)
	-- 
	-- Without those functions, we cannot call idle callback function,
	-- and possibly there are some other limitations. Anyway,
	-- I think we should not call anything after all. :(
	gui.register(function()
		--iup.LoopStep()
	end)
else
	iup.MainLoop()
end
