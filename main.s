	.file	"main.c"
	.text
	.globl	main
	.type	main, @function
main:
	movl	$69, %eax
	ret
	.size	main, .-main
	.ident	"GCC: (GNU) 15.2.1 20260209"
	.section	.note.GNU-stack,"",@progbits
