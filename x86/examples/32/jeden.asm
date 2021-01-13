        section .text
        global _start       ;Declaration for linker (ld)

;; System call number for INT 80H 

SYS_EXIT   equ 1

;; Argument

ARG        equ 4

_start:                     ;Program start (entry point)
        mov ebx,1           ;Computed value
        mov ecx,ARG
l1:     cmp ecx,1           ;Is it all?
        jle koniec
        imul ebx,ecx
        dec ecx             ;Decrement the argument
        jmp l1

koniec: mov eax,SYS_EXIT
        int 0x80            ;System call
