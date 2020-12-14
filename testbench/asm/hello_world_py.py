#!/usr/bin/python3

f = open("/home/bccue/Cores-SweRV/testbench/asm/hello_world.s", "r")
g = open("/home/bccue/Cores-SweRV/testbench/asm/hello_world_c.c", "w")

for data in f:
	data = data.strip("\n")
	if (data == "") or ("//" in data):
		continue		

	#New text to print to terminal
	if (".ascii" in data):
		print("__asm (\".ascii \\\"========================================\\n\\\"\");", file=g)
		print("__asm (\".ascii \\\"Technically C, but really just assembly.\\n\\\"\");", file=g)
		print("__asm (\".ascii \\\"========================================\\n\\\"\");", file=g)
		print("__asm (\".byte 0\");", file=g)
		break

	#Format the string
	print('__asm (\"', end="", file=g)

	for i in range(len(data)):
		if data[i] == '"':
			print("\\\"", end="", file=g)
		else:
			print(data[i], end="", file=g)
		
	print('\");', file=g)

	#Add .equ directives as #define doesn't work for some reason
	if (".text" in data):
		print("__asm (\".equ STDOUT, 0xd0580000\");", file=g)
		print("__asm (\".equ RV_ICCM_SADR, 0xee000000\");", file=g)

f.close()
g.close()
