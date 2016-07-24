#Kemu

This is a study project for me, but it is also something people can look at if they are interested.

The things I am doing could be wrong, please notify me if there is something wrong


Instructions supported in kemu

Tested instructions:<br/ >
	CPUID	(0x0FA2)<br/ >
	MOV*	(0x88, 0x89, 0x8A, 0x8B, 0x8E, 0xA0, 0xA1, 0xB0-0xB7, 0xB8-0xBF, 0xC6 /0, 0xC7 /0)<br/ >
	JMP*	(0xE9, 0xEA, 0xEB, 0xFF /4, 0xFF /5)<br/ >
	PUSH*	(0x50-0x57, 0xFF /6<br/ >
	LEA*** 	(0x8D)<br/ >
Not tested instructions:<br/ >
	CLD (0xFC)<br/ >
	STD (0xFD)<br/ >
	CLI (0xFA)<br/ >
	STI (0xFB)<br/ >
	CLC (0xF8)<br/ >
	STC (0xF9)<br/ >
	POP (0x8F /0, 0x58-0x5F, 0x1F, 0x0, 0x17, 0x0FA1, 0x0FA9)<br/ >
	ADD (0x04)**<br/ >
Instructions in processes:<br/ >
	ADD<br/ >
	JCC<br/ >
	
	
	
	
	
	
* 	- Not all opcodes was tested for this instruction
** 	- There are more opcodes to come for this instruction
*** - Although this instruction is tested or not, I am not sure if this is correct. 
------------------------------------------LEGEND------------------------------------------
Opcode /number - This opcode + the extended bits (/number) determine the instruction 


Intel manual:
	http://www.intel.com/content/www/us/en/processors/architectures-software-developer-manuals.html