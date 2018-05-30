STACK SEGMENT STACK
	DW 64 DUP (?)
STACK ENDS
;---------------------------------------------------------------
DATA SEGMENT
ParameterBlock dw ? ;сегментный адрес среды
	dd ? ;сегмент и смещение командной строки
	dd ? ;сегмент и смещение первого FCB
	dd ? ;сегмент и смещение второго FCB
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
;ПРОЦЕДУРЫ
;---------------------------------------------------------------
PRINT PROC NEAR ;печать на экран 
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
;--------------------------------------------------------------------------------
TETR_TO_HEX		PROC near ;половина байт AL переводится в символ шестнадцатиричного числа в AL
		and		al, 0Fh ;and 00001111 - оставляем только вторую половину al
		cmp		al, 09 ;если больше 9, то надо переводить в букву
		jbe		NEXT ;выполняет короткий переход, если первый операнд МЕНЬШЕ или РАВЕН второму операнду
		add		al, 07 ;дополняем код до буквы
	NEXT:	add		al, 30h ;16-ричный код буквы или цифры в al
		ret
TETR_TO_HEX		ENDP
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC near ;байт AL переводится в два символа шестнадцатиричного числа в AX
		push	cx
		mov		ah, al ;копируем al в ah
		call	TETR_TO_HEX ;переводим al в символ 16-рич.
		xchg	al, ah ;меняем местами al и  ah
		mov		cl, 4 
		shr		al, cl ;cдвиг всех битов al вправо на 4
		call	TETR_TO_HEX ;переводим al в символ 16-рич.
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;---------------------------------------------------------------
FreeSpaceInMemory PROC ;подготовка и освобождение места в памяти 
	;перед вызовом функции надо определить объём памяти, необходимый программе ЛР6 
	;и задать в регистре BX число параграфов, которые будут выделяться прграмме
	mov bx,offset LAST_BYTE ;кладём в ax адрес конца программы
	mov ax,es ;es-начало
	sub bx,ax ;bx=Размер=Конец-начало
	mov cl,4h
	shr bx,cl ;переводим в параграфы
	;освобождаем место в памяти
	mov ah,4Ah ;функция позволяет уменьшить отведённый программе блок памяти
	int 21h
	jnc NO_ERROR ;CF=0 - если нет ошибки
	
	;oбработка ошибок CF=1 AX = код ошибки если CF установлен 
	cmp ax,7 ;разрушен управляющий блок памяти
	mov dx,offset Mem_7
	je YES_ERROR
	cmp ax,8 ;недостаточно памяти для выполнения функции
	mov dx,offset Mem_8
	je YES_ERROR
	cmp ax,9 ;неверный адрес блока памяти
	mov dx,offset Mem_9
	
YES_ERROR:
	call PRINT ;выводим ошибку на экран
	xor al,al
	mov ah,4Ch
	int 21H
NO_ERROR:
	ret
FreeSpaceInMemory ENDP
;---------------------------------------------------------------
CreateBlockOfParameter PROC ;заполнение блока параметров
	mov ax, es
	mov ParameterBlock,0 ;сегментный адрес среды
	mov ParameterBlock+2, ax ;сегмент командной строки
	mov ParameterBlock+4, 80h ;смещение командной строки
	mov ParameterBlock+6, ax ;сегмент первого FCB
	mov ParameterBlock+8, 5Ch ;смещение первого FCB
	mov ParameterBlock+10, ax ;сегмент второго FCB
	mov ParameterBlock+12, 6Ch ;смещение второго FCB
	ret
CreateBlockOfParameter ENDP
;---------------------------------------------------------------
Calling PROC 
	
	
;-----------------------------------------	
	
	mov es, es:[2Ch]; сегментный адрес среды, передаваемый программе
	mov si, 0
env:
	mov dl, es:[si]
	cmp dl, 00h		; конец строки?
	je EOL_	
	inc si
	jmp env
EOL_:
	inc si
	mov dl, es:[si]
	cmp dl, 00h		;конец среды?
	jne env
	
	add si, 03h	; si указывает на начало маршрута	
	
	push di
	lea di, PATH
path_:
	mov dl, es:[si]
	cmp dl, 00h		;конец маршрута?
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
	;сохраняем содержимое регистров SS и SP в переменных
	mov KEEP_SP, SP
	mov KEEP_SS, SS
	
	;на блок параметров перед загрузкой вызываемой программы должны указывать ES:BX
	push ds
	pop es ;es - сегмент данных
	mov bx,offset ParameterBlock
	
	;подготовить строку, содержащую путь и имя вызываемой программы
	;на подготовленную строку должны указазывать DS:DX
	mov dx,offset PATH
	
	;вызываем загрузчик OS
	mov ax,4B00h
	int 21h
	jnc IS_LOADED ;если вызываемая программа не была загружена, 
	;то устанавливается флаг переноса CF=1 и в AX заносится код ошибки
	
	;восстанавление DS, SS, SP
	push ax
	mov ax,DATA
	mov ds,ax
	pop ax
	mov SS,KEEP_SS
	mov SP,KEEP_SP
	
	;обработка ошибок
	cmp ax,1 ;если номер функции неверен
	mov dx,offset Err_1
	je EXIT1
	cmp ax,2 ;если файл не найден
	mov dx,offset Err_2
	je EXIT1
	cmp ax,5 ;при ошибке диска
	mov dx,offset Err_5
	je EXIT1
	cmp ax,8 ;при недостаточном объёме памяти
	mov dx,offset Err_8
	je EXIT1
	cmp ax,10 ;при неправильной строке среды
	mov dx,offset Err_10
	je EXIT1
	cmp ax,11 ;если неверен формат
	mov dx,offset Err_11
	
EXIT1:
	call PRINT
	
	;выходим в DOS
	xor al,al
	mov ah,4Ch
	int 21h
		
IS_LOADED: ;если CF=0, то вызываемая программа выполнена
	mov ax,4d00h ;в AH - причина, в AL - код завершения
	int 21h
	
	;обработка завершения программы
	cmp ah,0 ;нормальное завершение
	mov dx,offset End_0
	je EXIT2
	cmp ah,1 ;завершение по Ctrl-Break
	mov dx,offset End_1
	je EXIT2
	cmp ah,2 ;завершение по ошибке устройства
	mov dx,offset End_2
	je EXIT2
	cmp ah,3 ;завершение по функции 31h, оставляющей программу резидентной
	mov dx,offset End_3

EXIT2:
	call PRINT

	;выводим код завершения на экран
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
	mov ah,4Ch ;выход 
	int 21h
LAST_BYTE:
	CODE ENDS
	END START