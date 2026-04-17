##############################################################################
# baremetal_template — General Makefile for STM32
#
# USAGE: Run 'make' to build, 'make clean' to remove build artifacts,
#        'make flash' to flash via OpenOCD.
#
# THINGS TO CHANGE before building:
#   1. MCU        — Cortex core of your chip
#   2. DEVICE     — STM32 device define for CMSIS
#   3. LDSCRIPT   — Linker script for your chip
#   4. ASM_SOURCES — Startup file for your chip
##############################################################################


#--------------------------------------------------------------
# 1. TARGET — name of the output binary (change freely)
#--------------------------------------------------------------
TARGET = firmware


#--------------------------------------------------------------
# 2. MCU CONFIGURATION — change to match your STM32
#
# Examples:
#   STM32F1xx → cortex-m3
#   STM32F4xx → cortex-m4
#   STM32G0xx → cortex-m0plus
#   STM32H7xx → cortex-m7
#--------------------------------------------------------------
MCU_CORE   = cortex-m3
FPU        =                        # leave empty if no FPU (M0, M3)
FLOAT_ABI  =                        # leave empty if no FPU

# STM32 device define — passed to the compiler so CMSIS headers
# know which chip you are using.
# Examples: STM32F103xB  STM32F401xC  STM32G071xx  STM32H743xx
DEVICE     = STM32F103xB


#--------------------------------------------------------------
# 3. LINKER SCRIPT — use the .ld file for your exact MCU
# Example: STM32F103C8TX_FLASH.ld
#--------------------------------------------------------------
LDSCRIPT   = STM32F103C8TX_FLASH.ld


#--------------------------------------------------------------
# 4. SOURCES
#--------------------------------------------------------------

# Startup file — assembly (.s) or C (.c) depending on your device
# Example: startup_stm32f103xb.s
ASM_SOURCES = \
	Core/Src/startup_stm32f103xb.s

# C source files — add your own .c files here
C_SOURCES = \
	Core/Src/main.c


#--------------------------------------------------------------
# 5. INCLUDE PATHS — folders containing .h header files
#--------------------------------------------------------------
C_INCLUDES = \
	-ICore/Inc \
	-IDrivers/CMSIS/Include \
	-IDrivers/CMSIS/Device/ST/STM32F1xx/Include


#--------------------------------------------------------------
# 6. TOOLCHAIN — arm-none-eabi must be on your PATH
#--------------------------------------------------------------
PREFIX  = arm-none-eabi-
CC      = $(PREFIX)gcc
AS      = $(PREFIX)gcc -x assembler-with-cpp
CP      = $(PREFIX)objcopy
SZ      = $(PREFIX)size
HEX     = $(CP) -O ihex
BIN     = $(CP) -O binary -S


#--------------------------------------------------------------
# 7. FLAGS
#--------------------------------------------------------------

# CPU flags
CPU = -mcpu=$(MCU_CORE) -mthumb $(FPU) $(FLOAT_ABI)

# Common compiler flags
COMMON_FLAGS = $(CPU) \
	-Wall \
	-fdata-sections \
	-ffunction-sections

# C-specific flags
CFLAGS = $(COMMON_FLAGS) \
	-D$(DEVICE) \
	-DUSE_FULL_ASSERT \
	$(C_INCLUDES) \
	-std=c11 \
	-O0 -g3

# Assembler flags
ASFLAGS = $(COMMON_FLAGS) \
	-D$(DEVICE) \
	$(C_INCLUDES) \
	-g3

# Linker flags
LDFLAGS = $(CPU) \
	-T$(LDSCRIPT) \
	-Wl,--gc-sections \
	-Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref \
	-nostdlib


#--------------------------------------------------------------
# 8. BUILD DIRECTORY
#--------------------------------------------------------------
BUILD_DIR = build


#--------------------------------------------------------------
# BUILD RULES — no need to change anything below this line
#--------------------------------------------------------------

# Collect all object files
OBJECTS  = $(addprefix $(BUILD_DIR)/, $(notdir $(C_SOURCES:.c=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)/, $(notdir $(ASM_SOURCES:.s=.o)))

# Directory search paths for make
vpath %.c $(sort $(dir $(C_SOURCES)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

# Default target
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin

# Compile C sources
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	@echo "[CC]  $<"
	@$(CC) -c $(CFLAGS) $< -o $@

# Assemble startup file
$(BUILD_DIR)/%.o: %.s | $(BUILD_DIR)
	@echo "[AS]  $<"
	@$(AS) -c $(ASFLAGS) $< -o $@

# Link
$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS)
	@echo "[LD]  $@"
	@$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	@$(SZ) $@

# Convert to HEX
$(BUILD_DIR)/$(TARGET).hex: $(BUILD_DIR)/$(TARGET).elf
	@echo "[HEX] $@"
	@$(HEX) $< $@

# Convert to BIN
$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	@echo "[BIN] $@"
	@$(BIN) $< $@

# Create build directory
$(BUILD_DIR):
	@mkdir -p $@


#--------------------------------------------------------------
# FLASH — requires OpenOCD
# Adjust -f flags to match your programmer and target
#--------------------------------------------------------------
flash: $(BUILD_DIR)/$(TARGET).elf
	openocd \
		-f interface/stlink.cfg \
		-f target/stm32f1x.cfg \
		-c "program $(BUILD_DIR)/$(TARGET).elf verify reset exit"


#--------------------------------------------------------------
# CLEAN
#--------------------------------------------------------------
clean:
	@echo "[CLEAN] Removing $(BUILD_DIR)/"
	@rm -rf $(BUILD_DIR)

.PHONY: all flash clean
