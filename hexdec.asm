global _start

section .data
filepath: db "ohyeah", 0
eight: db "kratuvid"
newline: db 10

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

; we use the cdecl calling convention in this program
print_uint64_dec:		; (uint64 number)
	push rbp
	mov rbp, rsp
	
	sub rsp, 20
	mov qword [rbp - 20], 0
	mov qword [rbp - 12], 0
	mov dword [rbp - 4], 0
	mov byte [rbp - 20], 48
	mov r8, 0

	mov rax, [rbp + 16]
	jmp .loopcheck
	.loop:
		mov rdx, 0
		mov rcx, 10
		div rcx

		add rdx, 48
		mov [rbp - 20 + r8], rdx
		inc r8

		.loopcheck:
			cmp rax, 0
			jne .loop

	mov rax, r8
	mov rdx, 0
	mov rcx, 2
	div rcx

	mov r9, 0

	jmp .loopcheck_swap_bytes
	.loop_swap_bytes:
		mov dil, [rbp - 20 + r9]
		mov r11, r8
		dec r11
		sub r11, r9
		mov cl, [rbp - 20 + r11]
		mov byte [rbp - 20 + r9], cl
		mov byte [rbp - 20 + r11], dil

		inc r9

		.loopcheck_swap_bytes:
			cmp r9, rax
			jl .loop_swap_bytes

	mov rdi, 1
	mov rsi, rbp
	sub rsi, 20
	mov rdx, 20
	call write

	add rsp, 20

	pop rbp
	ret

_start:
	mov rbp, rsp

	push rsp
	call print_uint64_dec
	add rsp, 8

	mov rdi, 0
	call exit
	
	mov rdi, filepath
	mov rsi, O_RDONLY
	mov rdx, 0
	call open

	mov rdi, rsp
	push 33
	push 67
	mov rdx, [rbp-16]
	mov rsi, rsp
	sub rdi, rsi
	add rsp, 16

	mov rdi, 0
	call exit
