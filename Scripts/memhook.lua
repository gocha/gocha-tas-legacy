memory.registerread(0x7e00be, function(address, size)
	print("read", string.format("%x", address), size)
end)

memory.registerwrite(0x7e00be, 2, function(address, size)
	print("write", string.format("%x", address), size)
end)
