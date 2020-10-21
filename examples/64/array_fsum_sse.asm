DEFAULT rel

;;; Procedure gets array address (in RDI) and its size (in RSI).
;;; The sum of elements is returned XMM0.

        section .data
zero    dq 0.0

        section .text
        global array_fsum

array_fsum:
        movq xmm0,[zero]                ;Initialize sum
        mov rcx,rsi          ;Size
add_loop:
        jrcxz done
        dec rcx
        movq xmm1,[rdi + rcx * 8]
        addsd xmm0,xmm1
        jmp add_loop
done:
        ret

