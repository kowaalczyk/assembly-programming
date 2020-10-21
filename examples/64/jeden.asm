        section .text
        global _start       ;Declaration for linker (ld)

;; System call number for SYSCALL 

SYS_EXIT   equ 60

;; Argument

ARG        equ 4

_start:                     ;Program start (entry point)
	nop
        mov rdi,1           ;Computed value
        mov rcx,ARG
l1:     cmp rcx,1           ;Is it all?
        jle finish
        imul rdi,rcx
        dec rcx             ;Decrement the argument
        jmp l1

finish: mov eax,SYS_EXIT
        syscall             ;System call
