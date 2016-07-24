local module = {}
local bitwise = require("Bitwise")

module.SearchPrefix = function(prefixes, prefix)
	for x = 1, #prefixes do 
		if (prefixes[x] == prefix) then 
			return true 
		end
	end
	return false
end

module.ToSign = function(n, b)
	if (n < 0) then 
		return bitwise:NOT(n, b) - 1 
	end
	return 
end

module.Signed = function(n, b)
	if (n > (2^(b-1))-1) then
		return -(bitwise:NOT(n, b) + 1)
	end 
	return n
end

module.Signable = function(self, n, bits)
	local val = self.Signed(n, bits)
	
	if (val < 0) then return true end 
	return false
end

module.InRange = function(n, min, max)
	return (min <= n and n <= max)
end

module.GetByteArray = function(tbl)
	--"32233223"
	local new_value = 0
	for x = 1, #tbl do 
		new_value = bitwise:SHL(new_value, 8)
		new_value = new_value + tbl[x]
	end
	return new_value
end 

module.ToHex = function(value, pad)
	--if (pad > 8) then pad = 8 end
	local hex = "0x"
	
	local switch = {
		[0xA] = 'A', [0xB] = 'B', [0xC] = 'C', [0xD] = 'D', [0xE] = 'E', [0xF] = 'F'
	}
			
	for i = pad-1, 0, -1 do
		local nibble = math.floor(bitwise:AND(bitwise:SHR(value, i * 4), 0xF, 4))
		
		if (not switch[nibble]) then
			hex = hex .. tostring(nibble)
		else
			hex = hex .. switch[nibble]
		end
	end
	return hex
end
--[[possible function 6/19/2016
module.MaxFit = function(bits)
	return (2^bits)-1 
end 
--]]

return module
