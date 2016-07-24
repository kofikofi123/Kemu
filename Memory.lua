return function(size)
	local array = {field={}}
	local bitwise = require("Bitwise")

	
	local function getByteArray(tbl)
		--"32233223"
		local new_value = 0
		for x = 1, #tbl do 
			new_value = bitwise:SHL(new_value, 8)
			new_value = new_value + tbl[x]
		end
		return new_value
	end 
	
	array.Get = function(self, place, bytes, inch)
		local x = {unpack(self.field, place + 1, place + 1 + (bytes-1))}
		if (inch) then return x end 
		return getByteArray(x)
	end
	
	array.GetByte = function(self, place)
		return tonumber(self.field[place + 1])
	end
	
	array.SetByte = function(self, place, value)
		self.field[place + 1] = value 
	end
	
	array.GetWord = function(self, place)
		return getByteArray({unpack(self.field, place + 1, place + 2)})
	end
	
	array.SetWord = function(self, place, value)
		local field = self.field
		field[place + 1] = bitwise:AND(value, 0xFF, 8)
		field[place + 2] = bitwise:AND(bitwise:SHR(value, 8), 0xFF, 8)
	end
	
	array.GetDword = function(self, place)
		return getByteArray({unpack(self.field, place + 1, place + 4)})
	end
	
	array.SetDword = function(self, place, value)
		local field = self.field
		field[place + 1] = bitwise:AND(value, 0xFF, 8)
		field[place + 2] = bitwise:AND(bitwise:SHR(value, 8), 0xFF, 8)
		field[place + 3] = bitwise:AND(bitwise:SHR(value, 16), 0xFF, 8)
		field[place + 4] = bitwise:AND(bitwise:SHR(value, 24), 0xFF, 8)
	end
	return array
end