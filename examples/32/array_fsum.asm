;;; Procedura dostaje na stosie adres tablicy i jej rozmiar.
;;; Zwraca sumę elementów w st0.

        section .text
        global array_fsum

array_fsum:
        enter 0,0
        mov edx,[ebp+8]      ;Adres tablicy
        mov ecx,[ebp+12]     ;Rozmiar
        fldz                 ;Inicjowanie sumy
add_loop:
        jecxz done
        dec ecx
        fadd qword[edx+ecx*8]
        jmp add_loop
done:
        leave
        ret

