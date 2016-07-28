--this is just a test script

function readFile(filename)
	if (not filename) then return nil end 
	local file = io.open(filename, "r")
	
	if (not file) then return nil end 
	local content = file:read("*a")
	
	io.close(file)
	
	return content 
end 

function warn(...)
	local str = ""
	local args = {...}
	
	for x = 1, #args do 
		str = str .. tostring(args[x])
	end

	--print(str)
	print(string.format("\27[00;31m%s\27[00;00m", str))
end 


local content = readFile(arg[1])
local input_cs = tonumber(arg[2])
local input_ip = tonumber(arg[3])

if (not input_cs) then 
	print("cs was not input, please input: ")
	input_cs = io.read("*n")
end 

if (not input_ip) then 
	print("ip was not input, please input: ")
	input_ip = io.read("*n")
end 

if (not content) then 
	print("File provided was unreadable.")
	os.exit(1)
end

-----------------------------------------------
local kemu = require("Kemu")
local emulator = kemu()

emulator:Load(content, input_cs, input_ip)

local execution = coroutine.create(emulator.Run)

local Outputer = {
	Emulator = emulator,
	Commands = {
		{{"dumpregs", "dumpreg"}, "Dumps registers", function(this, command, args) 
			table.foreach(this.Emulator.Processor.Registers, function(a, b)
				print(string.format("%s: %s", a, b))
			end)
			return 0 
		end},
		{{"run", "execute", "r", "Executes", "resume"}, "Starts executing or resume from point", function(this, command, args)
			
			warn("Executing")
			coroutine.resume(execution, emulator)
			
			return 0 
		end},
		{{"stop"}, "Stops execution", function(this, command, args)
			warn("Stopping")
			emulator:Stop()
			
			return 0 
		end},
		{{"help", "h"}, "Help text", function(this, command, args)
			this.Help()
		end},
		{{"exit"}, "Exits the script", function(this, command, args)
			os.exit(0)
		end}
	},
	Execute = function(self, command)
		command = command:lower()
		local main = string.match(command, "^%w+")
		if (not main) then return false, -1 end 
		local arg_strip = string.sub(command, string.find(command, main)+#main, -1)
		local args = self.StripArgs(arg_strip)
		
		local ctbl = self:SearchCommand(main)
		
		if (not ctbl) then return false, -2 end 
		
		local this = self:Thisify(ctbl)
		
		
		local handler = this.Handler 
		
		return true, handler(this, main, args)
	end,
	StripArgs = function(arg_strip)
		local args = {}
		
		for x in string.gmatch(arg_strip, "%S*") do 
			args[#args + 1] = x 
		end 
		
		return args
	end,
	SearchCommand = function(self, command)
		local function CompareTable(tbl, thing) 
			for x = 1, #tbl do 
				if (tbl[x] == thing) then 
					return true 
				end 
			end
			return false
		end 
		local commands = self.Commands 
		local temp 
		for x = 1, #commands do 
			temp = commands[x]
			if (CompareTable(temp[1], command)) then 
				return temp 
			end 
		end 
		
		return nil
	end,
	Thisify = function(self, command) 
		return {
			Aliases = command[1],
			Description = command[2],
			Handler = command[3],
			SearchArgs = function(args, arg)
				for x = 1, #args do 
					if (args[x] == arg) then 
						return true 
					end 
				end 
				return false
			end,
			Help = function() self:Help() end,
			Emulator = self.Emulator
		}
	end,
		Help = function(self)
			local function TableTostring(x)
				local str = ""
				
				for xd = 1, #x do 
					str = str .. x[xd] .. ", "
				end 
				
				return str:sub(1, #str-2)
			end 
			local commands = self.Commands 
			warn("Help menu:")
			local temp 
			for x = 1, #commands do 
				temp = commands[x]
				print(string.format(" {%s} - %s", TableTostring(temp[1]), temp[2]))
			end 
		end 
}

while true do 
	local line = io.read("*l")
	Outputer:Execute(line)
	
end 