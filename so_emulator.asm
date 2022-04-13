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
    A_REG:      resb    1
    D_REG:      resb    1
    X_REG:      resb    1
    Y_REG:      resb    1
    PC_REG:     resb    1
    unused:     resb    1
    C_FLAG:     resb    1
    Z_FLAG:     resb    1
    CODE_PTR:   resq    1

    alignb 4
    spin_lock:   resd 1

section .text

decode_arg1:

    ; decodes value of arg1 from [r11] to r8b
    ; arg1 is encoded in bits 9, 10, 11 of [r11] so we can take 3-th byte pf r11 and AND it with 0x7
    mov     r8b, byte [r11 + 1]
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

    ; decodes value of arg2 from [r11] to r9b
    ; arg2 is encoded in bits 12, 13, 14 of [r11] so we can shr r11 11 bites and AND it with 0x7
    mov     r9, [r11]
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

    xor     r9, r9  ; DEBUG 
    mov     r9b, al ; we only care about r9b value
    ret

decode_imm8:

    ; decodes value of imm8 from [r11] to r9b
    ; if is just firs bit of [r11] so we just move it into r9
    mov     r9, [r11]
    ret

encode_arg1:

    ; encodes value of arg1 from r8b to where it should go
    ; works similar as decode_arg1 but in reversed direction
    mov     al, byte [r11 + 1]
    and     al, 0x7

    push    r9 ; save and use r9 here
    xor     r9, r9

    lea     r10, [rel A_REG]
    cmp     al, byte [rel A_REG_CODE]
    je      .encoded_arg1_address

    lea     r10, [rel D_REG]
    cmp     al, byte [rel D_REG_CODE]
    je      .encoded_arg1_address

    lea     r10, [rel X_REG]
    cmp     al, byte [rel X_REG_CODE]
    je      .encoded_arg1_address

    lea     r10, [rel Y_REG]
    cmp     al, byte [rel Y_REG_CODE]
    je      .encoded_arg1_address

    mov     r9b,  byte [rel X_REG]
    lea     r10, [rsi + r9]
    cmp     al, byte [rel X_MEM_CODE]
    je      .encoded_arg1_address

    mov     r9b,  byte [rel Y_REG]
    lea     r10, [rsi + r9]
    cmp     al, byte [rel Y_MEM_CODE]
    je      .encoded_arg1_address

    mov     r9b,  byte [rel X_REG]
    add     r9b,  byte [rel D_REG]
    lea     r10, [rsi + r9]
    cmp     al, byte [rel XpD_MEM_CODE]
    je      .encoded_arg1_address

    mov     r9b,  byte [rel Y_REG]
    add     r9b,  byte [rel D_REG]
    lea     r10, [rsi + r9]
    cmp     al, byte [rel YpD_MEM_CODE]
    je      .encoded_arg1_address

    .encoded_arg1_address:

    mov     [r10], r8b
    pop     r9      ; restore r9
    ret

encode_arg2:

    ; encodes value of arg2 from r9b to where it should go
    ; works similar as decode_arg1 but in reversed direction
    mov     rax, [r11]
    shr     rax, 11
    and     al, 0x7

    push    r8 ; save and use r8 here
    xor     r8, r8

    lea     r10, [rel A_REG]
    cmp     al, byte [rel A_REG_CODE]
    je      .encoded_arg2_address

    lea     r10, [rel D_REG]
    cmp     al, byte [rel D_REG_CODE]
    je      .encoded_arg2_address

    lea     r10, [rel X_REG]
    cmp     al, byte [rel X_REG_CODE]
    je      .encoded_arg2_address

    lea     r10, [rel Y_REG]
    cmp     al, byte [rel Y_REG_CODE]
    je      .encoded_arg2_address

    mov     r8b,  byte [rel X_REG]
    lea     r10, [rsi + r8]
    cmp     al, byte [rel X_MEM_CODE]
    je      .encoded_arg2_address

    mov     r8b,  byte [rel Y_REG]
    lea     r10, [rsi + r8]
    cmp     al, byte [rel Y_MEM_CODE]
    je      .encoded_arg2_address

    mov     r8b,  byte [rel X_REG]
    add     r8b,  byte [rel D_REG]
    lea     r10, [rsi + r8]
    cmp     al, byte [rel XpD_MEM_CODE]
    je      .encoded_arg2_address

    mov     r8b,  byte [rel Y_REG]
    add     r8b,  byte [rel D_REG]
    lea     r10, [rsi + r8]
    cmp     al, byte [rel YpD_MEM_CODE]
    je      .encoded_arg2_address

    .encoded_arg2_address:

    mov     [r10], r9b
    pop     r8      ; restore r8
    ret

set_c_flag:
    mov     byte [rel C_FLAG], 0
    jnc     .do_not_set_c_to_one
    mov     byte [rel C_FLAG], 1 ; equal
    .do_not_set_c_to_one:
    ret

set_z_flag:
    mov     byte [rel Z_FLAG], 0
    jnz     .do_not_set_z_to_one
    mov     byte [rel Z_FLAG], 1
    .do_not_set_z_to_one:
    ret

so_emul:

    ; uint16_t const *code, uint8_t *data, size_t steps, size_t core
    ; rdi - code pointer, rsi - data pointer, rdx - steps, rcx - cores

    push    rbp    
    mov     rbp, rsp

    ; if CODE_PTR is not 0, we load code pointer from it, because it it shared across function executions
    ; if not, it must be first function call, so we take code pointer from rdi
    ; at the end of function, we save rdi (code pointer) to CODE_PTR
    ; we use r11 as current code pointer register
    ; mov     r11, qword [rel CODE_PTR]
    ; cmp     r11, 0
    ; cmovz   r11, rdi
    xor r11, r11
    add r11w, [rel PC_REG]
    imul r11w, 2
    add r11, rdi
    ; mov r11, rdi

    .emul_step:

        test    rdx, rdx    ; check if number of steps to perform is greater than zero
        jz      .steps_end 

        ; we have actions taking different types of argument and we have to detect them    

        ; detect jumps
        ; this can be done by shifting right 12 bits and checking if it is equal to 1100 (C??? - hex before shift) 
        mov     ax, [r11]                
        shr     ax, 12
        cmp     ax, [rel DETECT_JUMP]
        je     .switch_imm8        ; jump if equal

        ; detect no args operation
        ; its numbers are greater or equal to 0x8000 and different than jumps
        mov     ax, [r11]
        cmp     ax, [rel DETECT_NO_ARGS]
        jae     .switch_no_param    ; jump if greater or equal

        ; detect arg + imm8 operation
        ; its numbers are greater or equal to 0x4000 and different than jumps and no args
        mov     ax, [r11]
        cmp     ax, [rel DETECT_ARG_IMM]
        jae     .switch_arg_imm8    ; jump if greater or equal

        ; if none from above, than must be arg1 arg2 operation
        jmp     .switch_arg1_arg2 

        .switch_arg1_arg2:

            ; might be atomic
            cmp     byte [r11], 0x0008
            je      .xchg_arg1_arg2
            
            call    decode_arg1     ; stores it in r8b
            call    decode_arg2     ; stores it in r9b

            ; detect and perform arg1 arg2 actions
            cmp     byte [r11], 0x0000
            je      .mov_arg1_arg2

            cmp     byte [r11], 0x0002
            je      .or_arg1_arg2

            cmp     byte [r11], 0x0004
            je      .add_arg1_arg2

            cmp     byte [r11], 0x0005
            je      .sub_arg1_arg2

            cmp     byte [r11], 0x0006
            je      .adc_arg1_arg2

            cmp     byte [r11], 0x0007
            je      .sbb_arg1_arg2

            ; -- not documented instructions --

            cmp     byte [r11], 0x0001
            je      .and_arg1_arg2

            cmp     byte [r11], 0x0003
            je      .xor_arg1_arg2

            .xchg_arg1_arg2:

                mov     eax, 1
                .busy_wait:
                    lock xchg    [rel spin_lock], eax
                    test    eax, eax
                    jnz     .busy_wait

                call    decode_arg1     ; stores it in r8b
                call    decode_arg2

                xchg    r8b, r9b
                call    encode_arg1
                call    encode_arg2

                mov     eax, 0
                mov     [rel spin_lock], eax

                jmp     .switch_end

            .mov_arg1_arg2:

                mov     r8b, r9b
                call    encode_arg1
                jmp     .switch_end
            
            .or_arg1_arg2:

                or      r8b, r9b
                call    set_z_flag
                call    encode_arg1
                jmp     .switch_end

            .add_arg1_arg2:

                add     r8b, r9b
                call    set_z_flag
                call    encode_arg1
                jmp     .switch_end

            .sub_arg1_arg2:

                sub     r8b, r9b
                call    set_z_flag
                call    encode_arg1
                jmp     .switch_end

            .adc_arg1_arg2:

                xor     al, al    
                cmp     al, [rel C_FLAG]        ; set CF flag to what is in C_FLAG
                adc     r8b, r9b
                lahf                            ; because setting modifies flags
                call    set_c_flag
                sahf
                call    set_z_flag
                call    encode_arg1   
                jmp     .switch_end

            .sbb_arg1_arg2:

                xor     al, al    
                cmp     al, [rel C_FLAG]        ; set CF flag to what is in C_FLAG
                sbb     r8b, r9b
                lahf                            ; because setting modifies flags
                call    set_c_flag
                sahf
                call    set_z_flag
                call    encode_arg1
                jmp     .switch_end

            .and_arg1_arg2:

                and     r8b, r9b
                call    set_z_flag
                call    encode_arg1
                jmp     .switch_end

            .xor_arg1_arg2:

                xor     r8b, r9b
                call    set_z_flag
                call    encode_arg1
                jmp     .switch_end

        .switch_arg_imm8:

            call    decode_arg1     ; stores it in r8b
            call    decode_imm8     ; stores it in r9b

            mov     ax, [r11]
            and     ax, 0x7800      ; because we only care about 12, 13, 14,15 bits

            cmp     ax, 0x4000
            je      .movi_arg1_imm8

            cmp     ax, 0x5800
            je      .xori_arg1_imm8

            cmp     ax, 0x6000
            je      .addi_arg1_imm8

            cmp     ax, 0x6800
            je      .cmpi_arg1_imm8

            cmp     ax, 0x7000          ; RCRI also goes here
            je      .rcr_arg1_imm8

            cmp     ax, 0x4800
            je      .andi_arg1_imm8

            cmp     ax, 0x5000
            je      .ori_arg1_arg2

            .movi_arg1_imm8:

                mov     r8b, r9b 
                call    encode_arg1
                jmp     .switch_end

            .xori_arg1_imm8:

                xor     r8b, r9b
                call    set_z_flag
                call    encode_arg1
                jmp     .switch_end

            .addi_arg1_imm8:

                add     r8b, r9b
                call    set_z_flag
                call    encode_arg1
                jmp     .switch_end

            .cmpi_arg1_imm8:

                sub     r8b, r9b
                lahf
                call    set_c_flag
                sahf
                call    set_z_flag
                jmp     .switch_end

            .rcr_arg1_imm8:

                push    rcx
                mov     cl, r9b
                mov     al, 0
                cmp     al, byte [rel C_FLAG]   ; set CF flag as C_FLAG
                rcr     r8b, cl
                pop     rcx
                call    set_c_flag
                call    encode_arg1
                jmp     .switch_end

            .andi_arg1_imm8:

                and     r8b, r9b
                call    set_z_flag
                call    encode_arg1 
                jmp     .switch_end

            .ori_arg1_arg2:

                or      r8b, r9b
                call    set_z_flag
                call    encode_arg1               
                jmp     .switch_end

        .switch_no_param:

            cmp     word [r11], 0x8000
            je     .clc_no_param

            cmp     word [r11], 0x8100
            je     .stc_no_param

            cmp     word [r11], 0xFFFF
            je     .brk_no_param

            .clc_no_param:

                clc
                call    set_c_flag
                jmp     .switch_end

            .stc_no_param:

                stc
                call    set_c_flag
                jmp     .switch_end

            .brk_no_param:

                mov     rdx, 1          
                jmp     .switch_end     


        .switch_imm8:

            call decode_imm8

            mov     ax, [r11] 
            and     ax, 0xFF00 ; we only care about 3-th and 4-th byte

            cmp     ax, 0xC000 
            je      .jmp_imm8

            cmp     ax, 0xC200
            je      .jnc_imm8

            cmp     ax, 0xC300
            je      .jc_imm8

            cmp     ax, 0xC400
            je      .jnz_imm8

            cmp     ax, 0xC500
            je      .jz_imm8

            cmp     ax, 0xC100
            je      .djnz_imm8

            .jmp_imm8:

                ; xor     rax, rax
                mov     al, r9b
                add     [rel PC_REG], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .switch_end

            .jnc_imm8:
                
                mov     al, [rel C_FLAG]
                cmp     al, 1
                je      .switch_end

                ; xor     rax, rax
                mov     al, r9b
                add     [rel PC_REG], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .switch_end

            .jc_imm8:

                mov     al, [rel C_FLAG]
                cmp     al, 0
                je      .switch_end

                xor     rax, rax
                mov     al, r9b
                add     [rel PC_REG], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .switch_end

            .jnz_imm8:

                mov     al, [rel Z_FLAG]
                cmp     al, 1
                je      .switch_end

                xor     rax, rax
                mov     al, r9b
                add     [rel PC_REG], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .switch_end

            .jz_imm8:

                mov     al, [rel Z_FLAG]
                cmp     al, 0
                je      .switch_end

                xor     rax, rax
                mov     al, r9b
                add     [rel PC_REG], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .switch_end

            .djnz_imm8:

                mov     al, [rel D_REG]
                cmp     al, 0
                je      .switch_end

                sub     byte [rel D_REG], 1
                xor     rax, rax
                mov     al, r9b
                add     [rel PC_REG], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .switch_end

        .switch_end:

        add     byte [rel PC_REG], 1    ; increment total steps count
        dec     rdx                     ; decrement steps to execute count
        add     r11, 2                  ; increment code pointer by two because it points to int16
        jmp     .emul_step              ; jump to next step loop

    .steps_end:

    ; save code pointer
    mov     [rel CODE_PTR], r11

    leave
    mov     rax, qword [rel A_REG]  ; saves so cpu state 
    ret