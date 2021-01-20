; Implementation of Conway's Game of Life
; See conwaymain.c or conwaytest.c driver programs for examples of usage.
;
; (c) Krzysztof Kowalczyk 2020 kk385830@students.mimuw.edu.pl

section .bss
    width: resb 8   ; int (can be 64bit on a 64bit system)
    height: resb 8  ; int
    fields: resb 8  ; char*

section .text

global start
global run

start:
; prologue
    push rbp
    mov rbp, rsp

; body - arguments: rdi - width, rsi - height, rdx - fields
    mov [width], rdi
    mov [height], rsi
    mov [fields], rdx

; epilogue
    pop rbp
    ret

run:
; prologue
    push rbp
    mov rbp, rsp
    push r12        ; used for temporary variable, but has to be preserved

; body - arguments: rdi - number of steps to run
    mov rsi, [width]        ; rsi = width
    mov r12, [height]       ; r12 = height

    ; edge case: 0 steps
    cmp rdi, 0
    je .epilogue

    mov rcx, rdi            ; counter for the main loop
.step:
    ; edge case: empty game
    cmp rsi, 0
    je .count_step
    cmp r12, 0
    je .count_step

    ; start actual loop
    xor r10, r10            ; r10 = row index
    .set_row:               ; row loop

        xor r11, r11        ; r11 = column index
        .set_col:           ; column loop
            xor rdi, rdi    ; rdi = count of neighbours
            xor r8, r8      ; r8 = value of current neighbour cell

            mov rax, rsi
            mul r10                 ; [rdx|rax] = first cell in the current row
            add rax, r11            ; rax = index of current cell

            mov rdx, [fields]       ; rdx = pointer to first field
            add rdx, rax            ; rdx = pointer to the current cell

            .above:
                cmp r10, 0
                je .current ; first row, no top neighbours

                mov rax, rdx
                sub rax, rsi
                dec rax ; rax = top left neighbour

                .aboveleft:
                    cmp r11, 0
                    je .abovemiddle ; first column, no top left neighbour

                    mov r8b, byte [rax]
                    and r8b, 15 ; only count the 4 rightmost bits
                    add rdi, r8

                .abovemiddle:
                    inc rax ; if we're here, middle top neighbour has to exist
                    mov r8b, byte [rax]
                    and r8b, 15
                    add rdi, r8

                .aboveright:
                    lea r9, [r11 + 1]
                    cmp r9, rsi
                    je .current ; last column, no top right neighbour

                    inc rax
                    mov r8b, byte [rax]
                    and r8b, 15
                    add rdi, r8

            .current:
                .currentleft:
                    cmp r11, 0
                    je .currentright ; first column, skip left neighbour

                    lea rax, [rdx - 1]
                    mov r8b, byte [rax]
                    and r8b, 15
                    add rdi, r8

                .currentright:
                    lea r9, [r11 + 1]
                    cmp r9, rsi
                    je .below ; last column, skip right neighbour

                    lea rax, [rdx + 1]
                    mov r8b, byte [rax]
                    and r8b, 15
                    add rdi, r8

            .below:
                lea r9, [r10 + 1]
                cmp r9, r12
                je .update ; address after last row (r12 == height)

                mov rax, rdx
                add rax, rsi
                dec rax ; rax = bottom left neighbour

                .belowleft:
                    cmp r11, 0
                    je .belowmiddle

                    mov r8b, byte [rax]
                    and r8b, 15
                    add rdi, r8

                .belowmiddle:
                    inc rax
                    mov r8b, byte [rax]
                    and r8b, 15
                    add rdi, r8

                .belowright:
                    lea r9, [r11 + 1]
                    cmp r9, rsi
                    je .update

                    inc rax
                    mov r8b, byte [rax]
                    and r8b, 15
                    add rdi, r8

            .update:
                mov r8b, byte [rdx] ; r8 = [0000|000X]

                cmp rdi, 3
                je .set_live ; any cell that has 3 neighbours

                add rdi, r8
                cmp rdi, 3
                je .set_live ; live cell that has 2 neighbours

                ; cell dies: has <2 or >=4 neighbours, or 2 neighbours and is dead
                jmp .complete_loop

                .set_live:
                    or r8b, 16   ; r8 = [0001|000X]
                    mov byte[rdx], r8b
                    ; TODO: consider using CMOV instruction for speed

            .complete_loop: ; complete column loop
            inc r11
            cmp r11, rsi ; r11 == rsi <==> reached last column (rsi == width)
            jne .set_col

        ; complete row loop
        inc r10
        cmp r10, r12 ; reached last row (r12 == height)
        jne .set_row

    mov rax, r12            ; height
    mul rsi                 ; [rdx|rax] = rsi * rax = width * height
    mov rdx, [fields]
    lea rax, [rdx + rax]    ; rax = 1 cell after last field
    .refresh:
        dec rax
        mov r8b, byte [rax]
        shr r8b, 4          ; refresh: cell = [01|XX] -> cell = [00|01]
        mov byte [rax], r8b

        cmp rax, rdx        ; check if rax reached the first field
        jne .refresh

    .count_step:
        dec rcx
        cmp rcx, 0
        jne .step
        ; loop .step         ; equiv to: dec rcx; cmp rcx 0; jne .step TODO: figure out if loop is possible here

.epilogue:
    pop r12
    pop rbp
    ret
