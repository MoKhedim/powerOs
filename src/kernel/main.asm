org 0x0
bits 16

%define ENDL 0x0D, 0x0A

start:
	mov si, msg_hello
	call puts

.halt:
	cli
	hlt


puts:
	;save registers we will modify
	push si
	push ax
	push bx
	
.loop:
	lodsb ;loads next character in al
	or al, al ;verify if next char is null
	jz .done

	mov ah, 0x0e ;set ah to 0e
	mov bh, 0 ;set page number to 0
	int 0x10
	
	jmp .loop
	

.done:
	pop bx
	pop ax
	pop si
	ret

msg_hello: db 'Hello world from Kernel!', ENDL, 0
