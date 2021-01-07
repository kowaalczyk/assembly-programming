; (c) Krzysztof Kowalczyk 2020 kk385830@students.mimuw.edu.pl

FLOAT_BYTES equ 4 ; float is 32bit (on students and violet01)
INT_BYTES equ 4 ; int is 32bit (on students and violet01)
PTR_BYTES equ 8

PAD_TOP equ 5
PAD_COL equ 6 ; PADDING_TOP + PADDING_BOTTOM

ROWS_4 equ 5 ; PAD_TOP
ROWS_3 equ 4 ; PAD_TOP - 1
ROWS_2 equ 3 ; PAD_TOP - 2
ROWS_1 equ 2 ; PAD_TOP - 3
ROWS_0 equ 1 ; PAD_TOP - 4

section .bss
    width: resb INT_BYTES ; width of matrix M and matrix DELTA (wihtout padding)
    height: resb INT_BYTES ; height of matrix M aligned to multiple of 4 (wihtout padding)
    next_col_offset: resb PTR_BYTES ; offset in bytes between (row,col) and (row,col+1) in matrix M
    weight: resb FLOAT_BYTES ; weight for individual deltas
    TP: resb PTR_BYTES ; points to start of the placeholder for padded T value
    M: resb PTR_BYTES ; points to start of padding before M matrix
    DELTA: resb PTR_BYTES ; points to start of padding before temporary DELTA matrix

section .text

global start
global step


start:
; prologue
    push rbp
    mov rbp, rsp
; body - arguments - edi: int width, esi: int height, rdx: float* M, xmm0: float weight
    movd [weight], xmm0
    mov [width], edi
    mov [height], esi
    mov [TP], rdx
    ; calculate next_col_offset
    xor rcx, rcx
    lea ecx, [esi + PAD_COL]
    lea rcx, [0 + FLOAT_BYTES*rcx]
    mov [next_col_offset], rcx
    ; calculate start of M
    lea r8, [rdx + rcx]
    mov [M], r8
    ; calculate start of DELTA
    xor rax, rax
    mov eax, edi
    mul rcx
    lea r8, [r8 + rax]
    mov [DELTA], r8

; epilogue
    pop rbp
    ret


step:
; prologue
    push rbp
    mov rbp, rsp

    push r12
    push r13

; body - arguments - rdi: float* T
    ; load weights to memory
    xorps xmm0, xmm0
    movd xmm0, [weight]
    shufps xmm0, xmm0, 00h  ; xmm0 := [w,w,w,w]
    ; move T to first column in matrix for nicer vectorization
    ; if we could enforce users to load directly to that column, it could speed things up
    xor rcx, rcx
    mov ecx, [height]
    mov rsi, [TP]
    lea r8, [rsi + PAD_TOP*FLOAT_BYTES] ; r8 := first non-placeholder position in TP
.copy_next_batch:
    ; this is slightly faster than using rep movsd here (for the baseline and 1k benchmarks)
    dec rcx
    lea rdx, [rdi + FLOAT_BYTES*rcx]
    mov rdx, [rdx] ; load value from a row in T
    lea r9, [r8 + FLOAT_BYTES*rcx]
    mov [r9], rdx ; store in corresponding row of TP
    test rcx, rcx
    jne .copy_next_batch

    ; calculate deltas
    mov rsi, [TP]
    mov r9, [M]
    mov r10, [DELTA]
    xor r13, r13
    mov r13d, [height]
    add r13, PAD_TOP ; row size for resetting inner loop
    mov rcx, r13 ; row counter (inner loop)
    xor rax, rax
    mov eax, [width]
    mov r8, [next_col_offset]
    mov r12, 000000000ffffffffh ; first rows flag for the mask
.calculate_next_rows: ; rsi: left column (source), r9: current column (source), r10: current column (dest)
    sub rcx, 4
    ; set mask that affects weight application based on number of remaining rows:
    cmp rcx, ROWS_4
    jg .set_masks_standard
    cmp rcx, ROWS_3
    jg .set_masks_4
    cmp rcx, ROWS_2
    jg .set_masks_3
    cmp rcx, ROWS_1
    jg .set_masks_2
    cmp rcx, ROWS_0
    je .calculate_next_column ; 0 rows remaining - nothing left to do
    ; 1 row remaining:
    xorps xmm1, xmm1
    ror r12, 32
    and r12, 0ffffffff00000000h
    movq xmm1, r12 ; xmm1 = 0000 | 1000
    shufps xmm1, xmm1, 01Bh ; xmm1 = 0010 | 0011
    andps xmm1, xmm0 ; xmm1 := weighted mask+1
    xorps xmm2, xmm2
    mov r12, 000000000ffffffffh
    movq xmm2, r12 ; xmm2 := 1000
    shufps xmm2, xmm2, 01Bh ; xmm2 := 0001
    andps xmm2, xmm0 ; xmm2 := weighted mask0
    xorps xmm3, xmm3 ; xmm3 := weighted mask-1
    jmp .calculate_deltas
.set_masks_2: ; 2 rows remaining:
    xorps xmm1, xmm1
    ror r12, 32
    movq xmm1, r12 ; xmm1 = 0100 | 1100
    shufps xmm1, xmm1, 01Bh ; xmm1 = 0010 | 0011
    andps xmm1, xmm0 ; xmm1 := weighted mask+1
    mov r12, 0ffffffffffffffffh
    xorps xmm2, xmm2
    movq xmm2, r12 ; xmm2 := 1100
    shufps xmm2, xmm2, 01Bh ; xmm2 := 0011
    andps xmm2, xmm0 ; xmm2 := weighted mask0
    mov r12, 0000000000ffffffffh
    xorps xmm3, xmm3
    movq xmm3, r12 ; r12 := 1000
    shufps xmm3, xmm3, 01Bh ; xmm3 := 0001
    andps xmm3, xmm0 ; xmm3 := weighted mask-1
    jmp .calculate_deltas
.set_masks_3: ; 3 rows remaining:
    xorps xmm2, xmm2
    movq xmm2, r12
    mov r12, 0ffffffff00000000h ; TODO: test if this is actually faster than reading from memory
    xorps xmm1, xmm1
    movq xmm1, r12
    unpcklps xmm1, xmm2
    movaps xmm2, xmm1 ; F0 used below
    andps xmm1, xmm0 ; xmm1 := weighted mask+1
    cmpeqps xmm3, xmm3 ; xmm3 := 1111
    unpcklps xmm2, xmm3
    andps xmm2, xmm0 ; xmm2 := weighted mask0
    shufps xmm3, xmm3, 01Bh ; reverse order of floats (FF00 -> 00FF)
    andps xmm3, xmm0 ; xmm3 := weighted mask -1
    jmp .calculate_deltas
.set_masks_4:
    xorps xmm2, xmm2
    movq xmm2, r12
    cmpeqps xmm1, xmm1 ; xmm1 := 1111
    unpcklps xmm1, xmm2
    movaps xmm4, xmm1 ; xmm4 used below
    andps xmm1, xmm0 ; xmm1 := weighted mask+1
    movaps xmm2, xmm0 ; xmm2 := weighted mask0
    mov r12, 0ffffffff00000000h
    xorps xmm3, xmm3
    movq xmm3, r12
    unpcklps xmm3, xmm4
    andps xmm3, xmm0 ; xmm3 := weighted mask-1
    jmp .calculate_deltas
.set_masks_standard: ; >4 rows remaining, processing the next 4 rows only:
    xorps xmm2, xmm2
    movq xmm2, r12 ; xmm2 :=
    cmpeqps xmm1, xmm1 ; xmm1 := 1111
    unpcklps xmm1, xmm2
    andps xmm1, xmm0 ; xmm1 := weighted mask+1
    movaps xmm2, xmm0 ; xmm2 := weighted mask0
    movaps xmm3, xmm0 ; xmm3 := weighted mask-1
.calculate_deltas: ; xmm1: weighted mask0, xmm2: weighted mask+1, xmm3: weighted mask-1
    ; copy current values to xmm4 (for delta calculation) and xmm5 (where result will be stored):
    lea r11, [r9 + FLOAT_BYTES*rcx]
    movups xmm4, [r11] ; xmm4 := current rows in current col (src) ; TODO: align and use movaps
    movaps xmm5, xmm4
    ; left delta:
    lea r11, [rsi + FLOAT_BYTES*rcx]
    movups xmm6, [r11] ; xmm6 := current rows in left col (src) ; TODO: align and use movaps
    subps xmm6, xmm4
    mulps xmm6, xmm2 ; xmm6 := (current rows in left col - current rows in current col) * weight * mask0
    addps xmm5, xmm6 ; new value += left delta
    ; bottom left delta:
    lea r11, [rsi + FLOAT_BYTES*rcx]
    add r11, FLOAT_BYTES ; offset +1
    movups xmm6, [r11] ; xmm6 := rows+1 in left col (src)
    subps xmm6, xmm4
    mulps xmm6, xmm1 ; xmm6 := (rows+1 in left col - current rows in current col) * weight * mask+1
    addps xmm5, xmm6 ; new value += top left delta
    ; bottom delta:
    lea r11, [r9 + FLOAT_BYTES*rcx]
    add r11, FLOAT_BYTES ; offset +1
    movups xmm6, [r11] ; xmm6 := rows+1 in current col (src)
    subps xmm6, xmm4
    mulps xmm6, xmm1 ; xmm6 := (rows+1 in current col - current rows in current col) * weight * mask+1
    addps xmm5, xmm6 ; new value += top delta
    ; top left delta:
    lea r11, [rsi + FLOAT_BYTES*rcx]
    sub r11, FLOAT_BYTES ; offset -1
    movups xmm6, [r11] ; xmm6 := rows-1 in left col (src)
    subps xmm6, xmm4
    mulps xmm6, xmm3 ; xmm6 := (rows-1 in left col - current rows in current col) * weight * mask-1
    addps xmm5, xmm6 ; new value += bottom left delta
    ; top delta:
    lea r11, [r9 + FLOAT_BYTES*rcx]
    sub r11, FLOAT_BYTES ; offset -1
    movups xmm6, [r11] ; xmm6 := rows-1 in current col (src)
    subps xmm6, xmm4
    mulps xmm6, xmm3 ; xmm6 := (rows-1 in current col - current rows in current col) * weight * mask-1
    addps xmm5, xmm6 ; new value += bottom delta
    ; apply delta:
    lea r11, [r10 + FLOAT_BYTES*rcx]
    movups [r11], xmm5 ; TODO: align and use movaps
    ; reset mask settings for next row:
    xor r12, r12
    dec r12
    ; complete inner loop:
    cmp rcx, ROWS_4
    jg .calculate_next_rows
.calculate_next_column:
    ; reset mask settings for the bottom row:
    mov r12, 000000000ffffffffh ; first rows flag for the mask
    ; reset inner loop counter
    mov rcx, r13
    ; move to next column
    add rsi, r8
    add r9, r8
    add r10, r8
    dec eax
    jnz .calculate_next_rows
    ; apply deltas to M ; r9 now points to [DELTA]
    mov r10, [M]
    xor rax, rax
    mov eax, [width]
    mul r8 ; rax := total size of the matrix (r8 contained the single column offset)
.move_next_batch:
    ; this is slightly faster than using rep movsd here (for the baseline and 1k benchmarks)
    sub rax, FLOAT_BYTES
    ; copy DELTA to M
    lea r11, [r9 + rax]
    mov r11, [r11] ; load from DELTA to register
    lea r8, [r10 + rax]
    mov [r8], r11 ; save to memory (M)
    ; complete loop
    test rax, rax
    jne .move_next_batch

; epilogue
    pop r13
    pop r12

    pop rbp
    ret
