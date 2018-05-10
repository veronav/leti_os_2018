 DATA segment
    PSP	dw 	?
    path db 100 dup (?)
    dta db 43 dup (?)	
    overlay dw 0
    epb dw ?
    _ss dw ?
    _sp dw ?
    counter db 0
    way_file db 'Way: $'
    way_overlay db 'The segment address of the overlay file: $'
    error1_3 db 'No file.$'
    error2 db 'Route is found.$'
    error db 'Error! $'
	STRTEST db 'TEST'
    NewLine db 13, 10, '$'    
  DATA ends
;------------------------------------------------------------------  
  stack segment
    db 256 dup(0)
  stack ends
;------------------------------------------------------------------  
  code segment 
    assume ds:DATA, ss:stack, cs:code, es:nothing
;------------------------------------------------------------------ 
start:
    jmp begin
;вывод строки

output proc near
    push ax
    push dx
    mov ah, 09h
    int 21h
    pop dx
    pop ax
    ret
   output endp
;-------------------------------------------------------------------
;перевод строки   
   
endl proc near
    lea dx, NewLine
    call output
    ret
   endl endp
;-------------------------------------------------------------------
begin:
    
	mov ax, DATA
	mov ds, ax
	mov PSP, es
	
	mov ax, es:[2ch]
	mov es, ax

	mov si, 0
	mov cl, es:[si]	
	mov di, 0
	
m1:	cmp cl, 0
	je m2
	inc si
	mov cl, es:[si]
	jmp m1
	 
m2:	inc si
	mov cl, es:[si]
	cmp cl, 0
	jne m1 
	inc si
	inc si
	inc si
	mov cl, es:[si] 
	mov byte ptr [path+di], cl

m3:	inc si
	inc di
	mov cl, es:[si]
	mov byte ptr [path+di], cl
	cmp cl, 0
	jne m3
	
m4: dec di
	cmp byte ptr [path+di], '\'
	jne m4
	mov cl, es:[di]
	mov byte ptr [path+di], '\'
	inc di
	push di
	mov byte ptr [path+di], 'o'
	inc si
	inc di
	mov byte ptr [path+di], 'v'
	inc si
	inc di
	mov byte ptr [path+di], 'l'
	inc si
	inc di
	mov byte ptr [path+di], '_'
	inc si
	inc di
	mov byte ptr [path+di], '1'
	inc si
	inc di
	mov byte ptr [path+di], '.'
	inc si
	inc di
	mov byte ptr [path+di], 'c'
	inc si
	inc di
	mov byte ptr [path+di], 'o'
	inc si
	inc di
	mov byte ptr [path+di], 'm'
	inc si
	inc di
	mov byte ptr [path+di], 0h
	inc si
	inc di
	mov byte ptr [path+di], '$'
	
	call endl
	lea dx, way_file
	call output
	lea dx, path
	call output
	
	mov ah, 02h
	mov dl, 0dh
	int 21h
	mov dl, 0ah
	int 21h
	
	mov ax, PSP
	mov es, ax
	lea bx, last_byte
	mov cl,4
	shr bx,cl  
	add bx, 1
	add bx, code
	add bx, DATA
	add bx, 30h
	mov ah, 4ah
	int 21h ;изменения блока выделенной памяти
	
	lea dx, dta 
	mov ah, 1ah
	int 21h ;устанавливаем адрес для DTA
	
file2:		
	lea dx, path
	mov ah, 4eh
	mov cx, 0h
	int 21h 
	
;проверка флага на ошибки
	jnc end_c ;если нет ошибок идем дальше в путь 
	lea dx, error
	call output
	cmp ax, 2 ;если ошибка 2
	jne e1 ;идем дальше если не ошибка 2
	lea dx, error1_3
	call output
	jmp exit

e1:	cmp ax, 3 ;если ошибка 3
	jne e2 ;идем дальше если не ошибка 3
	lea dx, error2
	call output
	jmp exit

e2:	cmp ax, 18
	jne skip
	lea dx, error1_3
	call output
skip:
	jmp exit
		
end_c: 		
	mov bx, word ptr [ offset dta + 1ah ] ;вычисление  размера оверлея
	mov cl,4
	shr bx,cl
	inc bx ;
	
	mov ah, 48h 
	int 21h
	mov epb, ax 
	mov ax, ds 
	mov es, ax 
	lea bx, epb
	lea dx, path
	mov _sp, sp
	mov _ss, ss
	
	mov ax, 4b03h
	int 21h			
	
	mov ax, DATA
	mov ds, ax
	mov ss, _ss
	mov sp, _sp
	
	lea dx, way_overlay
	call output
	
	push ds	
	call dword ptr overlay
	call endl
	pop ds
	
	mov ax, epb
	mov es, ax
	mov ah, 49h
	int 21h	;освобождение памяти
	
	mov al, counter
	cmp al, 1
	je exit
	mov ah, 02h
	mov dl, 0dh
	int 21h
	mov dl, 0ah
	int 21h
	mov di, 0
	
go12:
	pop di
	mov [path+di], 'o'
	inc si
	inc di
	mov [path+di], 'v'
	inc si
	inc di
	mov [path+di], 'l'
	inc si
	inc di
	mov [path+di], '_'
	inc si
	inc di
	mov [path+di], '2'
	inc si
	inc di
	mov [path+di], '.'
	inc si
	inc di
	mov [path+di], 'c'
	inc si
	inc di
	mov [path+di], 'o'
	inc si
	inc di
	mov [path+di], 'm'
	inc si
	inc di
	;inc di
	mov [path+di], 0h
	inc si
	inc di
	mov [path+di], '$'
	mov al, 1
	mov counter, al
	lea dx, way_file
	call output
	lea dx, path
	call output
	mov ah, 02h
	mov dl, 0dh
	int 21h
	mov dl, 0ah
	int 21h
	jmp file2
;-----------------------------------------------------------------	
;Выход в DOS
exit:
	xor al, al
	mov ah, 4ch
	int 21h
last_byte:	
  code ends
    end start
