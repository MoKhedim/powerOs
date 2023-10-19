org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;
;FAT12 header
;
jmp short start
nop
bdb_oem:							db 'MSWIN4.1'    ;8 bytes
bdb_bytes_per_sector: 				dw 512
bdb_sectors_per_clusters:			db 1
bdb_reserved_sectors:				dw 1
bdb_fat_count:						db 2
bdb_dir_entries_count:				dw 0E0h
bdb_total_sectors:					dw 2880			;2880 * 512 = 1.4MB
bdb_media_descriptor_type:			db 0F0h			;F0= 3.5 inch floppy disk
bdb_sectors_per_fat:				dw 9
bdb_sectors_per_track:				dw 18
bdb_heads:							dw 2
bdb_hidden_sectors:					dd 0
bdb_hidden_sector_count:			dd 0

; extended boot record
ebr_drive_number:					db 0 			;0x00 = floppy, 0x80 = hdd
									db 0 			;signature
ebr_signature:						db 29h
ebr_volume_id:						db 12h, 34h, 56h, 78h	;derial number
ebr_volume_label:					db 'POWER OS  '		;11 bytes padded spaces
ebr_system_id:						db 'FAT12   '		;8 bytes padded spaces


;
;CODE
;
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

	;Read smth from floppy
	;BIOS SHOULD SET DL TO DRIVE NMBR
	mov [ebr_drive_number], dl
	mov ax, 1
	mov cl, 1
	mov bx, 0x7E00
	call disk_read
	
	;PRINT MSG
	mov si, msg_hello
	call puts

	hlt

floppy_error:
	mov si, msg_read_failed
	call puts
	jmp wait_key_and_reboot
	
wait_key_and_reboot:
	mov ah, 0
	int 16h
	jmp 0FFFFh:0
	
.halt:
	cli
	hlt


;
;Disk routine
;

;
;Convert LBA adress to CHS address
;Parameters:
;	- ax: LBA adress
;Returns:
;	- cx [bits 0-5]: sector number
;	- cx [6-15]: cylinder
;	- dh: head


lba_to_chs:

	push ax
	push dx

	xor dx,dx							;dx = 0
	div word [bdb_sectors_per_track]	;ax = LBA / SectorsPerTrack
										;dx = LBA %  SectorsPerTrack
	inc dx								;dx =(LBA %  SectorsPerTrack + 1) = sector
	mov cx, dx							;cx = sector

	xor dx,dx							;dx = 0
	div word [bdb_heads]				;ax = (LBA / SectorsPerTrack) / Heads = cylinder
										;dx = (LBA / SectorsPerTrack) %  Heads = head
	mov dh, dl							;dh = head
	mov ch, al							;ch = cylinder
	shl ah, 6							
	or cl, ah							; put upper 2 bits of cylinder in CL

	pop ax
	mov dl,al
	pop ax
	ret


;
;Reads sector from a disk
;Parameters:
;	- ax: LBA address
;	- cl: nmb of sectors to read [up to 128]
;	- dl: drive number
;	- es:bx: memory adress where to store read data
;
disk_read:

	push ax
	push bx
	push cx
	push dx
	push di
	
	push cx							   ;temp save CL (Nbrs of sectors to read)
	call lba_to_chs					   ;compute CHS
	pop ax							   ;AL = nmbrs of sectors to read
	mov ah, 02h
	mov di, 3						   ;retry count

.retry:
	pusha
	stc
	int 13h
	jnc .done
	;Failed
	popa
	call disk_reset
	
	dec di
	test di, di
	jnz .retry

.fail:
	;After all attempts are kaput
	jmp floppy_error
	
.done:
	popa

	push di
	push dx
	push cx
	push bx
	push ax
	ret
;
;Reset disk cotroller
;Parameters:
;	dl: drive number
;
disk_reset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc floppy_error
	popa
	ret

		
msg_hello: db 'Hello world!', ENDL, 0
msg_read_failed: db 'Read from disk failed sadge', ENDL, 0


times 510-($-$$) db 0
dw 0AA55h
