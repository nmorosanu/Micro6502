.SUFFIXES: .c .s .o

LD		 	= 	ld65
LD_FLAGS 	= 	-v -S 0x8000
AS 			= 	ca65
AS_FLAGS 	= 	-v --cpu W65C02
CC			= 	cc65
CC_FLAGS	= 	-v --cpu W65C02
SIM			=	sim65
SIMFLAGS	=	

ASM_SRC 	= 	src/main.s\
				src/vectors.s\
				src/peripherals.s\
				src/program.s\
				src/monitor.s\
				src/games.s

DIR_BUILD		=	build
ASM_OBJ 		= 	$(ASM_SRC:%.s=%.o)
FIRMWARE		= 	firmware.bin
FIRMWARE_SIM	=	simulation.bin

sim: $(ASM_OBJ)
	$(LD) $(LD_FLAGS) -t sim65c02 -o $(DIR_BUILD)/$(FIRMWARE_SIM) $(ASM_OBJ) /share/cc65/lib/sim65c02.lib
	$(SIM) --cycles --trace -v $(DIR_BUILD)/$(FIRMWARE_SIM)

$(FIRMWARE): $(ASM_OBJ)
	$(LD) $(LD_FLAGS) -C mem.cfg $(ASM_OBJ)
	rm $(ASM_OBJ)

.s.o:
	$(AS) $(AS_FLAGS) -o $@ $<
.c.o:
	$(CC) $(CC_FLAGS) -o $@ $<

prg:  $(FIRMWARE)
	python3 uartup.py

ru:	$(FIRMWARE)
	minipro -p AT28C256 -w $(DIR_BUILD)/$(FIRMWARE) -u
rd:
	minipro -p AT28C256 -r $(DIR_BUILD)/$(FIRMWARE).d
re:
	minipro -p AT28C256 -E

clr:
	rm -f $(ASM_OBJ) $(FIRMWARE)

.PHONY: clr
