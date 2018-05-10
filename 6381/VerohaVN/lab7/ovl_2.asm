CODE_OVL_2 segment
  assume cs:CODE_OVL_2, ds:CODE_OVL_2, ss:nothing, es:nothing 

OVERLAY_FUNC proc far
	push ds
	sub dx, dx
	mov ax, cs
	mov bx, 10h
	mov cx, 4

@SGT:div bx
	push dx
	sub dx, dx
	loop @SGT
	mov cx, 4
	
@printer:
	pop dx
	cmp dl, 09h
	jbe @add
	add dl, 07h
	
@add:  
	add dl, 30h
	mov ah, 02h
	int 21h
	loop @printer
	pop ds
	push ds
	pop ds
	retf	
OVERLAY_FUNC ENDP

CODE_OVL_2 ENDS
END