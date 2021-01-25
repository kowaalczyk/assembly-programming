.text

.global adjust_brightness

adjust_brightness:
    @prologue
    str lr, [sp,#-4]! @ store lr on the stack (decreasing sp by 4 bytes before load)

    @ preserve registers on the stack ; TODO: LDMFD?
    str r4, [sp,#-4]!
    str r5, [sp,#-4]!
    str r6, [sp,#-4]!

    @ r0 - pointer to image structure { width, height, max_value, pixels* }
    @ r1 - color to adjust
    @ r2 - adjustment
    ldmia r0, {r3-r6} @ load width, height, max_value and pixels* in one instruction
    @ r0: image*, r1: color, r2: adjustment, r3: width, r4: height, r5: max_value, r6: pixels*

    mul r0, r3, r4 @ r0 = number of pixels to process (controlling the loop)
    mov r4, #4 @ sizeof(int)
    mla r3, r4, r1, r6 @ r3 = pixels + color * sizeof(int) = desired color in pixel 0
    mov r5, #255
loop:
    ldr r4, [r3] @ load color for current pixel
    adds r4, r4, r2 @ add adjustment to the color value of pixel
    movmi r4, #0 @ N flag set (result is negative) - saturate color value to 0
    cmp r4, r5 @ compare with 255
    movgt r4, r5 @ if greater, saturate to 255

    str r4, [r3], #12 @ store updated color, move r0 to same color in next pixel
    subs r0, #1
    bne loop @ loop again if subtraction result is not zero

    @ restore preserved registers from the stack (increasing sp by 4 after each load) ; TODO: LDMFD?
    ldr r6, [sp], #4
    ldr r5, [sp], #4
    ldr r4, [sp], #4

    @ epilogue
    ldr lr, [sp], #4 @ load return address from the stack & reset stack
    bx lr @ jump to return address
