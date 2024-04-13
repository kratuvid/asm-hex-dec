global _start

section .data
newline: db 10
null: db 0

help_arg: db "--help", 0
generic_arg: db "--xy", 0
cont_arg: db "--cont", 0
help_string: db "Options: --help - prints this", 10
			 db "         --xy - convert from base x to y", 10
			 db "         --cont - run indefinitely", 10
			 db "Bases: he(x)adecimal, (d)ecimal, (o)ctal, (b)inary and (r)aw", 10, 0
bases_string: db "xdobr", 0

decimal_syms: db "0123456789"
hexadecimal_syms: db "0123456789abcdef"
octal_syms: db "012345678"
binary_syms: db "01"


section .text
exit:	; (int exit_code)
	mov rax, 60
	syscall
	ret

read:	; (int fd, void* buffer, int count)
	mov rax, 0
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

; Returns: 0: `char` is in `str`, 1: otherwise
; Args: `str`: String to check against
;       `char`: Character to check with
strin:		; (uint16 char +16, char* str +18)
	push rbp
	mov rbp, rsp

	push qword [rbp + 18]
	call strlen
	add rsp, 8
	mov r9, rax

	mov rax, 0				; assume equal

	mov cx, [rbp + 16]
	and cx, 0x00ff
	mov r8, 0
	jmp .loopcheck
	.loop:
		mov rdx, [rbp + 18]
		cmp cl, [rdx + r8]
		je .exit

		inc r8

		.loopcheck:
			cmp r8, r9
			jl .loop

	mov rax, 1
	
	.exit:
		pop rbp
		ret

; Returns: Length of `str`
; Args: `str`: null terminated string
strlen:		; (char* str +16)
	push rbp
	mov rbp, rsp
	
	mov rsi, [rbp + 16]

	mov rax, 0
	.loop:
		cmp byte [rsi + rax], 0
		je .exit

		inc rax

		jmp .loop

	.exit:
		pop rbp
		ret

; Args: `fd`: file descriptor to write to
;       `str`: null terminated string
print:		; (uint64 fd +16, char* str +24)
	push rbp
	mov rbp, rsp

	mov rsi, [rbp + 24]

	push rsi
	push rsi
	call strlen
	add rsp, 8
	pop rsi

	cmp rax, 0
	je .empty

	mov rdi, [rbp + 16]
	mov rdx, rax
	call write

	.empty:
		pop rbp
		ret

; Args: `buffer`: Buffer to fill
;       `size`: How many bytes to fill
;       `what`: What to fill each byte with
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

; Args: `number`: Raw number to print
;       `base`: Base to print in
;       `max_string`: Length of the string in bytes which can contain `number` maxxed
;                     Eg. len(str(0xffffffffffffffff)) * 1 for base 10
;       `symbols`: Symbols of length `base`, which will be used to represent the raw value
;                  Eg. "0123456789abcdef" for base 16
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
	jne .skip
	mov r8, 1
	.skip:

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

; Args: `number`: Raw number to print
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

; Args: `number`: Raw number to print
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

; Args: `number`: Raw number to print
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

; Args: `number`: Raw number to print
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

; Desc: Compares and checks if strings are equal
; Returns: 0: if equal, 1: otherwise
; Args: `first`: null terminated string
;       `second`: null terminated string
strcmp:		; (char* first +16, char* second +24)
	push rbp
	mov rbp, rsp

	mov rcx, [rbp + 16]		; first string
	mov rdx, [rbp + 24]		; second string

	mov rax, 0				; assume equal

	mov r8, 0
	.loop:
		mov dil, [rcx + r8]
		cmp dil, [rdx + r8]
		
		jne .unequal

		cmp dil, 0
		je .exit
		cmp byte [rdx + r8], 0
		je .exit

		inc r8

		jmp .loop

	jmp .exit

	.unequal:
		mov rax, 1
	.exit:
		pop rbp
		ret

; Desc: Prints the help string
print_help:
	push rbp
	mov rbp, rsp

	push help_string
	push qword 1
	call print
	add rsp, 16

	pop rbp
	ret

; Returns: Bits 0-15 == 0: if an error occured
;          Bits 0-7: base to convert from
;          Bits 8-15: base to convert to
;          Bit 16 == 1: if the program should run indefinitely
; Args: `start_rbp`: rbp register in the _start subroutine
parse_arguments:	; (void* start_rbp +16)
	push rbp
	mov rbp, rsp
	push r12
	push r15

	mov r15, 0

	mov r12, [rbp + 16]

	cmp qword [r12], 1
	jle .handle_help

	mov r8, 2
	jmp .loopcheck
	.loop:
		push r8
		push help_arg
		push qword [r12 + 8 * r8]
		call strcmp
		add rsp, 16
		pop r8
		cmp rax, 0
		je .handle_help

		push r8
		push cont_arg
		push qword [r12 + 8 * r8]
		call strcmp
		add rsp, 16
		pop r8
		cmp rax, 0
		je .handle_cont
		.handle_cont_return:

		push r8
		push qword [r12 + 8 * r8]
		call strlen
		add rsp, 8
		pop r8
		cmp rax, 4
		je .handle_xy
		.handle_xy_return:

		inc r8

		.loopcheck:
			cmp r8, [r12]
			jle .loop

	.exit:
		mov rax, r15

		pop r15
		pop r12
		pop rbp
		ret

	.handle_cont:
		or r15, 0x010000
		jmp .handle_cont_return

	.handle_xy:
		push r13
		push r14

		mov r12, [rbp + 16]

		mov rax, [r12 + 8 * r8]
		mov rcx, 0
		mov ecx, [rax]
		mov rax, rcx

		mov r13, rax
		shr r13, 16
		and r13, 0x00ff

		mov r14, rax
		shr r14, 24

		push r8
		push bases_string
		mov rax, r13
		push ax
		call strin
		add rsp, 10
		pop r8

		cmp rax, 1
		je .handle_xy_return_wrap

		push r8
		push bases_string
		mov rax, r14
		push ax
		call strin
		add rsp, 10
		pop r8

		cmp rax, 1
		je .handle_xy_return_wrap

		shl r14, 8
		mov rax, r14
		or rax, r13

		or r15, rax

		.handle_xy_return_wrap:
			pop r14
			pop r13
			jmp .handle_xy_return

	.handle_help:
		call print_help
		mov rdi, 1
		call exit

; Args: `from`: base to convert from
;       `to`: base to conver to
;       `cont`: whether the program should run indefinitely
run:	; (uint16 from +16, uint16 to +18; uint16 cont +20)
	push rbp
	mov rbp, rsp

	sub rsp, 8

	.run_begin:

	mov r8, 0
	.loop_read:
		mov rdi, 0
		lea rsi, [rbp - 8 + r8]
		mov r9, 8
		sub r9, r8
		mov rdx, r9
		call read

		add r8, rax
		.loop_read_check:
			cmp r8, 8
			jl .loop_read

	push qword [rbp - 8]

	cmp word [rbp + 18], 0x0078		; 'x\0'
	jne .switch_print_d
	call print_uint64_hexadecimal
	jmp .switch_print_out

	.switch_print_d:
	cmp word [rbp + 18], 0x0064		; 'd\0'
	jne .switch_print_o
	call print_uint64_decimal
	jmp .switch_print_out

	.switch_print_o:
	cmp word [rbp + 18], 0x006f		; 'o\0'
	jne .switch_print_b
	call print_uint64_octal
	jmp .switch_print_out

	.switch_print_b:
	cmp word [rbp + 18], 0x0062		; 'b\0'
	jne .switch_print_r
	call print_uint64_binary
	jmp .switch_print_out

	.switch_print_r:
	cmp word [rbp + 18], 0x0072		; 'r\0'
	jne .switch_print_out
	mov rdi, 1
	lea rsi, [rbp - 8]
	mov rdx, 8
	call write
	jmp .switch_print_out

	.switch_print_out:
		add rsp, 8					; pop arguments of print_uint64_*

	cmp word [rbp + 20], 1
	je .run_begin
	
	add rsp, 8

	pop rbp
	ret

_start:
	mov rbp, rsp

	push rbp
	call parse_arguments
	add rsp, 8

	mov rcx, rax
	cmp cx, 0
	mov rdi, 1
	je .exit

	mov rdi, rax
	mov rcx, rax
	and rdi, 0x10000
	shr rdi, 16
	and rcx, 0xff00
	shr rcx, 8
	and rax, 0xff
	push di
	push cx
	push ax
	call run
	add rsp, 4

	mov rdi, 0
	.exit:
		call exit

tests:
	; ----------

	push rbp
	call parse_arguments
	add rsp, 8

	sub rsp, 2

	mov [rbp - 2], al
	mov [rbp - 1], ah

	mov rdi, 1
	lea rsi, [rbp - 2]
	mov rdx, 2
	call write
	
	add rsp, 2

	mov rdi, 0
	call exit

	; ------------

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

	; mov rdi, filepath
	; mov rsi, O_RDONLY
	; mov rdx, 0
	; call open

	mov rdi, rsp
	push 33
	push 67
	mov rdx, [rbp-16]
	mov rsi, rsp
	sub rdi, rsi
	add rsp, 16

	mov rdi, 0
	call exit
