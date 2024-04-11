global _start

section .data
filepath: db "ohyeah", 0

O_CREAT: equ 100o
O_APPEND: equ 2000o
O_RDONLY: equ 0o
O_WRONLY: equ 1o
O_RDWR: equ 2o


section .text
exit:	; (int exit_code)
	mov rax, 60
	syscall
	ret

open:	; (str filepath, int flags, int mode)
	mov rax, 2
	syscall
	ret

write:	; (int fd, void* buffer, int count)
	mov rax, 1
	syscall
	ret

_start:
	mov rdi, filepath
	mov rsi, O_RDONLY
	mov rdx, 0
	call open

	mov rdi, rax
	call exit
