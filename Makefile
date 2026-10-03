LD		 := ld65
LDFLAGS  := -v -S 0x8000
AS 		 := ca65
ASFLAGS  := -v --cpu W65C02
CC		 := cc65
CFLAGS	 := -v --cpu W65C02
SIM		 :=	sim65
SIMFLAGS :=	

DIR_SRC		:=	src
DIR_BUILD	:=	build
DIR_DEBUG	:=	debug
DIR_OBJ		:=	$(DIR_BUILD)/obj
DIR_BIN		:=	$(DIR_BUILD)/bin

C_SRCS		:=	$(shell find $(DIR_SRC) -type f -name "*.c")
ASM_SRCS	:=	$(shell find $(DIR_SRC) -type f -name "*.s")
C_OBJS		:=	$(patsubst $(DIR_SRC)/%.c,$(DIR_OBJ)/%.c.o,$(C_SRCS))
ASM_OBJS	:=	$(patsubst $(DIR_SRC)/%.s,$(DIR_OBJ)/%.s.o,$(ASM_SRCS))
OBJS		:=	$(C_OBJS) \
				$(ASM_OBJS)

FIRMWARE		:= 	firmware.bin
FIRMWARE_SIM	:=	simulation.bin

.PHONY: sim
sim: $(OBJS)
	@mkdir -p $(DIR_BIN)
	$(LD) $(LDFLAGS) -t sim65c02 -o $(DIR_BIN)/$(FIRMWARE_SIM) $(OBJS) /share/cc65/lib/sim65c02.lib
	$(SIM) --cycles --trace -v $(DIR_BIN)/$(FIRMWARE_SIM)

$(FIRMWARE): $(OBJS)
	@mkdir -p $(DIR_BIN)
	@echo "[Linking into $@] $<"
	$(LD) $(LDFLAGS) -C mem.cfg $(OBJS)

$(DIR_OBJ)/%.c.o: $(DIR_SRC)/%.c
	@mkdir -p $(DIR_OBJ)
	@echo "[Compiling C file $< to $@]"
	$(CC) $(CFLAGS) -o $@ $<

$(DIR_OBJ)/%.s.o: $(DIR_SRC)/%.s
	@mkdir -p $(DIR_OBJ)
	@echo "[Compiling ASSEMBLY file $< to $@]"
	$(AS) $(ASFLAGS) -o $@ $<

.PHONY: prg
prg:  $(FIRMWARE)
	@echo "[Sending data over UART]"
	python3 uartup.py

.PHONY: ru
ru:	$(FIRMWARE)
	@echo "[Programming EEPROM]"
	minipro -p AT28C256 -w $(DIR_BIN)/$(FIRMWARE) -u

.PHONY: rd
rd:
	@echo "[Dumping EEPROM]"
	minipro -p AT28C256 -r $(DIR_DEBUG)/$(FIRMWARE).dumped

.PHONY: re
re:
	@echo "[Erasing EEPROM]"
	minipro -p AT28C256 -E

.PHONY: clr
clr:
	@echo "[Clearing build and debug dirs]"
	rm -rf $(DIR_BUILD) $(DIR_DEBUG)
