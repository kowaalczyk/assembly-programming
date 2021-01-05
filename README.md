# Programowanie w asemblerze / assembly programming course

- [course website](https://students.mimuw.edu.pl/~zbyszek/asm/pl/index.html)
  (all examples are copied from there)
- Folders `scen1` and `scen2` contain solutions to lab tasks
- Use NASM manual for all kind of references


## Useful tricks

### Lab 1

- Use `ldd` command to check linker error if "File doesn't exist" error occurs


### Lab 2

- Long loops (jumps) can be impossible to work on some assembly types, worth to check reference
- `jrcxz` can be used to jump if `rcx` is zero, very old instruction that makes it more intuitive to write loops
- `use16` and `use32` can be used in nasm to operate on smaller numbers than defaults
  (see manual  how to use them first + reference from the specific machine language - x86 or arm)


### Lab 3

- NASM allows you to perform pointer calculations like `add rsi, [array + rcx * 4]`,
  but note that `4` above is a power of 2 (otherwise pointer calculation doesn't make sense)
- common mistake: wrong argument order results in arrays passed to int args (and vice-versa)
- convention: always use integer argument before array (as far as I remember from previous lab),
  this is supposed to be a common UNIX convention
- LD failures regarding "cannot relocate .data section ..." / "nonrepresentable section on output":
  - is regarded to having multiple sections (eg. `bufor` or `data` and `.text`) addressed directly
  - modern unix and linux OSs are assuming sections can be moved anywhere (re-ordered, etc.)
  - cannot be recompiled with `-fPIC` because we're writing asm, not C
  - workaround: keep buffer on the stack: instead of `resb 1` in `bss` + in text
    `mov [bufor], rsi` we use `push rsi; mov rsi rsp`
    - actually this solution didn't work when presented on labs (XD)
    - last year popular workaround was to add `-no-pie` to CFLAGS (when compiling main program),
      this solved the problem (at least during the lab)
- trick: in 64-bit mode we can move stuff above the stack pointer
  (there is a guarantee that 128bytes above rsp are free to use for any purpose)
  this can be used the following way: `mov [rsp-8], rsi; lea rsi, [rsp-8]` (again,
  instead of using `mov [bufor], rsi`, to prevent using section `.data` which is immovable
  or using `malloc` which is expensive - the less syscalls the better)
- when we're moving bytes (chars) around, they are always in a seal of the register,
  which is the lowest part (in a little-endian systems, so pretty much everywhere)


## Lab 4

String instructions:
- advanced nasm tools for efficiently processing strings in loops (basically more optimized code):
  - `cld` and `std` for control flow - see:
  https://stackoverflow.com/questions/9636691/what-are-cld-and-std-for-in-x86-assembly-language-what-does-df-do
  - `rep` repeats an instruction (should work correctly with all kinds of block instructions)
  - `loop` - see: https://stackoverflow.com/questions/46881279/how-exactly-does-the-x86-loop-instruction-work
- writing on statically allocated string (which is then compiled from C to data entry) usually results in segmentation fault (so use `malloc` instead)
- `enter` and `leave` instructions are rarely used, there is no benefit in using them vs writing prolog and epilog manually

Block instructions:
- some assemblers support operating on contiguous blocks of data (spanning multiple memory units) simultaneusly using these instructions
- they are ususally related to string instructions

Meta:
- for all assignments expected tests (written in C) should include all usual edge cases (array start/end, etc.)


## Lab 5

Missed


## Lab 6

Compiling C:
- to NASM text: `gcc -S -masm=intel plik.c`
- to object file: `gcc -c -masm=intel plik.c` after which
  `objdump -M intel -d plik.o` prints binary with asm instructions
  (usually works better than `readelf` which was made for this purpose)


## Lab 7

Terminal I/o:
- Always check errno when read (and related functions) return a negative value
  (to retry if `errno == EAGAIN`)
- Never use ioctl
- Use `man termios` to check standards and local definitions of terminal sequences
  (would’ve been useful for SIK / telnet commands), and `tcsetattr` with `tcgetattr`
  to enable / disable some flags

Classic floating point arithmetic (FPU):
- Instruction names starting with F are dedicated to floating point arithmetic
- Arguments passed in `XMM1...XMM8` registers
- Result returned in `XMM0`
- Arguments need to be moved to a stack, as all floating point instructions operate only on stack arguments:
    - `FLD` - push to stack
- Default first argument is usually stack top (and the second one is usually specified for a given instruction, similarly to what MUL does for integers)
- Sample operations:
    - `FCOMI` -  comparison, stores result on the stack
    - `FCOMIP` - same, but also pops the result from the stack to xmm0
    - `FLDZ` - loads 0 to the stack
    - `FADD` and `FSUB` have a TO modifier that allows to customise where the output is written (to a register), but it is still better to stick to the convention of holding everything on the stack
    - `FSIN`, `FCOS`, `FSQRT` - there are many useful functions here
    - `FILD` - load integer
- Stack needs to be cleared before leaving the function!!!
    - Trick is to use any of the operations to clear the stack (eg. `fcomp st0`)
FPU is almost never used now, it’s only good parts are:
- Non-standard `80bit` floating point instructions (only on Intel X86)
- Many useful operations (eg. `SIN`, `SQRT` mentioned above)

Modern floating point arithmetic (SSE):
- First, only operations on 128bits (2 doubles or 4 floats)
- Then (SSE2), adds YMM 256bit registers and packed integer registers
- SSE3 only adds new operations, and is widely available on Xeon processors


## Lab 8

FPU programming (to complete previous lab):
- `DEFAULT REL` - when asm cannot determine whether to use absolute
  or relative address (wrt instruction pointer), it prefers the relative one
  (see `quad_roots` example)
- Values from the stack can be passed as arguments:
  - `st0` is the stack top
  - `st1` is below it, and so on
- Useful operations:
  - `fchs` change sign (multiply by `-1`)
  - `ftst` test if `!= 0`

SSE programming (modern tech, will likely be used in assignment):
- useful website with examples: http://www.songho.ca/misc/sse/sse.html
- other references:
  - SSE instructions: https://softpixel.com/~cwright/programming/simd/sse.php
  - SSE2 instructions: https://softpixel.com/~cwright/programming/simd/sse2.php
  - notes from the lab: https://students.mimuw.edu.pl/~zbyszek/asm/pl/instrukcje-sse.html
    (this one is specifically useful reference with all important packed instructions)
- see `cross_product` example for the most basic usage guide for SSE
  (though its 32-bit)
  - use `movups` to align the stack correctly and `movaps` for better performance
- intel published sse intrinsics for using these vectorized operations in C++


## Lab 9

Assignment 2 Q&A:
- new column that is passsed to `step` is temporary
  (doesn't become a part of the existing matrix for the next step)
- we should use `XMM` registers, and if feeling adventurous - `YMM` or `ZMM`,
  but we cannot assume YMM and ZMM exist (so we have to check in the program)
- we should make sure the solution works in lab `3045` (if YMM or ZMM are there,
  we actually don't need to worry about checking)
- minimal input is 3x3, we don't actually need to check size-related edge cases
  (we can reject such input from user immediately)
