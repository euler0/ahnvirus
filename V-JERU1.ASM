
;----------------------------------------------------------------
;
;         V-JERU1   µž¬iQ ¤a·¡œá¯a¶w ¤‚¯¥ Ïa¡‹aœ‘
;
;                   (¸á) 1994  ´e Àé ®
;
;----------------------------------------------------------------

          .MODEL  SMALL
          .STACK  100h
          .DATA
JeruMemDx DW   0C5h                ; ‹¡´â¸w­¡ »¥”e¶w ¢…¸aµi
          DB   10
          DB   0FCh, 6, 2Eh, 8Ch, 6, 31h, 0, 2Eh, 8Ch, 6
JeruExeDx DW   0                   ; EXE Ìa·© »¥”e¶w ¢…¸aµi
          DB   10
          DB   0FCh, 6, 2Eh, 8Ch, 6, 31h, 0, 2Eh, 8Ch, 6
iVirLn    DW   710h                ; ¤a·¡œá¯a ‹©·¡
iEntStLn  DW   0C5h                ; ¯¡¸b¸ñ Àa·¡ ‹©·¡
iOffOld21 DW   17h                 ; ¶¥œ ·¥ÈáœóËa ¸á¸w ¶áÃ¡
iOffOldLn DW   11h                 ; ¶¥œ Ìa·© ‹©·¡ ¸á¸w ¶áÃ¡
iOffCS    DW   49h                 ; ¶¥œ CS ˆt ¸á¸w ¶áÃ¡
iOffIP    DW   47h                 ; ¶¥œ IP ˆt ¸á¸w ¶áÃ¡
iOffSS    DW   45h                 ; ¶¥œ SS ˆt ¸á¸w ¶áÃ¡
iOffSP    DW   43h                 ; ¶¥œ SP ˆt ¸á¸w ¶áÃ¡

lpOldDTA  DD   ?                   ; ¶¥œ DTA º­¡
cOldDrive DB   ?                   ; ¶¥œ —aœa·¡§a
szOldDir  DB   '\'                 ; ¶¥œ —¡BÉ¡Ÿ¡
          DB   7Fh DUP(0)
sDTA      DB   40h DUP(?)          ; ¬a¶wÐi DTA
cDrive    DB   ?                   ; ˆñ¬aÐi —aœa·¡§a
szCurDir  DB   '\'                 ; ˆñ¬aº—·¥ —¡BÉ¡Ÿ¡
          DB   7Fh DUP(0)
pCurFile  DW   ?                   ; ˆñ¬aº—·¥ Ìa·©
pDirLevel DW   OFFSET sDirLevel
sDirLevel DB   40h DUP (1)
sExeHead  DB   20h DUP (?)         ; ¬å–µwµb ¥¡‰Å¶w ¤áÌá
sBuffer   DB   200h DUP(?)         ; Ìa·© ·ª´á—i·¡“e ¤áÌá
cFileType DB   ?                   ; Ìa·© ¹·ŸA
lOldLn    DD   ?                   ; ¶¥œ Ìa·© ‹©·¡
pAlloc    DW   ?                   ; Ði”w ¤h·e ‹¡´â¸w­¡ º­¡
lExeEntry DD   ?                   ; EXE Ìa·© ¯©Ð— ¯¡¸b ¶áÃ¡
iInfFile  DW   0                   ; ˆqµq Ìa·© ®

szRtDir   DB   '\', 0              ; º —¡BÉ¡Ÿ¡
szPtDir   DB   '..', 0             ; ¦¡¡ —¡BÉ¡Ÿ¡
szAll     DB   '*.*', 0            ; ¡¡—e Ìa·©
szPrgName DB   'V-JERU1 Vaccine program for Jerusalem virus'
          DB   0Dh, 0Ah
          DB   '       (c)Copyright 1994  by Cheolsoo Ahn'
          DB   0Dh, 0Ah, 0Ah, '$'
szMsg1    DB   'Usage: V-JERU1 <drive>', 0Dh, 0Ah, '$'
szMsg2    DB   'Checking the Memory : $'
szMsg3    DB   'Checking the Files  : $'
szMsg4    DB   'no Jerusalem virus', 0Dh, 0Ah, '$'
szMsg5    DB   ' : '
szMsg6    DB   7, 'Jerusalem virus found$'
szMsg7    DB   ' -> Cured', 0Dh, 0Ah, '$'
szErrMsg1 DB   0Dh, 0Ah, 7, 'ERROR: insufficient memory'
          DB   0Dh, 0Ah, '$'
szErrMsg2 DB   0Dh, 0Ah, 7, 'ERROR: file open error'
          DB   0Dh, 0Ah, '$'
szErrMsg3 DB   0Dh, 0Ah, 7, 'ERROR: file read error'
          DB   0Dh, 0Ah, '$'
szErrMsg4 DB   0Dh, 0Ah, 7, 'ERROR: file write error'
          DB   0Dh, 0Ah, '$'

          .CODE
Start:    mov  ax, @data
          mov  ds, ax

          mov  bx, sp              ; Ði”w ¤h·e ‹¡´â¸w­¡ ¹A¹¡¸÷
          add  bx, 0Fh
          and  bx, 0FFF0h
          mov  cl, 4
          shr  bx, cl
          mov  ax, ss
          add  bx, ax
          mov  ax, es
          sub  bx, ax
          mov  ah, 4Ah
          int  21h

          mov  ah, 9               ; Ïa¡‹aœ‘ ·¡Ÿq Â‰b
          mov  dx, OFFSET szPrgName
          int  21h

ChkArg:   mov  bx, 81h             ; ·¥¸a ˆñ¬a
ChkEnd:   mov  al, es:[bx]
          cmp  al, 0Dh
          jne  ChkSpace
          mov  ah, 9               ; ·¥¸a ´ô·i ˜ •¡¶‘ i Â‰b
          mov  dx, OFFSET szMsg1
          int  21h
          jmp  Exit

ChkSpace: cmp  al, ' '
          jne  ChkDrv
          inc  bx
          jmp  ChkEnd

ChkDrv:   and  al, 5Fh             ; ˆñ¬aÐi —aœa·¡§a
          sub  al, 'A'
          mov  cDrive, al

          ; ·©¤e ‹¡´â¸w­¡ ˆñ¬a

          mov  ah, 9               ; '‹¡´â¸w­¡ ˆñ¬a:' Â‰b
          mov  dx, OFFSET szMsg2
          int  21h

          mov  ax, 3521h
          int  21h

          mov  si, OFFSET JeruMemDx; ¤a·¡œá¯a ˆñ¬a
          lodsw
          mov  di, ax
          lodsb
          xor  ch, ch
          mov  cl, al
          repz cmpsb
          je   TxJeruMem

          mov  ah, 9               ; '¤a·¡œá¯a ´ô·q' Â‰b
          mov  dx, OFFSET szMsg4
          int  21h
          jmp  SrchDir

          ; ‹¡´â¸w­¡ Ã¡ža

TxJeruMem:mov  ah, 9               ; '¤a·¡œá¯a ¹¥¸' Â‰b
          mov  dx, OFFSET szMsg6
          int  21h

          push ds                  ; 21h¤å ·¥ÈáœóËa º­¡ ¥¢Š
          mov  di, iOffOld21
          mov  ax, 2521h
          lds  dx, es:[di]
          int  21h
          pop  ds

          mov  ah, 9               ; '-> Ã¡ža' Â‰b
          mov  dx, OFFSET szMsg7
          int  21h

          ; Ìa·©—i ˆñ¬a

Srchdir:  push ds
          pop  es
          mov  ah, 9               ; 'Ìa·©—i ˆñ¬a:' Â‰b
          mov  dx, OFFSET szMsg3
          int  21h

          push es                  ; Ñe¸ DTA º­¡ ´è·q
          mov  ah, 2Fh
          int  21h
          mov  WORD PTR lpOldDTA, bx
          mov  WORD PTR lpOldDTA[2], es
          pop  es
          mov  ah, 19h             ; Ñe¸ —aœa·¡§a ´è·q
          int  21h
          mov  cOldDrive, al
          inc  al
          mov  dl, al              ; Ñe¸ —¡BÉ¡Ÿ¡ ´è·q
          mov  ah, 47h
          mov  si, OFFSET szOldDir + 1
          int  21h

          mov  ah, 1Ah             ; DTA ¤aŽ‘
          mov  dx, OFFSET sDTA
          int  21h
          mov  ah, 0Eh             ; ˆñ¬aÐi —aœa·¡§a¡ ¤aŽ‘
          mov  dl, cDrive
          int  21h
          mov  ah, 3Bh             ; º —¡BÉ¡Ÿ¡¡ ¤aŽ‘
          mov  dx, OFFSET szRtDir
          int  21h

          call CheckFiles          ; Ìa·©—i ˆñ¬a

          push ds                  ; ¶¥œ DTA¡ ¤aŽ‘
          mov  ah, 1Ah
          mov  dx, WORD PTR lpOldDTA
          mov  ds, WORD PTR lpOldDTA[2]
          int  21h
          pop  ds                  ; ¶¥œ —aœa·¡§a¡ ¤aŽ‘
          mov  ah, 0Eh
          mov  dl, cOldDrive
          int  21h
          mov  ah, 3Bh             ; ¶¥œ —¡BÉ¡Ÿ¡¡ ¤aŽ‘
          mov  dx, OFFSET szOldDir
          int  21h

          cmp  iInfFile, 0
          jne  Exit
          mov  ah, 9               ; '¤a·¡œá¯a ´ô·q' Â‰b
          mov  dx, OFFSET szMsg4
          int  21h

          ; ¯©Ð— ¹·ža

Exit:     mov  ax, 4C00h
          int  21h

PrtErr:   mov  ah, 9               ; µAœá ¡A¯¡»¡ Â‰b
          int  21h

          mov  ax, 4C01h
          int  21h

;----------------------------------------------------------------

CheckFiles  PROC                   ; ¡¡—e —¡BÉ¡Ÿ¡ –á¹a Ìa·© ˆñ¬a

          push ax
          push bx
          push cx
          push si

Find1st:  mov  ah, 4Eh             ; Ìa·©·i Àx·q
FindFile: mov  cx, 100111b
          mov  dx, OFFSET szAll
          int  21h
          jc   ChDir

          mov  pCurFile, OFFSET sDTA + 1Eh
          mov  dx, pCurFile
          call CheckFileType       ; Ìa·© ¹·ŸA ˆñ¬a
          jc   ECF

          mov  dx, pCurFile
          cmp  cFileType, 0
          jne  ChkExe
          call CheckCom            ; COM Ìa·© ˆñ¬a
          jc   ECF
          jmp  FindNext
ChkExe:   call CheckExe            ; EXE Ìa·© ˆñ¬a
          jc   ECF

FindNext: mov  ah, 4Fh             ; ”a·q Ìa·© Àx·q
          jmp  FindFile

ECF:      jmp  ExitCF

          ; ”aŸe —¡BÉ¡Ÿ¡¡ ·¡•·

ChDir:    mov  si, pDirLevel
FindDir:  xor  bl, bl
          mov  ah, 4Eh             ; —¡BÉ¡Ÿ¡ Àx·q
          mov  cx, 10010b
          mov  dx, OFFSET szAll
          int  21h
          jc   ChkRtDir
          jmp  ChkDir

NextDir:  mov  ah, 4Fh             ; ”a·q —¡BÉ¡Ÿ¡ Àx·q
          int  21h
          jc   ChkRtDir

ChkDir:   cmp  BYTE PTR sDTA[15h], 10000b
          jz   IsCurDir
          cmp  BYTE PTR sDTA[15h], 10010b
          jnz  NextDir
IsCurDir: cmp  BYTE PTR sDTA[1Eh], '.'
          jz   NextDir
          inc  bl
          cmp  bl, [si]
          jnz  NextDir

          mov  ah, 3Bh             ; Àx·e —¡BÉ¡Ÿ¡¡ ·¡•·
          mov  dx, OFFSET sDTA + 1Eh
          int  21h
          inc  BYTE PTR [si]
          inc  si
          mov  pDirLevel, si
          jmp  Find1st

ChkRtDir: cmp  si, OFFSET sDirLevel; º —¡BÉ¡Ÿ¡·¥ˆa?
          je   ExitCF
          mov  ah, 3Bh             ; ¬w¶á —¡BÉ¡Ÿ¡¡ ·¡•·
          mov  dx, OFFSET szPtDir
          int  21h
          mov  BYTE PTR [si], 1
          dec  si
          jmp  FindDir

ExitCF:   pop  si
          pop  cx
          pop  bx
          pop  ax
          ret

CheckFiles  ENDP

;----------------------------------------------------------------

CheckFileType  PROC                ; Ìa·© ¹·ŸA Š¥i

          push ax
          push bx
          push cx

          ; Ìa·© µ¡Ïe
          mov  ax, 3D00h
          int  21h
          jnc  ReadFile
          mov  dx, OFFSET szErrMsg2
          stc
          jmp  ExitCFT

          ; Ìa·© ·ª·q
ReadFile: mov  bx, ax
          mov  ah, 3Fh
          mov  cx, 200h
          mov  dx, OFFSET sBuffer
          int  21h
          jnc  CloseFile
          mov  ah, 3Eh
          int  21h
          mov  dx, OFFSET szErrMsg3
          stc
          jmp  ExitCFT

          ; Ìa·© ”h·q
CloseFile:mov  ah, 3Eh
          int  21h

          cmp  WORD PTR sBuffer, 'MZ'
          je   ExeFile
          cmp  WORD PTR sBuffer, 'ZM'
          je   ExeFile
          mov  cFileType, 0        ; COM Ìa·©
          clc
          jmp  ExitCFT

ExeFile:  mov  cFileType, 1        ; EXE Ìa·©
          clc

ExitCFT:  pop  cx
          pop  bx
          pop  ax
          ret

CheckFileType  ENDP

;----------------------------------------------------------------

CheckCom  PROC                     ; COM Ìa·© ˆñ¬a

          push ax
          push bx
          push cx
          push si
          push di

          ; ¤a·¡œá¯a ˆñ¬a

          mov  si, OFFSET JeruMemDx
          lodsw
          mov  di, ax
          add  di, OFFSET sBuffer
          lodsb
          xor  cx, cx
          mov  cl, al
          repz cmpsb
          je   TxCom
          clc
          jmp  ExitCC

          ; ¤a·¡œá¯a Ã¡ža

TxCom:    inc  iInfFile            ; ˆqµq Ìa·© ® »wˆa
          call PrintPathname       ; Ìa·© ·¡Ÿq Â‰b

          push dx                  ; '¤a·¡œá¯a ¹¥¸' Â‰b
          mov  ah, 9
          mov  dx, OFFSET szMsg5
          int  21h

          ; ¶¥œ Ìa·© ‹©·¡ ´è·q
          mov  bx, iOffOldLn
          mov  ax, WORD PTR sBuffer[bx]
          mov  WORD PTR lOldLn, ax

          ; ‹¡´â¸w­¡ Ði”w
          mov  ah, 48h
          mov  bx, 1000h
          int  21h
          pop  dx
          jnc  Alloc
          mov  dx, OFFSET szErrMsg1
          stc
          jmp  ExitCC
Alloc:    mov  pAlloc, ax

          mov  ax, 4300h
          xor  cx, cx
          int  21h
          mov  ax, 3D02h
          int  21h
          jnc  SetFpCom1
          mov  dx, OFFSET szErrMsg2
          stc
          jmp  ExitCC

          ; Ìa·© µ¡Ïe
SetFpCom1:mov  bx, ax
          mov  ax, 4200h
          xor  cx, cx
          mov  dx, iVirLn
          int  21h

          ; ¶¥œ Ìa·© ¶w ·ª·q
          push ds
          mov  ah, 3Fh
          mov  cx, WORD PTR lOldLn
          mov  ds, pAlloc
          xor  dx, dx
          int  21h
          pop  ds
          jnc  SetFpCom2
          mov  ah, 3Eh
          int  21h
          mov  dx, OFFSET szErrMsg3
          stc
          jmp  ExitCC

          ; ¶¥œ Ìa·© ¶w ³q
SetFpCom2:mov  ax, 4200h
          xor  cx, cx
          xor  dx, dx
          int  21h
          push ds
          mov  ah, 40h
          mov  cx, WORD PTR lOldLn
          mov  ds, pAlloc
          xor  dx, dx
          int  21h
          pop  ds
          jnc  AdjSize
          mov  ah, 3Eh
          int  21h
          mov  dx, OFFSET szErrMsg4
          stc
          jmp  ExitCC

          ; Ìa·© ‹©·¡ ¥¢Š
AdjSize:  mov  ah, 40h
          xor  cx, cx
          int  21h
          jnc  CloseCom
          mov  ah, 3Eh
          int  21h
          mov  dx, OFFSET szErrMsg4
          stc
          jmp  ExitCC

          ; Ìa·© ”h·q
CloseCom: mov  ah, 3Eh
          int  21h

          ; ‹¡´â¸w­¡ Ð¹A
          push es
          mov  ah, 49h
          mov  es, pAlloc
          int  21h
          pop  es

          mov  ah, 9               ; '-> Ã¡ža' Â‰b
          mov  dx, OFFSET szMsg7
          int  21h

ExitCC:   pop  di
          pop  si
          pop  cx
          pop  bx
          pop  ax
          ret

CheckCom  ENDP

;----------------------------------------------------------------

CheckExe  PROC                     ; EXE Ìa·© ˆñ¬a

          push ax
          push bx
          push cx
          push si
          push di

          ; ¯©Ð— ¯¡¸b ¶áÃ¡ ´è·q
          mov  si, OFFSET sBuffer
          mov  di, OFFSET sExeHead
          mov  cx, 10h
          rep  movsw

          mov  ax, WORD PTR sExeHead[8]
          add  ax, WORD PTR sExeHead[16h]
          mov  dx, 10h
          mul  dx
          add  ax, WORD PTR sExeHead[14h]
          adc  dx, 0
          mov  WORD PTR lExeEntry, ax
          mov  WORD PTR lExeEntry[2], dx

          ; Ìa·© µ¡Ïe
          mov  ax, 3D00h
          mov  dx, pCurFile
          int  21h
          jnc  SetFpExe1
          mov  dx, OFFSET szErrMsg2
          stc
          jmp  ExitCE

          ; ¯©Ð— ¯¡¸b ¦¶á ·ª·q
SetFpExe1:mov  bx, ax
          mov  ax, 4200h
          mov  cx, WORD PTR lExeEntry[2]
          mov  dx, WORD PTR lExeEntry
          int  21h
          mov  ah, 3Fh
          mov  cx, 200h
          mov  dx, OFFSET sBuffer
          int  21h
          jnc  CloseExe1
          mov  ah, 3Eh
          int  21h
          mov  dx, OFFSET szErrMsg2
          stc
          jmp  ExitCE

          ; Ìa·© ”h·q
CloseExe1:mov  ah, 3Eh
          int  21h

          ; ¤a·¡œá¯a ˆñ¬a

          mov  si, OFFSET JeruExeDx
          lodsw
          mov  di, ax
          add  di, OFFSET sBuffer
          lodsb
          xor  ch, ch
          mov  cl, al
          repz cmpsb
          je   TxExe
          clc
          jmp  ExitCE

          ; ¤a·¡œá¯a Ã¡ža

TxExe:    inc  iInfFile            ; ˆqµq Ìa·© ® »wˆa
          mov  dx, pCurFile
          call PrintPathname       ; Ìa·© ·¡Ÿq Â‰b

          push dx                  ; '¤a·¡œá¯a ¹¥¸' Â‰b
          mov  ah, 9
          mov  dx, OFFSET szMsg5
          int  21h
          pop  dx

          ; Ìa·© µ¡Ïe
          mov  ax, 4300h
          xor  cx, cx
          int  21h
          mov  ax, 3D02h
          int  21h
          jnc  SetFpExe2
          mov  dx, OFFSET szErrMsg2
          stc
          jmp  ExitCE

          ; ¶¥œ CS, IP, SS, SP ˆt—i ´è·q
SetFpExe2:mov  bx, ax              ; ¤a·¡œá¯a ¯¡¸b ¦¶á ·ª·q
          mov  ax, 4200h
          mov  dx, WORD PTR lExeEntry
          mov  cx, WORD PTR lExeEntry[2]
          sub  dx, iEntStLn
          sbb  cx, 0
          mov  WORD PTR lOldLn, dx
          mov  WORD PTR lOldLn[2], cx
          int  21h
          mov  ah, 3Fh
          mov  cx, 200h
          mov  dx, OFFSET sBuffer
          int  21h
          jnc  GetEntry
          mov  ah, 3Eh
          int  21h
          mov  dx, OFFSET szErrMsg3
          stc
          jmp  ExitCE

GetEntry: mov  si, iOffCS          ; ¶¥œ CS ˆt ´è·q
          mov  ax, WORD PTR sBuffer[si]
          mov  WORD PTR sExeHead[16h], ax
          mov  si, iOffIP          ; ¶¥œ IP ˆt ´è·q
          mov  ax, WORD PTR sBuffer[si]
          mov  WORD PTR sExeHead[14h], ax
          mov  si, iOffSS          ; ¶¥œ SS ˆt ´è·q
          mov  ax, WORD PTR sBuffer[si]
          mov  WORD PTR sExeHead[0Eh], ax
          mov  si, iOffSP          ; ¶¥œ SP ˆt ´è·q
          mov  ax, WORD PTR sBuffer[si]
          mov  WORD PTR sExeHead[10h], ax

          ; ¶¥œ ‹©·¡ ‰¬e
          mov  dx, WORD PTR lOldLn[2]
          mov  ax, WORD PTR lOldLn
          mov  cx, 200h
          div  cx
          cmp  dx, 0
          jz   NoRmnd
          inc  ax
NoRmnd:   mov  WORD PTR sExeHead[2], dx
          mov  WORD PTR sExeHead[4], ax

          ; ¬å–µwµb ¥¢Š
          mov  ax, 4200h
          xor  cx, cx
          xor  dx, dx
          int  21h
          mov  ah, 40h
          mov  cx, 20h
          mov  dx, OFFSET sExeHead
          int  21h
          jnc  SetFpExe3
          mov  ah, 3Eh
          int  21h
          mov  dx, OFFSET szErrMsg4
          stc
          jmp  ExitCE

          ; Ìa·© ‹©·¡ ¥¢Š
SetFpExe3:mov  ax, 4200h
          mov  dx, WORD PTR lOldLn
          mov  cx, WORD PTR lOldLn[2]
          int  21h
          mov  ah, 40h
          xor  cx, cx
          int  21h
          jnc  CloseExe2
          mov  ah, 3Eh
          int  21h
          mov  dx, OFFSET szErrMsg4
          stc
          jmp  ExitCE

          ; Ìa·© ”h·q
CloseExe2:mov  ah, 3Eh
          int  21h

          mov  ah, 9               ; '-> Ã¡ža' Â‰b
          mov  dx, OFFSET szMsg7
          int  21h

ExitCE:   pop  di
          pop  si
          pop  cx
          pop  bx
          pop  ax
          ret

CheckExe  ENDP

;----------------------------------------------------------------
PrintPathname  PROC                ; µÅ¸åÐe Ì¯a ·¡Ÿq Â‰b

          push ax
          push dx
          push si

          push dx                  ; —aœa·¡§a ·¡Ÿq Â‰b
          mov  ah, 2
          mov  dl, cDrive
          add  dl, 'A'
          int  21h
          mov  dl, ':'
          int  21h

          mov  ah, 48h             ; Ñe¸ —¡BÉ¡Ÿ¡ ´è·q
          xor  dl, dl
          mov  si, OFFSET szCurDir + 1
          int  21h

          cmp  BYTE PTR [si], 0    ; Ñe¸ —¡BÉ¡Ÿ¡ ·¡Ÿq Â‰b
          je   PrtFn
          dec  si
          mov  ah, 2
PathChr:  mov  dl, [si]
          cmp  dl, 0
          je   PrtFn
          int  21h
          inc  si
          jmp  PathChr

PrtFn:    mov  ah, 2               ; '\' Â‰b
          mov  dl, '\'
          int  21h

          pop  si                  ; Ìa·© ·¡Ÿq Â‰b
          mov  ah, 2
FileChr:  mov  dl, [si]
          cmp  dl, 0
          je   ExitPP
          int  21h
          inc  si
          jmp  FileChr

ExitPP:   pop  si
          pop  dx
          pop  ax
          ret

PrintPathname  ENDP

;----------------------------------------------------------------

          END Start

