
;----------------------------------------------------------------
;
;         V-JERU1   예루살렘 바이러스용 백신 프로그램
;
;                   (저) 1994  안 철 수
;
;----------------------------------------------------------------

          .MODEL  SMALL
          .STACK  100h
          .DATA
JeruMemDx DW   0C5h                ; 기억장소 진단용 문자열
          DB   10
          DB   0FCh, 6, 2Eh, 8Ch, 6, 31h, 0, 2Eh, 8Ch, 6
JeruExeDx DW   0                   ; EXE 파일 진단용 문자열
          DB   10
          DB   0FCh, 6, 2Eh, 8Ch, 6, 31h, 0, 2Eh, 8Ch, 6
iVirLn    DW   710h                ; 바이러스 길이
iEntStLn  DW   0C5h                ; 시작점 차이 길이
iOffOld21 DW   17h                 ; 원래 인터럽트 저장 위치
iOffOldLn DW   11h                 ; 원래 파일 길이 저장 위치
iOffCS    DW   49h                 ; 원래 CS 값 저장 위치
iOffIP    DW   47h                 ; 원래 IP 값 저장 위치
iOffSS    DW   45h                 ; 원래 SS 값 저장 위치
iOffSP    DW   43h                 ; 원래 SP 값 저장 위치

lpOldDTA  DD   ?                   ; 원래 DTA 주소
cOldDrive DB   ?                   ; 원래 드라이브
szOldDir  DB   '\'                 ; 원래 디렉토리
          DB   7Fh DUP(0)
sDTA      DB   40h DUP(?)          ; 사용할 DTA
cDrive    DB   ?                   ; 검사할 드라이브
szCurDir  DB   '\'                 ; 검사중인 디렉토리
          DB   7Fh DUP(0)
pCurFile  DW   ?                   ; 검사중인 파일
pDirLevel DW   OFFSET sDirLevel
sDirLevel DB   40h DUP (1)
sExeHead  DB   20h DUP (?)         ; 선두영역 보관용 버퍼
sBuffer   DB   200h DUP(?)         ; 파일 읽어들이는 버퍼
cFileType DB   ?                   ; 파일 종류
lOldLn    DD   ?                   ; 원래 파일 길이
pAlloc    DW   ?                   ; 할당 받은 기억장소 주소
lExeEntry DD   ?                   ; EXE 파일 실행 시작 위치
iInfFile  DW   0                   ; 감염 파일 수

szRtDir   DB   '\', 0              ; 주 디렉토리
szPtDir   DB   '..', 0             ; 부모 디렉토리
szAll     DB   '*.*', 0            ; 모든 파일
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

          mov  bx, sp              ; 할당 받은 기억장소 제조정
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

          mov  ah, 9               ; 프로그램 이름 출력
          mov  dx, OFFSET szPrgName
          int  21h

ChkArg:   mov  bx, 81h             ; 인자 검사
ChkEnd:   mov  al, es:[bx]
          cmp  al, 0Dh
          jne  ChkSpace
          mov  ah, 9               ; 인자 없을 때 도움말 출력
          mov  dx, OFFSET szMsg1
          int  21h
          jmp  Exit

ChkSpace: cmp  al, ' '
          jne  ChkDrv
          inc  bx
          jmp  ChkEnd

ChkDrv:   and  al, 5Fh             ; 검사할 드라이브
          sub  al, 'A'
          mov  cDrive, al

          ; 일반 기억장소 검사

          mov  ah, 9               ; '기억장소 검사:' 출력
          mov  dx, OFFSET szMsg2
          int  21h

          mov  ax, 3521h
          int  21h

          mov  si, OFFSET JeruMemDx; 바이러스 검사
          lodsw
          mov  di, ax
          lodsb
          xor  ch, ch
          mov  cl, al
          repz cmpsb
          je   TxJeruMem

          mov  ah, 9               ; '바이러스 없음' 출력
          mov  dx, OFFSET szMsg4
          int  21h
          jmp  SrchDir

          ; 기억장소 치료

TxJeruMem:mov  ah, 9               ; '바이러스 존재' 출력
          mov  dx, OFFSET szMsg6
          int  21h

          push ds                  ; 21h번 인터럽트 주소 복구
          mov  di, iOffOld21
          mov  ax, 2521h
          lds  dx, es:[di]
          int  21h
          pop  ds

          mov  ah, 9               ; '-> 치료' 출력
          mov  dx, OFFSET szMsg7
          int  21h

          ; 파일들 검사

Srchdir:  push ds
          pop  es
          mov  ah, 9               ; '파일들 검사:' 출력
          mov  dx, OFFSET szMsg3
          int  21h

          push es                  ; 현재 DTA 주소 얻음
          mov  ah, 2Fh
          int  21h
          mov  WORD PTR lpOldDTA, bx
          mov  WORD PTR lpOldDTA[2], es
          pop  es
          mov  ah, 19h             ; 현재 드라이브 얻음
          int  21h
          mov  cOldDrive, al
          inc  al
          mov  dl, al              ; 현재 디렉토리 얻음
          mov  ah, 47h
          mov  si, OFFSET szOldDir + 1
          int  21h

          mov  ah, 1Ah             ; DTA 바꿈
          mov  dx, OFFSET sDTA
          int  21h
          mov  ah, 0Eh             ; 검사할 드라이브로 바꿈
          mov  dl, cDrive
          int  21h
          mov  ah, 3Bh             ; 주 디렉토리로 바꿈
          mov  dx, OFFSET szRtDir
          int  21h

          call CheckFiles          ; 파일들 검사

          push ds                  ; 원래 DTA로 바꿈
          mov  ah, 1Ah
          mov  dx, WORD PTR lpOldDTA
          mov  ds, WORD PTR lpOldDTA[2]
          int  21h
          pop  ds                  ; 원래 드라이브로 바꿈
          mov  ah, 0Eh
          mov  dl, cOldDrive
          int  21h
          mov  ah, 3Bh             ; 원래 디렉토리로 바꿈
          mov  dx, OFFSET szOldDir
          int  21h

          cmp  iInfFile, 0
          jne  Exit
          mov  ah, 9               ; '바이러스 없음' 출력
          mov  dx, OFFSET szMsg4
          int  21h

          ; 실행 종료

Exit:     mov  ax, 4C00h
          int  21h

PrtErr:   mov  ah, 9               ; 에러 메시지 출력
          int  21h

          mov  ax, 4C01h
          int  21h

;----------------------------------------------------------------

CheckFiles  PROC                   ; 모든 디렉토리 뒤져 파일 검사

          push ax
          push bx
          push cx
          push si

Find1st:  mov  ah, 4Eh             ; 파일을 찾음
FindFile: mov  cx, 100111b
          mov  dx, OFFSET szAll
          int  21h
          jc   ChDir

          mov  pCurFile, OFFSET sDTA + 1Eh
          mov  dx, pCurFile
          call CheckFileType       ; 파일 종류 검사
          jc   ECF

          mov  dx, pCurFile
          cmp  cFileType, 0
          jne  ChkExe
          call CheckCom            ; COM 파일 검사
          jc   ECF
          jmp  FindNext
ChkExe:   call CheckExe            ; EXE 파일 검사
          jc   ECF

FindNext: mov  ah, 4Fh             ; 다음 파일 찾음
          jmp  FindFile

ECF:      jmp  ExitCF

          ; 다른 디렉토리로 이동

ChDir:    mov  si, pDirLevel
FindDir:  xor  bl, bl
          mov  ah, 4Eh             ; 디렉토리 찾음
          mov  cx, 10010b
          mov  dx, OFFSET szAll
          int  21h
          jc   ChkRtDir
          jmp  ChkDir

NextDir:  mov  ah, 4Fh             ; 다음 디렉토리 찾음
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

          mov  ah, 3Bh             ; 찾은 디렉토리로 이동
          mov  dx, OFFSET sDTA + 1Eh
          int  21h
          inc  BYTE PTR [si]
          inc  si
          mov  pDirLevel, si
          jmp  Find1st

ChkRtDir: cmp  si, OFFSET sDirLevel; 주 디렉토리인가?
          je   ExitCF
          mov  ah, 3Bh             ; 상위 디렉토리로 이동
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

CheckFileType  PROC                ; 파일 종류 구별

          push ax
          push bx
          push cx

          ; 파일 오픈
          mov  ax, 3D00h
          int  21h
          jnc  ReadFile
          mov  dx, OFFSET szErrMsg2
          stc
          jmp  ExitCFT

          ; 파일 읽음
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

          ; 파일 닫음
CloseFile:mov  ah, 3Eh
          int  21h

          cmp  WORD PTR sBuffer, 'MZ'
          je   ExeFile
          cmp  WORD PTR sBuffer, 'ZM'
          je   ExeFile
          mov  cFileType, 0        ; COM 파일
          clc
          jmp  ExitCFT

ExeFile:  mov  cFileType, 1        ; EXE 파일
          clc

ExitCFT:  pop  cx
          pop  bx
          pop  ax
          ret

CheckFileType  ENDP

;----------------------------------------------------------------

CheckCom  PROC                     ; COM 파일 검사

          push ax
          push bx
          push cx
          push si
          push di

          ; 바이러스 검사

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

          ; 바이러스 치료

TxCom:    inc  iInfFile            ; 감염 파일 수 증가
          call PrintPathname       ; 파일 이름 출력

          push dx                  ; '바이러스 존재' 출력
          mov  ah, 9
          mov  dx, OFFSET szMsg5
          int  21h

          ; 원래 파일 길이 얻음
          mov  bx, iOffOldLn
          mov  ax, WORD PTR sBuffer[bx]
          mov  WORD PTR lOldLn, ax

          ; 기억장소 할당
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

          ; 파일 오픈
SetFpCom1:mov  bx, ax
          mov  ax, 4200h
          xor  cx, cx
          mov  dx, iVirLn
          int  21h

          ; 원래 파일 내용 읽음
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

          ; 원래 파일 내용 씀
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

          ; 파일 길이 복구
AdjSize:  mov  ah, 40h
          xor  cx, cx
          int  21h
          jnc  CloseCom
          mov  ah, 3Eh
          int  21h
          mov  dx, OFFSET szErrMsg4
          stc
          jmp  ExitCC

          ; 파일 닫음
CloseCom: mov  ah, 3Eh
          int  21h

          ; 기억장소 해제
          push es
          mov  ah, 49h
          mov  es, pAlloc
          int  21h
          pop  es

          mov  ah, 9               ; '-> 치료' 출력
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

CheckExe  PROC                     ; EXE 파일 검사

          push ax
          push bx
          push cx
          push si
          push di

          ; 실행 시작 위치 얻음
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

          ; 파일 오픈
          mov  ax, 3D00h
          mov  dx, pCurFile
          int  21h
          jnc  SetFpExe1
          mov  dx, OFFSET szErrMsg2
          stc
          jmp  ExitCE

          ; 실행 시작 부위 읽음
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

          ; 파일 닫음
CloseExe1:mov  ah, 3Eh
          int  21h

          ; 바이러스 검사

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

          ; 바이러스 치료

TxExe:    inc  iInfFile            ; 감염 파일 수 증가
          mov  dx, pCurFile
          call PrintPathname       ; 파일 이름 출력

          push dx                  ; '바이러스 존재' 출력
          mov  ah, 9
          mov  dx, OFFSET szMsg5
          int  21h
          pop  dx

          ; 파일 오픈
          mov  ax, 4300h
          xor  cx, cx
          int  21h
          mov  ax, 3D02h
          int  21h
          jnc  SetFpExe2
          mov  dx, OFFSET szErrMsg2
          stc
          jmp  ExitCE

          ; 원래 CS, IP, SS, SP 값들 얻음
SetFpExe2:mov  bx, ax              ; 바이러스 시작 부위 읽음
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

GetEntry: mov  si, iOffCS          ; 원래 CS 값 얻음
          mov  ax, WORD PTR sBuffer[si]
          mov  WORD PTR sExeHead[16h], ax
          mov  si, iOffIP          ; 원래 IP 값 얻음
          mov  ax, WORD PTR sBuffer[si]
          mov  WORD PTR sExeHead[14h], ax
          mov  si, iOffSS          ; 원래 SS 값 얻음
          mov  ax, WORD PTR sBuffer[si]
          mov  WORD PTR sExeHead[0Eh], ax
          mov  si, iOffSP          ; 원래 SP 값 얻음
          mov  ax, WORD PTR sBuffer[si]
          mov  WORD PTR sExeHead[10h], ax

          ; 원래 길이 계산
          mov  dx, WORD PTR lOldLn[2]
          mov  ax, WORD PTR lOldLn
          mov  cx, 200h
          div  cx
          cmp  dx, 0
          jz   NoRmnd
          inc  ax
NoRmnd:   mov  WORD PTR sExeHead[2], dx
          mov  WORD PTR sExeHead[4], ax

          ; 선두영역 복구
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

          ; 파일 길이 복구
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

          ; 파일 닫음
CloseExe2:mov  ah, 3Eh
          int  21h

          mov  ah, 9               ; '-> 치료' 출력
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
PrintPathname  PROC                ; 완전한 패스 이름 출력

          push ax
          push dx
          push si

          push dx                  ; 드라이브 이름 출력
          mov  ah, 2
          mov  dl, cDrive
          add  dl, 'A'
          int  21h
          mov  dl, ':'
          int  21h

          mov  ah, 48h             ; 현재 디렉토리 얻음
          xor  dl, dl
          mov  si, OFFSET szCurDir + 1
          int  21h

          cmp  BYTE PTR [si], 0    ; 현재 디렉토리 이름 출력
          je   PrtFn
          dec  si
          mov  ah, 2
PathChr:  mov  dl, [si]
          cmp  dl, 0
          je   PrtFn
          int  21h
          inc  si
          jmp  PathChr

PrtFn:    mov  ah, 2               ; '\' 출력
          mov  dl, '\'
          int  21h

          pop  si                  ; 파일 이름 출력
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

