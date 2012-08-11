local mode = "get"
local registerprefix = "" -- e.g. sub.
local registernames = {
	"a0", "a1", "a2", "a3"
}

if not memory.getregister then
	error("memory.getregister is not available")
end

for i = 1, #registernames do
	local name = registerprefix .. registernames[i]
	if mode == "set" then
		memory.setregister(name, i)
		print(name, memory.getregister(name))
	else
		print(name, memory.getregister(name))
	end
end
