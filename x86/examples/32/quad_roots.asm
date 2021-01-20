;;; Procedura otrzymuje współczynniki równania kwadratowego a, b, c.
;;; Oblicza pierwiastki równania i zwraca w dodatkowych parametrach
;;; wyjściowych roo1 i root2.  Wartość boolowska zwracana w eax podaje, czy
;;; znaleziono pierwiastki rzeczywiste.

%define a qword[ebp+8]
%define b qword[ebp+16]
%define c qword[ebp+24]
%define root1 qword[ebp+32]
%define root2 qword[ebp+36]

        section .text
        global quad_roots

quad_roots:
        enter 0,0
        fld a
        fadd st0      ;2a na potem
        fld a
        fld c
        fmulp st1     ;ac
        fadd st0      ;2ac
        fadd st0      ;4ac
        fchs          ;-4ac
        fld b
        fld b
        fmulp st1     ;b*b
        faddp st1     ;b*b-4ac
        ftst          ;b*b-4ac <>= 0
        fstsw ax      ;status
        sahf
        jb no_real_roots
        fsqrt         ;sqrt(b*b-4ac)
        fld b
        fchs          ;-b
        fadd st1      ;-b+sqrt(b*b-4ac)
        fdiv st2      ;-b+sqrt(b*b-4ac)/2a
        mov eax,root1
        fstp qword [eax]        ;zapisanie pierwiastka
        fchs          ;sqrt(b*b-4ac)
        fld b
        fsubp st1               ;-b-sqrt(b*b-4ac)
        fdivrp st1              ;-b+sqrt(b*b-4ac)/2a
        mov eax,root2
        fstp qword [eax]        ;zapisanie pierwiastka
        mov eax,1               ;są pierwiastki
        jmp done
no_real_roots:
        sub eax,eax             ;nie ma
done:
        leave
        ret
