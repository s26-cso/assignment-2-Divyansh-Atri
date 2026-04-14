.global make_node
.global insert
.global get
.global getAtMost
.extern malloc

.section .text

# Node* make_node(int val)
make_node:
	push %rbp
	mov %rsp, %rbp
	push %rdi

	mov $24, %rdi
	call malloc

	pop %rdi
	test %rax, %rax
	je .mn_ret

	mov %edi, (%rax)
	movq $0, 8(%rax)
	movq $0, 16(%rax)

.mn_ret:
	leave
	ret

# Node* insert(Node* root, int val)
insert:
	test %rdi, %rdi
	jne .ins_recur
	push %rsi
	mov %esi, %edi
	call make_node
	pop %rsi
	ret

.ins_recur:
	mov (%rdi), %eax
	cmp %esi, %eax
	jg .go_left
	jl .go_right
	mov %rdi, %rax
	ret

.go_left:
	push %rdi
	mov 8(%rdi), %rdi
	call insert
	
	pop %rdi
	mov %rax, 8(%rdi)
	mov %rdi, %rax
	ret

.go_right:
	push %rdi
	mov 16(%rdi), %rdi
	call insert
	pop %rdi
	mov %rax, 16(%rdi)
	mov %rdi, %rax
	ret

# Node* get(Node* root, int val)
get:
.loop_get:
	test %rdi, %rdi
	je .not_found
	mov (%rdi), %eax
	cmp %esi, %eax
	je .found
	jg .left_get
	mov 16(%rdi), %rdi
	jmp .loop_get
.left_get:
	mov 8(%rdi), %rdi
	jmp .loop_get
.found:
	mov %rdi, %rax
	ret
.not_found:
	xor %rax, %rax
	ret

# int getAtMost(int val, Node* root)
# rdi = val, rsi = root
getAtMost:
	mov $-1, %eax
.loop_gam:
	test %rsi, %rsi
	je .done_gam

	mov (%rsi), %edx
	cmp %edi, %edx
	jg .left_gam

	mov %edx, %eax
	mov 16(%rsi), %rsi
	jmp .loop_gam

.left_gam:
	mov 8(%rsi), %rsi
	jmp .loop_gam

.done_gam:
	ret
