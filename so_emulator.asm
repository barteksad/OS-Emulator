global so_emul

%ifndef CORES
%define CORES 1
%endif

section .data

    align 4
    spin_lock   dd 0

section .bss

    align 8
    REGS        resq CORES

section .text

decode_arg1:

    ; decodes value of arg1 from [r11] to r8b
    ; arg1 is encoded in bits 9, 10, 11 of [r11] so we can take 3-th byte pf r11 and AND it with 0x7
    mov     r8b, byte [r11 + 1]
    and     r8b, 0x7

    ; use rax for temporary lea source
    xor     rax, rax

    mov     al,  byte [r12 + 8 * rcx + 0]
    cmp     r8b, 0 ; A register
    je      .decoded_arg1

    mov     al,  byte [r12 + 8 * rcx + 1]
    cmp     r8b, 1 ; D register
    je      .decoded_arg1

    mov     al,  byte [r12 + 8 * rcx + 2]
    cmp     r8b, 2 ; X register
    je      .decoded_arg1

    mov     al,  byte [r12 + 8 * rcx + 3]
    cmp     r8b, 3 ; Y register
    je      .decoded_arg1

    mov     al,  byte [r12 + 8 * rcx + 2]
    mov     al,  byte [rsi + rax]
    cmp     r8b, 4 ; memory [X]
    je      .decoded_arg1

    mov     al,  byte [r12 + 8 * rcx + 3]
    mov     al,  byte [rsi + rax]
    cmp     r8b, 5 ; memory [X]
    je      .decoded_arg1

    mov     al,  byte [r12 + 8 * rcx + 2]
    add     al,  byte [r12 + 8 * rcx + 1]
    mov     al,  byte [rsi + rax]
    cmp     r8b, 6 ; memory [X + D]
    je      .decoded_arg1

    mov     al,  byte [r12 + 8 * rcx + 3]
    add     al,  byte [r12 + 8 * rcx + 1]
    mov     al,  byte [rsi + rax]
    cmp     r8b, 7 ; memory [Y + D]
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

    mov     al,  byte [r12 + 8 * rcx + 0]
    cmp     r9b, 0 ; A register
    je      .decoded_arg2

    mov     al,  byte [r12 + 8 * rcx + 1]
    cmp     r9b, 1 ; D register
    je      .decoded_arg2

    mov     al,  byte [r12 + 8 * rcx + 2]
    cmp     r9b, 2 ; X register
    je      .decoded_arg2

    mov     al,  byte [r12 + 8 * rcx + 3]
    cmp     r9b, 3 ; Y register
    je      .decoded_arg2

    mov     al,  byte [r12 + 8 * rcx + 2]
    mov     al,  byte [rsi + rax]
    cmp     r9b, 4 ; memory [X]
    je      .decoded_arg2

    mov     al,  byte [r12 + 8 * rcx + 3]
    mov     al,  byte [rsi + rax]
    cmp     r9b, 5 ; memory [Y]
    je      .decoded_arg2

    mov     al,  byte [r12 + 8 * rcx + 2]
    add     al,  byte [r12 + 8 * rcx + 1]
    mov     al,  byte [rsi + rax]
    cmp     r9b, 6 ; memory [X + D]
    je      .decoded_arg2

    mov     al,  byte [r12 + 8 * rcx + 3]
    add     al,  byte [r12 + 8 * rcx + 1]
    mov     al,  byte [rsi + rax]
    cmp     r9b, 7 ; memory [Y + D]
    je      .decoded_arg2

    .decoded_arg2:

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

    lea     r10, [r12 + 8 * rcx + 0]
    cmp     al, 0 ; A register
    je      .encoded_arg1_address

    lea     r10, [r12 + 8 * rcx + 1]
    cmp     al, 1 ; D register
    je      .encoded_arg1_address

    lea     r10, [r12 + 8 * rcx + 2]
    cmp     al, 2 ; X register
    je      .encoded_arg1_address

    lea     r10, [r12 + 8 * rcx + 3]
    cmp     al, 3 ; Y register
    je      .encoded_arg1_address

    mov     r9b,  byte [r12 + 8 * rcx + 2]
    lea     r10, [rsi + r9]
    cmp     al, 4 ; memory [X]
    je      .encoded_arg1_address

    mov     r9b,  byte [r12 + 8 * rcx + 3]
    lea     r10, [rsi + r9]
    cmp     al, 5 ; memory [Y]
    je      .encoded_arg1_address

    mov     r9b,  byte [r12 + 8 * rcx + 2]
    add     r9b,  byte [r12 + 8 * rcx + 1]
    lea     r10, [rsi + r9]
    cmp     al, 6 ; memory [X + D]
    je      .encoded_arg1_address

    mov     r9b,  byte [r12 + 8 * rcx + 3]
    add     r9b,  byte [r12 + 8 * rcx + 1]
    lea     r10, [rsi + r9]
    cmp     al, 7 ; memory [Y + D]
    je      .encoded_arg1_address

    .encoded_arg1_address:

    mov     [r10], r8b
    pop     r9      ; restore r9
    ret

encode_arg2_address:

    ; encodes address of arg2 from r11 to r10
    ; only used in xchg
    mov     rax, [r11]
    shr     rax, 11
    and     al, 0x7

    push    r8 ; save and use r8 here
    xor     r8, r8

    lea     r10, [r12 + 8 * rcx + 0]
    cmp     al, 0 ; A register
    je      .encoded_arg2_address

    lea     r10, [r12 + 8 * rcx + 1]
    cmp     al, 1 ; D register
    je      .encoded_arg2_address

    lea     r10, [r12 + 8 * rcx + 2]
    cmp     al, 2 ; X register
    je      .encoded_arg2_address

    lea     r10, [r12 + 8 * rcx + 3]
    cmp     al, 3 ; Y register
    je      .encoded_arg2_address

    mov     r8b,  byte [r12 + 8 * rcx + 2]
    lea     r10, [rsi + r8]
    cmp     al, 4 ; memory [X]
    je      .encoded_arg2_address

    mov     r8b,  byte [r12 + 8 * rcx + 3]
    lea     r10,  [rsi + r8]
    cmp     al,  5 ; memory [Y]
    je      .encoded_arg2_address

    mov     r8b,  byte [r12 + 8 * rcx + 2]
    add     r8b,  byte [r12 + 8 * rcx + 1]
    lea     r10,  [rsi + r8]
    cmp     al,  6 ; memory [X + D]
    je      .encoded_arg2_address

    mov     r8b,  byte [r12 + 8 * rcx + 3]
    add     r8b,  byte [r12 + 8 * rcx + 1]
    lea     r10, [rsi + r8]
    cmp     al, 7 ; memory [Y + D]
    je      .encoded_arg2_address

    .encoded_arg2_address:

    pop     r8      ; restore r8
    ret

set_c_flag:
    mov     byte [r12 + 8 * rcx + 6], 0
    jnc     .do_not_set_c_to_one
    mov     byte [r12 + 8 * rcx + 6], 1 ; equal
    .do_not_set_c_to_one:
    ret

set_z_flag:
    mov     byte [r12 + 8 * rcx + 7], 0
    jnz     .do_not_set_z_to_one
    mov     byte [r12 + 8 * rcx + 7], 1
    .do_not_set_z_to_one:
    ret


align 8
so_emul:

    ; uint16_t const *code, uint8_t *data, size_t steps, size_t core
    ; rdi - code pointer, rsi - data pointer, rdx - steps, rcx - REGS

    push    r12
    push    rbp    
    mov     rbp, rsp

    lea     r12, [rel REGS]


    xor r11, r11
    add r11b, byte [r12 + 8 * rcx + 4]
    imul r11w, 2
    add r11, rdi

    .emul_step:

        test    rdx, rdx    ; check if number of steps to perform is greater than zero
        jz      .steps_end 

        ; acquire lock 
        lea     r8, [rel spin_lock]
        mov     r9d, 1
        .busy_wait:
            xor     eax, eax
            lock \
            cmpxchg [r8], r9d
            jne     .busy_wait


        ; we have actions taking different types of argument and we have to detect them    

        ; detect jumps
        ; this can be done by shifting right 12 bits and checking if it is equal to 1100 (C??? - hex before shift) 
        mov     ax, [r11]                
        shr     ax, 12
        cmp     ax, 0xC
        je     .switch_imm8        ; jump if equal

        ; detect no args operation
        ; its numbers are greater or equal to 0x8000 and different than jumps
        mov     ax, [r11]
        cmp     ax, 0x8000
        jae     .switch_no_param    ; jump if greater or equal

        ; detect arg + imm8 operation
        ; its numbers are greater or equal to 0x4000 and different than jumps and no args
        mov     ax, [r11]
        cmp     ax, 0x4000
        jae     .switch_arg_imm8    ; jump if greater or equal

        ; if none from above, than must be arg1 arg2 operation
        jmp     .switch_arg1_arg2 

        .switch_arg1_arg2:

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

            cmp     byte [r11], 0x0008
            je      .xchg_arg1_arg2

            .xchg_arg1_arg2:

                xchg    r8b, r9b
                call    encode_arg2_address
                push    r10
                call    encode_arg1
                pop     r10
                mov     [r10], r9b

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
                mov     r10b,  byte [r12 + 8 * rcx + 6]
                cmp     al, r10b  ; set CF flag as C_FLAG
                adc     r8b, r9b
                lahf              ; because setting modifies flags
                call    set_c_flag
                sahf
                call    set_z_flag
                call    encode_arg1   
                jmp     .switch_end

            .sbb_arg1_arg2:

                xor     al, al
                mov     r10b,  byte [r12 + 8 * rcx + 6]
                cmp     al, r10b  ; set CF flag as C_FLAG
                sbb     r8b, r9b
                lahf              ; because setting modifies flags
                call    set_c_flag
                sahf
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

            cmp     ax, 0x7000         
            je      .rcr_arg1_imm8

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
                xor     al, al
                mov     r10b,  byte [r12 + 8 * rcx + 6]
                cmp     al, r10b  ; set CF flag as C_FLAG
                mov     cl, 1
                rcr     r8b, cl
                pop     rcx
                call    set_c_flag
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

            .jmp_imm8:

                mov     al, r9b
                add     [r12 + 8 * rcx + 4], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .set_code_ptr_after_jump

            .jnc_imm8:
                
                mov     al, [r12 + 8 * rcx + 6]
                cmp     al, 1
                je      .switch_end

                mov     al, r9b
                add     [r12 + 8 * rcx + 4], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .set_code_ptr_after_jump

            .jc_imm8:

                mov     al, [r12 + 8 * rcx + 6]
                cmp     al, 0
                je      .switch_end

                xor     rax, rax
                mov     al, r9b
                add     [r12 + 8 * rcx + 4], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .set_code_ptr_after_jump

            .jnz_imm8:

                mov     al, [r12 + 8 * rcx + 7]
                cmp     al, 1
                je      .switch_end

                xor     rax, rax
                mov     al, r9b
                add     [r12 + 8 * rcx + 4], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .set_code_ptr_after_jump

            .jz_imm8:

                mov     al, [r12 + 8 * rcx + 7]
                cmp     al, 0
                je      .switch_end

                xor     rax, rax
                mov     al, r9b
                add     [r12 + 8 * rcx + 4], al
                movsx   rax, r9b
                imul    rax, 2
                add     r11, rax
                jmp     .set_code_ptr_after_jump

            .set_code_ptr_after_jump:

                xor     r11, r11
                add     r11b, byte [r12 + 8 * rcx + 4]
                imul    r11w, 2
                add     r11, rdi
                jmp     .switch_end

        .switch_end:

        xor     eax, eax
        lea     r8, [rel spin_lock]
        mov     [r8], eax

        add     byte [r12 + 8 * rcx + 4], 1    ; increment total steps count
        add     r11, 2                         ; increment code pointer by two because it points to int16
        mov     al, byte [r12 + 8 * rcx + 4]   ; check if overflow, and set to 0 if so
        cmp     al, 0
        jne     .do_not_set_PC_to_0
        mov     r11, rdi
        .do_not_set_PC_to_0:
        dec     rdx                            ; decrement steps to execute count

        jmp     .emul_step                     ; jump to next step loop

    .steps_end:

    leave
    mov     rax, qword [r12 + 8 * rcx]  ; saves so cpu state 
    pop     r12
    ret