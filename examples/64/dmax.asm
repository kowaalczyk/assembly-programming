;; File: dmax.asm

        section .text
        global dmax

;; Function dmax
;;
;; Returns the larger of its two double arguments
;;
;; C prototype:
;;
;; double dmax (double d1, double d2);
;;
;; Parameters:
;;   XMM0(d1)   - first double
;;   XMM1(d2)   - second double
;;
;; Return value:
;;   larger of d1 and d2 (in XMM0)

dmax:
        movq [rsp - 8],xmm1
        fld qword [rsp - 8]
        movq [rsp - 8],xmm0         ;reuse space
        fld qword [rsp - 8]         ;ST0 = d1, ST1 = d2
        fcomip st1                  ;ST0 = d2
        jnb short exit              ;if d1 is bigger, nothing to do
        movq xmm0,xmm1
exit:
        fcomp st0                   ;pop d2 from stack
        ret
