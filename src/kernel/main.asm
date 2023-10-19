org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start:
	jmp main

;print function
;Params:
;	-ds:si points to string
;	
puts:
	;save registers we will modify
	push si
	push ax
	
.loop:
	lodsb ;loads next character in al
	or al, al ;verify if next char is null
	jz .done

	mov ah, 0x0e ;set ah to 0e
	mov bh, 0 ;set page number to 0
	int 0x10
	
	jmp .loop
	

.done:
	pop ax
	pop si
	ret

main:
	;setup data segments
	mov ax, 0 ;cant write ds or es directly
	mov ds, ax
	mov es, ax

	;setup stack
	mov ss, ax
	mov sp, 0x7C00

	;PRINT MSG
	mov si, msg_hello
	call puts

	hlt

.halt:
	jmp .halt

msg_hello: db 'Hello world!', ENDL, 0


times 510-($-$$) db 0
dw 0AA55h
