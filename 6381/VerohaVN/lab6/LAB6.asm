.SEQ    

L6_CODE SEGMENT
        ASSUME CS: L6_CODE, DS: L6_DATA, ES: NOTHING, SS: L6_STACK

START:  jmp l6_start


L6_DATA SEGMENT

        PSP_SIZ = 10h                 
        STK_SIZ = 10h                  

        MEM_ERR db 'Error functions 4AH interruptions 21H, error code:     H.',       0Dh, 0Ah, '$'

        EXE_E01 db 'Start error, code 0001H: Wrong number subfunctions.',              0Dh, 0Ah, '$'
        EXE_E02 db 'Start error, code 0002H: Specified file is not found.',            0Dh, 0Ah, '$'
        EXE_E03 db 'Start error, code 0003H: Specified path does not exist.',          0Dh, 0Ah, '$'
        EXE_E04 db 'Start error, code 0004H: Openly there are too much files.',        0Dh, 0Ah, '$'
        EXE_E05 db 'Start error, code 0005H: File access error.',                      0Dh, 0Ah, '$'
        EXE_E08 db 'Start error, code 0008H: Not enough free memory.',                 0Dh, 0Ah, '$'
        EXE_E0A db 'Start error, code 000AH: Environment block larger than 32 KB.',    0Dh, 0Ah, '$'
        EXE_E0B db 'Start error, code 000BH: Incorrect file format.',                  0Dh, 0Ah, '$'
        EXE_EUN db 'Start error, code     H: < Unknown error code >',                  0Dh, 0Ah, '$'

        TRM_C00 db ' Reason of completion 00H: Normal completion, code:    H.',  0Dh, 0Ah, '$'
        TRM_C01 db 'Reason of completion 01H: Completion with Ctrl-Break.',      0Dh, 0Ah, '$'
        TRM_C02 db 'Reason of completion 02H: Critical device error.',           0Dh, 0Ah, '$'
        TRM_C03 db 'Reason of completion 03H: Resident completion on 31H.',      0Dh, 0Ah, '$'
        TRM_CUN db 'Reason of completion   H: < Unknown point >, code:   H.',    0Dh, 0Ah, '$'

        ENV_SAD dw 00h                  
        CMLN_IP dw offset CMD_LIN      
        CMLN_CS dw seg CMD_LIN         
        FCB1_CI dd 00h                 
        FCB2_CI dd 00h                

        ABS_NAM db 100h dup (?)        
        PR_NAME db 'LAB2.COM', 00h  ; 
        CMD_LIN db 0Ch, ' -safe /help'  

        KEEP_SS dw ?                    
        KEEP_SP dw ?                    

        CHR_EOT = '$'
        INF_CLR = 0Fh
	ERR_CLR = 0Ch
	MSG_CLR = 0Ah

L6_DATA ENDS

L6_STACK SEGMENT STACK
        db STK_SIZ * 10h dup (?)
L6_STACK ENDS

;Процедуры
;__________________________________________

TETR_TO_HEX PROC NEAR
                and     AL, 0Fh
                cmp     AL, 09h
                jbe     NEXT
                add     AL, 07h
NEXT:           add     AL, 30h
                ret
TETR_TO_HEX ENDP

;перевод байта из AL в два символа HEX

BYTE_TO_HEX PROC NEAR
                push    CX
                mov     AH, AL
                call    TETR_TO_HEX
                xchg    AL, AH
                mov     CL, 04h
                shr     AL, CL
                call    TETR_TO_HEX     
                pop     CX              
                ret
BYTE_TO_HEX ENDP

;перевод в HEX слова из AX

WRD_TO_HEX PROC NEAR
                push    AX
                push    BX
                push    DI
                mov     BH, AH
                call    BYTE_TO_HEX
                mov     DS:[DI], AH
                dec     DI
                mov     DS:[DI], AL
                dec     DI
                mov     AL, BH
                call    BYTE_TO_HEX
                mov     DS:[DI], AH
                dec     DI
                mov     DS:[DI], AL
                pop     DI
                pop     BX
                pop     AX
                ret
WRD_TO_HEX ENDP

;вывод текста

PR_STR_BIOS PROC NEAR
                push    AX
                push    BX
                push    CX
                push    DX
                push    DI
                push    ES
                mov     AX, DS
                mov     ES, AX
                mov     AH, 0Fh         
                int     10h             
                mov     AH, 03h         
                int     10h             
                mov     DI, 00h         
dsbp_nxt:       cmp     byte ptr DS:[BP+DI], CHR_EOT 
                je      dsbp_out        
                inc     DI              
                jmp     dsbp_nxt
dsbp_out:       mov     CX, DI          
                mov     AH, 13h         
                mov     AL, 01h         
                int     10h
                pop     ES
                pop     DI
                pop     DX
                pop     CX
                pop     BX
                pop     AX
                ret
PR_STR_BIOS ENDP

;__________________________________________

;Начало работы программы

;Освобождение неиспользуемой памяти


l6_start:       mov     BX, L6_DATA     
                mov     DS, BX          
                mov     BX, L6_STACK    
                add     BX, STK_SIZ     
                sub     BX, L6_CODE     
                add     BX, PSP_SIZ     
                mov     AH, 4Ah         
                int     21h             
                jc      error_4A        
                jmp     prep_nam

; вывод информации об ошибке

error_4A:       lea     DI, MEM_ERR     
                add     DI, 50          
                call    WRD_TO_HEX
                mov     BL, ERR_CLR     
                lea     BP, MEM_ERR
                call    PR_STR_BIOS
                jmp     dos_quit

;подготовка абсолютного имени файла

prep_nam:       push    ES              
                mov     ES, ES:[2Ch]    
                xor     SI, SI          
prep_eel:       cmp     word ptr ES:[SI], 0000h 
                je      prep_lsi        
                inc     SI              
                jmp     prep_eel        
prep_lsi:       add     SI, 04h         
                mov     DI, SI          
                xor     AX, AX          
prep_lsl:       cmp     byte ptr ES:[DI], 00h   
                je      prep_cpi        
                cmp     byte ptr ES:[DI], "/"   
                je      prep_sls        
                cmp     byte ptr ES:[DI], "\"   
                je      prep_sls        
                jmp     prep_lsn        
prep_sls:       mov     AX, DI          
prep_lsn:       inc     DI              
                jmp     prep_lsl
prep_cpi:       lea     DI, ABS_NAM     
prep_cpl:       cmp     SI, AX          
                ja      prep_cni        
                mov     BL, ES:[SI]     
                mov     DS:[DI], BL     
                inc     SI              
                inc     DI              
                jmp     prep_cpl
prep_cni:       pop     ES              
                lea     SI, PR_NAME     
prep_cnl:       cmp     byte ptr DS:[SI], 00h   
                je      prep_pbs        
                mov     BL, DS:[SI]     
                mov     DS:[DI], BL     
                inc     SI              
                inc     DI              
                jmp     prep_cnl

; подготовка блоков параметров и стека

prep_pbs:       push    ES              
                mov     BX, seg ENV_SAD
                mov     ES, BX          
                lea     BX, ENV_SAD     
                mov     DX, seg ABS_NAM
                mov     DS, DX          
                lea     DX, ABS_NAM     
                mov     KEEP_SS, SS     
                mov     KEEP_SP, SP     
                jmp     exec_prg

; запуск дочерней программы с помощью 4Bh

exec_prg:       mov     AH, 4Bh         
                mov     AL, 00h         
                int     21h
                mov     BX, L6_DATA
                mov     DS, BX          
                mov     SS, KEEP_SS     
                mov     SP, KEEP_SP     
                pop     ES              
                jc      exec_e01        
                jmp     term_cds
exec_e01:       cmp     AX, 01h
                jne     exec_e02
                mov     BL, ERR_CLR     
                lea     BP, EXE_E01
                call    PR_STR_BIOS
                jmp     dos_quit
exec_e02:       cmp     AX, 02h
                jne     exec_e03
                mov     BL, ERR_CLR     
                lea     BP, EXE_E02
                call    PR_STR_BIOS
                jmp     dos_quit
exec_e03:       cmp     AX, 03h
                jne     exec_e04
                mov     BL, ERR_CLR     
                lea     BP, EXE_E03
                call    PR_STR_BIOS
                jmp     dos_quit
exec_e04:       cmp     AX, 04h
                jne     exec_e05
                mov     BL, ERR_CLR     
                lea     BP, EXE_E04
                call    PR_STR_BIOS
                jmp     dos_quit
exec_e05:       cmp     AX, 05h
                jne     exec_e08
                mov     BL, ERR_CLR     
                lea     BP, EXE_E05
                call    PR_STR_BIOS
                jmp     dos_quit
exec_e08:       cmp     AX, 08h
                jne     exec_e0A
                mov     BL, ERR_CLR     
                lea     BP, EXE_E08
                call    PR_STR_BIOS
                jmp     dos_quit
exec_e0A:       cmp     AX, 0Ah
                jne     exec_e0B
                mov     BL, ERR_CLR     
                lea     BP, EXE_E0A
                call    PR_STR_BIOS
                jmp     dos_quit
exec_e0B:       cmp     AX, 0Bh
                jne     exec_eun
                mov     BL, ERR_CLR     
                lea     BP, EXE_E0B
                call    PR_STR_BIOS
                jmp     dos_quit
exec_eun:       lea     DI, EXE_EUN     
                add     DI, 23          
                call    WRD_TO_HEX
                mov     BL, ERR_CLR     
                lea     BP, EXE_EUN
                call    PR_STR_BIOS
                jmp     dos_quit

; обработка завершения дочерней программы

term_cds:       mov     AH, 4Dh         
                int     21h
                cmp     AH, 00h
                jne     term_c01
                call    BYTE_TO_HEX
   
                lea     DI, TRM_C00
                add     DI, 53         
                mov     DS:[DI], AX
                mov     BL, MSG_CLR     
                lea     BP, TRM_C00
                call    PR_STR_BIOS
                jmp     dos_quit
term_c01:       cmp     AH, 01h
                jne     term_c02
                mov     BL, MSG_CLR     
                lea     BP, TRM_C01
                call    PR_STR_BIOS
                jmp     dos_quit
term_c02:       cmp     AH, 02h
                jne     term_c03
                mov     BL, MSG_CLR     
                lea     BP, TRM_C02
                call    PR_STR_BIOS
                jmp     dos_quit
term_c03:       cmp     AH, 03h
                jne     term_cun
                mov     BL, MSG_CLR     
                lea     BP, TRM_C03
                call    PR_STR_BIOS
                jmp     dos_quit                                                
term_cun:       mov     BL, AH
                call    BYTE_TO_HEX     
                lea     DI, TRM_CUN
                add     DI, 52          
                mov     DS:[DI], AX
                mov     AL, BL
                call    BYTE_TO_HEX     
                lea     DI, TRM_CUN
                add     DI, 19          
                mov     DS:[DI], AX
                mov     BL, MSG_CLR     
                lea     BP, TRM_CUN
                call    PR_STR_BIOS
                jmp     dos_quit

;выход из программы

dos_quit:       mov     AH, 01h
                int     21h
                mov     AH, 4Ch
                int     21h

L6_CODE ENDS
END START


