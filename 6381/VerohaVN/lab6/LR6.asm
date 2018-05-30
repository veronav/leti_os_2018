STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;---------------------------------------------------------------
DATA SEGMENT
ParameterBlock dw ? ;���������� ����� �����
	dd ? ;������� � �������� ��������� ������
	dd ? ;������� � �������� ������� FCB
	dd ? ;������� � �������� ������� FCB
	Mem_7    DB 0DH, 0AH,'Memory control unit destroyed!',0DH,0AH,'$'
	Mem_8    DB 0DH, 0AH,'Not enough memory to perform the function!',0DH,0AH,'$'
	Mem_9    DB 0DH, 0AH,'Wrong address of the memory block!',0DH,0AH,'$'
	Err_1    DB 0DH, 0AH,'The number of function is wrong!',0DH,0AH,'$'
	Err_2    DB 0DH, 0AH,'File not found!',0DH,0AH,'$'
	Err_5    DB 0DH, 0AH,'Disk error!',0DH,0AH,'$'
	Err_8    DB 0DH, 0AH,'Insufficient value of memory!',0DH,0AH,'$'
	Err_10   DB 0DH, 0AH,'Incorrect environment string!',0DH,0AH,'$'
	Err_11   DB 0DH, 0AH,'Wrong format!',0DH,0AH,'$'
	End_0    DB 0DH, 0AH,'Normal termination!',0DH,0AH,'$'
	End_1    DB 0DH, 0AH,'End by Ctrl-Break!',0DH,0AH,'$'
	End_2    DB 0DH, 0AH,'The completion of the device error!',0DH,0AH,'$'
	End_3    DB 0DH, 0AH,'Completion by function 31h!',0DH,0AH,'$'
	PATH 	 DB '                                               ',0DH,0AH,'$',0
	KEEP_SS  DW 0
	KEEP_SP  DW 0
	END_CODE DB 'End code:   ',0DH,0AH,'$'
DATA ENDS
;---------------------------------------------------------------
CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:STACK
START: JMP MAIN
;���������
;---------------------------------------------------------------
PRINT PROC NEAR ;������ �� ����� 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
TETR_TO_HEX		PROC near ;�������� ���� AL ����������� � ������ ������������������ ����� � AL
		and		al, 0Fh ;and 00001111 - ��������� ������ ������ �������� al
		cmp		al, 09 ;���� ������ 9, �� ���� ���������� � �����
		jbe		NEXT ;��������� �������� �������, ���� ������ ������� ������ ��� ����� ������� ��������
		add		al, 07 ;��������� ��� �� �����
	NEXT:	add		al, 30h ;16-������ ��� ����� ��� ����� � al
		ret
TETR_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC near ;���� AL ����������� � ��� ������� ������������������ ����� � AX
		push	cx
		mov		ah, al ;�������� al � ah
		call	TETR_TO_HEX ;��������� al � ������ 16-���.
		xchg	al, ah ;������ ������� al �  ah
		mov		cl, 4 
		shr		al, cl ;c���� ���� ����� al ������ �� 4
		call	TETR_TO_HEX ;��������� al � ������ 16-���.
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;---------------------------------------------------------------
FreeSpaceInMemory PROC ;���������� � ������������ ����� � ������ 
	;����� ������� ������� ���� ���������� ����� ������, ����������� ��������� ��6 
	;� ������ � �������� BX ����� ����������, ������� ����� ���������� ��������
	mov bx,offset LAST_BYTE ;����� � ax ����� ����� ���������
	mov ax,es ;es-������
	sub bx,ax ;bx=������=�����-������
	mov cl,4h
	shr bx,cl ;��������� � ���������
	;����������� ����� � ������
	mov ah,4Ah ;������� ��������� ��������� ��������� ��������� ���� ������
	int 21h
	jnc NO_ERROR ;CF=0 - ���� ��� ������
	
	;o�������� ������ CF=1 AX = ��� ������ ���� CF ���������� 
	cmp ax,7 ;�������� ����������� ���� ������
	mov dx,offset Mem_7
	je YES_ERROR
	cmp ax,8 ;������������ ������ ��� ���������� �������
	mov dx,offset Mem_8
	je YES_ERROR
	cmp ax,9 ;�������� ����� ����� ������
	mov dx,offset Mem_9
	
YES_ERROR:
	call PRINT ;������� ������ �� �����
	xor al,al
	mov ah,4Ch
	int 21H
NO_ERROR:
	ret
FreeSpaceInMemory ENDP
;---------------------------------------------------------------
CreateBlockOfParameter PROC ;���������� ����� ����������
	mov ax, es
	mov ParameterBlock,0 ;���������� ����� �����
	mov ParameterBlock+2, ax ;������� ��������� ������
	mov ParameterBlock+4, 80h ;�������� ��������� ������
	mov ParameterBlock+6, ax ;������� ������� FCB
	mov ParameterBlock+8, 5Ch ;�������� ������� FCB
	mov ParameterBlock+10, ax ;������� ������� FCB
	mov ParameterBlock+12, 6Ch ;�������� ������� FCB
	ret
CreateBlockOfParameter ENDP
;---------------------------------------------------------------
Calling PROC 
	
	
;-----------------------------------------	
	
	mov es, es:[2Ch]; ���������� ����� �����, ������������ ���������
	mov si, 0
env:
	mov dl, es:[si]
	cmp dl, 00h		; ����� ������?
	je EOL_	
	inc si
	jmp env
EOL_:
	inc si
	mov dl, es:[si]
	cmp dl, 00h		;����� �����?
	jne env
	
	add si, 03h	; si ��������� �� ������ ��������	
	
	push di
	lea di, PATH
path_:
	mov dl, es:[si]
	cmp dl, 00h		;����� ��������?
	je EOL2	
	mov [di], dl	
	inc di			
	inc si			
	jmp path_
EOL2:
	sub di, 05h	
	mov [di], byte ptr '2'	
	mov [di+2], byte ptr 'C'
	mov [di+3], byte ptr 'O'
	mov [di+4], byte ptr 'M'
	mov [di+5], byte ptr 0h
	
	pop di
;-----------------------------------------
	;��������� ���������� ��������� SS � SP � ����������
	mov KEEP_SP, SP
	mov KEEP_SS, SS
	
	;�� ���� ���������� ����� ��������� ���������� ��������� ������ ��������� ES:BX
	push ds
	pop es ;es - ������� ������
	mov bx,offset ParameterBlock
	
	;����������� ������, ���������� ���� � ��� ���������� ���������
	;�� �������������� ������ ������ ����������� DS:DX
	mov dx,offset PATH
	
	;�������� ��������� OS
	mov ax,4B00h
	int 21h
	jnc IS_LOADED ;���� ���������� ��������� �� ���� ���������, 
	;�� ��������������� ���� �������� CF=1 � � AX ��������� ��� ������
	
	;�������������� DS, SS, SP
	push ax
	mov ax,DATA
	mov ds,ax
	pop ax
	mov SS,KEEP_SS
	mov SP,KEEP_SP
	
	;��������� ������
	cmp ax,1 ;���� ����� ������� �������
	mov dx,offset Err_1
	je EXIT1
	cmp ax,2 ;���� ���� �� ������
	mov dx,offset Err_2
	je EXIT1
	cmp ax,5 ;��� ������ �����
	mov dx,offset Err_5
	je EXIT1
	cmp ax,8 ;��� ������������� ������ ������
	mov dx,offset Err_8
	je EXIT1
	cmp ax,10 ;��� ������������ ������ �����
	mov dx,offset Err_10
	je EXIT1
	cmp ax,11 ;���� ������� ������
	mov dx,offset Err_11
	
EXIT1:
	call PRINT
	
	;������� � DOS
	xor al,al
	mov ah,4Ch
	int 21h
		
IS_LOADED: ;���� CF=0, �� ���������� ��������� ���������
	mov ax,4d00h ;� AH - �������, � AL - ��� ����������
	int 21h
	
	;��������� ���������� ���������
	cmp ah,0 ;���������� ����������
	mov dx,offset End_0
	je EXIT2
	cmp ah,1 ;���������� �� Ctrl-Break
	mov dx,offset End_1
	je EXIT2
	cmp ah,2 ;���������� �� ������ ����������
	mov dx,offset End_2
	je EXIT2
	cmp ah,3 ;���������� �� ������� 31h, ����������� ��������� �����������
	mov dx,offset End_3

EXIT2:
	call PRINT

	;������� ��� ���������� �� �����
	mov di,offset END_CODE
	call BYTE_TO_HEX
	add di,0Ah
	mov [di],al
	add di,1h
	xchg ah,al
	mov [di],al
	mov dx, offset END_CODE
	call PRINT
	ret
Calling ENDP
;---------------------------------------------------------------
MAIN:
	mov AX,DATA
	mov DS,AX
	call FreeSpaceInMemory 
	call CreateBlockOfParameter
	call Calling
	xor al,al
	mov ah,4Ch ;����� 
	int 21h
LAST_BYTE:
	CODE ENDS
	END START