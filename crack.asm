;================================Settings================================
.286
LOCALS @@
.model tiny
.code
org 100h
;========================================================================
STOS_LINE           macro sym, clr, len
                    mov al, sym
                    mov ah, clr 
                    mov cx, len
                    rep stosw ;ax -> es:di
                    endm
;========================================================================
STOSUP_LINE         macro clr, len
                    STOS_LINE 201, clr, 1 ;up lft corner
                    STOS_LINE 205, clr, len ;up hor line
                    STOS_LINE 187, clr, 1 ;up rght corner
                    endm
;========================================================================
NEXTLINE            macro len
                    lea di, [di + (80d - len - 2d) * 2] ;next line
                    endm
;========================================================================
STOSDWN_LINE        macro clr, len
                    STOS_LINE 200, clr, 1 ;up lft corner
                    STOS_LINE 205, clr, len ;up hor line
                    STOS_LINE 188, clr, 1 ;up rght corner
                    endm
;=========================================================================
END_PROG		 	macro
					mov ax, 4c00h
					int 21h
					endm
;========================================================================
_VmemSeg_ equ 0b800h
_VmemPos_ equ (12 * 80d + 27d) * 2
color_0 equ 1ah ;or 80h
symbol_1 equ '+'
symbol_0 equ '-'
scancode_0 equ 3eh ;f4
hght_0 equ 5
wdth_0 equ 13
accces_strlen equ 18
pwd_len equ 8
def_size equ 9d
huge_size equ 100d
;==============================DATASEG===================================
.data
grant_msg db '! Access granted !', '$' 
deny_msg db '! Access  denied !', '$'
prompt db 'Enter Password: ', '$'
Input_Buf db 9, 0, 9 dup('$') ;pwd + 0dh
Pwd_Buf db '12345670', 0dh
msg db 'Press any key to start... ', 0dh, 0ah, '$'
Menu_Data db '| Settings  |', '$'
Settings_Data db 12, 4ch, 3, 13, '(0) SizeLim ', '-', '(1) Encode  ', '-', '(2) StopInt ', '-' ;statuspos, color, nsets, setlen, set1, set2, set3...
Status_Data db 0, 1, 0 ;default turn ON
;========================================================================

;=============================CODESEG====================================
.code
Start:
;=================================Main===================================
Main            proc
                call Get_Access
                END_PROG
                endp
;========================================================================

;===============================Get_Access===============================
Get_Access      proc
                call WaitForKey ;waiting for any key to start
                mov di, ax
                call Enter_Pwd ;cl - len input_buf - pwd for check
                mov ax, di
                call Encode_Pwd

                call Check_Pwd ;al - set access flag

                call Show_Access ;draw access frame al = 1 granted 

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

;===============================WaitForKey===============================
WaitForKey      proc
@@back:         mov ah, 09h ;dos output
                mov dx, offset msg
                int 21h ;out msg

                xor ah, ah       ; AH = 0
                int 16h          ; BIOS keyboard interrupt wait for any key
                ; AH = scancode, AL = ASCII
                ; call Encode_Pwd

                cmp ah, scancode_0 ;f4
                jne @@exit

                call Show_Settings ;f4 pressed -> call settings
                jmp @@back

@@exit:         ret
                endp
;===============================WaitForKey===============================
;Entry: 
;Exit: mode
;Expected: ds = default
;Destroyed: ax, cx, dx
;Comment: cpy cmd pwd_str to input buf
;ToDo:
;========================================================================

;==============================Encode_Pwd================================
Encode_Pwd      proc

                ; cmp ah, 0 ;0scancode not checked
                ; je @@exit 

                mov bl, [Status_Data + 1d]
                test bl, bl
                jz @@exit

                mov bl, ah ;save scancode
                mov cx, pwd_len
                mov si, offset Pwd_Buf
                push ds
                pop es
                mov di, si

@@lp:           lodsb
                mul bl ;ax - res could be more than al
                stosb
                loop @@lp

@@exit:         ret
                endp
;==============================Encode_Pwd================================
;Entry: ah = scancode of first key pressed
;Exit: encoded pwd in Pwd_buf
;Expected: ds = def
;Destroyed: ax, bx, cx
;Comment: encode pwd with scancode from waitforkey
;ToDo:
;========================================================================

;===============================Enter_Pwd================================
Enter_Pwd       proc

                mov bl, [Status_Data]
                test bl, bl
                jnz @@skip_resize
                mov byte ptr [Input_Buf], huge_size ;100d

@@skip_resize:
                mov ah, 09h ;dos output
                mov dx, offset prompt ; enter str
                int 21h ;make prompt str

                mov ah, 0ah ;dos input
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

;===============================Check_Pwd================================
Check_Pwd       proc
                xor al, al ; def flag = 0
                
                ; cmp cl, pwd_len
                ; jne @@exit ;not equal length

                mov bx, ds
                mov es, bx
                mov di, offset Pwd_Buf
                lea si, [Input_Buf + 2] ;pwd start
                mov cx, pwd_len
                repe cmpsb
                jne @@exit 
                inc al ; flag = 1 

@@exit:         ret
                endp
;===============================Check_Pwd================================
;Entry: es:di - buf seg
;       di - write offset 
;Exit:  al - access flag
;Expected:
;Destroyed: ax, bx, cx, es
;Comment: return access flag  in al - 0(deny) or 1(grant) 
;ToDo:
;========================================================================

;================================Show_Access=============================
Show_Access     proc
                mov dx, _VmemSeg_
                mov es, dx
                mov di, _VmemPos_

                mov si, offset deny_msg
                cmp al, 1; is granted
                jne @@next
                mov si, offset grant_msg

@@next:         STOSUP_LINE color_0, accces_strlen
                NEXTLINE accces_strlen

                STOS_LINE 186, color_0, 1 ;left piece
                mov cx, accces_strlen ;wdth - 2 borders
                mov ah, color_0                
@@lp:           lodsb   ; ds:si -> al
                stosw   ; ax -> vmem
                loop @@lp
                STOS_LINE 186, color_0, 1 ;right piece

                NEXTLINE accces_strlen
                STOSDWN_LINE color_0, accces_strlen
                ret
                endp
;================================Show_Access=============================
;Entry: es:di - draw:pos
;       ds:si - access str addr
;       al - access flag
;Exit:  -
;Expected: ds = default
;Destroyed: cx, dx, di, si
;Comment: draw access frame
;ToDo:
;========================================================================

;===============================Show_Settings============================
Show_Settings   proc
                mov ax, _VmemSeg_
                mov es, ax
                mov di, _VmemPos_
                mov bx, offset Status_Data
                
                STOSUP_LINE color_0, wdth_0
                NEXTLINE wdth_0 ;next line

                STOS_LINE 186, color_0, 1
                mov ah, color_0
                mov si, offset Menu_Data
                mov cx, wdth_0
@@Menu:         lodsb
                stosw
                loop @@Menu
                STOS_LINE 186, color_0, 1
                NEXTLINE wdth_0 ;next line

                lea si, [Settings_Data + 4d] ; addr = data + skip params
                xor ch, ch
                mov cl, [Settings_Data + 2d] ; cx = Nsettings

@@lp:           mov dx, cx ;save cx
                STOS_LINE 186, color_0, 1 ;left piece
                
                mov cl, [Settings_Data + 3d] ;line wdth

@@lp_line:      lodsb   ; ds:si -> al

                cmp cl, 1d ;last symbol = status
                je @@set_clr

@@OFF:          mov ah, color_0 
@@ON:           stosw   ; ax -> vmem
                loop @@lp_line

                STOS_LINE 186, color_0, 1 ;right piece
                NEXTLINE wdth_0

                inc bx ;next status
                mov cx, dx
                loop @@lp

                STOSDWN_LINE color_0, wdth_0      
                jmp @@wait   

@@set_clr:      mov al, [bx]
                test al, al
                mov al, symbol_0 ;off
                jz @@OFF
                mov al, symbol_1 ;on
                mov ah, [Settings_Data + 1d]
                jmp @@ON

@@wait:         call Switch_Settings

@@exit:         ret
                endp
;===============================Show_Settings============================
;Entry: 
;Exit: mode
;Expected: ds = default
;Destroyed: ax, bx, cx, dx, si, di, es
;Comment: show settings of crack
;ToDo:
;========================================================================


;===============================Switch_Settings==========================
Switch_Settings proc

@@next_press:   xor ah, ah
                int 16h ;get ax - scan(ah) + ascii(al) code
                cmp ah, scancode_0 ;is f4 -> exit
                je @@exit

                cmp al, '0'
                jb @@next_press
                cmp al, '2' 
                ja @@next_press
                sub al, '0' ;digit from 0 to 2 string
                call Get_Turn

                jmp @@next_press

@@exit:         call ClrScrDOS
                ret
                endp
;===============================Switch_Settings==========================
;Entry: 
;Exit:
;Expected: ds = default
;Destroyed: ax, bl, cx, si, di, es
;Comment: set settings of crack
;ToDo:
;========================================================================

;==============================Get_Turn==================================
Get_Turn        proc

                xor ah, ah
                mov si, ax
                lea si, [si + Status_Data]
                mov bl, [si]
                xor bl, 1 ; swap status
                mov byte ptr [si], bl

                mov cx, _VmemSeg_
                mov es, cx
                mov di, _VmemPos_

                xor ch, ch
                mov cl, al
                add cl, 2d

@@lp:           lea di, [di + 80d * 2];next line
                loop @@lp ;cx = 0

                xor ch, ch
                mov cl, [Settings_Data]
                inc cl ;1 byte more
                shl cx, 1
                add di, cx ;get pos of switch

                test bl, bl
                jz @@off
                mov bh, [Settings_Data + 1d]
                STOS_LINE symbol_1, bh, 1 
                jmp @@exit

@@off:          STOS_LINE symbol_0, color_0, 1	
                
@@exit:         ret
                endp
;==============================Get_Turn==================================
;Entry: al - setting idx
;       bl - status flag
;Exit:  
;Expected:
;Destroyed: si, ax, es:di, cx, bx
;Comment: return turn setting pos and make changes
;ToDo:
;========================================================================

;==============================ClrScrDOS=================================
ClrScrDOS       proc
                mov ax, 0600h ;ah - clear screen, al - clear entire screen
                mov bh, 07h ;scroll wndw dwn
                xor cx, cx
                mov dx, 184fh
                int 10h ;10!
                ret
                endp
;==============================ClrScrDOS=================================
;Entry: 
;Exit:  
;Expected:
;Destroyed: ax, bh, cx, dx
;Comment: clear entire terminal screen
;ToDo:
;========================================================================

;====================================End=================================
End_Of_Prog:
end             Start