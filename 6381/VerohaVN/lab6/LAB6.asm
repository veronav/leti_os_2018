CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACKSEG
START: JMP BEGIN
;---------------------------------------
; �������� ����������, ���������� ������.
PRINT PROC near
	push ax
	mov AH,09h
	int 21h
	pop ax
	ret
PRINT ENDP

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX 
	pop CX 
	ret
BYTE_TO_HEX ENDP

; ������� ������������ ������ ������
CLEARMEMORY PROC
	; ��������� � BX ����������� ���������� ������ ��� ���� ��������� � ����������
		mov ax,STACKSEG ; � ax ���������� ����� �����
		mov bx,es
		sub ax,bx ; �������� ���������� ����� PSP
		add ax,10h ; ���������� ������ ����� � ����������
		mov bx,ax
	; ������� ���������� ������ ������
		mov ah,4Ah
		int 21h
		jnc CLEARMEMORY_SUCCESS
	
	; ��������� ������
		mov dx,offset ERR_CLEARMEMORY
		call PRINT
		cmp ax,7
		mov dx,offset ERR_MCB_DESTROYED
		je CLEARMEMORY_PRINT
		cmp ax,8
		mov dx,offset ERR_FEW
		je CLEARMEMORY_PRINT
		cmp ax,9
		mov dx,offset ERR_WRONG_ADDR
		
		CLEARMEMORY_PRINT:
		call PRINT
		mov dx,offset STRENDL
		call PRINT
	
	; ����� � DOS
		xor AL,AL
		mov AH,4Ch
		int 21H
	
	CLEARMEMORY_SUCCESS:
	ret
CLEARMEMORY ENDP

; ������� �������� ����� ����������
PARAMETERS_BLOCK PROC
	mov ax, es:[2Ch]
	mov PARAMETERSBLOCK,ax ; ����� ���������� ����� �����
	mov PARAMETERSBLOCK+2,es ; ���������� ����� ���������� ��������� ������(PSP)
	mov PARAMETERSBLOCK+4,80h ; �������� ���������� ��������� ������
	ret
PARAMETERS_BLOCK ENDP

; ������� ������� ��������� ��������
CHILD_PROCESS PROC
	mov dx,offset STRENDL
	call PRINT
	; ������������� DS:DX �� ��� ���������� ���������
		
		mov dx,offset STD_CHILD_PATH
		; �������, ���� �� �����
		xor ch,ch
		mov cl,es:[80h]
		cmp cx,0
		je CHILD_PROCESS_NO_TAIL ; ���� ��� ������, �� ���������� ����������� ��� ���������� ���������
		mov si,cx ; si - ����� ����������� �������
		push si ; ��������� ���-�� ��������
		CHILD_PROCESS_CYCLE:
			mov al,es:[81h+si]
			mov [offset CHILD_PATH+si-1],al			
			dec si
		loop CHILD_PROCESS_CYCLE
		pop si
		mov [CHILD_PATH+si-1],0 ; ����� � ����� 0
		mov dx,offset CHILD_PATH ; ����� ����, ���������� ���
		CHILD_PROCESS_NO_TAIL:
		
	; ������������� ES:BX �� ���� ����������
		push ds
		pop es
		mov bx,offset PARAMETERSBLOCK

	; ��������� SS, SP
		mov KEEP_SP, SP
		mov KEEP_SS, SS
	
	; �������� ���������:
		mov ax,4b00h
		int 21h
		jnc CHILD_PROCESS_SUCCESS
	
	; ��������������� DS, SS, SP
		push ax
		mov ax,DATA
		mov ds,ax
		pop ax
		mov SS,KEEP_SS
		mov SP,KEEP_SP
	
	; ������������ ������:
		cmp ax,1
		mov dx,offset ERR_WRONG_FUNCNUM
		je CHILD_PROCESS_PRINT
		cmp ax,2
		mov dx,offset ERR_FILE_NOT_FOUND
		je CHILD_PROCESS_PRINT
		cmp ax,5
		mov dx,offset ERR_DISK
		je CHILD_PROCESS_PRINT
		cmp ax,8
		mov dx,offset ERR_FEW2
		je CHILD_PROCESS_PRINT
		cmp ax,10
		mov dx,offset ERR_WRONG_ENVIRON_STR
		je CHILD_PROCESS_PRINT
		cmp ax,11
		mov dx,offset ERR_WRONG_FORMAT
		CHILD_PROCESS_PRINT:
		call PRINT
		mov dx,offset STRENDL
		call PRINT
	
	; ������� � DOS
		xor AL,AL
		mov AH,4Ch
		int 21H
		
	CHILD_PROCESS_SUCCESS:
	mov dx,offset STRENDL
	call PRINT
	mov ax,4d00h
	int 21h
	; ����� ������� ����������
		cmp ah,0
		mov dx,offset NORMAL_COMPLETION
		je CHILD_PROCESS_PRINT_REASON
		cmp ah,1
		mov dx,offset CTRL_BREAK
		je CHILD_PROCESS_PRINT_REASON
		cmp ah,2
		mov dx,offset DEVICE_ERROR
		je CHILD_PROCESS_PRINT_REASON
		cmp ah,3
		mov dx,offset RESIDENT_END
		CHILD_PROCESS_PRINT_REASON:
		call PRINT
		mov dx,offset STRENDL
		call PRINT

	; ����� ���� ����������:
		mov dx,offset END_CODE
		call PRINT
		call BYTE_TO_HEX
		push ax
		mov ah,02h
		mov dl,al
		int 21h
		pop ax
		xchg ah,al
		mov ah,02h
		mov dl,al
		int 21h
		mov dx,offset STRENDL
		call PRINT

	ret
CHILD_PROCESS ENDP

BEGIN:
	mov ax,data
	mov ds,ax
	
	call CLEARMEMORY
	call PARAMETERS_BLOCK
	call CHILD_PROCESS
	
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS

DATA SEGMENT
	; ������ ������:
	ERR_CLEARMEMORY	 	db 'Error with clear memory: $'
	ERR_MCB_DESTROYED 	db 'MCB is destroyed$'
	ERR_FEW 			db 'Not enough memory$'
	ERR_WRONG_ADDR 		db 'Wrong addres$'
		
	; ������ �� ���������� OS
	ERR_WRONG_FUNCNUM		db 'Function number is wrong$'
	ERR_FILE_NOT_FOUND		db 'File is not found$'
	ERR_DISK				db 'Disk error$'
	ERR_FEW2				db 'Not enough memory$'
	ERR_WRONG_ENVIRON_STR	db 'Wrong environment string$'
	ERR_WRONG_FORMAT		db 'Wrong format$'
	; ������, ���������� ������� ���������� �������� ���������
	NORMAL_COMPLETION	db 'Normal completion$'
	CTRL_BREAK			db 'End Ctrl-Break$'
	DEVICE_ERROR		db 'End device error$'
	RESIDENT_END		db 'End 31h function$'
	END_CODE			db 'End code: $'

	STRENDL db 0DH,0AH,'$'
	; ���� ����������. ����� ��������� �������� ��������� �� ���� ������ ��������� ES:BX
	PARAMETERSBLOCK 	dw 0 ; ���������� ����� �����
						dd ? ; ���������� ����� � �������� ���������� ��������� ������
						dd 0 ; ������� � �������� ������� FCB
						dd 0 ; �������
	
	CHILD_PATH  	db 50h dup ('$')
	STD_CHILD_PATH	db 'L2.EXE',0
	; ���������� ��� �������� SS, SP
	KEEP_SS dw 0
	KEEP_SP dw 0
DATA ENDS

STACKSEG SEGMENT STACK
	dw 80h dup (?) ; 100h ����
STACKSEG ENDS
 END START