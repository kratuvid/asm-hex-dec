global _start

section .data
filepath: db "ohyeah", 0
eight: db "kratuvid"
newline: db 10
null: db 0

help_arg: db "--help", 0
generic_arg: db "--xy", 0
help_string: db "Convert to and from, (h)exadecimal, (d)ecimal, (o)ctal, (b)inary and (r)aw", 0

decimal_syms: db "0123456789"
hexadecimal_syms: db "0123456789abcdef"
octal_syms: db "012345678"
binary_syms: db "01"

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
print:		; (uint64 fd +16, void* buffer +24)
	push rbp
	mov rbp, rsp

	mov rsi, [rbp + 24]

	mov r8, 0
	jmp .loopcheck
	.loop:
		inc r8
		.loopcheck:
			cmp byte [rsi + r8], 0
			jne .loop

	cmp r8, 0
	je .empty

	mov rdi, [rbp + 16]
	mov rdx, r8
	call write

	.empty:
		pop rbp
		ret

memset8:		; (void* buffer +16, uint64 size +24, uint16 what +32)
	push rbp
	mov rbp, rsp

	; Loop based
	; mov sil, [rbp + 32]
	; mov rax, [rbp + 24]
	; dec rax

	; mov r8, [rbp + 16]

	; jmp .loopcheck
	; .loop:
	; 	mov byte [r8 + rax], sil
	; 	dec rax

	; 	.loopcheck:
	; 		cmp rax, 0
	; 		jge .loop

	mov al, [rbp + 32]
	mov rdi, [rbp + 16]
	mov rcx, [rbp + 24]
	cld
	rep stosb

	pop rbp
	ret

; number: number to print
; base: base to print in. like 16
; max_string: length of the string which can contain the largest number
;             eg. len(str(0xffffffffffffffff)) * 1 for base 10
; symbols: symbols to represent individual positions. for base 16, "0123456789abcdef"
print_uint64_generic:	; (uint64 number +16, uint64 base +24, uint64 max_string +32, char* symbols +40)
	push rbp
	mov rbp, rsp
	push rbx
	push r12

	mov rbx, [rbp + 32]			; perma register, stores the actual length = max_length + 1
	inc rbx

	sub rsp, rbx				; variable, to store the resultant string

	mov r12, rbp				; perma register, address of the resultant string
	sub r12, rbx

	push word 0					; memset the resultant string
	push rbx
	push r12
	call memset8
	add rsp, 18

	mov rdi, [rbp + 40]			; pointer to the symbols array
	mov sil, [rdi + 0]			; the symbol at index 0
	mov byte [r12], sil			; first byte is '0' to prevent logical errors in the loop below

	mov r8, 0					; index into the string
	mov rax, [rbp + 16]			; dividend
	jmp .loopcheck
	.loop:
		mov rdx, 0				; needs to be done for the div instruction
		mov rcx, [rbp + 24]		; divisor
		div rcx

		mov rdi, [rbp + 40]		; get the symbol at index rdx
		mov sil, [rdi + rdx]
		mov [r12 + r8], sil		; just set at the appropriate index in the resultant string

		inc r8

		.loopcheck:
			cmp rax, 0
			jne .loop

	cmp r8, 0
	jne .out
	mov r8, 1
	.out:

	mov rdx, 0
	mov rax, r8					; r8 now holds the number of characters in the string
	mov rcx, 2
	div rcx

	mov r9, 0					; holds the byte to swap. r9 and (r8 - 1 - r9)
	jmp .loopcheck_swap_bytes
	.loop_swap_bytes:
		mov dl, [r12 + r9]
		mov r10, r8
		dec r10
		sub r10, r9
		mov cl, [r12 + r10]
		mov [r12 + r9], cl
		mov [r12 + r10], dl

		inc r9

		.loopcheck_swap_bytes:
			cmp r9, rax
			jl .loop_swap_bytes

	mov rdi, 1
	mov rsi, r12
	mov rdx, r8
	call write

	add rsp, rbx

	pop r12
	pop rbx
	pop rbp
	ret

print_uint64_decimal:	; (uint64 number +16)
	push rbp
	mov rbp, rsp

	push decimal_syms
	push qword 20
	push qword 10
	push qword [rbp + 16]
	call print_uint64_generic
	add rsp, 32

	pop rbp
	ret

print_uint64_hexadecimal:	; (uint64 number +16)
	push rbp
	mov rbp, rsp

	push hexadecimal_syms
	push qword 16
	push qword 16
	push qword [rbp + 16]
	call print_uint64_generic
	add rsp, 32

	pop rbp
	ret

print_uint64_octal:	; (uint64 number +16)
	push rbp
	mov rbp, rsp

	push octal_syms
	push qword 22
	push qword 8
	push qword [rbp + 16]
	call print_uint64_generic
	add rsp, 32

	pop rbp
	ret

print_uint64_binary:	; (uint64 number +16)
	push rbp
	mov rbp, rsp

	push binary_syms
	push qword 64
	push qword 2
	push qword [rbp + 16]
	call print_uint64_generic
	add rsp, 32

	pop rbp
	ret

_start:
	mov rbp, rsp

	mov r8, 0
	jmp .loopcheck0
	.loop0:
		push r8
		push qword r8
		call print_uint64_binary
		add rsp, 8
		pop r8

		mov rdi, 1
		mov rsi, newline
		mov rdx, 1
		call write

		inc r8

		.loopcheck0:
			cmp r8, 20
			jle .loop0

	mov rdi, 0
	call exit

	; ------------

	mov r8, 1
	jmp .loopcheck
	.loop:
		push r8
		mov rax, [rbp + 8 * r8]
		push rax
		push 1
		call print
		add rsp, 16
		pop r8

		mov rdi, 1
		mov rsi, newline
		mov rdx, 1
		call write

		inc r8

		.loopcheck:
			cmp r8, [rbp]
			jle .loop

	mov rdi, 0
	call exit

	; ------------

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
