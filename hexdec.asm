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

; like write but stops when it sees NULL. be careful using it
print:	; (int fd, void* buffer)
	mov r8, 0
	jmp .loopcheck
	.loop:
		inc r8
		.loopcheck:
			cmp byte [rsi + r8], 0
			jne .loop

	cmp r8, 0
	je .empty

	mov rdx, r8
	call write

	.empty:
		ret

; we use the cdecl calling convention in this program
print_uint64_dec:		; (uint64 number)
	push rbp
	mov rbp, rsp
	
	; 20 bytes is all the memory you'll ever need to store a 64-bit number
	; calculated using: len(str(0xffffffffffffffff)) * 1
	sub rsp, 21
	mov qword [rbp - 21], 0
	mov qword [rbp - 13], 0
	mov dword [rbp - 5], 0		; zero out the blocks
	mov byte [rbp - 1], 0
	mov byte [rbp - 21], 48		; first byte is '0' to prevent logical errors in the loop below

	mov r8, 0					; index into the string
	mov rax, [rbp + 16]			; stores the quotient
	jmp .loopcheck
	.loop:
		mov rdx, 0				; stores the remainder
		mov rcx, 10
		div rcx

		add rdx, 48				; convert from raw number to ascii
		mov [rbp - 21 + r8], rdx

		inc r8

		.loopcheck:
			cmp rax, 0
			jne .loop

	mov rdx, 0
	mov rax, r8					; r8 now holds the number of characters in the string
	mov rcx, 2
	div rcx

	mov r9, 0					; holds the byte to swap. r9 and (r8 - 1 - r9)
	jmp .loopcheck_swap_bytes
	.loop_swap_bytes:
		mov dl, [rbp - 21 + r9]
		mov r10, r8
		dec r10
		sub r10, r9
		mov cl, [rbp - 21 + r10]
		mov byte [rbp - 21 + r9], cl
		mov byte [rbp - 21 + r10], dl

		inc r9

		.loopcheck_swap_bytes:
			cmp r9, rax
			jl .loop_swap_bytes

	mov rdi, 1
	mov rsi, rbp
	sub rsi, 21
	call print

	add rsp, 21

	pop rbp
	ret

_start:
	mov rbp, rsp

	push 123456789
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
