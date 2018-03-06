ASSUME CS:CODE, DS:DATA, SS:MY_STACK
;------------------------------------
MY_STACK SEGMENT STACK 
	DW 64 DUP(?)
MY_STACK ENDS
;------------------------------------
CODE SEGMENT
;------------------------------------
INTERRUPTION PROC FAR
	jmp FUNC_FOR_START
	
	;TMP DATA
	PSP_ADDRESS_0 dw 0                            ;offset - 3
	PSP_ADDRESS_1 dw 0	                          ;offset - 5
	KEEP_CS dw 0                                  ;offset - 7
	KEEP_IP dw 0                                  ;offset - 9
	INTERRUPTION_SET dw 0FEDCh                 ;offset - 11
	INT_COUNT db 'Interrupts call count: 0000  $' ;offset - 13

FUNC_FOR_START:
	push ax      
	push bx
	push cx
	push dx

	mov ah, 03h
	mov bh, 00h
	int 10h
	push dx 
	
	mov ah, 02h
	mov bh, 00h
	mov dx, 0220h
	int 10h

	push si
	push cx
	push ds
	mov ax, SEG INT_COUNT
	mov ds, ax
	mov si, offset INT_COUNT
	add si, 1Ah

	mov ah,[si]
	inc ah
	mov [si], ah
	cmp ah, 3Ah
	jne END_CALC
	mov ah, 30h
	mov [si], ah	

	mov bh, [si - 1] 
	inc bh
	mov [si - 1], bh
	cmp bh, 3Ah                    
	jne END_CALC
	mov bh, 30h
	mov [si - 1], bh

	mov ch, [si - 2]
	inc ch
	mov [si - 2], ch
	cmp ch, 3Ah
	jne END_CALC
	mov ch, 30h
	mov [si - 2], ch

	mov dh, [si - 3]
	inc dh
	mov [si - 3], dh
	cmp dh, 3Ah
	jne END_CALC
	mov dh, 30h
	mov [si - 3],dh
	
END_CALC:
    pop ds
    pop cx
	pop si
	
	push es
		push bp
			mov ax, SEG INT_COUNT
			mov es, ax
			mov ax, offset INT_COUNT
			mov bp, ax
			mov ah, 13h
			mov al, 00h
			mov cx, 1Dh
			mov bh, 0
			int 10h
		pop bp
	pop es
	
	pop dx
	mov ah, 02h
	mov bh, 0h
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax     

	iret
INTERRUPTION ENDP
;------------------------------------
NEED_MEM_AREA PROC
NEED_MEM_AREA ENDP
;------------------------------------
IS_INTERRUPTION_SET PROC NEAR
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 0FEDCh
	je INT_IS_SET
	mov al, 00h
	jmp POP_REG

INT_IS_SET:
	mov al, 01h
	jmp POP_REG

POP_REG:
	pop es
	pop dx
	pop bx

	ret
IS_INTERRUPTION_SET ENDP
;------------------------------------
CHECK_COMMAND_PROMT PROC NEAR
	push es
	
	mov ax, PSP_ADDRESS_0
	mov es, ax

	mov bx, 0082h

	mov al, es:[bx]
	inc bx
	cmp al, '/'
	jne NULL_CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'u'
	jne NULL_CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'n'
	jne NULL_CMD

	mov al, 0001h
NULL_CMD:
	pop es

	ret
CHECK_COMMAND_PROMT ENDP
;------------------------------------
LOAD_INTERRUPTION PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov KEEP_IP, bx
	mov KEEP_CS, es

	push ds
		mov dx, offset INTERRUPTION
		mov ax, seg INTERRUPTION
		mov ds, ax

		mov ah, 25h
		mov al, 1Ch
		int 21h
	pop ds

	mov dx, offset M_INT_ISLOADED0
	call PRINT_STRING

	pop es
	pop dx
	pop bx
	pop ax

	ret
LOAD_INTERRUPTION ENDP
;------------------------------------
UNLOAD_INTERRUPTION PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	cli
	push ds            
		mov dx, es:[bx + 9]   
		mov ax, es:[bx + 7]   
		
		mov ds, ax
		mov ah, 25h
		mov al, 1Ch
		int 21h
	pop ds
	sti

	mov dx, offset M_INT_RESTORED
	call PRINT_STRING

	push es	
		mov cx, es:[bx + 3]
		mov es, cx
		mov ah, 49h
		int 21h
	pop es
	
	mov cx, es:[bx + 5]
	mov es, cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	
	ret
UNLOAD_INTERRUPTION ENDP
;------------------------------------
PRINT_STRING PROC NEAR
	push ax
	mov ah, 09h
	int	21h
	pop ax
	ret
PRINT_STRING ENDP
;------------------------------------
MAIN_PROGRAM PROC FAR
	mov bx, 02Ch
	mov ax, [bx]
	mov PSP_ADDRESS_1, ax
	mov PSP_ADDRESS_0, ds  
	sub ax, ax    
	xor bx, bx

	mov ax, DATA  
	mov ds, ax    

	call CHECK_COMMAND_PROMT   ;Загрузка или выгрузка(проверка параметра)
	cmp al, 01h
	je UNLOAD_START

	call IS_INTERRUPTION_SET   ;Установлен ли разработанный вектор прерывания
	cmp al, 01h
	jne INTERRUPTI0N_IS_NOT_LOADED
	
	mov dx, offset M_INT_ISLOADED	;Уже установлен(выход с сообщение)
	call PRINT_STRING
	jmp EXIT_PROGRAM
       
	mov ah,4Ch
	int 21h

INTERRUPTI0N_IS_NOT_LOADED:
	call LOAD_INTERRUPTION
	
	mov dx, offset NEED_MEM_AREA
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh

	mov ax, 3100h
	int 21h
         
UNLOAD_START:
	call IS_INTERRUPTION_SET
	cmp al, 00h
	je INT_IS_NOT_SET
	call UNLOAD_INTERRUPTION
	jmp EXIT_PROGRAM

INT_IS_NOT_SET:
	mov dx, offset M_INT_NOT_SET
	call PRINT_STRING
    jmp EXIT_PROGRAM
	
EXIT_PROGRAM:
	mov ah, 4Ch
	int 21h
MAIN_PROGRAM ENDP
;------------------------------------
CODE ENDS
;------------------------------------
DATA SEGMENT
	;messages
	M_INT_NOT_SET db "Interruption didnt load!", 0dh, 0ah, '$'
	M_INT_RESTORED db "Interruption was restored!", 0dh, 0ah, '$'
	M_INT_ISLOADED db "Interruption already load!", 0dh, 0ah, '$'
	M_INT_ISLOADED0 db "Interuption is loading now!", 0dh, 0ah, '$'
DATA ENDS
;------------------------------------
END MAIN_PROGRAM