local bitwise = {
		AND = function(self, byte1, byte2, size)
			local value = 0
			for i = 1, size do
				--[[
				local bit1, bit2 = (math.floor(byte1/(2^(i-1)))%2), (math.floor(byte2/(2^(i-1)))%2)
				kprint(string.format("bits(%d, %d) index(%d)", bit1, bit2, i))
				]]
				value = value + ((((math.floor(byte1/(2^(i-1)))%2))*((math.floor(byte2/(2^(i-1)))%2)))*2^(i-1))
			end
			return value
		end,
		OR = function(self, byte1, byte2, size)
			local value = 0
			for i = 1, size do
				local bit1, bit2 = (math.floor(byte1/(2^(i-1)))%2), (math.floor(byte2/(2^(i-1)))%2)
				--kprint(string.format("bits(%d, %d) index(%d)", bit1, bit2, i))
				local final_bit = 0
				
				if (bit1 == 1 and bit2 == 1) then
					final_bit = 1
				elseif(bit1 == 1 or bit2 == 1) then
					final_bit = 1
				else
					final_bit = 0
				end
				
				value = value + (final_bit * 2 ^ (i-1))
			end
			
			return value
		end,
		NOT = function(self, byte1, size) 
			local value = 0
			for i = 1, size do
				local bit = (math.floor(byte1/(2^(i-1)))%2)
				local final_bit = 0
				
				if (bit == 1) then
					final_bit = 0
				else
					final_bit = 1
				end
				
				value = value + (final_bit * 2 ^ (i-1))
				
			end
			
			return value
		end,
		XOR = function(self, byte1, byte2, size)
			local value = 0
			for i = 1, size do
				local bit1, bit2 = (math.floor(byte1/(2^(i-1)))%2), (math.floor(byte2/(2^(i-1)))%2)
				local final_bit = 0
				
				if (bit1 == 1 and bit2 == 1) then
					final_bit = 0
				elseif(bit1 == 1 or bit2 == 1) then
					final_bit = 1
				else
					final_bit = 0
				end
				
				value = value + (final_bit * 2 ^ (i-1))
			end
			
			return value
		end,
		SHL = function(self, byte, shift)
			return byte * (2 ^ shift)
		end,
		SHR = function(self, byte, shift)
			return math.floor(byte / (2 ^ shift))
		end,
		ROL = function(self, byte, shift, size)
			return self:OR(self:SHL(byte, shift), self:SHR(byte, shift), size)
		end,
		ROR = function(self, byte, shift, size)
			return self:OR(self:SHR(byte, shift), self:SHL(byte, shift), size)
		end
}

return bitwise