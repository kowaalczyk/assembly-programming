DEFAULT REL

;;; Procedura otrzymuje współczynniki równania kwadratowego a, b, c.
;;; Oblicza pierwiastki równania i zwraca w dodatkowych parametrach
;;; wyjściowych roo1 i root2.  Wartość boolowska zwracana w eax podaje, czy
;;; znaleziono pierwiastki rzeczywiste.

        section .bss
a       resq 1
b       resq 1
c       resq 1

        section .text
        global quad_roots

quad_roots:
        push rbp
        mov rbp,rsp
        movsd [a],xmm0
        movsd [b],xmm1
        movsd [c],xmm2
        fld qword [a]
        fadd st0      ;2a na potem
        fld qword [a]
        fld qword [c]
        fmulp st1     ;ac
        fadd st0      ;2ac
        fadd st0      ;4ac
        fchs          ;-4ac
        fld qword [b]
        fld qword [b]
        fmulp st1     ;b*b
        faddp st1     ;b*b-4ac
        ftst          ;b*b-4ac <>= 0
        fstsw ax      ;status
        sahf
        jb no_real_roots
        fsqrt         ;sqrt(b*b-4ac)
        fld qword [b]
        fchs          ;-b
        fadd st1      ;-b+sqrt(b*b-4ac)
        fdiv st2      ;-b+sqrt(b*b-4ac)/2a
        fstp qword [rdi]        ;zapisanie pierwiastka
        fchs          ;sqrt(b*b-4ac)
        fld qword [b]
        fsubp st1               ;-b-sqrt(b*b-4ac)
        fdivrp st1              ;-b+sqrt(b*b-4ac)/2a
        fstp qword [rsi]        ;zapisanie pierwiastka
        mov eax,1               ;są pierwiastki
        jmp done
no_real_roots:
        sub eax,eax             ;nie ma
done:
        pop rbp
        ret
