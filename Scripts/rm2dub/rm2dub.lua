-- Rockman 2: Maxim Kischine AudioDub Script
-- Known Bugs: sfxs empty bug (I think something in FCEUX is wrong...)

local printAVS = false

local proAudioRt = require("proAudioRt")

if not proAudio.create() then
	error("proAudio initialization failed.")
end

-- audio file table
local sfxFilenames =
{
	jump = {
		"jump0.wav",
		"jump1.wav",
		"jump2.wav"
	},
	damage = {
		"damage1.wav",
		"damage2.wav"
	},
	die = {
		"die1.wav",
		"die2.wav"
	}
}

-- load audio files
local sfxs = {}
for groupName, filenames in pairs(sfxFilenames) do
	sfxs[groupName] = {}
	for i, filename in ipairs(filenames) do
		sfxs[groupName][i] = proAudio.sampleFromFile(filename)
	end
end

-- initialize RNG
math.randomseed(os.time())

-- AviSynth script dump, for video editing
function writeAVS(line)
	if printAVS then
		print(line)
	end
end
function writeAudioDubAVS(frame, audioName)
	writeAVS(string.format("a = %s.DelayAudio(f2s(%d, last))", audioName, frame))
	writeAVS(string.format("MixAudio(last, a, 1.0, 1.0)"))
end
-- and its first header part
writeAVS("AviSource(\"filename.avi\")")
writeAVS("function FrameToSeconds(int Frame, float FPS) {")
writeAVS("  return Frame / FPS")
writeAVS("}")
writeAVS("function f2s(int Frame, clip c) {")
writeAVS("  return FrameToSeconds(Frame, c.FrameRate)")
writeAVS("}")
for groupName, filenames in pairs(sfxFilenames) do
	for i, filename in ipairs(filenames) do
		writeAVS(string.format("%s%d_wav = WavSource(\"%s\")", groupName, i, filenames[i]))
	end
end

local prevYVel = 0
local prevHP = 0
local frame = 0
if emu.registerstart then
	emu.registerstart(function()
		-- prevent play sound on reset
		prevYVel = 0
		prevHP = 0
	end)
end

emu.registerafter(function()
	local yVel = memory.readbytesigned(0x0640)
	local hp = memory.readbyte(0x06c0)

	if yVel >= 4 and yVel ~= prevYVel then
		local sfxIndex = math.random(#sfxs.jump)
		proAudio.soundPlay(sfxs.jump[sfxIndex])
		writeAudioDubAVS(frame, "jump" .. sfxIndex .. "_wav")
	end
	if hp < prevHP then
		if hp == 0 then
			local sfxIndex = math.random(#sfxs.die)
			proAudio.soundPlay(sfxs.die[sfxIndex])
			writeAudioDubAVS(frame, "die" .. sfxIndex .. "_wav")
		else
			local sfxIndex = math.random(#sfxs.damage)
			proAudio.soundPlay(sfxs.damage[sfxIndex])
			writeAudioDubAVS(frame, "damage" .. sfxIndex .. "_wav")
		end
	end

	prevYVel = yVel
	prevHP = hp
	frame = frame + 1
end)

emu.registerexit(function()
	proAudio.destroy()
end)
