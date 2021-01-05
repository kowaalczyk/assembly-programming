; (c) Krzysztof Kowalczyk 2020 kk385830@students.mimuw.edu.pl

FLOAT_BYTES equ 4  ; float is 32bit (at least on students server)
INT_BYTES equ 8   ; int (can be 64bit on a 64bit system)
PTR_BYTES equ 8

section .bss
    width: resb INT_BYTES
    height: resb INT_BYTES
    M: resb PTR_BYTES ; main matrix
    MT: resb PTR_BYTES ; temporary matrix
    weight: resb FLOAT_BYTES

section .text

global start
global step


start:
; prologue
    push rbp
    mov rbp, rsp

; body - arguments - rdi: int width, rsi: int height, rdx: float* M, xmm0: float weight
    mov [width], rdi
    mov [height], rsi
    mov [M], rdx
    movd [weight], xmm0

    imul rdi, rsi  ; rdi := number of elements in the main matrix (M)
    lea rdi, [rdx + rdi*FLOAT_BYTES]  ; rdi := address of temporary matrix MT
    mov [MT], rdi

; epilogue
    pop rbp
    ret


step:
; prologue
    push rbp
    mov rbp, rsp

; body - arguments - rdi: float* T
    movd xmm0, [weight]
    shufps xmm0, xmm0, 00h  ; xmm0 := [weight, weight, weight, weight]

; sets (left column) x (weight) as the delta for current column
    mov r11, [M] ; r11 := start of column 0 in M
    mov rsi, [MT]
    mov rcx, [height]
    lea rsi, [rsi + FLOAT_BYTES*rcx] ; rsi := start of column 1 in MT
    mov r9, [width]  ; r9 - width for controlling outer loop
    dec r9 ; column 0  is an edge case, handled below
.setdelta_left_coln_nextrows:
    sub rcx, 4 ; RANGE TEST
    lea rdx, [rsi + FLOAT_BYTES*rcx]  ; rdx := &current_col[rcx]
    lea r8, [r11 + FLOAT_BYTES*rcx]  ; r8 := &left_col[rcx]
    movaps xmm1, [r8]  ; xmm1 := current_col[rcx:rcx+4]
    mulps xmm1, xmm0 ; xmm1 := weight * current_col[rcx:rcx+4]
    movaps [rdx], xmm1  ; &current_col[rcx:rcx+4] := weight * left_col[rcx:rcx+4]
    test rcx, rcx
    jne .setdelta_left_coln_nextrows  ; process next batch of rows in the same column
    ; reset position to start of next column:
    mov rcx, [height]  ; rcx - inner loop counter (row in column)
    lea rsi, [rsi + FLOAT_BYTES*rcx]  ; rsi - beginning of current column in MT
    lea r11, [r11 + FLOAT_BYTES*rcx]  ; r11 - begginning of left column in M
    dec r9
    test r9, r9
    jne .setdelta_left_coln_nextrows  ; process next column

; sets (T) x (weight) to the delta for column 0
    mov r11, [M]
    mov rsi, [MT]
    mov rcx, [height]  ; rcx - inner loop counter (row in column)
.setdelta_left_col0_nextrows:
    sub rcx, 4 ; RANGE TEST
    lea rdx, [rsi + FLOAT_BYTES*rcx]  ; rdx := &MT[rcx]
    lea r8, [rdi + FLOAT_BYTES*rcx]  ; r8 := &T[rcx]
    movaps xmm1, [r8]  ; xmm1 := T[rcx:rcx+4]
    mulps xmm1, xmm0 ; xmm1 := weight * T[rcx:rcx+4]
    movaps [rdx], xmm1  ; &MT[rcx:rcx+4] := weight * T[rcx:rcx+4]
    test rcx, rcx  ; set ZF=1 if rcx==0
    jne .setdelta_left_col0_nextrows  ; continue loop if rcx!=0 (ZF==0)

; apply deltas calculated in MT to M
    mov rcx, [height]  ; rcx - inner loop counter (row in column)
    mov r9, [width]  ; r9 - width for controlling outer loop
    imul rcx, r9  ; rcx := height x width
.applydelta_nextbatch:
    sub rcx, 4 ; RANGE TEST
    lea rdx, [rsi + FLOAT_BYTES*rcx]  ; &MT[rcx]
    lea r8, [r11 + FLOAT_BYTES*rcx]  ; &M[rcx]
    movaps xmm0, [rdx]  ; xmm0 := MT[rcx:rcx+4]
    movaps xmm1, [r8]  ; xmm1 := M[rcx:rcx+4]
    addps xmm1, xmm0  ; xmm1 := MT[rcx:rcx+4] + M[rcx:rcx+4]
    movaps [r8], xmm1  ; &M[rcx:rcx+4] := MT[rcx:rcx+4] + M[rcx:rcx+4]
    test rcx, rcx
    jne .applydelta_nextbatch


; epilogue
    pop rbp
    ret
