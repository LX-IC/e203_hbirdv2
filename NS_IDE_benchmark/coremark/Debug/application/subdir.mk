################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../application/core_list_join.c \
../application/core_main.c \
../application/core_matrix.c \
../application/core_portme.c \
../application/core_state.c \
../application/core_util.c 

OBJS += \
./application/core_list_join.o \
./application/core_main.o \
./application/core_matrix.o \
./application/core_portme.o \
./application/core_state.o \
./application/core_util.o 

C_DEPS += \
./application/core_list_join.d \
./application/core_main.d \
./application/core_matrix.d \
./application/core_portme.d \
./application/core_state.d \
./application/core_util.d 


# Each subdirectory must supply rules for building sources it contributes
application/%.o: ../application/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross C Compiler'
	riscv-nuclei-elf-gcc -march=rv32imac -mabi=ilp32 -mcmodel=medany -mno-save-restore -DITERATIONS=1 -DPERFORMANCE_RUN=1 -O2 -ffunction-sections -fdata-sections -fno-common  -g -DDOWNLOAD_MODE=DOWNLOAD_MODE_ILM -DSOC_HBIRDV2 -DBOARD_DDR200T -I"E:\NucleiStudio\NucleiStudio_IDE_202102-win64\NucleiStudio_workspace\coremark\application" -I"E:\NucleiStudio\NucleiStudio_IDE_202102-win64\NucleiStudio_workspace\coremark\hbird_sdk\NMSIS\Core\Include" -I"E:\NucleiStudio\NucleiStudio_IDE_202102-win64\NucleiStudio_workspace\coremark\hbird_sdk\SoC\hbirdv2\Common\Include" -I"E:\NucleiStudio\NucleiStudio_IDE_202102-win64\NucleiStudio_workspace\coremark\hbird_sdk\SoC\hbirdv2\Board\ddr200t\Include" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


