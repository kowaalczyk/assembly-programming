;;; Procedure gets array address (in RDI) and its size (in RSI).
;;; The sum of elements is returned XMM0.

        section .text
        global array_fsum

array_fsum:
        mov rcx,rsi          ;Size
        fldz                 ;Initialize sum
add_loop:
        jrcxz done
        dec rcx
        fadd qword [rdi + rcx * 8]
        jmp add_loop
done:
        fstp qword [rsp - 8]
        movq xmm0,[rsp - 8]
        ret

