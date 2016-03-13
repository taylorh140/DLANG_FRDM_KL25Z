
echo "Compile Code"
".\..\LDC\bin\ldc2.exe" -output-o -march=thumb -mcpu=cortex-m0plus -mtriple=arm-linux -g -c main.d start.d MKL25Z4.d
rem ".\..\ARM_GDC\bin\arm-unknown-linux-gnueabi-gdc.exe" -mthumb -mcpu=cortex-m0 -c -fno-emit-moduleinfo -ffunction-sections main.d start.d MKL25Z4.d
rem .\libaeabi-cortexm0-master\idivmod.S .\libaeabi-cortexm0-master\uidivmod.S .\libaeabi-cortexm0-master\idiv.S  -fdata-sections -fdebug -g -O1
echo "Link Objects"
".\..\ARM_GDC\bin\arm-unknown-linux-gnueabi-ld.exe" -T mkl25z4.ld --gc-sections  start.o MKL25Z4.o main.o  -o ldoutput.elf

rem 'idivmod.o uidivmod.o  idiv.o' .\..\ARM_GDC\arm-unknown-linux-gnueabi\lib\libgdruntime.a
copy ldoutput.elf ".\..\UVISION\Objects\Blinky.axf"
echo "Change Object Format"
".\..\ARM_GDC\bin\arm-unknown-linux-gnueabi-objcopy.exe" -S -O srec ldoutput.elf program.srec
echo "Done: Dumping information"
".\..\ARM_GDC\bin\arm-unknown-linux-gnueabi-objdump.exe" -s -D ldoutput.elf > ldout_dump.txt
rem TIMEOUT /T 40
pause