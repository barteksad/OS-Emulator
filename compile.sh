gcc -DCORES=4 -c -Wall -Wextra -std=c17 -g -o so_emulator_example.o so_emulator_example.c
nasm -DCORES=4 -f elf64 -g -F dwarf -w+all -w+error -o so_emulator.o so_emulator.asm
gcc -pthread  -o  so_emulator_example so_emulator_example.o so_emulator.o