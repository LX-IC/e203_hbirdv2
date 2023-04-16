################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include hbird_sdk/SoC/hbirdv2/Common/Source/Stubs/subdir.mk
-include hbird_sdk/SoC/hbirdv2/Common/Source/GCC/subdir.mk
-include hbird_sdk/SoC/hbirdv2/Common/Source/Drivers/subdir.mk
-include hbird_sdk/SoC/hbirdv2/Common/Source/subdir.mk
-include application/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(CC_DEPS)),)
-include $(CC_DEPS)
endif
ifneq ($(strip $(C++_DEPS)),)
-include $(C++_DEPS)
endif
ifneq ($(strip $(C_UPPER_DEPS)),)
-include $(C_UPPER_DEPS)
endif
ifneq ($(strip $(CXX_DEPS)),)
-include $(CXX_DEPS)
endif
ifneq ($(strip $(ASM_DEPS)),)
-include $(ASM_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
ifneq ($(strip $(CPP_DEPS)),)
-include $(CPP_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
SECONDARY_FLASH += \
dhrystone.hex \

SECONDARY_SIZE += \
dhrystone.siz \


# All Target
all: dhrystone.elf secondary-outputs

# Tool invocations
dhrystone.elf: $(OBJS) $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: GNU RISC-V Cross C++ Linker'
	riscv-nuclei-elf-g++ -march=rv32imac -mabi=ilp32 -mcmodel=medany -mno-save-restore -O2 -ffunction-sections -fdata-sections -fno-common  -g -T "E:\NucleiStudio\NucleiStudio_IDE_202102-win64\NucleiStudio_workspace\dhrystone\hbird_sdk\SoC\hbirdv2\Board\ddr200t\Source\GCC\gcc_hbirdv2_ilm.ld" -nostartfiles -Xlinker --gc-sections -Wl,-Map,"dhrystone.map" --specs=nano.specs -u _printf_float --specs=nosys.specs -u _isatty -u _write -u _sbrk -u _read -u _close -u _fstat -u _lseek -o "dhrystone.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '
	$(MAKE) --no-print-directory post-build

dhrystone.hex: dhrystone.elf
	@echo 'Invoking: GNU RISC-V Cross Create Flash Image'
	riscv-nuclei-elf-objcopy -O ihex "dhrystone.elf"  "dhrystone.hex"
	@echo 'Finished building: $@'
	@echo ' '

dhrystone.siz: dhrystone.elf
	@echo 'Invoking: GNU RISC-V Cross Print Size'
	riscv-nuclei-elf-size --format=berkeley "dhrystone.elf"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(CC_DEPS)$(C++_DEPS)$(OBJS)$(C_UPPER_DEPS)$(CXX_DEPS)$(SECONDARY_FLASH)$(SECONDARY_SIZE)$(ASM_DEPS)$(S_UPPER_DEPS)$(C_DEPS)$(CPP_DEPS) dhrystone.elf
	-@echo ' '

post-build:
	-riscv-nuclei-elf-objcopy -O verilog "dhrystone.elf" "dhrystone.verilog";riscv-nuclei-elf-objdump -D "dhrystone.elf" >& "dhrystone.dump";sed -i 's/@800/@000/g' "dhrystone.verilog"; sed -i 's/@00002FB8/@00002000/g' "dhrystone.verilog";
	-@echo ' '

secondary-outputs: $(SECONDARY_FLASH) $(SECONDARY_SIZE)

.PHONY: all clean dependents post-build

-include ../makefile.targets
