; (c) Krzysztof Kowalczyk 2020 kk385830@students.mimuw.edu.pl

FLOAT_BYTES equ 4 ; float is 32bit (on students and violet01)
INT_BYTES equ 4 ; int is 32bit (on students and violet01)
PTR_BYTES equ 8

PAD_TOP equ 8
PAD_COL equ 12 ; PADDING_TOP + PADDING_BOTTOM

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
    ; movd [weight], xmm0
    ; mov [width], edi
    ; ; ; padding for matrix M starts 5 rows above M
    ; ; lea r10, [5*FLOAT_BYTES]
    ; ; sub rdx, r10
    ; mov [TP], rdx
    ; ; ; physical height is 4 rows higher than logical (user-facing one)
    ; ; add rsi, 4
    ; mov [height], esi
    ; ; ; actual height is the nearest number > height that is divisible by 4
    ; ; ; NOTE: using number >height, not >=height, to make calculation simpler
    ; ; mov rcx, rsi ; rsi = [0000|esi]
    ; ; shr ecx, 2 ; TODO: validate the number is positive in C (otherwise it doesn't work)
    ; ; inc ecx
    ; ; shl ecx, 2
    ; ; mov [height], ecx
    ; ; offset necessary to next column is (height + padding)*FLOAT_BYTES
    ; mov r8, rsi
    ; add r8, 6
    ; lea r8, [FLOAT_BYTES*r8]
    ; mov [next_col_offset], r8
    ; ; start of padding for TP is positioned one column offset before start of padding for M
    ; mov r9, rdx
    ; sub r9, r8
    ; mov [TP], r9
    ; ; start of padding for DELTA is positioned after end of M (with all its padding)
    ; mov rax, r8
    ; mul rdi ; TODO: Ensure all arguments are >=0 in C to use mul ; TODO: This assumes no overflow
    ; mov [DELTA], rax

; epilogue
    pop rbp
    ret


step:
; prologue
    push rbp
    mov rbp, rsp
; body - arguments - rdi: float* T
    ; load weights to memory
    xorps xmm0, xmm0
    movd xmm0, [weight]
    shufps xmm0, xmm0, 00h  ; xmm0 := [w,w,w,w]
    ; move T to first column in matrix for nicer vectorization
    ; TODO: if we can enforce on users that row is loaded directly to that column, it would speed things up
    xor rcx, rcx ; TODO: is it necessary?
    mov ecx, [height]
    mov rsi, [TP]
    lea r8, [rsi + PAD_TOP*FLOAT_BYTES] ; r8 := first non-placeholder position in TP
.copy_next_batch:
    dec rcx
    lea rdx, [rdi + FLOAT_BYTES*rcx]
    mov rdx, [rdx] ; load value from a row in T
    lea r9, [r8 + FLOAT_BYTES*rcx]
    mov [r9], rdx ; store in corresponding row of TP
    test rcx, rcx
    jne .copy_next_batch

    ; calculate deltas
    mov rsi, [TP]
    ; lea rsi, [rsi + FLOAT_BYTES] ; row0 in left col (src)
    mov r9, [M]
    ; lea r9, [r9 + FLOAT_BYTES] ; row0 in current col (src)
    mov r10, [DELTA]
    ; lea r10, [r10 + FLOAT_BYTES] ; row0 in current col (dest)
    xor rcx, rcx
    mov ecx, [height] ; row counter (inner loop)
    add rcx, PAD_TOP
    xor rax, rax
    mov eax, [width] ; column counter (outer loop)
    mov r8, [next_col_offset]
    mov r12, 0ffffffff00000000h ; first rows flag for the mask
.calculate_next_rows: ; rsi: left column (source), r9: current column (source), r10: current column (dest)
    sub rcx, 4
    ; ; copy weights in preparation for applying masks to them in the next step:
    ; movaps xmm1, xmm0
    ; movaps xmm2, xmm0
    ; movaps xmm3, xmm0
    ; set mask that affects weight application based on number of remaining rows:
    cmp rcx, 4
    jg .set_masks_standard
    cmp rcx, 3
    jg .set_masks_4
    cmp rcx, 2
    jg .set_masks_3
    cmp rcx, 1
    jg .set_masks_2
    test rcx, rcx
    je .calculate_next_column ; 0 rows remaining - nothing left to do
    ; only 1 row remaining:
    ; andps xmm1, ff000000h ; xmm1 := [weight, 0, 0, 0] - weighted mask0
    ; andps xmm2, 0 ; xmm2 := [0, 0, 0, 0] - weighted mask+1
    ; andps xmm3, ffff0000h ; xmm3 := [weight, weight, 0, 0] - weighted mask-1
    jmp .calculate_deltas
.set_masks_2: ; 2 rows remaining:
    ; andps xmm1, ffff0000h ; xmm1 := [weight, weight, 0, 0] - weighted mask0
    ; andps xmm2, ff000000h ; xmm2 := [weight, 0, 0, 0] - weighted mask+1
    ; andps xmm3, ffffff00h ; xmm3 := [weight, weight, weight, 0] - weighted mask-1
    jmp .calculate_deltas
.set_masks_3: ; 3 rows remaining:
    ; andps xmm1, ffffff00h ; xmm1 := [weight, weight, weight, 0] - weighted mask0
    ; andps xmm2, ffff0000h ; xmm2 := [weight, weight, 0, 0] - weighted mask+1
    ; ; xmm3 := [weight, weight, weight, weight] - weighted mask-1
    jmp .calculate_deltas
.set_masks_4: ; TODO: 4 rows remaining:
    movq xmm1, r12
    mov r12, 0ffffffffffffffffh ; TODO: test if this is actually faster than reading from memory
    movq xmm2, r12
    unpcklps xmm1, xmm2
    andps xmm1, xmm0 ; xmm1 := weighted mask+1
    movaps xmm2, xmm0 ; xmm2 := weighted mask0
    mov r12, 000000000ffffffffh
    movq xmm3, r12
    unpcklps xmm2, xmm3
    andps xmm3, xmm0 ; xmm3 := weighted mask-1
    jmp .calculate_deltas
.set_masks_standard: ; >=4 rows remaining, processing the next 4 rows only:
    movq xmm1, r12
    mov r12, 0ffffffffffffffffh
    movq xmm2, r12
    unpcklps xmm1, xmm2
    andps xmm1, xmm0 ; xmm1 := weighted mask+1
    movaps xmm2, xmm0 ; xmm2 := weighted mask0
    movaps xmm3, xmm0 ; xmm3 := weighted mask-1
    ; ; xmm1 := [weight, weight, weight, weight] - weighted mask0
    ; andps xmm2, ffffff00h ; xmm2 := [weight, weight, weight, 0] - weighted mask+1
    ; andps xmm3, 00ffffffh ; xmm3 := [0, weight, weight, weight] - weighted mask-1 ; TODO: this should be used only in the 1st iteration!!!
.calculate_deltas: ; xmm1: weighted mask0, xmm2: weighted mask+1, xmm3: weighted mask-1
    ; copy current values to xmm4 (for delta calculation) and xmm5 (where result will be stored):
    lea r11, [r9 + FLOAT_BYTES*rcx]
    movaps xmm4, [r11] ; xmm4 := current rows in current col (src)
    movaps xmm5, xmm4
    ; left delta:
    lea r11, [rsi + FLOAT_BYTES*rcx]
    movaps xmm6, [r11] ; xmm6 := current rows in left col (src)
    subps xmm6, xmm4
    mulps xmm6, xmm2 ; xmm6 := (current rows in left col - current rows in current col) * weight * mask0
    addps xmm5, xmm6 ; new value += left delta
    ; top left delta:
    lea r11, [rsi + FLOAT_BYTES*rcx]
    add r11, FLOAT_BYTES ; offset +1
    movups xmm6, [r11] ; xmm6 := rows+1 in left col (src)
    subps xmm6, xmm4
    mulps xmm6, xmm1 ; xmm6 := (rows+1 in left col - current rows in current col) * weight * mask+1
    addps xmm5, xmm6 ; new value += top left delta
    ; top delta:
    lea r11, [r9 + FLOAT_BYTES*rcx]
    add r11, FLOAT_BYTES ; offset +1
    movups xmm6, [r11] ; xmm6 := rows+1 in current col (src)
    subps xmm6, xmm4
    mulps xmm6, xmm1 ; xmm6 := (rows+1 in current col - current rows in current col) * weight * mask+1
    addps xmm5, xmm6 ; new value += top delta
    ; bottom left delta:
    lea r11, [rsi + FLOAT_BYTES*rcx]
    sub r11, FLOAT_BYTES ; offset -1
    movups xmm6, [r11] ; xmm6 := rows-1 in left col (src)
    subps xmm6, xmm4
    mulps xmm6, xmm3 ; xmm6 := (rows-1 in left col - current rows in current col) * weight * mask-1
    addps xmm5, xmm6 ; new value += bottom left delta
    ; bottom delta:
    lea r11, [r9 + FLOAT_BYTES*rcx]
    sub r11, FLOAT_BYTES ; offset -1
    movups xmm6, [r11] ; xmm6 := rows-1 in current col (src)
    subps xmm6, xmm4
    mulps xmm6, xmm3 ; xmm6 := (rows-1 in current col - current rows in current col) * weight * mask-1
    addps xmm5, xmm6 ; new value += bottom delta
    ; apply delta:
    lea r11, [r10 + FLOAT_BYTES*rcx]
    movaps [r11], xmm5
    ; reset mask settings for next row:
    xor r12, r12 ; first rows flag for the mask
    ; complete inner loop:
    test rcx, rcx
    je .calculate_next_rows
.calculate_next_column:
    ; reset mask settings for the bottom row:
    mov r12, 0ffffffff00000000h ; first rows flag for the mask
    ; move to next column
    add rsi, r8
    add r9, r8
    add r10, r8
    dec eax
    jnz .calculate_next_rows
    ; TODO: apply deltas to M ; r9 should now point to [DELTA]

; epilogue
    pop rbp
    ret








; ================================================================


; step:
; ; prologue
;     push rbp
;     mov rbp, rsp

; ; body - arguments - rdi: float* T
;     movd xmm0, [weight]
;     shufps xmm0, xmm0, 00h  ; xmm0 := [weight, weight, weight, weight]

; ; for column 0, set deltas based on T
;     mov r11, [M] ; r11 := start of column 0 in M
;     mov rsi, [DELTA]
;     mov rcx, [height]  ; rcx := counter for inner loop
; .setdelta_col0_nextbatch:
;     sub rcx, 4 ; RANGE TEST
; ; delta from left neighbour:
;     lea rdx, [r11 + FLOAT_BYTES*rcx] ; row in column 0 of M
;     lea r8, [rdi + FLOAT_BYTES*rcx] ; row in T
;     movaps xmm1, [rdx]
;     movaps xmm2, [r8]
;     subps xmm2, xmm1
;     mulps xmm2, xmm0
;     movaps xmm3, xmm2 ; xmm3 := delta
;     test rcx, rcx
;     je .setdelta_col0_checkbelow
; ; delta from top left neighbour:
;     mov r8, rcx
;     dec r8
;     lea r8, [rdi + FLOAT_BYTES*r8] ; row-1 in T
;     movaps xmm2, [r8] ; TODO: macro
;     subps xmm2, xmm1
;     mulps xmm2, xmm0
;     addps xmm3, xmm2
; ; delta from top neighbour
;     mov r8, rcx
;     dec r8
;     lea r8, [r11 + FLOAT_BYTES*r8] ; row-1 in column 0 of M
;     movaps xmm2, [r8]
;     subps xmm2, xmm1
;     mulps xmm2, xmm0
;     addps xmm3, xmm2
; .setdelta_col0_checkbelow: ; TODO: consider unrolling it here (happens only once)
;     mov r8, rcx
;     add r8, 4
;     cmp r8, r10
;     je .setdelta_col0_applydelta
; ; delta from bottom left neighbour:
;     mov r8, rcx
;     inc r8
;     lea r8, [rdi + FLOAT_BYTES*r8]
;     movaps xmm2, [r8] ; TODO: macro
;     subps xmm2, xmm1
;     mulps xmm2, xmm0
;     addps xmm3, xmm2
; ; delta from bottom neighbour:
;     mov r8, rcx
;     inc r8
;     lea r8, [r11 + FLOAT_BYTES*r8]
;     movaps xmm2, [r8] ; TODO: macro
;     subps xmm2, xmm1
;     mulps xmm2, xmm0
;     addps xmm3, xmm2
; .setdelta_col0_applydelta:
;     ; TODO


; ; for each column, set (left column) x (weight) as the delta for current column
;     mov r11, [M] ; r11 := start of column 0 in M
;     mov rsi, [DELTA]
;     mov r10, [height]  ; r10 := height for controlling inner loop
;     mov rcx, r10  ; rcx := counter for inner loop
;     lea rsi, [rsi + FLOAT_BYTES*rcx] ; rsi := start of column 1 in DELTA
;     mov r9, [width]  ; r9 - width for controlling outer loop
;     dec r9 ; column 0  is an edge case, handled above
; .setdelta_nextbatch:
;     sub rcx, 4 ; RANGE TEST
;     lea rdx, [r11 + FLOAT_BYTES*rcx]  ; rdx := &left_col[rcx] (in M) TODO: make this calculation nicer
;     lea rdx, [rdx + FLOAT_BYTES*r10]  ; rdx := &current_col[rcx] (in M)
;     movaps xmm1, [rdx] ; xmm1 := current_col[rcx:rcx+4] (in M)
; ; always calculate delta from left neighbour:
;     lea r8, [r11 + FLOAT_BYTES*rcx]  ; r8 := &left_col[rcx] (in M)
;     movaps xmm2, [r8]  ; xmm2 := left_col[rcx:rcx+4]
;     subps xmm2, xmm1  ; xmm2 := left_col[rcx:rcx+4] - current_col[rcx:rcx+4]
;     mulps xmm2, xmm0 ; xmm2 := weight * (left_col[rcx:rcx+4] - current_col[rcx:rcx+4])
;     movaps xmm3, xmm2 ; xmm3 := delta
; ; if possible, calculate delta from top and top-left neighbour:
;     test rcx, rcx
;     je .setdelta_checkbelow
;     ; add top-left neighbour:
;     mov r8, rcx
;     dec r8
;     lea r8, [r11 + FLOAT_BYTES*r8]
;     movaps xmm2, [r8] ; xmm2 := left_col[rcx-1:rcx+3] (in M)
;     subps xmm2, xmm1
;     mulps xmm2, xmm0
;     addps xmm3, xmm2  ; delta += weighted difference vs top left neighbour
;     ; add top neighbour:
;     lea r8, [r8 + FLOAT_BYTES*r10]
;     movaps xmm2, [r8] ; xmm2 := current_col[rcx-1:rcx+3] (in M)
;     subps xmm2, xmm1
;     mulps xmm2, xmm0
;     addps xmm3, xmm2  ; delta += weighted difference vs top neighbour
; .setdelta_checkbelow:
;     ; if possible, calculate delta from bottom and bottom-left neighbour:
;     ; TODO: Check ranges & handle edge cases (loading 3 out of 4 rows) !!!
;     lea r8, [rcx+4]
;     cmp r8, r10
;     je .setdelta_applydelta
;     ; TODO: define macro for applying delta
;     ; add bottom-left neighbour:
;     mov r8, rcx
;     inc r8
;     lea r8, [r11 + FLOAT_BYTES*r8]
;     movaps xmm2, [r8] ; xmm2 := left_col[rcx+1:rcx+5] (in M)
;     subps xmm2, xmm1
;     mulps xmm2, xmm0
;     addps xmm3, xmm2  ; delta += weighted difference vs bottom left neighbour
;     ; add bottom neighbour:
;     lea r8, [r8 + FLOAT_BYTES*r10]
;     movaps xmm2, [r8] ; xmm2 := current_col[rcx+1:rcx+5] (in M)
;     subps xmm2, xmm1
;     mulps xmm2, xmm0
;     addps xmm3, xmm2  ; delta += weighted difference vs bottom neighbour
;     ; store delta in the temporary matrix DELTA:
; .setdelta_applydelta:
;     lea rdx, [rsi + FLOAT_BYTES*rcx]  ; rdx := &current_col[rcx] (in DELTA)
;     movaps [rdx], xmm3  ; &current_col[rcx:rcx+4] (in DELTA) := delta
;     ; check if there are more batches in current column:
;     test rcx, rcx
;     jne .setdelta_nextbatch  ; process next batch of rows in the same column
;     ; reset position to start of next column:
;     mov rcx, r10  ; reset rcx to height of the column
;     lea rsi, [rsi + FLOAT_BYTES*rcx]  ; rsi - beginning of current column in DELTA
;     lea r11, [r11 + FLOAT_BYTES*rcx]  ; r11 - begginning of left column in M
;     dec r9
;     test r9, r9
;     jne .setdelta_nextbatch  ; process next column


; ; set (T) x (weight) as the delta for column 0 (edge case)
;     mov r11, [M]
;     mov rsi, [DELTA]
;     mov rcx, [height]  ; rcx - inner loop counter (row in column)
; .setdelta_col0_nextbatch:
;     sub rcx, 4 ; RANGE TEST
;     lea rdx, [rsi + FLOAT_BYTES*rcx]  ; rdx := &DELTA[rcx]
;     lea r8, [rdi + FLOAT_BYTES*rcx]  ; r8 := &T[rcx]
;     movaps xmm1, [r8]  ; xmm1 := T[rcx:rcx+4]
;     mulps xmm1, xmm0 ; xmm1 := weight * T[rcx:rcx+4]
;     movaps [rdx], xmm1  ; &DELTA[rcx:rcx+4] := weight * T[rcx:rcx+4]
;     test rcx, rcx  ; set ZF=1 if rcx==0
;     jne .setdelta_col0_nextbatch  ; continue loop if rcx!=0 (ZF==0)


; ; apply deltas calculated in DELTA to M
;     mov rcx, [height]  ; rcx - inner loop counter (row in column)
;     mov r9, [width]  ; r9 - width for controlling outer loop
;     imul rcx, r9  ; rcx := height x width
; .applydelta_nextbatch:
;     sub rcx, 4 ; RANGE TEST
;     lea rdx, [rsi + FLOAT_BYTES*rcx]  ; &DELTA[rcx]
;     lea r8, [r11 + FLOAT_BYTES*rcx]  ; &M[rcx]
;     movaps xmm0, [rdx]  ; xmm0 := DELTA[rcx:rcx+4]
;     movaps xmm1, [r8]  ; xmm1 := M[rcx:rcx+4]
;     addps xmm1, xmm0  ; xmm1 := DELTA[rcx:rcx+4] + M[rcx:rcx+4]
;     movaps [r8], xmm1  ; &M[rcx:rcx+4] := DELTA[rcx:rcx+4] + M[rcx:rcx+4]
;     test rcx, rcx
;     jne .applydelta_nextbatch

; ; at this point, DELTA = weight * M


; ; epilogue
;     pop rbp
;     ret
