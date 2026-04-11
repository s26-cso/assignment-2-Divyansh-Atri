.global main
.extern fopen
.extern fseek
.extern ftell
.extern fgetc
.extern printf
.extern rewind

.section .rodata
fname: .string "input.txt"
mode: .string "r"
yes: .string "Yes\n"
no: .string "No\n"

.section .text
main:
	push %rbp
	mov %rsp, %rbp

	lea fname(%rip), %rdi
	lea mode(%rip), %rsi
	call fopen
	mov %rax, %r12

	test %r12, %r12
	je not_pal

	# Seek to end to get file size
	mov %r12, %rdi
	mov $0, %rsi
	mov $2, %rdx
	call fseek

	mov %r12, %rdi
	call ftell
	mov %rax, %r13         # r13 = file size

	xor %r14, %r14         # r14 = l = 0
	mov %r13, %r15
	dec %r15               # r15 = r = size - 1

	# Peek at last byte: strip trailing newline (added by echo/editors)
	mov %r12, %rdi
	mov %r15, %rsi
	mov $0, %rdx
	call fseek
	mov %r12, %rdi
	call fgetc
	cmp $10, %eax          # '\n' == 10
	jne loop_cmp
	dec %r15               # skip trailing newline

loop_cmp:
	# FIX: was "cmp %r14, %r15; jge" which checks r15>=r14 (always true at start).
	# Correct: jump to is_pal when l (r14) >= r (r15), i.e., pointers have crossed.
	cmp %r15, %r14         # compute r14 - r15
	jge is_pal             # if r14 >= r15, done — it's a palindrome

	# Read left char (index r14)
	mov %r12, %rdi
	mov %r14, %rsi
	mov $0, %rdx
	call fseek
	mov %r12, %rdi
	call fgetc
	mov %eax, %ebx         # save left char (ebx is callee-saved, safe across calls)

	# Read right char (index r15)
	mov %r12, %rdi
	mov %r15, %rsi
	mov $0, %rdx
	call fseek
	mov %r12, %rdi
	call fgetc

	cmp %eax, %ebx         # compare left vs right
	jne not_pal

	inc %r14
	dec %r15
	jmp loop_cmp

is_pal:
	lea yes(%rip), %rdi
	xor %eax, %eax
	call printf
	jmp end

not_pal:
	lea no(%rip), %rdi
	xor %eax, %eax
	call printf

end:
	mov $0, %eax
	leave
	ret
