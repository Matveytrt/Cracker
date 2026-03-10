;================================Settings================================
.286
LOCALS @@
.model tiny
.code
org 100h
;========================================================================
STOS_LINE       macro sym, clr, len
                mov al, sym
                mov ah, clr 
                mov cx, len
                rep stosw ;ax -> es:di
                endm
;=========================================================================
END_PROG		 	macro
					mov ax, 4c00h
					int 21h
					endm
;========================================================================
Start:
;=================================Main===================================
Main            proc
                call Get_Access

                END_PROG
                endp
;========================================================================
_VmemSeg_ equ 0b800h
_VmemPos_ equ (5 * 80d + 40d) * 2
color_0 equ 0bh or 80h
symbol_0 equ 03h
hght_0 equ 3
wdth_0 equ 20
accces_strlen equ 18
pwd_len = 8
prompt db 'Enter Password: ', '$'
Input_Buf db 18, 0, 9 dup('$') ;pwd + 0dh
Pwd_Buf db '12345670', 0dh
grant_msg db '! Access granted !', '$' 
deny_msg db '! Access  denied !', '$'
;===============================Get_Access===============================
Get_Access      proc
                call Enter_Pwd ;cl - len input_buf - pwd for check

                call Check_Pwd ;al - set access flag

                call Draw_Frame ;draw access frame

                ret
                endp
;===============================Get_Access===============================
;Entry: es - buf seg
;       di - write offset 
;Exit:  -
;Expected:
;Destroyed:
;Comment: check access and draw access frame
;ToDo: hash secure
;========================================================================

;===============================Check_Pwd================================
Check_Pwd       proc

                xor al, al ; def flag = 0
                
                ; cmp cl, pwd_len
                ; jne @@exit ;not equal length

                mov bx, ds
                mov es, bx
                mov di, offset Pwd_Buf
                lea si, [Input_Buf + 2]
                mov cx, pwd_len
                repe cmpsb
                jne @@exit 

                inc al ; flag = 1 

@@exit:         ret
                endp
;===============================Check_Pwd================================
;Entry: es:di - buf seg
;       di - write offset 
;Exit:  al
;Expected:
;Destroyed: ax, bx, cx, es
;Comment: return access flag  in al - 0(deny) or 1(grant) 
;ToDo:
;========================================================================

;===============================Enter_Pwd================================
Enter_Pwd       proc
                mov ah, 09h
                mov dx, offset prompt ; enter str
                int 21h

                mov ah, 0ah
                mov dx, offset Input_Buf
                int 21h ;input pwd in ds:dx 

                mov cl, [Input_Buf + 1] ;get length
                xor ch, ch

                ret
                endp
;===============================Enter_Pwd================================
;Entry: 
;Exit: cl - len
;Expected: ds = default
;Destroyed: ax, cx, dx
;Comment: cpy cmd pwd_str to input buf
;ToDo:
;========================================================================

;================================Draw_Frame==============================
Draw_Frame      proc

                mov dx, _VmemSeg_
                mov es, dx
                mov di, _VmemPos_

                mov si, offset deny_msg
                cmp al, 1; is granted
                jne @@next
                mov si, offset grant_msg

@@next:         STOS_LINE 201, color_0, 1 ;up lft corner
                STOS_LINE 205, color_0, accces_strlen ;up hor line
                STOS_LINE 187, color_0, 1 ;up rght corner
                lea di, [di + (80d - wdth_0) * 2] ;next line


                STOS_LINE 186, color_0, 1 ;left piece
                mov cx, wdth_0 - 2 ;wdth - 2 borders
                mov ah, color_0                
@@lp:           lodsb ;ds:si -> al
                stosw ;ax -> vmem
                loop @@lp
                STOS_LINE 186, color_0, 1 ;right piece

                lea di, [di + (80d - wdth_0) * 2] ;next line
                STOS_LINE 200, color_0, 1 ;lft corner
                STOS_LINE 205, color_0, accces_strlen;dwn line
                STOS_LINE 188, color_0, 1 ;rght corner

                ret
                endp
;================================Draw_Frame==============================
;Entry: es:di - draw:pos
;       ds:si - access str addr
;       al - access flag
;Exit:  -
;Expected: ds = default
;Destroyed: dx, di, si
;Comment: draw access frame
;ToDo:
;========================================================================

;====================================End=================================
End_Of_Prog:
end             Start