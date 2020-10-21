        section .text
        global three        ;Declaration for linker (ld)

;; Argument

ARG     equ 4

three:                      ;Procedure start (entry point)
        push rbp
        mov rbp,rsp
        mov ebx,1           ;Computed value
        mov ecx,ARG
l1:     cmp ecx,1           ;Is it all?
        jle finish
        imul ebx,ecx
        dec ecx             ;Decrement the argument
        jmp l1

finish: mov eax,ebx
        pop rbp
        ret
