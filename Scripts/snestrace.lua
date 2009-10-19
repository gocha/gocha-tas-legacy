-- SNES Trace Logger, based on the disassembler of bsnes

if not emu then emu = snes9x end
if not bit then require("bit") end

-- return info string about current instruction and registers.
function gettraceline(cpuname)
	local OPTYPE_DP       = 1   -- dp
	local OPTYPE_DPX      = 2   -- dp,x
	local OPTYPE_DPY      = 3   -- dp,y
	local OPTYPE_IDP      = 4   -- (dp)
	local OPTYPE_IDPX     = 5   -- (dp,x)
	local OPTYPE_IDPY     = 6   -- (dp),y
	local OPTYPE_ILDP     = 7   -- [dp]
	local OPTYPE_ILDPY    = 8   -- [dp],y
	local OPTYPE_ADDR     = 9   -- addr
	local OPTYPE_ADDRX    = 10  -- addr,x
	local OPTYPE_ADDRY    = 11  -- addr,y
	local OPTYPE_IADDRX   = 12  -- (addr,x)
	local OPTYPE_ILADDR   = 13  -- [addr]
	local OPTYPE_LONG     = 14  -- long
	local OPTYPE_LONGX    = 15  -- long, x
	local OPTYPE_SR       = 16  -- sr,s
	local OPTYPE_ISRY     = 17  -- (sr,s),y
	local OPTYPE_ADDR_PC  = 18  -- pbr:addr
	local OPTYPE_IADDR_PC = 19  -- pbr:(addr)
	local OPTYPE_RELB     = 20  -- relb
	local OPTYPE_RELW     = 21  -- relw

	local cpuprefix = cpuname
	if cpuprefix == nil then cpuprefix = "" end
	if cpuprefix ~= ""  then cpuprefix = cpuprefix .. "." end
	local flags = memory.getregister(cpuprefix.."p")
	local regs = {
		a = memory.getregister(cpuprefix.."a"),
		x = memory.getregister(cpuprefix.."x"),
		y = memory.getregister(cpuprefix.."y"),
		s = memory.getregister(cpuprefix.."s"),
		d = memory.getregister(cpuprefix.."d"),
		db = memory.getregister(cpuprefix.."db"),
		pb = memory.getregister(cpuprefix.."pb"),
		pc = memory.getregister(cpuprefix.."pc"),
		pbpc = memory.getregister(cpuprefix.."pbpc"),
		e = (bit.band(memory.getregister(cpuprefix.."e"), 1)~=0),
		p = {
			n = (bit.band(flags, 0x80)~=0),
			v = (bit.band(flags, 0x40)~=0),
			m = (bit.band(flags, 0x20)~=0),
			x = (bit.band(flags, 0x10)~=0),
			d = (bit.band(flags, 0x08)~=0),
			i = (bit.band(flags, 0x04)~=0),
			z = (bit.band(flags, 0x02)~=0),
			c = (bit.band(flags, 0x01)~=0),
			b = flags
		}
	}

	local toint8  = function(a) bit.band(a, 0xff)   if a < 0x80   then return a else return a - 0x100   end end
	local toint16 = function(a) bit.band(a, 0xffff) if a < 0x8000 then return a else return a - 0x10000 end end
	local readwordbyte = function(addr)
		return memory.readword(addr) + bit.lshift(memory.readbyte(addr+2), 16)
	end
	local decode = {
	[OPTYPE_DP] = function(addr)
		return bit.band(regs.d + bit.band(addr, 0xffff), 0xffff)
	end;
	[OPTYPE_DPX] = function(addr)
		return bit.band((regs.d + regs.x + bit.band(addr, 0xffff)), 0xffff)
	end;
	[OPTYPE_DPY] = function(addr)
		return bit.band((regs.d + regs.y + bit.band(addr, 0xffff)), 0xffff)
	end;
	[OPTYPE_IDP] = function(addr)
		addr = bit.band((regs.d + bit.band(addr, 0xffff)), 0xffff)
		return bit.lshift(regs.db, 16) + memory.readword(addr)
	end;
	[OPTYPE_IDPX] = function(addr)
		addr = bit.band((regs.d + regs.x + bit.band(addr, 0xffff)), 0xffff)
		return bit.lshift(regs.db, 16) + memory.readword(addr)
	end;
	[OPTYPE_IDPY] = function(addr)
		addr = bit.band((regs.d + bit.band(addr, 0xffff)), 0xffff)
		return bit.band(bit.lshift(regs.db, 16) + memory.readword(addr) + regs.y, 0xffffff)
	end;
	[OPTYPE_ILDP] = function(addr)
		addr = bit.band(regs.d + bit.band(addr, 0xffff), 0xffff)
		return readwordbyte(addr)
	end;
	[OPTYPE_ILDPY] = function(addr)
		addr = bit.band((regs.d + bit.band(addr, 0xffff)), 0xffff)
		return bit.band(readwordbyte(addr) + regs.y, 0xffffff)
	end;
	[OPTYPE_ADDR] = function(addr)
		return bit.lshift(regs.db, 16) + bit.band(addr, 0xffff)
	end;
	[OPTYPE_ADDR_PC] = function(addr)
		return bit.lshift(regs.pb, 16) + bit.band(addr, 0xffff)
	end;
	[OPTYPE_ADDRX] = function(addr)
		return bit.band(bit.lshift(regs.db, 16) + bit.band(addr, 0xffff) + regs.x, 0xffffff)
	end;
	[OPTYPE_ADDRY] = function(addr)
		return bit.band(bit.lshift(regs.db, 16) + bit.band(addr, 0xffff) + regs.y, 0xffffff)
	end;
	[OPTYPE_IADDR_PC] = function(addr)
		return bit.lshift(regs.pb, 16) + bit.band(addr, 0xffff)
	end;
	[OPTYPE_IADDRX] = function(addr)
		return bit.lshift(regs.pb, 16) + bit.band((addr + regs.x), 0xffff)
	end;
	[OPTYPE_ILADDR] = function(addr)
		return bit.band(addr, 0xffffff)
	end;
	[OPTYPE_LONG] = function(addr)
		return bit.band(addr, 0xffffff)
	end;
	[OPTYPE_LONGX] = function(addr)
		return bit.band(addr + regs.x, 0xffffff)
	end;
	[OPTYPE_SR] = function(addr)
		return bit.band((regs.s + bit.band(addr, 0xff)), 0xffff)
	end;
	[OPTYPE_ISRY] = function(addr)
		addr = bit.band((regs.s + bit.band(addr, 0xff)), 0xffff)
		return bit.band(bit.lshift(regs.db, 16) + memory.readword(addr) + regs.y, 0xffffff)
	end;
	[OPTYPE_RELB] = function(addr)
		return bit.band(bit.lshift(regs.pb, 16) + bit.band((regs.pc + 2), 0xffff) + toint8(addr), 0xffffff)
	end;
	[OPTYPE_RELW] = function(addr)
		return bit.band(bit.lshift(regs.pb, 16) + bit.band((regs.pc + 3), 0xffff) + toint16(addr), 0xffffff)
	end
	}

	local line = ""

	local pc = regs.pbpc
	line = line .. string.format("%.6x ", pc)

	local op = memory.readbyte(pc)
	local op8 = memory.readbyte(pc+1)
	local op16 = memory.readword(pc+1)
	local op24 = readwordbyte(pc+1)
	local a8 = (regs.e or regs.p.m)
	local x8 = (regs.e or regs.p.x)

	local disasm = {
	[0x00] = function() return string.format("brk #$%.2x              ", op8) end;
	[0x01] = function() return string.format("ora ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8)) end;
	[0x02] = function() return string.format("cop #$%.2x              ", op8) end;
	[0x03] = function() return string.format("ora $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8)) end;
	[0x04] = function() return string.format("tsb $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x05] = function() return string.format("ora $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x06] = function() return string.format("asl $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x07] = function() return string.format("ora [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8)) end;
	[0x08] = function() return string.format("php                   ") end;
	[0x09] = function() if a8 then return string.format("ora #$%.2x              ", op8)
	                            else return string.format("ora #$%.4x            ", op16) end end;
	[0x0a] = function() return string.format("asl a                 ") end;
	[0x0b] = function() return string.format("phd                   ") end;
	[0x0c] = function() return string.format("tsb $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x0d] = function() return string.format("ora $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x0e] = function() return string.format("asl $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x0f] = function() return string.format("ora $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24)) end;
	[0x10] = function() return string.format("bpl $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8)) end;
	[0x11] = function() return string.format("ora ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8)) end;
	[0x12] = function() return string.format("ora ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8)) end;
	[0x13] = function() return string.format("ora ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8)) end;
	[0x14] = function() return string.format("trb $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x15] = function() return string.format("ora $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x16] = function() return string.format("asl $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x17] = function() return string.format("ora [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8)) end;
	[0x18] = function() return string.format("clc                   ") end;
	[0x19] = function() return string.format("ora $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16)) end;
	[0x1a] = function() return string.format("inc                   ") end;
	[0x1b] = function() return string.format("tcs                   ") end;
	[0x1c] = function() return string.format("trb $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x1d] = function() return string.format("ora $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x1e] = function() return string.format("asl $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x1f] = function() return string.format("ora $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24)) end;
	[0x20] = function() return string.format("jsr $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR_PC](op16)) end;
	[0x21] = function() return string.format("and ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8)) end;
	[0x22] = function() return string.format("jsl $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24)) end;
	[0x23] = function() return string.format("and $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8)) end;
	[0x24] = function() return string.format("bit $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x25] = function() return string.format("and $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x26] = function() return string.format("rol $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x27] = function() return string.format("and [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8)) end;
	[0x28] = function() return string.format("plp                   ") end;
	[0x29] = function() if a8 then return string.format("and #$%.2x              ", op8)
	                            else return string.format("and #$%.4x            ", op16) end end;
	[0x2a] = function() return string.format("rol a                 ") end;
	[0x2b] = function() return string.format("pld                   ") end;
	[0x2c] = function() return string.format("bit $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x2d] = function() return string.format("and $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x2e] = function() return string.format("rol $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x2f] = function() return string.format("and $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24)) end;
	[0x30] = function() return string.format("bmi $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8)) end;
	[0x31] = function() return string.format("and ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8)) end;
	[0x32] = function() return string.format("and ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8)) end;
	[0x33] = function() return string.format("and ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8)) end;
	[0x34] = function() return string.format("bit $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x35] = function() return string.format("and $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x36] = function() return string.format("rol $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x37] = function() return string.format("and [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8)) end;
	[0x38] = function() return string.format("sec                   ") end;
	[0x39] = function() return string.format("and $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16)) end;
	[0x3a] = function() return string.format("dec                   ") end;
	[0x3b] = function() return string.format("tsc                   ") end;
	[0x3c] = function() return string.format("bit $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x3d] = function() return string.format("and $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x3e] = function() return string.format("rol $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x3f] = function() return string.format("and $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24)) end;
	[0x40] = function() return string.format("rti                   ") end;
	[0x41] = function() return string.format("eor ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8)) end;
	[0x42] = function() return string.format("wdm                   ") end;
	[0x43] = function() return string.format("eor $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8)) end;
	[0x44] = function() return string.format("mvp $%.2x,$%.2x           ", op1, op8) end;
	[0x45] = function() return string.format("eor $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x46] = function() return string.format("lsr $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x47] = function() return string.format("eor [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8)) end;
	[0x48] = function() return string.format("pha                   ") end;
	[0x49] = function() if a8 then return string.format("eor #$%.2x              ", op8)
	                            else return string.format("eor #$%.4x            ", op16) end end;
	[0x4a] = function() return string.format("lsr a                 ") end;
	[0x4b] = function() return string.format("phk                   ") end;
	[0x4c] = function() return string.format("jmp $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR_PC](op16)) end;
	[0x4d] = function() return string.format("eor $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x4e] = function() return string.format("lsr $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x4f] = function() return string.format("eor $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24)) end;
	[0x50] = function() return string.format("bvc $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8)) end;
	[0x51] = function() return string.format("eor ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8)) end;
	[0x52] = function() return string.format("eor ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8)) end;
	[0x53] = function() return string.format("eor ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8)) end;
	[0x54] = function() return string.format("mvn $%.2x,$%.2x           ", op1, op8) end;
	[0x55] = function() return string.format("eor $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x56] = function() return string.format("lsr $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x57] = function() return string.format("eor [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8)) end;
	[0x58] = function() return string.format("cli                   ") end;
	[0x59] = function() return string.format("eor $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16)) end;
	[0x5a] = function() return string.format("phy                   ") end;
	[0x5b] = function() return string.format("tcd                   ") end;
	[0x5c] = function() return string.format("jml $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24)) end;
	[0x5d] = function() return string.format("eor $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x5e] = function() return string.format("lsr $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x5f] = function() return string.format("eor $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24)) end;
	[0x60] = function() return string.format("rts                   ") end;
	[0x61] = function() return string.format("adc ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8)) end;
	[0x62] = function() return string.format("per $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x63] = function() return string.format("adc $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8)) end;
	[0x64] = function() return string.format("stz $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x65] = function() return string.format("adc $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x66] = function() return string.format("ror $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x67] = function() return string.format("adc [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8)) end;
	[0x68] = function() return string.format("pla                   ") end;
	[0x69] = function() if a8 then return string.format("adc #$%.2x              ", op8)
	                            else return string.format("adc #$%.4x            ", op16) end end;
	[0x6a] = function() return string.format("ror a                 ") end;
	[0x6b] = function() return string.format("rtl                   ") end;
	[0x6c] = function() return string.format("jmp ($%.4x)   [%.6x]", op16, decode[OPTYPE_IADDR_PC](op16)) end;
	[0x6d] = function() return string.format("adc $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x6e] = function() return string.format("ror $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x6f] = function() return string.format("adc $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24)) end;
	[0x70] = function() return string.format("bvs $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8)) end;
	[0x71] = function() return string.format("adc ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8)) end;
	[0x72] = function() return string.format("adc ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8)) end;
	[0x73] = function() return string.format("adc ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8)) end;
	[0x74] = function() return string.format("stz $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x75] = function() return string.format("adc $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x76] = function() return string.format("ror $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x77] = function() return string.format("adc [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8)) end;
	[0x78] = function() return string.format("sei                   ") end;
	[0x79] = function() return string.format("adc $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16)) end;
	[0x7a] = function() return string.format("ply                   ") end;
	[0x7b] = function() return string.format("tdc                   ") end;
	[0x7c] = function() return string.format("jmp ($%.4x,x) [%.6x]", op16, decode[OPTYPE_IADDRX](op16)) end;
	[0x7d] = function() return string.format("adc $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x7e] = function() return string.format("ror $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x7f] = function() return string.format("adc $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24)) end;
	[0x80] = function() return string.format("bra $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8)) end;
	[0x81] = function() return string.format("sta ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8)) end;
	[0x82] = function() return string.format("brl $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELW](op16), 0xffff), decode[OPTYPE_RELW](op16)) end;
	[0x83] = function() return string.format("sta $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8)) end;
	[0x84] = function() return string.format("sty $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x85] = function() return string.format("sta $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x86] = function() return string.format("stx $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0x87] = function() return string.format("sta [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8)) end;
	[0x88] = function() return string.format("dey                   ") end;
	[0x89] = function() if a8 then return string.format("bit #$%.2x              ", op8)
	                            else return string.format("bit #$%.4x            ", op16) end end;
	[0x8a] = function() return string.format("txa                   ") end;
	[0x8b] = function() return string.format("phb                   ") end;
	[0x8c] = function() return string.format("sty $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x8d] = function() return string.format("sta $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x8e] = function() return string.format("stx $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x8f] = function() return string.format("sta $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24)) end;
	[0x90] = function() return string.format("bcc $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8)) end;
	[0x91] = function() return string.format("sta ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8)) end;
	[0x92] = function() return string.format("sta ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8)) end;
	[0x93] = function() return string.format("sta ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8)) end;
	[0x94] = function() return string.format("sty $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x95] = function() return string.format("sta $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0x96] = function() return string.format("stx $%.2x,y     [%.6x]", op8, decode[OPTYPE_DPY](op8)) end;
	[0x97] = function() return string.format("sta [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8)) end;
	[0x98] = function() return string.format("tya                   ") end;
	[0x99] = function() return string.format("sta $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16)) end;
	[0x9a] = function() return string.format("txs                   ") end;
	[0x9b] = function() return string.format("txy                   ") end;
	[0x9c] = function() return string.format("stz $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0x9d] = function() return string.format("sta $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x9e] = function() return string.format("stz $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0x9f] = function() return string.format("sta $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24)) end;
	[0xa0] = function() if x8 then return string.format("ldy #$%.2x              ", op8)
	                            else return string.format("ldy #$%.4x            ", op16) end end;
	[0xa1] = function() return string.format("lda ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8)) end;
	[0xa2] = function() if x8 then return string.format("ldx #$%.2x              ", op8)
	                            else return string.format("ldx #$%.4x            ", op16) end end;
	[0xa3] = function() return string.format("lda $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8)) end;
	[0xa4] = function() return string.format("ldy $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0xa5] = function() return string.format("lda $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0xa6] = function() return string.format("ldx $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0xa7] = function() return string.format("lda [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8)) end;
	[0xa8] = function() return string.format("tay                   ") end;
	[0xa9] = function() if a8 then return string.format("lda #$%.2x              ", op8)
	                            else return string.format("lda #$%.4x            ", op16) end end;
	[0xaa] = function() return string.format("tax                   ") end;
	[0xab] = function() return string.format("plb                   ") end;
	[0xac] = function() return string.format("ldy $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0xad] = function() return string.format("lda $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0xae] = function() return string.format("ldx $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0xaf] = function() return string.format("lda $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24)) end;
	[0xb0] = function() return string.format("bcs $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8)) end;
	[0xb1] = function() return string.format("lda ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8)) end;
	[0xb2] = function() return string.format("lda ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8)) end;
	[0xb3] = function() return string.format("lda ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8)) end;
	[0xb4] = function() return string.format("ldy $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0xb5] = function() return string.format("lda $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0xb6] = function() return string.format("ldx $%.2x,y     [%.6x]", op8, decode[OPTYPE_DPY](op8)) end;
	[0xb7] = function() return string.format("lda [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8)) end;
	[0xb8] = function() return string.format("clv                   ") end;
	[0xb9] = function() return string.format("lda $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16)) end;
	[0xba] = function() return string.format("tsx                   ") end;
	[0xbb] = function() return string.format("tyx                   ") end;
	[0xbc] = function() return string.format("ldy $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0xbd] = function() return string.format("lda $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0xbe] = function() return string.format("ldx $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16)) end;
	[0xbf] = function() return string.format("lda $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24)) end;
	[0xc0] = function() if x8 then return string.format("cpy #$%.2x              ", op8)
	                            else return string.format("cpy #$%.4x            ", op16) end end;
	[0xc1] = function() return string.format("cmp ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8)) end;
	[0xc2] = function() return string.format("rep #$%.2x              ", op8) end;
	[0xc3] = function() return string.format("cmp $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8)) end;
	[0xc4] = function() return string.format("cpy $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0xc5] = function() return string.format("cmp $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0xc6] = function() return string.format("dec $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0xc7] = function() return string.format("cmp [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8)) end;
	[0xc8] = function() return string.format("iny                   ") end;
	[0xc9] = function() if a8 then return string.format("cmp #$%.2x              ", op8)
	                            else return string.format("cmp #$%.4x            ", op16) end end;
	[0xca] = function() return string.format("dex                   ") end;
	[0xcb] = function() return string.format("wai                   ") end;
	[0xcc] = function() return string.format("cpy $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0xcd] = function() return string.format("cmp $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0xce] = function() return string.format("dec $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0xcf] = function() return string.format("cmp $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24)) end;
	[0xd0] = function() return string.format("bne $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8)) end;
	[0xd1] = function() return string.format("cmp ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8)) end;
	[0xd2] = function() return string.format("cmp ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8)) end;
	[0xd3] = function() return string.format("cmp ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8)) end;
	[0xd4] = function() return string.format("pei ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8)) end;
	[0xd5] = function() return string.format("cmp $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0xd6] = function() return string.format("dec $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0xd7] = function() return string.format("cmp [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8)) end;
	[0xd8] = function() return string.format("cld                   ") end;
	[0xd9] = function() return string.format("cmp $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16)) end;
	[0xda] = function() return string.format("phx                   ") end;
	[0xdb] = function() return string.format("stp                   ") end;
	[0xdc] = function() return string.format("jmp [$%.4x]   [%.6x]", op16, decode[OPTYPE_ILADDR](op16)) end;
	[0xdd] = function() return string.format("cmp $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0xde] = function() return string.format("dec $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0xdf] = function() return string.format("cmp $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24)) end;
	[0xe0] = function() if x8 then return string.format("cpx #$%.2x              ", op8)
	                            else return string.format("cpx #$%.4x            ", op16) end end;
	[0xe1] = function() return string.format("sbc ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8)) end;
	[0xe2] = function() return string.format("sep #$%.2x              ", op8) end;
	[0xe3] = function() return string.format("sbc $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8)) end;
	[0xe4] = function() return string.format("cpx $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0xe5] = function() return string.format("sbc $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0xe6] = function() return string.format("inc $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8)) end;
	[0xe7] = function() return string.format("sbc [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8)) end;
	[0xe8] = function() return string.format("inx                   ") end;
	[0xe9] = function() if a8 then return string.format("sbc #$%.2x              ", op8)
	                            else return string.format("sbc #$%.4x            ", op16) end end;
	[0xea] = function() return string.format("nop                   ") end;
	[0xeb] = function() return string.format("xba                   ") end;
	[0xec] = function() return string.format("cpx $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0xed] = function() return string.format("sbc $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0xee] = function() return string.format("inc $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0xef] = function() return string.format("sbc $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24)) end;
	[0xf0] = function() return string.format("beq $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8)) end;
	[0xf1] = function() return string.format("sbc ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8)) end;
	[0xf2] = function() return string.format("sbc ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8)) end;
	[0xf3] = function() return string.format("sbc ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8)) end;
	[0xf4] = function() return string.format("pea $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16)) end;
	[0xf5] = function() return string.format("sbc $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0xf6] = function() return string.format("inc $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8)) end;
	[0xf7] = function() return string.format("sbc [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8)) end;
	[0xf8] = function() return string.format("sed                   ") end;
	[0xf9] = function() return string.format("sbc $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16)) end;
	[0xfa] = function() return string.format("plx                   ") end;
	[0xfb] = function() return string.format("xce                   ") end;
	[0xfc] = function() return string.format("jsr ($%.4x,x) [%.6x]", op16, decode[OPTYPE_IADDRX](op16)) end;
	[0xfd] = function() return string.format("sbc $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0xfe] = function() return string.format("inc $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16)) end;
	[0xff] = function() return string.format("sbc $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24)) end
	}
	line = line .. disasm[op]()

	line = line .. " "

	line = line .. string.format("A:%.4x X:%.4x Y:%.4x S:%.4x D:%.4x DB:%.2x ",
		regs.a, regs.x, regs.y, regs.s, regs.d, regs.db)

	if regs.e then
		line = line .. 
			(regs.p.n and "N" or "n") .. (regs.p.v and "V" or "v") ..
			(regs.p.m and "1" or "0") .. (regs.p.x and "B" or "b") ..
			(regs.p.d and "D" or "d") .. (regs.p.i and "I" or "i") ..
			(regs.p.z and "Z" or "z") .. (regs.p.c and "C" or "c")
	else
		line = line .. 
			(regs.p.n and "N" or "n") .. (regs.p.v and "V" or "v") ..
			(regs.p.m and "M" or "m") .. (regs.p.x and "X" or "x") ..
			(regs.p.d and "D" or "d") .. (regs.p.i and "I" or "i") ..
			(regs.p.z and "Z" or "z") .. (regs.p.c and "C" or "c")
	end

	return line
end
-- the following function works pretty slow when you call it frequently,
-- but it's somewhat useful for easy checking.
function trace(cpuname)
	print(gettraceline(cpuname))
end
