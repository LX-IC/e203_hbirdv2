################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../application/cpuidc.c \
../application/whets.c 

OBJS += \
./application/cpuidc.o \
./application/whets.o 

C_DEPS += \
./application/cpuidc.d \
./application/whets.d 


# Each subdirectory must supply rules for building sources it contributes
application/%.o: ../application/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-nuclei-elf-gcc -march=rv32imac -mabi=ilp32 -mcmodel=medany -mno-save-restore -funroll-loops -fsingle-precision-constant -O3 -ffunction-sections -fdata-sections -fno-common  -g -DDOWNLOAD_MODE=DOWNLOAD_MODE_ILM -DSOC_HBIRDV2 -DBOARD_DDR200T -I"E:\NucleiStudio\NucleiStudio_IDE_202102-win64\NucleiStudio_workspace\whetstone\application" -I"E:\NucleiStudio\NucleiStudio_IDE_202102-win64\NucleiStudio_workspace\whetstone\hbird_sdk\NMSIS\Core\Include" -I"E:\NucleiStudio\NucleiStudio_IDE_202102-win64\NucleiStudio_workspace\whetstone\hbird_sdk\SoC\hbirdv2\Common\Include" -I"E:\NucleiStudio\NucleiStudio_IDE_202102-win64\NucleiStudio_workspace\whetstone\hbird_sdk\SoC\hbirdv2\Board\ddr200t\Include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


