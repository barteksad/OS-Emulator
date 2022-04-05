global so_emul

section .data

    align 8
    DETECT_JUMP:     dw 0xC
    DETECT_NO_ARGS:  dw 0x8000
    DETECT_ARG_IMM:  dw 0x4000

    A_REG_CODE:      db  0
    D_REG_CODE:      db  1
    X_REG_CODE:      db  2
    Y_REG_CODE:      db  3
    X_MEM_CODE:      db  4
    Y_MEM_CODE:      db  5
    XpD_MEM_CODE:    db  6
    YpD_MEM_CODE:    db  7

section .bss

    align 8
    A_REG:       resb    1
    D_REG:       resb    1
    X_REG:       resb    1
    Y_REG:       resb    1
    PC_REG:      resb    1
    unused:      resb    1
    C_REG:       resb    1
    Z_REG:       resb    1

section .text

decode_arg1:

    mov byte [rel X_REG], 5;

    ; decodes value of arg1 from [rdi] to r8b
    ; arg1 is encoded in bites 9, 10, 11 of [rdi] so we can take 3-th byte pf rdi and AND it with 0x7
    mov     r8b, byte [rdi + 1]
    and     r8b, 0x7

    ; use rax for temporary lea source
    xor     rax, rax

    mov     al,  byte [rel A_REG]
    cmp     r8b, byte [rel A_REG_CODE]
    je      .decoded_arg1

    mov     al,  byte [rel D_REG]
    cmp     r8b, byte [rel D_REG_CODE]
    je      .decoded_arg1

    mov     al,  byte [rel X_REG]
    cmp     r8b, byte [rel X_REG_CODE]
    je      .decoded_arg1

    mov     al,  byte [rel Y_REG]
    cmp     r8b, byte [rel Y_REG_CODE]
    je      .decoded_arg1

    mov     al,  byte [rel X_REG]
    mov     al,  byte [rsi + rax]
    cmp     r8b, byte [rel X_MEM_CODE]
    je      .decoded_arg1

    mov     al,  byte [rel Y_REG]
    mov     al,  byte [rsi + rax]
    cmp     r8b, byte [rel Y_MEM_CODE]
    je      .decoded_arg1

    mov     al,  byte [rel X_REG]
    add     al,  byte [rel D_REG]
    mov     al,  byte [rsi + rax]
    cmp     r8b, byte [rel XpD_MEM_CODE]
    je      .decoded_arg1

    mov     al,  byte [rel Y_REG]
    add     al,  byte [rel D_REG]
    mov     al,  byte [rsi + rax]
    cmp     r8b, byte [rel YpD_MEM_CODE]
    je      .decoded_arg1

    .decoded_arg1:

    mov     r8b, al ; we only care about r8b value
    ret
        
decode_arg2:

    ; decodes value of arg2 from [rdi] to r9b
    ; arg1 is encoded in bites 12, 13, 14 of [rdi] so we can shr rdi 11 bites and AND it with 0x7
    mov     r9, [rdi]
    shr     r9, 11
    and     r9b, 0x7

    ; use rax for temporary lea source
    xor     rax, rax

    mov     al,  byte [rel A_REG]
    cmp     r9b, byte [rel A_REG_CODE]
    je      .decoded_arg2

    mov     al,  byte [rel D_REG]
    cmp     r9b, byte [rel D_REG_CODE]
    je      .decoded_arg2

    mov     al,  byte [rel X_REG]
    cmp     r9b, byte [rel X_REG_CODE]
    je      .decoded_arg2

    mov     al,  byte [rel Y_REG]
    cmp     r9b, byte [rel Y_REG_CODE]
    je      .decoded_arg2

    mov     al,  byte [rel X_REG]
    mov     al,  byte [rsi + rax]
    cmp     r9b, byte [rel X_MEM_CODE]
    je      .decoded_arg2

    mov     al,  byte [rel Y_REG]
    mov     al,  byte [rsi + rax]
    cmp     r9b, byte [rel Y_MEM_CODE]
    je      .decoded_arg2

    mov     al,  byte [rel X_REG]
    add     al,  byte [rel D_REG]
    mov     al,  byte [rsi + rax]
    cmp     r9b, byte [rel XpD_MEM_CODE]
    je      .decoded_arg2

    mov     al,  byte [rel Y_REG]
    add     al,  byte [rel D_REG]
    mov     al,  byte [rsi + rax]
    cmp     r9b, byte [rel YpD_MEM_CODE]
    je      .decoded_arg2

    .decoded_arg2:

    mov     r9b, al ; we only care about r9b value
    ret

so_emul:

    ; uint16_t const *code, uint8_t *data, size_t steps, size_t core
    ; rdi - code pointer, rsi - data pointer, rdx - steps, rcx - cores

    push    rbp  
    mov     rbp, rsp

    .emul_step:

        test    rdx, rdx    ; check if number of steps to perform is greater than zero
        jz      .steps_end 

        ; we have actions taking different types of argument and we have to detect them    

        ; detect jumps
        ; this can be done by shifting right 12 bits and checking if it is equal to 1100 (C??? - hex before shift) 
        mov     ax, [rdi]                
        shr     ax, 12
        test    ax, [rel DETECT_JUMP]
        jnz     .switch_imm8 

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

        ; if none from above, than must be arg arg operation
        jmp .switch_arg_arg 

        .switch_arg_arg:
            ; rsp + 8 is 16 aligned because we pushed rbp
            call decode_arg1
            call decode_arg2
            

        .switch_arg_imm8:
        mov rax, 0
        .switch_no_param:
        mov rax, 0
        .switch_imm8:
        mov rax, 0
        


        inc     byte [rel PC_REG]   ; increment total steps count
        dec     rdx                 ; decrement steps to execute count
        inc     rdi                 ; increment code pointer
        jmp     .emul_step          ; jump to next step loop

    .steps_end:

    leave
    mov     rax, qword [rel A_REG]  ; saves so cpu state 
    ret