global so_emul

section .data

    align 2
    DETECT_JUMP     dw 0xC
    DETECT_NO_ARGS  dw 0x8000
    DETECT_ARG_IMM  dw 0x4000

    A_REG_CODE      equ 0
    D_REG_CODE      equ 1
    X_REG_CODE      equ 2
    Y_REG_CODE      equ 3
    X_MEM_CODE      equ 4
    Y_MEM_CODE      equ 5
    XpD_MEM_CODE    equ 4
    YpD_MEM_CODE    equ 4

section .bss

    align 8
    A_REG       resb    1
    D_REG       resb    1
    X_REG       resb    1
    Y_REG       resb    1
    PC_REG      resb    1
    unused      resb    1
    C_REG       resb    1
    Z_REG       resb    1

section .text


so_emul:
    ; uint16_t const *code, uint8_t *data, size_t steps, size_t core
    ; rdi - code pointer, sil - data pointer, rdx - steps, rcx - cores

    push    rbp
    mov     rbp, rsp
    ; allocate mem for possibly two instruction arguments
    ; first arg = [rbp - 8], second arg = [rbp - 16]
    sub     rsp, 16 

    .emul_step:

        test    rdx, rdx
        jz      .steps_end 

        ; we have actions taking different types of argument and we have to detect them    

        ; detect jumps
        ; this can be done by shifting right 12 bits and checking if it is equal to 1100 (C??? - hex before shift) 
        mov     ax, [rdi]                
        shr     ax, 12
        test    ax, [rel DETECT_JUMP]
        jz     .switch_imm8 

        ; detect no args operation
        ; its numbers are greater or equal to 0x8000 and different than jumps
        mov     ax, [rdi]
        cmp     ax, [rel DETECT_NO_ARGS]
        jae     .switch_no_param    ; jump if greater or equal

        ; detect arg + imm8 operation
        ; its numbers are greater or equal to 0x4000 and different than jumps and no args
        mov     ax, [rdi]
        cmp     ax, [rel DETECT_ARG_IMM]
        jae     .switch_arg_imm8    ; jump if greater or equal

        ; if any from above, than must be arg arg operation
        jmp switch_arg_arg 

        .switch_arg_arg:
            mov rax, 0
        .switch_arg_imm8:
        mov rax, 0
        .switch_no_param:
        mov rax, 0
        .switch_imm8:
        mov rax, 0
        


        inc     byte [rel PC_REG]   ; increment total steps count
        dec     rdx             ; decrement steps to execute count
        inc     rdi              ; increment code pointer
        jmp .emul_step          ; jump to next step loop

    .steps_end:

    leave
    mov     rax, qword [rel A_REG]  ; saves so cpu state 
    ret