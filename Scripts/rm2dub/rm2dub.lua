require("proAudioRt")
if not proAudio.create() then os.exit(1) end

local sfxs =
{
	jump = {
		proAudio.sampleFromFile("jump0.wav"),
		proAudio.sampleFromFile("jump1.wav"),
		proAudio.sampleFromFile("jump2.wav")
	},
	damage = {
		proAudio.sampleFromFile("damage1.wav"),
		proAudio.sampleFromFile("damage2.wav")
	},
	die = {
		proAudio.sampleFromFile("die1.wav"),
		proAudio.sampleFromFile("die2.wav")
	}
}

math.randomseed(os.time())

local prevYVel = 0
local prevHP = 0
emu.registerafter(function()
	local yVel = memory.readbytesigned(0x0640)
	local hp = memory.readbyte(0x06c0)
	if yVel >= 4 and yVel ~= prevYVel then
		proAudio.soundPlay(sfxs.jump[math.random(#sfxs.jump)])
	end
	if hp < prevHP then
		if hp == 0 then
			proAudio.soundPlay(sfxs.die[math.random(#sfxs.die)])
		else
			proAudio.soundPlay(sfxs.damage[math.random(#sfxs.damage)])
		end
	end
	prevYVel = yVel
	prevHP = hp
end)

emu.registerexit(function()
	proAudio.destroy()
end)
