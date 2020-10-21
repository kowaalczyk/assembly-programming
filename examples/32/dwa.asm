        section .text
        global _start       ;Declaration for linker (ld)
        extern printf,exit

_start:                     ;Program start (entry point)
        push msg
        call printf

        push 0
        call exit

        section .data

;; Message for display

msg     db 'Witaj swiecie!',0xa,0   ;string terminated with LF character and zero byte
