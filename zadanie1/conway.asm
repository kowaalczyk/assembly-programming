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
    push r12
    push r13
    push r14
    push r15

; body - arguments: rdi - number of steps to run
    mov rsi, [width]        ; rsi = width
    mov r12, [height]       ; r12 = height
    mov rcx, rdi            ; counter for loop instruction
.step:

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

            .left:
                cmp r11, 0
                je .top ; address before first row

                mov r8b, byte [rdx - 1] ; previous col, same row
                and r8b, 15
                add rdi, r8

            .top:
                cmp r10, 0
                je .right ; address before first row

                mov rax, rdx
                sub rax, rsi
                mov r8b, byte [rax] ; same col, previous row
                and r8b, 15
                add rdi, r8

            .right:
                lea r9, [r11 + 1]
                cmp r9, rsi
                je .bottom ; address after last column (rsi == width)

                mov r8b, byte [rdx + 1] ; next col, same row
                and r8b, 15
                add rdi, r8

            .bottom:
                lea r9, [r10 + 1]
                cmp r9, r12
                je .update ; address after last row (r12 == height)

                mov rax, rdx
                add rax, rsi
                mov r8b, byte [rax] ; same col, next row
                and r8b, 15
                add rdi, r8

            .update:
                ; current cell: if (count == 3) then [01|XX] else [00|XX]
                cmp rdi, 3
                jne .complete_loop

                ; TODO: try movc later to see if it improves speed (1 less jump)
                mov r8b, byte [rdx] ; r8 = [0000|000X]
                or r8b, 16   ; r8 = [0001|000X]
                mov byte [rdx], r8b

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
    lea rax, [rdx + rax]    ; rax = 1 cell after last field
    .refresh:
        dec rax
        mov r8b, byte [rax]
        shr r8b, 4          ; refresh: cell = [01|XX] -> cell = [00|01]
        mov byte [rax], r8b

        cmp rax, rdx        ; check if rax reached the first field
        jne .refresh

    dec rcx
    cmp rcx, 0
    jne .step
    ; loop .step         ; equiv to: dec rcx; cmp rcx 0; jne .step TODO: figure out if loop is possible here

; epilogue
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
