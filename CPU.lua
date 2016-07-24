return function()
	local cpu = {}
	
	--helper vars 
	local bitwise = require("Bitwise")
	local helper = require("GHelper")
	
	
	--main
	cpu.Mode = 1
	cpu.Halted = false
	cpu.Registers = {
		a = 0, b = 0, c = 0, d = 0, di = 0, si = 0, sp = 0, bp = 0,
		ss = 0, ds = 0, fs = 0, es = 0, gs = 0, ss = 0, cs = 0,
		ip = 0,
		flags = 0
	}
	cpu.Gdtr = 0 
	cpu.Ldtr = 0
	cpu.Idtr = 0
	
	cpu.Busses = {
		Address = 0,
		Control = 0, 
		Data = 0
	}
	cpu.Memory = require("Memory")(0x10FFEF)
	
	cpu.CpuidIdentification = {
		VendorString = "!!RAREMEME!!",
		ProcessorIdenitficationString = "Kemu processor (x86)\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"--maybe replace some of the \0 with spaces
	}--table config (not done)
	--helper functions
	
	 --[[
	cpu.EditFlag = function(self, flagp, bit)
		local regs = self.Registers 
		local old = regs.flags
		regs.flags = bitwise:OR(old, bitwise:SHL(bit, flagp), 32)
	end]]
	
	cpu.SetFlag = function(self, flagp)
		local regs = self.Registers 
		local old = regs.flags
		regs.flags = bitwise:OR(old, bitwise:SHL(1, flagp), 32)
	end
	
	cpu.ClearFlag = function(self, flagp)
		local regs = self.Registers 
		local old = regs.flags 
		regs.flags = bitwise:AND(old, bitwise:NOT(bitwise:SHL(1, flagp), 32), 32)
	end
	cpu.GetFlag = function(self, flagp)
		local f = self.Registers.flags 
		return bitwise:AND(bitwise:SHR(f, flagp), 1, 1)
	end
	cpu.CheckFlag = function(self, flagp, bit)
		local f = self.Registers.flags 
		local temp = self:GetFlag(flagp)--bitwise:AND(bitwise:SHR(f, flagp), 1, 1)
		return (temp == bit and true or false)
	end
	cpu.CalculateAddress = function(self, offset)
		local regs = self.Registers
		if (self.Mode == 1) then 
			return (regs.cs * 16) + offset
		end
	end
	cpu.GetExtendedBits = function(byte)
		return bitwise:AND(bitwise:SHR(byte, 3), (2^3)-1, 8)
	end
	cpu.GetGDTDescriptor = function(self, index, mode)
		if (mode == 3) then 
			return self.DecodeDescriptor(self:Get(index, 8, true))
		end
	end
	cpu.GetMODRM = function(self)
		local byte = self:GetByte()
		
		
		return {
			RM = bitwise:AND(byte, (2^3)-1, 3),
			REG = bitwise:AND(bitwise:SHR(byte, 3), (2^3)-1, 3),
			MOD = bitwise:AND(bitwise:SHR(byte, 6), (2^2)-1, 2)	
		}
	end
	cpu.GetOperandSize = function(self, prefixes)
		if (helper.SearchPrefix(prefixes, 0x66)) then 
			return 32
		elseif (self.Mode > 2) then 
			--[[
				not ready yet
				local descriptor = self:GetCurrentDescriptor()
				local d_bit = bitwise:AND(bitwise:SHR(descriptor.Flags, 6), 0x01, 1)
				
				if (d_bit == 0) then 
					return 16 
				else 
					return 32 
				end
			--]]
		else 
			return 16
		end
	end	
	cpu.GetAddressSize = function(self, prefixes)
		if (helper.SearchPrefix(prefixes, 0x67)) then 
			return 32 
		elseif (self.Mode > 2) then
			--[[
				not ready yet 
				local descriptor = self:GetCurrentDescriptor()
				local d_bit = bitwise:AND(bitwise:SHR(descriptor.Flags, 6), 0x01, 1)
				
				if (d_bit == 0) then 
					return 16 
				else 
					return 32 
				end
			--]]
		else 
			return 16
		end
	end
	cpu.DecodeReg = function(self, val, bits)
		
		if (bits == 32 or bits == 16) then
			if (val == 0) then 
				return "a"
			elseif (val == 1) then 
				return "c"
			elseif (val == 2) then 
				return "d"
			elseif (val == 3) then 
				return "b" 
			elseif (val == 4) then 
				return "sp"
			elseif (val == 5) then 
				return "bp"
			elseif (val == 6) then 
				return "si"
			elseif (val == 7) then 
				return "di"
			end
		else 
			if (val == 0) then 
				return "a"
			elseif (val == 1) then
				return "c"
			elseif (val == 2) then 
				return "d" 
			elseif (val == 3) then 
				return "b" 
			elseif (val == 4) then 
				return "a", 8 
			elseif (val == 5) then 
				return "c", 8 
			elseif (val == 6) then 
				return "d", 8 
			elseif (val == 7) then 
				return "b", 8
			end
		end
	end
	cpu.DecodeSegmentReg = function(self, val, bits)
		local  stuf = {
			"es", "cs", "ss", "ds", "fs", "gs"
		}		
		
		return stuf[val + 1] 
	end 
	cpu.DecodeControlReg = function(self, val, doc, bits)
		local stuff = {
			"cr0",
			"",
			"cr2",
			"cr3",
			"cr4"
		}
		local  stuff2 = {
			"dr0",
			"dr1",
			"dr2",
			"dr3",
			"",
			"",
			"dr6",
			"dr7"
		}
		
		if (doc == 1) then 
			return stuff[val + 1]
		else 
			return stuff2[val + 1]
		end
	end
	cpu.DecodeAddressFromMODRM = function(self, prefix, modrm)
		local function EffectiveAddress16()
			local calc
			local mod, rm = modrm.MOD, modrm.RM
			local disp = 0
			if (mod == 0 and rm == 6) then 
				local xd = self:GetWord()
				return xd
			elseif (mod == 1) then 
				disp = self:GetByte()
			elseif (mod == 2) then 
				disp = self:GetWord()
			elseif (mod == 3) then
				local a, b = self:DecodeReg(rm, 16)
				
				return self:GetRegister(a, 16, b)
			end 
			
			
			if (rm == 0) then 
				calc = self:GetRegister("b", 16) + self:GetRegister("si", 16) + disp
			elseif (rm == 1) then
				calc = self:GetReister("b", 16) + self:GetRegister("di", 16) + disp
			elseif (rm == 2) then 
				calc = self:GetRegister("bp", 16) + self:GetRegister("si", 16) + disp
			elseif (rm == 3) then 
				calc = self:GetRegister("bp", 16) + self:GetRegister("di", 16) + disp
			elseif (rm == 4) then 
				calc = self:GetRegister("si", 16) + disp
			elseif (rm == 5) then 
				calc = self:GetRegister("di", 16) + disp
			elseif (rm == 6) then 
				calc = self:GetRegister("bp", 16) + disp
			elseif (rm == 7) then 
				calc = self:GetRegister("b", 16) + disp
			end
			
			return calc
		end	
		local function EffectiveAddress32()
			local calc 
			local mod, rm = modrm.MOD, modrm.RM
			local disp = 0 
		end
		
		local opr = self:GetAddressSize(prefix)
		
		if (opr == 16) then 
			return EffectiveAddress16()
		elseif (opr == 32) then 
			return EffectiveAddress32()
		end
	
	end
	--instructioons 
	
	cpu.Instructions = {}
	do 
		cpu.Jump = function(self, prefix, instruction) --not finshed
			local regs = self.Registers
			local oper_size = self:GetOperandSize(prefix)
			if (instruction == 0xEB) then
				local pp = self:GetByte()
				local offset = regs.ip + helper.Signed(pp, 8)--helper.Signed(self:GetByte()repeat wait() until true==false
				
				regs.ip = offset 
			elseif (instruction == 0xE9) then 
				local pp
				if (oper_size == 16) then --realize that its not dependant on the actual mode, but the operand size, will change
					pp = self:GetWord()
					--offset = regs.ip + helper.Signed(self:GetWord(), 16)
				else
					pp = self:GetDword()
					--offset = regs.ip + helper.Signed(self:GetDword(), 32)
				end
				local offset =  regs.ip + helper.Signed(pp, oper_size)
				regs.ip = offset
			elseif (instruction == 0xFF) then
				local modrm = self:GetMODRM()
				local extended_bits = modrm.REG
				local regs = self.Registers
				if (extended_bits == 4 or extended_bits == 5) then 
					local offset = self:DecodeAddressFromMODRM(prefix, modrm)
					--error(tostring(offset))
					if (oper_size == 16)  then 
						offset = bitwise:OR(offset, 0, 16) -- bitwise shaves off the upper 16, no need to and it 
					end
					
					regs.ip = offset
				elseif (extended_bits == 6) then 
					local addr = self:DecodeAddressFromMODRM(prefix, modrm)
					local mem = self.Memory 
					
					local offset = mem:GetWord(addr)
					local cs = mem:GetWord(addr + 2)
					
					regs.cs = cs 
					regs.ip = offset
				end 
			elseif (instruction == 0xEA) then 
				local oper_size = self:GetOperandSize(prefix)
				local offseti = self:GetWord()
				
				local cs = self:GetWord()
				
				warn(offseti, cs)
				regs.cs = cs 
				regs.ip = bitwise:AND(offseti, (2^oper_size)-1, oper_size)
			end
			
		end 
		
		cpu.Move = function(self, prefix, instruction)
			local mem = self.Memory
			if (instruction == 0x88) then 
				local modrm = self:GetMODRM()
				local destination_reg = self:DecodeAddressFromMODRM(prefix, modrm)
				local source_reg, sh = self:DecodeReg(modrm.REG, 8);source_reg = self:GetRegister(source_reg, 8, sh)
			
				self:SetByte(destination_reg, source_reg)
			elseif (instruction == 0x89) then 
				local modrm = self:GetMODRM()
				local destination_reg = self:DecodeAddressFromMODRM(prefix, modrm)
				local operand_size = self:GetOperandSize(prefix)
				
				local source_reg, srsh = self:DecodeReg(modrm.REG, operand_size);source_reg = self:GetRegister(source_reg, operand_size, srsh)
				
				if (operand_size == 16) then 
					self:SetWord(destination_reg, source_reg)
				elseif (operand_size == 32) then 
					self:SetDword(destination_reg, source_reg)
				end
			elseif (instruction == 0x8B) then
				local modrm = self:GetMODRM()
				local operand_size = self:GetOperandSize(prefix)
				--[[local destination_reg = self:DecodeAddressFromMODRM(prefix, modrm)
				local source_reg, sh = self:DecodeReg(modrm.REG, operand_size);source_reg = self:GetRegister(source_reg, operand_size, sh)
				]]
				local reg, regsh = self:DecodeReg(modrm.REG, operand_size)
				local sauce = self:DecodeAddressFromMODRM(prefix, modrm)				
				
				
				self:SetRegister(reg, sauce, operand_size, regsh)
				
			elseif (helper.InRange(instruction, 0xB0,  0xB7)) then 
				local register, regsh = self:DecodeReg(bitwise:AND(instruction, 0x0F, 4), 8)
				local imm8 = self:GetByte()
				

				self:SetRegister(register, imm8, 8, regsh)
			elseif (helper.InRange(instruction, 0xB8, 0xBF)) then 
				local operand_size = self:GetOperandSize(prefix)
				local imm = 0 
				
				if (operand_size == 16) then 
					imm = self:GetWord()
				elseif (operand_size == 32) then 
					imm = self:GetDword()
				end
				
				local register, regsh = self:DecodeReg(bitwise:AND(instruction, 0x0F, 4)-8, operand_size)
				
				self:SetRegister(register, imm, operand_size, regsh)
			elseif (instruction == 0x8E)then
				local modrm = self:GetMODRM()
				local a = self:DecodeAddressFromMODRM(prefix, modrm)
				local b, bsh = self:DecodeSegmentReg(modrm.REG, 16)
				
				self:SetRegister(b, a, 16, bsh)
			elseif (instruction == 0xA0) then 
				local addr_size = self:GetAddressSize(prefix)
				local value
				if (addr_size == 16) then 
					value = mem:GetByte(self:GetWord())
				elseif (addr_size == 32) then 
					value = mem:GetByte(self:GetDword())
				end 
				
				self:SetRegister("a", value, 8, 0)
			elseif (instruction == 0xA1) then 
				local addr_size = self:GetAddressSize(prefix)
				local value
				
				if (addr_size == 16) then 
					value = mem:GetWord(self:GetWord())
				elseif (addr_size == 32) then 
					value = mem:GetDword(self:GetDword())
				end
				
				self:SetRegister("a", value, 16, 0)
			elseif (instruction == 0xA2) then 
				local value = self:GetRegister("a", 8)
				local addr_size = self:GetAddressSize(prefix)
				local addr 
				
				if (addr_size == 16) then 
					addr = self:GetWord()
				elseif (addr_size == 32) then 
					addr = self:GetDword()
				end
			
				self:SetByte(addr, value)
			elseif (instruction == 0xA3) then 
				local value
				local addr_size = self:GetAddressSize(prefix)
				local addr
				
				if (addr_size == 16) then 
					addr = self:GetWord()
					value = self:GetRegister("a", 16)
					self:SetWord(addr, value)
				elseif (addr_size == 32) then 
					addr = self:GetDword()
					value = self:GetRegister("a", 32)
					self:SetDword(addr, value)
				end
			elseif (instruction == 0xC6) then 
				local value 
				local modrm = self:GetMODRM()
				local addr = self:DecodeAddressFromMODRM(prefix, modrm)
				local imm = self:GetByte()
				
				
				self:SetByte(addr, imm)
			elseif (instruction == 0xC7) then 
				local value 
				local modrm = self:GetMODRM()
				local addr = self:DecodeAddressFromMODRM(prefix, modrm)
				local oper_size = self:GetOperandSize(prefix)
				local imm 
				
				if (oper_size == 16) then 
					imm = self:GetWord()
					self:SetWord(addr, imm)
				elseif (oper_size == 32) then 
					imm = self:Dword()
					self:SetDword(addr, imm)
				end
			else 
				warn("ONOES", instruction)
				
			end
		end
		
		cpu.Halt = function(self, prefix, instruction)
			self.Halted = true
			warn("Cpu halted")
		end
		
		cpu.Cli = function(self, prefix, instruction)
			--self:EditFlag(9, 0)
			self:ClearFlag(9)
		end
		
		cpu.Sti = function(self, prefix, instruction)
			--self:EditFlag(9, 1)
			self:SetFlag(9)
		end
		
		cpu.Cld = function(self, prefix, instruction)
			--self:EditFlag(10, 0)
			self:ClearFlag(10)
		end
		
		cpu.Std = function(self, prefix, instruction)
			--self:EditFlag(10, 1)
			self:SetFlag(10)
		end
		
		cpu.Clc = function(self, prefix, instruction)
			--self:EditFlag(0, 0)
			self:ClearFlag(0)
		end

		cpu.Stc = function(self, prefix, instruction)
			--self:EditFlag(0, 1)
			self:SetFlag(0)
		end
		
		cpu.Cpuid = function(self, prefix, instruction)
			local regs = self.Registers
			local eax = regs.a 
			local id = self.CpuidIdentification
			local temp 
			if (eax == 0) then 
				temp = id.VendorString 
				regs.a = 2
				regs.b = helper.GetByteArray({string.sub(temp, 1, 4):byte(1, 4)})
				regs.c = helper.GetByteArray({string.sub(temp, 5, 8):byte(1, 4)})
				regs.d = helper.GetByteArray({string.sub(temp, 9, 12):byte(1, 4)})
			elseif (eax == 1) then 
				regs.a = 0x206A7 -- for now 
				regs.b = 0 -- for now
			end
			
		end
		
		cpu.Push = function(self, prefix, instruction)
			local regs = self.Registers			
			if (instruction == 0xFF) then 
				local modrm = self:GetMODRM()
				local addr = self:DecodeAddressFromMODRM(prefix, modrm)
				local addr_size = self:GetAddressSize(modrm)
				local mem = self.Memory
				local value
				if (addr_size == 16) then 
					value = mem:GetWord(addr)
					self:PushWord(value)
				elseif (addr_size == 32) then 
					value = mem:GetDword(addr)
					self:PushDword(value)
				end				
			elseif (helper.InRange(instruction, 0x50, 0x57)) then 
				local reg = bitwise:AND(instruction, 0x0F, 4)			
				local operand_size = self:GetOperandSize(prefix)
				
				local a, b 
				if (operand_size == 16) then 
					a, b = self:DecodeReg(reg, 16)
					self:PushWord(self:GetRegister(a, 16, b))
				elseif (operand_size == 32) then 
					a, b= self:DecodeReg(reg, 32)
					self:PushDword(self:GetRegister(a, 32, b))
				end
			elseif (instruction == 0x6A) then 
				local imm = self:GetByte()
				
				self:PushWord(imm)
			elseif (instruction == 0x68) then 
				local operand_size = self:GetOperandSize(prefix)
				
				if (operand_size == 16) then 
					self:PushWord(self:GetWord())
				elseif (operand_size == 32) then 
					self:PushDword(self:GetDword())
				end	
			elseif (instruction == 0x0E) then 
				regs.cs = self:GetWord()
			elseif (instruction == 0x16) then 
				regs.ss = self:GetWord()
			elseif (instruction == 0x1E) then 
				regs.ds = self:GetWord()
			elseif (instruction == 0x06) then 
				regs.es = self:GetWord()
			elseif (instruction == 0x0FA0) then 
				regs.fs = self:GetWord()
			elseif (instruction == 0x0FA8) then 
				regs.gs = self:GetWord()
			end
		end
		
		cpu.Pop = function(self, prefix, instruction)
			local regs = self.Registers			
			if (instruction == 0x8F) then
				local modrm = self:GetMODRM()
				local addr = self:DecodeAddressFromMODRM(modrm)
				local operand_size = self:GetOperandSize(prefix)
				
				if (operand_size == 16) then 
					self:SetWord(addr, self:PopWord())
				elseif (operand_size == 32) then 
					self:SetDword(addr, self:PopDword())
				end
			elseif (helper.InRange(instruction, 0x58, 0x5F)) then
				local reg = bitwise:AND(instruction, 0x0F, 4)-8
				local operand_size = self:GetOperandSize(prefix)
				local a, b
				if (operand_size == 16) then 
					a, b = self:DecodeReg(reg, 16)
					self:SetRegister(a, self:PopWord(), 16, b)
				elseif (operand_size == 32) then 
					a, b = self:DecodeReg(reg, 32)
					self:SetRegister(a, self:PopWord(), 32, b)
				end
			elseif (instruction == 0x1F) then 
				regs.ds = self:PopWord()
			elseif (instruction == 0x07) then 
				regs.es = self:PopWord()
			elseif (instruction == 0x17) then 
				regs.ss = self:PopWord()
			elseif (instruction == 0x0FA1) then 
				local operand_size = self:GetOperandSize(prefix)
	
				regs.fs = self:PopWord()
				if (operand_size == 32) then 
					self:PopWord()
				end 
			elseif (instruction == 0x0FA9) then 
				local operand_size = self:GetOperandSize(prefix)
				
				regs.gs = self:PopWord()
				if (operand_size == 32) then 
					self:PopWord()
				end
			end
		end
		
		cpu.Lea = function(self, prefix, instruction)
			local modrm = self:GetMODRM()
			local addr = self:DecodeAddressFromMODRM(prefix, modrm)
			local opr, adr = self:GetOperandSize(prefix), self:GetAddressSize(prefix)
			local reg, regsh = self:DecodeReg(modrm.REG, opr)
			
			if (adr == 16 and opr == 32) then 
				self:SetRegister(reg, addr, 32, regsh)
			elseif (adr == 32 and opr == 16) then 
				self:SetRegister(reg, bitwise:AND(addr, 0xFFFF, 16), 16, regsh)
			else 
				self:SetRegister(reg, addr, opr, regsh)
			end	
		end
		
		cpu.Call = function(self, prefix, instruction)
			
		end
		
		cpu.Pushad = function(self, prefix, instruction)
			local regs = self.Registers 
			local operand_size = self:GetOperandSize(prefix)
			local temp = self.sp
			if (operand_size == 16) then 
				self:PushWord(regs.a)
				self:PushWord(regs.c)
				self:PushWord(regs.d)
				self:PushWord(regs.b)
				self:PushWord(temp)
				self:PushWord(regs.bp)
				self:PushWord(regs.si)
				self:PushWord(regs.di)
			else
				self:PushDword(regs.a)
				self:PushDword(regs.c)
				self:PushDword(regs.d)
				self:PushDword(regs.b)
				self:PushDword(temp)
				self:PushDword(regs.bp)
				self:PushDword(regs.si)
				self:PushDword(regs.di)
			end
		end
		
		cpu.Pushfd = function(self, prefix, instruction)
			local flags = self.Registers.flags
			local operand_size = self:GetOperandSize(prefix)
			
			if (operand_size == 16) then 
				self:PushWord(flags)
			elseif (operand_size == 32) then 
				self:PushDword(flags)
			end
		end
		cpu.Jcc = function(self, prefix, instruction)--repetetive :(
			local temp = 0
			local tempt 
			local regs = self.Registers
			local flags_check = { -- possible strain, will move it and make it upvalued
				[0x77] = {{0, 0}, {6, 0}},
				[0x73] = {{0, 0}},
				[0x72] = {{0, 1}},
				[0x76] = {{0, 1}, {6, 1}},
				[0x72] = {{0, 1}},
				[0x74] = {{6, 1}},
				[0x7F] = {{6, 0}, {7, {11}}},
				[0x7D] = {{7, {11}}},
				[0x7C] = {{7, {11}, 0}},
				[0x7E] = {{6, 1}, {7, {11}, 0}},
				[0x76] = {{0, 1}, {6, 1}},
				[0x72] = {{0, 1}},
				[0x73] = {{0, 0}},
				[0x75] = {{6, 0}},
				[0x71] = {{11, 0}},
				[0x7B] = {{2, 0}},
				[0x79] = {{7, 0}},
				[0x7A] = {{2, 1}},
				[0x78] = {{7, 1}},
				[0x70] = {{11, 0}}
			}
			
			if (flags_check[instruction]) then 
				local c = flags_check[instruction]
				
				local boolean = true
				 
				tempt = self:GetByte()
				temp = regs.ip + tempt
				for x = 1, #c do 
					local temp = c[x]
					local a, b, c = self:GetFlag(temp[1]), temp[2], temp[3] or 1
					
					if (type(b) == "table") then 
						b = self:GetFlag(b)
					end
				
					if (c == 1) then 
						boolean = boolean and (a==b)
					else 
						boolean = boolean and (a~=b)
					end
				end
				if (boolean) then 
					temp = regs.ip + tempt
				end
			end
			
			
			regs.ip = temp
		end
		cpu.Add = function(self, prefix, instruction)
			if (instruction == 4) then 
				local imm8 = helper.Signed(self:GetByte(), 8)
				local al = self:GetRegister("a", 8)
				local temp = al + imm8 
				
				cpu:CheckOverflow(0, 8, al, imm8)
				cpu:CheckSigned(temp, 8)
				cpu:CheckCarry(temp, 8)
				cpu:CheckParity(temp, 8)
				self:SetRegister("a", temp, 8, 0)
				
			elseif (instruction == 5) then 
				self:SetRegister("a", self:GetWord(), 16)
								
			end
		end
		--Junktions --This for instructions that have the same opcodes, because I do not specify the extended bits within them 
		cpu.JunktionFF = function(self, prefix, instruction)
			local x = self.GetExtendedBits(self:Get(1))
			if (x == 4 or x == 5) then
				self:Jump(prefix, instruction)
			elseif (x == 6) then 
				self:Push(prefix, instruction)			
			end 
		end
		
		cpu.Junktion8F = function(self, prefix, instruction)
			local x = self.GetExtendedBits(self:Get(1))
			
			if (x == 0) then 
				self:Pop(prefix, instruction)
			end
		end
		cpu.JunktionC6 = function(self, prefix, instruction)-- even though this junktion only has one instruction listed in the manual, better safe than sorry k
			local x = self.GetExtendedBits(self:Get(1))
			
			if (x == 0) then 
				self:Move(prefix, instruction)
			end
		end
		cpu.JunktionC7 = function(self, prefix, instruction) -- even though this junktion only has one instruction listed in the manual, better safe than sorry k
			local x = self.GetExtendedBits(self:Get(1))
			
			if (x == 0) then 
				self:Move(prefix, instruction)
			end
		end
	end
	--cpu.Move = function(...) end
		--end of instructioons
		--reflects memory functions (v)
		
	--setting the instructions
	do
		local ins = cpu.Instructions
		
		ins[0x04] = cpu.Add 
		ins[0x06] = cpu.Push
		ins[0x0E] = cpu.Push
		ins[0x16] = cpu.Push 
		ins[0x1E] = cpu.Push 
		
		
		
		for x = 0x50, 0x57, 1 do 
			ins[x] = cpu.Push
		end
		for x = 0x58, 0x5F, 1 do 
			ins[x] = cpu.Pop
		end
		ins[0x60] = cpu.Pushad
		ins[0x68] = cpu.Push
		ins[0x6A] = cpu.Push  
		ins[0xE9] = cpu.Jump
		ins[0xEA] = cpu.Jump
		ins[0xEB] = cpu.Jump
		
		ins[0x70] = cpu.Jcc
		ins[0x72] = cpu.Jcc
		--[[
		ins[0x88] = cpu.Move
		ins[0x89] = cpu.Move
		ins[0x8A] = cpu.Move
		ins[0x8B] = cpu.Move]]
		for x = 0x88, 0x8B, 1 do 
			ins[x] = cpu.Move
		end
	
		ins[0xA0] = cpu.Move
		ins[0xA1] = cpu.Move
				
		
		ins[0x8E] = cpu.Move
		
		ins[0x8D] = cpu.Lea 
		
		for x = 0xB0, 0xBF, 1 do 
			ins[x] = cpu.Move
		end 
		
		ins[0xF4] = cpu.Halt
		
		ins[0xF8] = cpu.Clc
		ins[0xF9] = cpu.Stc 
		ins[0xFA] = cpu.Cli
		ins[0xFB] = cpu.Sti 
		ins[0xFC] = cpu.Cld 
		ins[0xFD] = cpu.Std
		
		ins[0x0FA0] = cpu.Push 
		ins[0x0FA2] = cpu.Cpuid
		ins[0x0FA8] = cpu.Push 
		--junktions
		ins[0xC6] = cpu.JunktionC6
		ins[0xC7] = cpu.JunktionC7
		ins[0x8F] = cpu.Junktion8F
		ins[0xFF] = cpu.JunktionFF
		
	end
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------
	
	cpu.Get = function(self, bytes, inch) -- 6/19/2016 
		return self.Memory:Get(self.Registers.ip, bytes, inch)
	end
	cpu.CheckSigned = function(self, temp, bits, dest, source)
		return bitwise:AND(bitwise:SHR(temp, bits-1), 1, 1) == 1 and self:SetFlag(7) or self:ClearFlag(7)
	end
	cpu.CheckCarry = function(self, temp, bits, dest, source)
		
		if (temp > (2^bits)-1) then 
			self:SetFlag(0)
		end
	end
	cpu.CheckParity = function(self, temp, bits, dest, source)
		return ((bitwise:AND(temp, 0xFF, 8) % 2) == 0 and self:SetFlag(2) or self:ClearFlag(2))
	end
	cpu.CheckZero = function(self, temp, bits, dest, source) -- ::
		return (temp == 0 and self:SetFlag( ) or self:ClearFlag( ))
	end
	cpu.CheckOverflow = function(self, temp, bits, dest, source)
		
		if (not (helper:Signable(dest, bits) == helper:Signable(source, bits))) then 
			return 
		end
		
		if (helper:Signable(temp, bits) ~= helper:Signable(dest, bits)) then 
			self:SetFlag(11)
		end
		
		return
	end
	cpu.ToLittleEndian = function(number, b)
		local new = 0 
		local temp = b 
		while (temp ~= 0) do 
			new = bitwise:SHL(new, 8)
			new = bitwise:OR(new, bitwise:AND(number, 0xFF, 8), b * 8)
			number = bitwise:SHR(number, 8)
			temp = temp - 1
		end
		
		return new
	end
	cpu.GetByte = function(self)
		local regs = self.Registers 
		local ip = regs.ip
		local value = self.Memory:GetByte(cpu:CalculateAddress(ip))
		regs.ip = ip + 1 
		return value
	end
	cpu.SetByte = function(self, where, value)
		self.Memory:SetByte(where, value)
		return 
	end
	cpu.GetWord = function(self)
		local regs = self.Registers 
		local ip = regs.ip
		local value = self.ToLittleEndian(self.Memory:GetWord(cpu:CalculateAddress(ip)), 2)
		--warn(value, self.Memory:GetWord(cpu:CalculateAddress(ip)))
		regs.ip = ip + 2
		return value
	end 
	cpu.SetWord = function(self, where, value)
		self.Memory:SetWord(where, self.ToLittleEndian(value, 2))
		return
	end
	cpu.GetDword = function(self)
		
		local regs = self.Registers
		local ip = regs.ip
		local value = self.ToLittleEndian(self.Memory:GetDword(cpu:CalculateAddress(ip)), 4)
		regs.ip = ip + 4
		return value
	end
	cpu.SetDword = function(self, where, value)
		self.Memory:SetDword(where, self.ToLittleEndian(value, 4)) --reverse
	end
	cpu.PushWord = function(self, value)
		local regs = self.Registers
		regs.sp = regs.sp - 2
		self.Memory:SetWord(regs.sp, value) --reverse it
	end
	cpu.PushDword = function(self, value)
		local regs = self.Registers 
		regs.sp = regs.sp - 4 
		self.Memory:SetDword(regs.sp, value)
	end
	cpu.PopWord = function(self)
		local regs = self.Registers
		local value = self.ToLittleEndian(self.Memory:GetWord(regs.sp), 2)
		regs.sp = regs.sp + 2
		return value
	end--[[
	cpu.PushDword = function(self, value)
		local regs = self.Registers
	end]]
	cpu.ExecuteServiceRoutine = function(self, routine)
		
	end--[[
	cpu.ExecuteNearCall = function(self) --function paramters unknown for now
		local regs = self.Registers
		self:PushWord(
	end]]
	cpu.SetRegister = function(self, reg_name, value, bits, sh) --may be traunced 
		
		local regs = self.Registers
		local old = regs[reg_name]
		
		
		local value = bitwise:SHL(bitwise:AND(value, (2^bits)-1, bits), sh or 0)
		
		if (sh) then 
			regs[reg_name] = value
		else 
			regs[reg_name] = value
		end
	end 
	cpu.GetRegister = function(self, reg_name, bits, sh)
		if (not sh) then sh = 0 end
		return bitwise:SHR(bitwise:AND(self.Registers[reg_name], (2^bits)-1, bits), sh)
	end
	return cpu
end