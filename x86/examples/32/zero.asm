; syscall numbers: /usr/include/asm/unistd_32.h

	global _start
        section .text

_start: 
	mov	edx,msg_size
	lea	ecx,[msg]
	mov	ebx,1		;STDOUT
	mov	eax,4		;sys_write
	int     0x80

	xor	eax,eax		;exit code 0
	mov	eax,1		;sys_exit
	int     0x80

        section .data

msg db `Hello 32-bit world!\n`
msg_size equ $-msg
