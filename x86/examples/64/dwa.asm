        section .text
        global _start       ;Declaration for linker (ld)
        extern printf,exit

_start:                     ;Program start (entry point)
        mov rdi,msg
        mov rax,0
        call printf

        mov rdi,0
        call exit

        section .data

;; Message for display

msg     db 'Hello assembly world!',0xa,0   ;string terminated with LF character and zero byte
