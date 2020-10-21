DEFAULT REL

;;; Procedura otrzymuje współczynniki równania kwadratowego a, b, c.
;;; Oblicza pierwiastki równania i zwraca w dodatkowych parametrach
;;; wyjściowych roo1 i root2.  Wartość boolowska zwracana w eax podaje, czy
;;; znaleziono pierwiastki rzeczywiste.

        section .data
zero    dq 0.0

        section .text
        global quad_roots

quad_roots:
        movsd xmm3,xmm0
        addsd xmm3,xmm0      ;2a na potem
        mulsd xmm0,xmm2      ;ac
        addsd xmm0,xmm0      ;2ac
        addsd xmm0,xmm0      ;4ac
        movsd xmm4,xmm1      ;b
        mulsd xmm4,xmm4
        subsd xmm4,xmm0      ;b*b-4ac
        comisd xmm4,[zero]   ;b*b-4ac <>= 0
        jb no_real_roots
        sqrtsd xmm4,xmm4     ;sqrt(b*b-4ac)
        movsd xmm5,[zero]
        subsd xmm5,xmm1      ;-b
        addsd xmm5,xmm4      ;-b+sqrt(b*b-4ac)
        divsd xmm5,xmm3      ;-b+sqrt(b*b-4ac)/2a
        movsd [rdi],xmm5     ;zapisanie pierwiastka
        movsd xmm5,[zero]
        subsd xmm5,xmm1      ;-b
        subsd xmm5,xmm4      ;-b-sqrt(b*b-4ac)
        divsd xmm5,xmm3      ;-b-sqrt(b*b-4ac)/2a
        movsd [rsi],xmm5     ;zapisanie pierwiastka
        mov eax,1               ;są pierwiastki
        jmp done
no_real_roots:
        sub eax,eax             ;nie ma
done:
        ret
