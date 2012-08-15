local mode = "get"
local registerprefix = "main." -- e.g. sub.
local registernames = {
	"db", "p", "e", "a", "d", "s", "x", "y", "pb", "pc", "pbpc"
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
