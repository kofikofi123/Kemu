local bitwise = require("Bitwise")

local helper = require("GHelper")
return function(cpu)
	local asd = {}
	local continue = true
	local warn = (warn or print)
	
	asd.Processor = (cpu or require("CPU")())
			
	
	
	asd.Step = function(self)
		local debugger = {}
		local cpu = self.Processor
		local memory = cpu.Memory
		local regs = cpu.Registers
		local ins = cpu.Instructions
		
		local prefix = self:DecodePrefix()
		local instruction = self:DecodeInstruction(prefix)
		
		local handler = ins[instruction]
		
		if (handler) then 
			handler(cpu, prefix, instruction)
		else
			error(string.format("Unknown instruction: %#x\ncs=%#x\nip=%#x\nThis instruction either does not exist, or is not supported in this emulator yet.", instruction, regs.cs, regs.ip))
		end
		return debugger
	end
	
	asd.Stop = function(self)
		continue = false
	end
	
	asd.Run = function(self)
		local cpu = self.Processor
		continue = true
		while true do
			if (continue) then 
				self:Step()
			else 
				break
			end
		end
	end
	
	asd.DecodePrefix = function(self)
		local temp 
		local prefixes = {}
		local cpu = self.Processor
		local regs = cpu.Registers
		local possible_prefixes = {
			[0xF0] = true,
			[0xF2] = true,
			[0xF3] = true, 
			[0x2E] = true,
			[0x36] = true,
			[0x3E] = true,
			[0x26] = true,
			[0x64] = true,
			[0x65] = true,
			[0x66] = true,
			[0x67] = true,
			[0x0F] = true
			
		}
		while true do
			temp = cpu:GetByte()
			if (not possible_prefixes[temp]) then 
				regs.ip = regs.ip - 1
				break 
			end
			
			prefixes[#prefixes + 1] = temp
		end		
		return prefixes
	end
	
	asd.DecodeInstruction = function(self, prefixes)
		--[[local function search(prefix)
			for x = 1, #prefixes do 
				if (prefixes[x] == prefix) then 
					return true 
				end
			end
			return false 
		end]]
		
		local cpu = self.Processor 
		
		local opc
		
		if (helper.SearchPrefix(prefixes, 0x0F)) then 
			opc = bitwise:OR(0x0F00, cpu:GetByte(), 16)
		else 
			opc = cpu:GetByte()
		end
		
		return opc
	end
	--thnx euo https://media2.giphy.com/media/9wydK1Q6LGkhO/200.gif
	
	asd.Load = function(self, prog, cs, ip) -- I could rewrite it better, but laterAQA
		local mem = self.Processor.Memory
		local where = (cs * 16) + ip		
		for x = 1, #prog do 
			mem:SetByte((where + (x-1)), string.byte(string.sub(prog, x, x)))
		end
		
		local regs = self.Processor.Registers
		regs.cs = cs 
		regs.ip = ip 
	end
	--[[
		Instruction prefix: 1
	--]]
	--I should have a progam before I start
	return asd 
end