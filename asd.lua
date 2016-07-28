local env = getfenv()
env.asdd = {}

function asd()
	print(asdd)
end 

function basd()
	print(asdd)
end 



setfenv(asd, env)

asd()
basd()