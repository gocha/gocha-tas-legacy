-- movie.setrerecordcount(5555)
-- movie.setreadonly(true)

if movie.active then
	print("movie.active", movie.active())
else
	print("movie.active is not available")
end

if movie.recording then
	print("movie.recording", movie.recording())
else
	print("movie.recording is not available")
end

if movie.playing then
	print("movie.playing", movie.playing())
else
	print("movie.playing is not available")
end

if movie.mode then
	print("movie.mode", movie.mode())
else
	print("movie.mode is not available")
end

if movie.length then
	print("movie.length", movie.length())
else
	print("movie.length is not available")
end

if movie.name then
	print("movie.name", movie.name())
else
	print("movie.name is not available")
end

if movie.rerecordcount then
	print("movie.rerecordcount", movie.rerecordcount())
else
	print("movie.rerecordcount is not available")
end

if movie.readonly then
	print("movie.readonly", movie.readonly())
else
	print("movie.readonly is not available")
end

if movie.framecount then
	print("movie.framecount", movie.framecount())
else
	print("movie.framecount is not available")
end
