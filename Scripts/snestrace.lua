-- SNES Trace Logger, based on the disassembler of bsnes
-- TODO: speedups

if not emu then emu = snes9x end
if not bit then require("bit") end

-- return info string about current instruction and registers
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

	-- TODO: use table instead for speedup
	    if op == 0x00 then line = line .. string.format("brk #$%.2x              ", op8)
	elseif op == 0x01 then line = line .. string.format("ora ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8))
	elseif op == 0x02 then line = line .. string.format("cop #$%.2x              ", op8)
	elseif op == 0x03 then line = line .. string.format("ora $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8))
	elseif op == 0x04 then line = line .. string.format("tsb $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x05 then line = line .. string.format("ora $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x06 then line = line .. string.format("asl $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x07 then line = line .. string.format("ora [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8))
	elseif op == 0x08 then line = line .. string.format("php                   ")
	elseif op == 0x09 then if a8 then line = line .. string.format("ora #$%.2x              ", op8)
	                             else line = line .. string.format("ora #$%.4x            ", op16) end
	elseif op == 0x0a then line = line .. string.format("asl a                 ")
	elseif op == 0x0b then line = line .. string.format("phd                   ")
	elseif op == 0x0c then line = line .. string.format("tsb $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x0d then line = line .. string.format("ora $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x0e then line = line .. string.format("asl $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x0f then line = line .. string.format("ora $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24))
	elseif op == 0x10 then line = line .. string.format("bpl $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8))
	elseif op == 0x11 then line = line .. string.format("ora ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8))
	elseif op == 0x12 then line = line .. string.format("ora ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8))
	elseif op == 0x13 then line = line .. string.format("ora ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8))
	elseif op == 0x14 then line = line .. string.format("trb $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x15 then line = line .. string.format("ora $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x16 then line = line .. string.format("asl $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x17 then line = line .. string.format("ora [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8))
	elseif op == 0x18 then line = line .. string.format("clc                   ")
	elseif op == 0x19 then line = line .. string.format("ora $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16))
	elseif op == 0x1a then line = line .. string.format("inc                   ")
	elseif op == 0x1b then line = line .. string.format("tcs                   ")
	elseif op == 0x1c then line = line .. string.format("trb $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x1d then line = line .. string.format("ora $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x1e then line = line .. string.format("asl $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x1f then line = line .. string.format("ora $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24))
	elseif op == 0x20 then line = line .. string.format("jsr $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR_PC](op16))
	elseif op == 0x21 then line = line .. string.format("and ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8))
	elseif op == 0x22 then line = line .. string.format("jsl $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24))
	elseif op == 0x23 then line = line .. string.format("and $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8))
	elseif op == 0x24 then line = line .. string.format("bit $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x25 then line = line .. string.format("and $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x26 then line = line .. string.format("rol $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x27 then line = line .. string.format("and [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8))
	elseif op == 0x28 then line = line .. string.format("plp                   ")
	elseif op == 0x29 then if a8 then line = line .. string.format("and #$%.2x              ", op8)
	                             else line = line .. string.format("and #$%.4x            ", op16) end
	elseif op == 0x2a then line = line .. string.format("rol a                 ")
	elseif op == 0x2b then line = line .. string.format("pld                   ")
	elseif op == 0x2c then line = line .. string.format("bit $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x2d then line = line .. string.format("and $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x2e then line = line .. string.format("rol $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x2f then line = line .. string.format("and $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24))
	elseif op == 0x30 then line = line .. string.format("bmi $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8))
	elseif op == 0x31 then line = line .. string.format("and ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8))
	elseif op == 0x32 then line = line .. string.format("and ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8))
	elseif op == 0x33 then line = line .. string.format("and ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8))
	elseif op == 0x34 then line = line .. string.format("bit $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x35 then line = line .. string.format("and $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x36 then line = line .. string.format("rol $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x37 then line = line .. string.format("and [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8))
	elseif op == 0x38 then line = line .. string.format("sec                   ")
	elseif op == 0x39 then line = line .. string.format("and $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16))
	elseif op == 0x3a then line = line .. string.format("dec                   ")
	elseif op == 0x3b then line = line .. string.format("tsc                   ")
	elseif op == 0x3c then line = line .. string.format("bit $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x3d then line = line .. string.format("and $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x3e then line = line .. string.format("rol $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x3f then line = line .. string.format("and $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24))
	elseif op == 0x40 then line = line .. string.format("rti                   ")
	elseif op == 0x41 then line = line .. string.format("eor ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8))
	elseif op == 0x42 then line = line .. string.format("wdm                   ")
	elseif op == 0x43 then line = line .. string.format("eor $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8))
	elseif op == 0x44 then line = line .. string.format("mvp $%.2x,$%.2x           ", op1, op8)
	elseif op == 0x45 then line = line .. string.format("eor $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x46 then line = line .. string.format("lsr $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x47 then line = line .. string.format("eor [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8))
	elseif op == 0x48 then line = line .. string.format("pha                   ")
	elseif op == 0x49 then if a8 then line = line .. string.format("eor #$%.2x              ", op8)
	                             else line = line .. string.format("eor #$%.4x            ", op16) end
	elseif op == 0x4a then line = line .. string.format("lsr a                 ")
	elseif op == 0x4b then line = line .. string.format("phk                   ")
	elseif op == 0x4c then line = line .. string.format("jmp $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR_PC](op16))
	elseif op == 0x4d then line = line .. string.format("eor $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x4e then line = line .. string.format("lsr $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x4f then line = line .. string.format("eor $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24))
	elseif op == 0x50 then line = line .. string.format("bvc $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8))
	elseif op == 0x51 then line = line .. string.format("eor ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8))
	elseif op == 0x52 then line = line .. string.format("eor ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8))
	elseif op == 0x53 then line = line .. string.format("eor ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8))
	elseif op == 0x54 then line = line .. string.format("mvn $%.2x,$%.2x           ", op1, op8)
	elseif op == 0x55 then line = line .. string.format("eor $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x56 then line = line .. string.format("lsr $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x57 then line = line .. string.format("eor [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8))
	elseif op == 0x58 then line = line .. string.format("cli                   ")
	elseif op == 0x59 then line = line .. string.format("eor $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16))
	elseif op == 0x5a then line = line .. string.format("phy                   ")
	elseif op == 0x5b then line = line .. string.format("tcd                   ")
	elseif op == 0x5c then line = line .. string.format("jml $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24))
	elseif op == 0x5d then line = line .. string.format("eor $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x5e then line = line .. string.format("lsr $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x5f then line = line .. string.format("eor $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24))
	elseif op == 0x60 then line = line .. string.format("rts                   ")
	elseif op == 0x61 then line = line .. string.format("adc ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8))
	elseif op == 0x62 then line = line .. string.format("per $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x63 then line = line .. string.format("adc $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8))
	elseif op == 0x64 then line = line .. string.format("stz $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x65 then line = line .. string.format("adc $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x66 then line = line .. string.format("ror $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x67 then line = line .. string.format("adc [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8))
	elseif op == 0x68 then line = line .. string.format("pla                   ")
	elseif op == 0x69 then if a8 then line = line .. string.format("adc #$%.2x              ", op8)
	                             else line = line .. string.format("adc #$%.4x            ", op16) end
	elseif op == 0x6a then line = line .. string.format("ror a                 ")
	elseif op == 0x6b then line = line .. string.format("rtl                   ")
	elseif op == 0x6c then line = line .. string.format("jmp ($%.4x)   [%.6x]", op16, decode[OPTYPE_IADDR_PC](op16))
	elseif op == 0x6d then line = line .. string.format("adc $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x6e then line = line .. string.format("ror $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x6f then line = line .. string.format("adc $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24))
	elseif op == 0x70 then line = line .. string.format("bvs $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8))
	elseif op == 0x71 then line = line .. string.format("adc ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8))
	elseif op == 0x72 then line = line .. string.format("adc ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8))
	elseif op == 0x73 then line = line .. string.format("adc ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8))
	elseif op == 0x74 then line = line .. string.format("stz $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x75 then line = line .. string.format("adc $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x76 then line = line .. string.format("ror $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x77 then line = line .. string.format("adc [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8))
	elseif op == 0x78 then line = line .. string.format("sei                   ")
	elseif op == 0x79 then line = line .. string.format("adc $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16))
	elseif op == 0x7a then line = line .. string.format("ply                   ")
	elseif op == 0x7b then line = line .. string.format("tdc                   ")
	elseif op == 0x7c then line = line .. string.format("jmp ($%.4x,x) [%.6x]", op16, decode[OPTYPE_IADDRX](op16))
	elseif op == 0x7d then line = line .. string.format("adc $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x7e then line = line .. string.format("ror $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x7f then line = line .. string.format("adc $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24))
	elseif op == 0x80 then line = line .. string.format("bra $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8))
	elseif op == 0x81 then line = line .. string.format("sta ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8))
	elseif op == 0x82 then line = line .. string.format("brl $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELW](op16), 0xffff), decode[OPTYPE_RELW](op16))
	elseif op == 0x83 then line = line .. string.format("sta $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8))
	elseif op == 0x84 then line = line .. string.format("sty $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x85 then line = line .. string.format("sta $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x86 then line = line .. string.format("stx $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0x87 then line = line .. string.format("sta [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8))
	elseif op == 0x88 then line = line .. string.format("dey                   ")
	elseif op == 0x89 then if a8 then line = line .. string.format("bit #$%.2x              ", op8)
	                             else line = line .. string.format("bit #$%.4x            ", op16) end
	elseif op == 0x8a then line = line .. string.format("txa                   ")
	elseif op == 0x8b then line = line .. string.format("phb                   ")
	elseif op == 0x8c then line = line .. string.format("sty $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x8d then line = line .. string.format("sta $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x8e then line = line .. string.format("stx $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x8f then line = line .. string.format("sta $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24))
	elseif op == 0x90 then line = line .. string.format("bcc $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8))
	elseif op == 0x91 then line = line .. string.format("sta ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8))
	elseif op == 0x92 then line = line .. string.format("sta ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8))
	elseif op == 0x93 then line = line .. string.format("sta ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8))
	elseif op == 0x94 then line = line .. string.format("sty $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x95 then line = line .. string.format("sta $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0x96 then line = line .. string.format("stx $%.2x,y     [%.6x]", op8, decode[OPTYPE_DPY](op8))
	elseif op == 0x97 then line = line .. string.format("sta [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8))
	elseif op == 0x98 then line = line .. string.format("tya                   ")
	elseif op == 0x99 then line = line .. string.format("sta $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16))
	elseif op == 0x9a then line = line .. string.format("txs                   ")
	elseif op == 0x9b then line = line .. string.format("txy                   ")
	elseif op == 0x9c then line = line .. string.format("stz $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0x9d then line = line .. string.format("sta $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x9e then line = line .. string.format("stz $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0x9f then line = line .. string.format("sta $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24))
	elseif op == 0xa0 then if x8 then line = line .. string.format("ldy #$%.2x              ", op8)
	                             else line = line .. string.format("ldy #$%.4x            ", op16) end
	elseif op == 0xa1 then line = line .. string.format("lda ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8))
	elseif op == 0xa2 then if x8 then line = line .. string.format("ldx #$%.2x              ", op8)
	                             else line = line .. string.format("ldx #$%.4x            ", op16) end
	elseif op == 0xa3 then line = line .. string.format("lda $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8))
	elseif op == 0xa4 then line = line .. string.format("ldy $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0xa5 then line = line .. string.format("lda $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0xa6 then line = line .. string.format("ldx $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0xa7 then line = line .. string.format("lda [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8))
	elseif op == 0xa8 then line = line .. string.format("tay                   ")
	elseif op == 0xa9 then if a8 then line = line .. string.format("lda #$%.2x              ", op8)
	                             else line = line .. string.format("lda #$%.4x            ", op16) end
	elseif op == 0xaa then line = line .. string.format("tax                   ")
	elseif op == 0xab then line = line .. string.format("plb                   ")
	elseif op == 0xac then line = line .. string.format("ldy $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0xad then line = line .. string.format("lda $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0xae then line = line .. string.format("ldx $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0xaf then line = line .. string.format("lda $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24))
	elseif op == 0xb0 then line = line .. string.format("bcs $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8))
	elseif op == 0xb1 then line = line .. string.format("lda ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8))
	elseif op == 0xb2 then line = line .. string.format("lda ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8))
	elseif op == 0xb3 then line = line .. string.format("lda ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8))
	elseif op == 0xb4 then line = line .. string.format("ldy $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0xb5 then line = line .. string.format("lda $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0xb6 then line = line .. string.format("ldx $%.2x,y     [%.6x]", op8, decode[OPTYPE_DPY](op8))
	elseif op == 0xb7 then line = line .. string.format("lda [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8))
	elseif op == 0xb8 then line = line .. string.format("clv                   ")
	elseif op == 0xb9 then line = line .. string.format("lda $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16))
	elseif op == 0xba then line = line .. string.format("tsx                   ")
	elseif op == 0xbb then line = line .. string.format("tyx                   ")
	elseif op == 0xbc then line = line .. string.format("ldy $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0xbd then line = line .. string.format("lda $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0xbe then line = line .. string.format("ldx $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16))
	elseif op == 0xbf then line = line .. string.format("lda $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24))
	elseif op == 0xc0 then if x8 then line = line .. string.format("cpy #$%.2x              ", op8)
	                             else line = line .. string.format("cpy #$%.4x            ", op16) end
	elseif op == 0xc1 then line = line .. string.format("cmp ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8))
	elseif op == 0xc2 then line = line .. string.format("rep #$%.2x              ", op8)
	elseif op == 0xc3 then line = line .. string.format("cmp $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8))
	elseif op == 0xc4 then line = line .. string.format("cpy $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0xc5 then line = line .. string.format("cmp $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0xc6 then line = line .. string.format("dec $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0xc7 then line = line .. string.format("cmp [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8))
	elseif op == 0xc8 then line = line .. string.format("iny                   ")
	elseif op == 0xc9 then if a8 then line = line .. string.format("cmp #$%.2x              ", op8)
	                             else line = line .. string.format("cmp #$%.4x            ", op16) end
	elseif op == 0xca then line = line .. string.format("dex                   ")
	elseif op == 0xcb then line = line .. string.format("wai                   ")
	elseif op == 0xcc then line = line .. string.format("cpy $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0xcd then line = line .. string.format("cmp $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0xce then line = line .. string.format("dec $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0xcf then line = line .. string.format("cmp $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24))
	elseif op == 0xd0 then line = line .. string.format("bne $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8))
	elseif op == 0xd1 then line = line .. string.format("cmp ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8))
	elseif op == 0xd2 then line = line .. string.format("cmp ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8))
	elseif op == 0xd3 then line = line .. string.format("cmp ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8))
	elseif op == 0xd4 then line = line .. string.format("pei ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8))
	elseif op == 0xd5 then line = line .. string.format("cmp $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0xd6 then line = line .. string.format("dec $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0xd7 then line = line .. string.format("cmp [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8))
	elseif op == 0xd8 then line = line .. string.format("cld                   ")
	elseif op == 0xd9 then line = line .. string.format("cmp $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16))
	elseif op == 0xda then line = line .. string.format("phx                   ")
	elseif op == 0xdb then line = line .. string.format("stp                   ")
	elseif op == 0xdc then line = line .. string.format("jmp [$%.4x]   [%.6x]", op16, decode[OPTYPE_ILADDR](op16))
	elseif op == 0xdd then line = line .. string.format("cmp $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0xde then line = line .. string.format("dec $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0xdf then line = line .. string.format("cmp $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24))
	elseif op == 0xe0 then if x8 then line = line .. string.format("cpx #$%.2x              ", op8)
	                             else line = line .. string.format("cpx #$%.4x            ", op16) end
	elseif op == 0xe1 then line = line .. string.format("sbc ($%.2x,x)   [%.6x]", op8, decode[OPTYPE_IDPX](op8))
	elseif op == 0xe2 then line = line .. string.format("sep #$%.2x              ", op8)
	elseif op == 0xe3 then line = line .. string.format("sbc $%.2x,s     [%.6x]", op8, decode[OPTYPE_SR](op8))
	elseif op == 0xe4 then line = line .. string.format("cpx $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0xe5 then line = line .. string.format("sbc $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0xe6 then line = line .. string.format("inc $%.2x       [%.6x]", op8, decode[OPTYPE_DP](op8))
	elseif op == 0xe7 then line = line .. string.format("sbc [$%.2x]     [%.6x]", op8, decode[OPTYPE_ILDP](op8))
	elseif op == 0xe8 then line = line .. string.format("inx                   ")
	elseif op == 0xe9 then if a8 then line = line .. string.format("sbc #$%.2x              ", op8)
	                             else line = line .. string.format("sbc #$%.4x            ", op16) end
	elseif op == 0xea then line = line .. string.format("nop                   ")
	elseif op == 0xeb then line = line .. string.format("xba                   ")
	elseif op == 0xec then line = line .. string.format("cpx $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0xed then line = line .. string.format("sbc $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0xee then line = line .. string.format("inc $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0xef then line = line .. string.format("sbc $%.6x   [%.6x]", op24, decode[OPTYPE_LONG](op24))
	elseif op == 0xf0 then line = line .. string.format("beq $%.4x     [%.6x]", bit.band(decode[OPTYPE_RELB](op8), 0xffff), decode[OPTYPE_RELB](op8))
	elseif op == 0xf1 then line = line .. string.format("sbc ($%.2x),y   [%.6x]", op8, decode[OPTYPE_IDPY](op8))
	elseif op == 0xf2 then line = line .. string.format("sbc ($%.2x)     [%.6x]", op8, decode[OPTYPE_IDP](op8))
	elseif op == 0xf3 then line = line .. string.format("sbc ($%.2x,s),y [%.6x]", op8, decode[OPTYPE_ISRY](op8))
	elseif op == 0xf4 then line = line .. string.format("pea $%.4x     [%.6x]", op16, decode[OPTYPE_ADDR](op16))
	elseif op == 0xf5 then line = line .. string.format("sbc $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0xf6 then line = line .. string.format("inc $%.2x,x     [%.6x]", op8, decode[OPTYPE_DPX](op8))
	elseif op == 0xf7 then line = line .. string.format("sbc [$%.2x],y   [%.6x]", op8, decode[OPTYPE_ILDPY](op8))
	elseif op == 0xf8 then line = line .. string.format("sed                   ")
	elseif op == 0xf9 then line = line .. string.format("sbc $%.4x,y   [%.6x]", op16, decode[OPTYPE_ADDRY](op16))
	elseif op == 0xfa then line = line .. string.format("plx                   ")
	elseif op == 0xfb then line = line .. string.format("xce                   ")
	elseif op == 0xfc then line = line .. string.format("jsr ($%.4x,x) [%.6x]", op16, decode[OPTYPE_IADDRX](op16))
	elseif op == 0xfd then line = line .. string.format("sbc $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0xfe then line = line .. string.format("inc $%.4x,x   [%.6x]", op16, decode[OPTYPE_ADDRX](op16))
	elseif op == 0xff then line = line .. string.format("sbc $%.6x,x [%.6x]", op24, decode[OPTYPE_LONGX](op24)) end

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
-- call this function on the callback of memory.registerexec
function trace(cpuname)
	print(gettraceline(cpuname))
end
