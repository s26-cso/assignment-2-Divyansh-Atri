# NOTE: GNU x86-64 Linux, AT&T syntax
.global main
.extern printf
.extern atoi
.extern malloc
.extern free

.section .rodata
fmt:
	.string "%d "
newline:
	.string "\n"

.section .text
main:
	push %rbp
	mov %rsp, %rbp
	sub $16, %rsp          # locals: -8(%rbp) = saved stack-array ptr

	# argc in rdi, argv in rsi
	mov %rdi, %r12        # argc  (callee-saved)
	mov %rsi, %r13        # argv  (callee-saved)

	cmp $2, %r12
	jl done

	mov %r12, %rax
	dec %rax              # n = argc-1
	mov %rax, %r14        # r14 = n (callee-saved)

	# allocate arr (r15), res (rbx), nge_stack (r10)
	mov %r14, %rdi
	shl $2, %rdi
	call malloc
	mov %rax, %r15        # arr (callee-saved)

	mov %r14, %rdi
	shl $2, %rdi
	call malloc
	mov %rax, %rbx        # res (callee-saved)

	mov %r14, %rdi
	shl $2, %rdi
	call malloc
	mov %rax, %r10        # nge_stack (caller-saved — must save before atoi calls!)

	# FIX: save r10 (nge_stack ptr) before parse_loop.
	# atoi is a library call that can clobber any caller-saved register (r8–r11,
	# rax, rcx, rdx, rsi, rdi). r10 holds our malloc'd stack pointer and WILL
	# be overwritten. We save it to a local frame slot instead.
	mov %r10, -8(%rbp)

	# parse argv[1..n] into arr; initialise res to -1
	xor %r8, %r8
parse_loop:
	cmp %r14, %r8
	jge nge_start

	mov 8(%r13,%r8,8), %rdi   # argv[i+1]

	# FIX: save r8 (loop counter) around atoi — it is caller-saved and will be
	# clobbered by atoi.  A single push/pop keeps the stack 16-byte aligned
	# (rbp push already moved rsp by 8, sub $16 by 16 → aligned; push adds 8
	# making it 8 mod 16, which is exactly what call expects before pushing rip).
	push %r8
	call atoi
	pop %r8

	mov %eax, (%r15,%r8,4)    # arr[i] = atoi(argv[i+1])
	movl $-1, (%rbx,%r8,4)    # res[i] = -1
	inc %r8
	jmp parse_loop

nge_start:
	# FIX: restore nge_stack ptr that atoi clobbered.
	mov -8(%rbp), %r10

	mov $-1, %r9          # top = -1 (stack empty)
	mov %r14, %r8
	dec %r8               # i = n-1 (process right-to-left)

outer:
	cmp $-1, %r8
	je print_ans

inner:
	cmp $-1, %r9
	je set_result                   # stack empty → no NGE found yet

	mov (%r10,%r9,4), %eax          # eax = stack[top]  (an index)
	mov (%r15,%rax,4), %edx         # edx = arr[stack[top]]
	mov (%r15,%r8,4), %ecx          # ecx = arr[i]
	cmp %ecx, %edx                  # edx - ecx; jg if arr[stack[top]] > arr[i]
	jg set_result                   # found the NGE for element i
	dec %r9                         # arr[stack[top]] <= arr[i]: pop (useless entry)
	jmp inner

set_result:
	cmp $-1, %r9
	je push_stack                   # stack empty → no NGE, leave res[i] = -1

	mov (%r10,%r9,4), %eax          # eax = index of the NGE element
	# FIX: was storing the index.  Must store the actual VALUE.
	mov (%r15,%rax,4), %eax         # eax = arr[index]  = the NGE value
	mov %eax, (%rbx,%r8,4)          # res[i] = NGE value

push_stack:
	inc %r9
	mov %r8d, (%r10,%r9,4)          # push current index i onto nge_stack
	dec %r8
	jmp outer

print_ans:
	xor %r8, %r8
print_loop:
	cmp %r14, %r8
	jge done
	lea fmt(%rip), %rdi
	mov (%rbx,%r8,4), %esi
	xor %eax, %eax
	# FIX: save r8 around printf (variadic; clobbers caller-saved regs including r8).
	push %r8
	call printf
	pop %r8
	inc %r8
	jmp print_loop

done:
	lea newline(%rip), %rdi
	xor %eax, %eax
	call printf
	mov $0, %eax
	leave
	ret
