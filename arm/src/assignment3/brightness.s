.text

.global adjust_brightness

adjust_brightness:
    @prologue
    str lr, [sp,#-4]! @ store lr on the stack (increasing sp by 4 bytes before load)

    @ preserve registers on the stack ; TODO: LDMFD?
    str r4, [sp,#-4]!
    str r5, [sp,#-4]!
    str r6, [sp,#-4]!

    @ sub sp, sp, #4 @ stack increased by 1 byte

    @ r0 - pointer to image structure { width, height, max_value, pixels* }
    @ r1 - color to adjust
    @ r2 - adjustment
    ldmia r0, {r3-r6} @ load width, height, max_value and pixels* in one instruction
    @ r0: image*, r1: color, r2: adjustment, r3: width, r4: height, r5: max_value, r6: pixels*

    mov r0, r4 @ TODO

    @ add sp, sp, #4 @ reset stack to inital position

    @ restore preserved registers from the stack (decreasing stack after each load) ; TODO: LDMFD?
    ldr r6, [sp],#4
    ldr r5, [sp],#4
    ldr r4, [sp],#4

    @ epilogue
    ldr lr, [sp], #4 @ load return address from the stack & reset stack
    bx lr @ jump to return address
