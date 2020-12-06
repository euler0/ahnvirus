
;----------------------------------------------------------------
;
;         Vaccine Toolkit for C language (Version 2.0)
;
;                   (∏·) 1994  ¥e ¿È ÆÅ
;
;----------------------------------------------------------------

.MODEL  SMALL

.STACK  100h

.DATA

          PUBLIC  _wErrCode

_wErrCode DW   0
ParaBlk   DW   5 DUP (?)
sBuffer   DB   200h DUP (?)
sExeHead  DB   20h  DUP (?)
lOldLn    DD   ?
wTemp     DW   ?

.CODE

          Arg1    EQU  [bp + 4]
          Arg2    EQU  [bp + 6]
          Arg3    EQU  [bp + 8]

          PUBLIC  _CheckBootVirusInMem, _CureBootVirusInMem
          PUBLIC  _CheckBootVirusInMBS, _CureBootVirusInMBS
          PUBLIC  _CheckBootVirusInDBS, _CureBootVirusInDBS
          PUBLIC  _CheckFileVirusInMem, _CureFileVirusInMem
          PUBLIC  _CheckFileType
          PUBLIC  _CheckFileVirusInCOM, _CureFileVirusInCOM
          PUBLIC  _CheckFileVirusInEXE, _CureFileVirusInEXE

;-----------------------------------------------------------

_CheckBootVirusInMem  PROC

          ; Function : check boot virus in memory
          ; Call with: address of diagnostic data structure
          ; Returns  : AX       =  0 (virus not found)
          ;                        1 (virus found)

          push bp
          mov  bp, sp

          push cx
          push si
          push di
          push es

          mov  si, Arg1

          int  12h
          mov  cl, 6                 ; segment address
          shl  ax, cl                ; = (size in KB) X 64
          mov  es, ax
          xor  di, di

          call CompareString
          mov  _wErrCode, 0

          pop  es
          pop  di
          pop  si
          pop  cx

          pop  bp
          ret

_CheckBootVirusInMem  ENDP

;-----------------------------------------------------------

_CureBootVirusInMem  PROC

          ; Function : disable boot virus in memory
          ; Call with: virus type
          ;            address of treatment data
          ; Returns: if function successful,
          ;            AX       =  0
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  1 (invalid virus type)

          push bp
          mov  bp, sp

          push cx
          push si
          push di

          mov  ax, Arg1
          mov  si, Arg2

          cmp  ax, 0
          je   BvMem0
          cmp  ax, 10h
          je   BvMem10
          jmp  ErTyBvMem

BvMem0:   lodsw
          push si
          mov  si, ax

          push ds
          int  12h
          mov  cl, 6
          shl  ax, cl
          mov  ds, ax

          mov  di, 13h
          call ResetIntA
          pop  ds
          pop  si

          jmp  ReMemSize

BvMem10:  lodsw
          push si
          mov  si, ax

          mov  di, 13h
          call ResetIntI
          pop  si

ReMemSize:push es
          xor  ax, ax
          mov  es, ax
          lodsw
          add  es:[413h], ax
          pop  es

          xor  ax, ax
          mov  _wErrCode, 0

ExCuBvMem:pop  di
          pop  si
          pop  cx

          pop  bp
          ret

ErTyBvMem:mov  ax, -1
          mov  _wErrCode, 1
          jmp  ExCuBvMem

_CureBootVirusInMem  ENDP

;-----------------------------------------------------------

_CheckBootVirusInMBS  PROC

          ; Function : check boot virus in master boot sector
          ; Call with: drive (0 = A, 1 = B, etc)
          ;            address of diagnostic string
          ; Returns: if function successful,
          ;            AX       = 0 (virus not found)
          ;                       1 (virus found)
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  2 (disk read error)

          push bp
          mov  bp, sp

          push bx
          push dx
          push si
          push di

          mov  dx, Arg1
          cmp  dl, 2
          jb   RdMbs
          add  dl, 7Eh

RdMbs:    mov  bx, OFFSET sBuffer
          call ReadMBS
          jc   ErRdMbs

          mov  si, Arg2
          mov  di, OFFSET sBuffer
          call CompareString
          mov  _wErrCode, 0

ExChBvMbs:pop  di
          pop  si
          pop  dx
          pop  bx

          pop  bp
          ret

ErRdMbs:  mov  ax, -1
          mov  _wErrCode, 2
          jmp  ExChBvMbs

_CheckBootVirusInMBS  ENDP

;-----------------------------------------------------------

_CureBootVirusInMBS  PROC

          ; Function : cure boot virus in master boot sector
          ; Call with: drive (0 = A, 1 = B, etc)
          ;            virus type
          ;            address of treatment string
          ; Returns: if function successful,
          ;            AX       =  0
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  1 (invalid virus type)
          ;                        2 (disk read error)
          ;                        3 (disk write error)

          push bp
          mov  bp, sp

          push bx
          push cx
          push dx
          push si

          mov  dx, Arg1
          cmp  dl, 2
          jb   ChkTyMbs
          add  dl, 7Eh

ChkTyMbs: mov  ax, Arg2
          mov  si, Arg3

          cmp  ax, 0
          je   BvMbs0
          cmp  ax, 10h
          je   BvMbs10
          jmp  ErTyMbs

BvMbs0:   lodsb
          mov  ch, al
          lodsb
          mov  dh, al
          lodsb
          mov  cl, al
          jmp  RdOldMbs

BvMbs10:  lodsw
          mov  bx, ax
          mov  ch, sBuffer[bx]
          lodsw
          mov  bx, ax
          mov  dh, sBuffer[bx]
          lodsw
          mov  bx, ax
          mov  cl, sBuffer[bx]
          lodsb
          add  cl, al

RdOldMbs: mov  al, 1
          mov  bx, OFFSET sBuffer
          call ReadPhysicalSector
          jc   ErRdMbsCu

          call WriteMBS
          jc   ErWtMbsCu

          xor  ax, ax
          mov  _wErrCode, 0

ExCuBvMbs:pop  si
          pop  dx
          pop  cx
          pop  bx

          pop  bp
          ret

ErTyMbs:  mov  ax, -1
          mov  _wErrCode, 1
          jmp  ExCuBvMbs

ErRdMbsCu:mov  ax, -1
          mov  _wErrCode, 2
          jmp  ExCuBvMbs

ErWtMbsCu:mov  ax, -1
          mov  _wErrCode, 3
          jmp  ExCuBvMbs

_CureBootVirusInMBS  ENDP

;-----------------------------------------------------------

_CheckBootVirusInDBS  PROC

          ; Function : check boot virus in DOS boot sector
          ; Call with: drive (0 = A, 1 = B, etc)
          ;            address of diagnostic string
          ; Returns: if function successful,
          ;            AX       =  0 (virus not found)
          ;                        1 (virus found)
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  2 (disk read error)

          push bp
          mov  bp, sp

          push bx
          push si
          push di

          mov  ax, Arg1
          mov  bx, OFFSET sBuffer
          call ReadDBS
          jc   ErRdDbs

          mov  si, Arg2
          mov  di, OFFSET sBuffer
          call CompareString
          mov  _wErrCode, 0

ExChBvDbs:pop  di
          pop  si
          pop  bx

          pop  bp
          ret

ErRdDbs:  mov  ax, -1
          mov  _wErrCode, 2
          jmp  ExChBvDbs

_CheckBootVirusInDBS  ENDP

;-----------------------------------------------------------

_CureBootVirusInDBS  PROC

          ; Function : cure boot virus in DOS boot sector
          ; Call with: drive (0 = A, 1 = B, etc)
          ;            virus type
          ;            address of treatment string
          ; Returns: if function successful,
          ;            AX       =  0
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  1 (invalid virus type)
          ;                        2 (disk read error)
          ;                        3 (disk write error)

          push bp
          mov  bp, sp

          push bx
          push cx
          push dx
          push es

          mov  ax, Arg2
          mov  si, Arg3

          cmp  ax, 80h
          je   BvDbs1
          cmp  ax, 90h
          je   BvDbs1
          cmp  ax, 0A0h
          je   BvDbsA0
          cmp  ax, 0B0h
          je   BvDbsB0
          jmp  ErTyDbs

BvDbs1:   mov  dx, Arg1
          cmp  dl, 2
          jb   ChkBvDbs1
          add  dl, 7Eh

ChkBvDbs1:cmp  ax, 90h
          je   BvDbs90

          lodsb
          mov  ch, al
          lodsb
          mov  dh, al
          lodsb
          mov  cl, al
          jmp  RdOldDbs1

BvDbs90:  lodsw
          mov  bx, ax
          mov  ch, sBuffer[bx]
          lodsw
          mov  bx, ax
          mov  dh, sBuffer[bx]
          lodsw
          mov  bx, ax
          mov  cl, sBuffer[bx]
          lodsb
          add  cl, al

RdOldDbs1:mov  al, 1
          mov  bx, OFFSET sBuffer
          call ReadPhysicalSector
          jnc  WtOldDbs
          jmp  ErRdDbsCu

BvDbsA0:  lodsw
          mov  dx, ax
          jmp  RdOldDbs2

BvDbsB0:  lodsw
          mov  bx, ax
          mov  dx, WORD PTR sBuffer[bx]
          lodsw
          add  dx, ax

RdOldDbs2:mov  al, Arg1
          mov  bx, OFFSET sBuffer
          mov  cx, 0001
          call ReadLogicalSector
          jc   ErRdDbsCu

WtOldDbs: mov  al, Arg1
          call WriteDBS
          jc   ErWtDbsCu

          xor  ax, ax
          mov  _wErrCode, 0

ExCuBvDbs:pop  es
          pop  dx
          pop  cx
          pop  bx

          pop  bp
          ret

ErTyDbs:  mov  ax, -1
          mov  _wErrCode, 1
          jmp  ExCuBvDbs

ErRdDbsCu:mov  ax, -1
          mov  _wErrCode, 2
          jmp  ExCuBvDbs

ErWtDbsCu:mov  ax, -1
          mov  _wErrCode, 3
          jmp  ExCuBvDbs

_CureBootVirusInDBS  ENDP

;-----------------------------------------------------------

_CheckFileVirusInMem  PROC

          ; Function : check file virus in memory
          ; Call with: address of diagnostic string
          ; Returns  : AX    = 0 (virus not found)
          ;            AX    = 1 (virus found)

          push bp
          mov  bp, sp

          push si
          push di
          push es

          mov  si, Arg1

          xor  ax, ax
          mov  es, ax
          xor  di, di
          mov  es, es:[86h]

          call CompareString
          mov  _wErrCode, 0

          pop  es
          pop  di
          pop  si

          pop  bp
          ret

_CheckFileVirusInMem  ENDP

;-----------------------------------------------------------

_CureFileVirusInMem  PROC

          ; Function : disable file virus in memory
          ; Call with: virus type
          ;            address of treatment string
          ; Returns: if function successful,
          ;            AX       =  0
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  1 (invalid virus type)

          push bp
          mov  bp, sp

          push si
          push di

          mov  ax, Arg1
          mov  si, Arg2

          cmp  al, 80h
          je   FvMem80
          jmp  ErTyFvMem

FvMem80:  lodsw
          mov  si, ax

          push ds
          xor  ax, ax
          mov  ds, ax
          mov  ds, ds:[86h]

          mov  di, 21h
          call ResetIntA
          pop  ds

          xor  ax, ax
          mov  _wErrCode, 0

ExCuFvMem:pop  di
          pop  si

          pop  bp
          ret

ErTyFvMem:mov  ax, -1
          mov  _wErrCode, 1
          jmp  ExCuFvMem

_CureFileVirusInMem  ENDP

;-----------------------------------------------------------

_CheckFileType  PROC

          ; Function : check the type of the file
          ; Call with: DS:DX = address of ASCIIZ filename
          ; Returns: if function successful,
          ;            AX       =  0 (COM file)
          ;                        1 (EXE file)
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  4 (open error)
          ;                        5 (file read error)

          push bp
          mov  bp, sp

          push bx
          push cx
          push dx

          call OpenFileForRead
          jc   ErOpFile

          mov  bx, ax
          mov  cx, 2
          mov  dx, OFFSET wTemp
          call ReadFile
          jc   ErRdFile

          call CloseFile

          cmp  WORD PTR wTemp, 'MZ'
          je   ExeFile
          cmp  WORD PTR wTemp, 'ZM'
          je   ExeFile

          xor  ax, ax
          mov  _wErrCode, 0
          jmp  ExChFile

ExeFile:  mov  ax, 1
          mov  _wErrCode, 0

ExChFile: pop  dx
          pop  cx
          pop  bx

          pop  bp
          ret

ErOpFile: mov  ax, -1
          mov  _wErrCode, 4
          jmp  ExChFile

ErRdFile: mov  ax, -1
          mov  _wErrCode, 5
          jmp  ExChFile

_CheckFileType  ENDP

;-----------------------------------------------------------

_CheckFileVirusInCOM  PROC

          ; Function : check file virus in COM file
          ; Call with: address of ASCIIZ filename
          ;            address of diagnostic string
          ; Returns: if function successful,
          ;            AX       =  0 (virus not found)
          ;                        1 (virus found)
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  4  (open error)
          ;                        5  (file read error)

          push bp
          mov  bp, sp

          push bx
          push cx
          push dx
          push si
          push di

          mov  dx, Arg1
          call OpenFileForRead
          jc   ErOpCom

          mov  bx, ax
          mov  cx, 200h
          mov  dx, OFFSET sBuffer
          call ReadFile
          Jc   ErRdCom

          mov  cx, 3
          mov  dx, 2
          mov  si, OFFSET sBuffer
ChkJmp:   lodsb
          inc  dx
          cmp  al, 0E9h
          je   CalComE
          cmp  al, 0E8h
          je   CalComE
          loop ChkJmp
          jmp  ClsCom

CalComE: lodsw
          add  dx, ax
          xor  cx, cx
          call SetFilePointer

          mov  cx, 200h
          mov  dx, OFFSET sBuffer
          call ReadFile
          jc   ErRdCom

ClsCom:   call CloseFile

          mov  si, Arg2
          mov  di, OFFSET sBuffer
          call CompareString
          mov  _wErrCode, 0

ExChFvCom:pop  di
          pop  si
          pop  dx
          pop  cx
          pop  bx

          pop  bp
          ret

ErOpCom:  mov  ax, -1
          mov  _wErrCode, 4
          jmp  ExChFvCom

ErRdCom:  mov  ax, -1
          mov  _wErrCode, 5
          jmp  ExChFvCom

_CheckFileVirusInCOM  ENDP

;-----------------------------------------------------------

_CureFileVirusInCOM  PROC

          ; Function : cure file virus in COM file
          ; Call with: address of ASCIIZ filename
          ;            virus type
          ;            address of treatment string
          ; Returns: if function successful,
          ;            AX       =  0
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  1 (invalid virus type)
          ;                        4 (open error)
          ;                        5 (file read error)
          ;                        6 (file write error)
          ;                        7 (set attribute error)
          ;                        8 (delete error)
          ;                        9 (insufficient memory)

          push bp
          mov  bp, sp

          push bx
          push cx
          push dx
          push si

          mov  dx, Arg1
          xor  cx, cx
          call SetFileAttr
          jnc  DelCom
          jmp  ErAtComCu

DelCom:   cmp  WORD PTR Arg2, 0
          jne  OpComCu

          mov  dx, Arg1
          call DeleteFile
          jc   ErDCC
          jmp  ScCuCom
ErDCC:    jmp  ErDlComCu

OpComCu:  mov  dx, Arg1
          call OpenFileForWrite
          jnc  ReadCom
          jmp  ErOpComCu

ReadCom:  mov  bx, ax
          mov  cx, 200h
          mov  dx, OFFSET sBuffer
          call ReadFile
          jnc  ChkTyCom1
          jmp  ErRdComCu

ChkTyCom1:mov  ax, Arg2
          cmp  ax, 10h
          je   AppdType
          cmp  ax, 20h
          je   AppdType
          cmp  ax, 30h
          je   PT
          cmp  ax, 40h
          je   PT
ErTC:     jmp  ErTyCom
PT:       jmp  PrpdType

AppdType: mov  cx, 3
          mov  dx, 2
          mov  si, OFFSET sBuffer
ChkJmpCu: lodsb
          inc  dx
          cmp  al, 0E9h
          je   CalComECu
          cmp  al, 0E8h
          je   CalComECu
          loop ChkJmpCu
          jmp  ErTC

CalComECu:lodsw
          add  dx, ax

          mov  si, Arg3
          lodsw
          sub  dx, ax
          mov  WORD PTR lOldLn, dx

          lodsw
          add  dx, ax
          xor  cx, cx
          call SetFilePointer

          lodsw
          mov  cx, ax
          mov  dx, OFFSET sBuffer
          call ReadFile
          jnc  RprCom1
          jmp  ErRdComCu

RprCom1:  call SetFPtoStart
          mov  cx, [si - 2]
          mov  dx, OFFSET sBuffer
          call WriteFile
          jnc  ChkTyCom2
          jmp  ErWtComCu

ChkTyCom2:cmp  WORD PTR Arg2, 10h
          jne  AdjFS
          jmp  ClComCu
AdjFS:    jmp  AdjstFS

PrpdType: mov  si, Arg3
          mov  dx, [si + 2]
          xor  cx, cx
          call SetReadWord
          jnc  GetOldLn
          jmp  ErRdComCu

GetOldLn: mov  WORD PTR lOldLn, ax
          mov  cx, ax
          lodsw
          mov  dx, ax
          cmp  WORD PTR Arg2, 40h
          jne  AllocMem
          cmp  dx, cx
          jae  AllocMem
          xchg dx, cx

AllocMem: push cx
          xor  cx, cx
          call SetFilePointer
          pop  cx

          push bx
          mov  ah, 48h
          mov  bx, 1000h
          int  21h
          pop  bx
          jnc  RdOldCom
          jmp  ErMmComCu

RdOldCom: push ds
          push es
          mov  es, ax
          push es
          pop  ds
          xor  dx, dx
          call ReadFile
          jnc  RprCom2

          mov  ah, 49h
          int  21h
          pop  es
          pop  ds
          jmp  ErRdComCu

RprCom2:  call SetFPtoStart

          call WriteFile
          jnc  DeMem

          mov  ah, 49h
          int  21h
          pop  es
          pop  ds
          jmp  ErWtComCu

DeMem:    mov  ah, 49h
          int  21h
          pop  es
          pop  ds

AdjstFS:  mov  dx, WORD PTR lOldLn
          xor  cx, cx
          call AdjustFileSize

ClComCu:  call CloseFile

ScCuCom:  xor  ax, ax
          mov  _wErrCode, 0

ExCuFvCom:pop  si
          pop  dx
          pop  cx
          pop  bx

          pop  bp
          ret

ErTyCom:  mov  ax, -1
          mov  _wErrCode, 1
          jmp  ExCuFvCom

ErOpComCu:mov  ax, -1
          mov  _wErrCode, 4
          jmp  ExCuFvCom

ErRdComCu:mov  ax, -1
          mov  _wErrCode, 5
          jmp  ExCuFvCom

ErWtComCu:mov  ax, -1
          mov  _wErrCode, 6
          jmp  ExCuFvCom

ErAtComCu:mov  ax, -1
          mov  _wErrCode, 7
          jmp  ExCuFvCom

ErDlComCu:mov  ax, -1
          mov  _wErrCode, 8
          jmp  ExCuFvCom

ErMmComCu:mov  ax, -1
          mov  _wErrCode, 9
          jmp  ExCuFvCom

_CureFileVirusInCOM  ENDP

;-----------------------------------------------------------

_CheckFileVirusInEXE  PROC

          ; Function : check file virus in EXE file
          ; Call with: address of ASCIIZ filename
          ;            address of diagnostic string
          ; Returns: if function successful,
          ;            AX       =  0 (virus not found)
          ;                        1 (virus found)
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  4 (open error)
          ;                        5 (file read error)

          push bp
          mov  bp, sp

          push bx
          push cx
          push dx
          push si
          push di

          mov  dx, Arg1
          call OpenFileForRead
          jc   ErOpExe

          mov  bx, ax
          mov  cx, 20h
          mov  dx, OFFSET sExeHead
          call ReadFile
          jc   ErRdExe

          mov  ax, WORD PTR sExeHead[8]
          add  ax, WORD PTR sExeHead[16h]
          mov  dx, 10h
          mul  dx
          add  ax, WORD PTR sExeHead[14h]
          adc  dx, 0
          mov  cx, dx                   ; pointer to entry
          mov  dx, ax
          call SetFilePointer

          mov  cx, 200h
          mov  dx, OFFSET sBuffer
          call ReadFile
          jc   ErRdExe

          call CloseFile

          mov  si, Arg2
          mov  di, OFFSET sBuffer
          call CompareString
          mov  _wErrCode, 0

ExChFvExe:pop  di
          pop  si
          pop  dx
          pop  cx
          pop  bx

          pop  bp
          ret

ErOpExe:  mov  ax, -1
          mov  _wErrCode, 4
          jmp  ExChFvExe

ErRdExe:  mov  ax, -1
          mov  _wErrCode, 5
          jmp  ExChFvExe

_CheckFileVirusInEXE  ENDP

;-----------------------------------------------------------

_CureFileVirusInEXE  PROC

          ; Function : cure file virus in EXE file
          ; Call with: address of ASCIIZ filename
          ;            virus type
          ;            address of treatment string
          ; Returns: if function successful,
          ;            AX       =  0
          ;          if function unsuccessful,
          ;            AX       = -1
          ;            wErrCode =  1 (invalid virus type)
          ;                        4 (open error)
          ;                        5 (file read error)
          ;                        6 (file write error)
          ;                        7 (set attribute error)
          ;                        8 (delete error)

          push bp
          mov  bp, sp

          push bx
          push cx
          push dx
          push si

          mov  dx, Arg1
          xor  cx, cx
          call SetFileAttr
          jnc  DelExe
          jmp  ErAtExeCu

DelExe:   cmp  WORD PTR Arg2, 80h
          jne  OpExeCu

          mov  dx, Arg1
          call DeleteFile
          jc   ErDEC
          jmp  ScCuExe
ErDEC:    jmp  ErDlExeCu

OpExeCu:  mov  dx, Arg1
          call OpenFileForWrite
          jnc  RdExeHead
          jmp  ErOpExeCu

RdExeHead:mov  bx, ax
          mov  cx, 20h
          mov  dx, OFFSET sExeHead
          call ReadFile
          jnc  CalExeE
          jmp  ErRdExeCu

CalExeE:  mov  ax, WORD PTR sExeHead[8]
          add  ax, WORD PTR sExeHead[16h]
          mov  dx, 10h
          mul  dx
          add  ax, WORD PTR sExeHead[14h]
          adc  dx, 0
          mov  cx, dx                   ; pointer to entry
          mov  dx, ax

          mov  ax, Arg2
          cmp  ax, 90h
          je   FvExe90
          cmp  ax, 0A0h
          je   FvExeA0
          jmp  ErTyExe

FvExe90:  mov  si, Arg3
          lodsw
          sub  dx, ax
          sbb  cx, 0
          mov  WORD PTR lOldLn, dx
          mov  WORD PTR lOldLn[2], cx

          lodsw
          add  dx, ax
          adc  cx, 0
          call SetFilePointer

          lodsw
          mov  cx, ax
          mov  dx, OFFSET sExeHead
          call ReadFile
          jc   ErREC
          jmp  RprHead
ErREC:    jmp  ErRdExeCu

FvExeA0:  mov  si, Arg3
          lodsw
          sub  dx, ax
          sbb  cx, 0
          mov  WORD PTR lOldLn, dx
          mov  WORD PTR lOldLn[2], cx

          lodsw
          cmp  ax, -1
          je   ReadIP
          add  dx, ax
          adc  cx, 0
          call SetReadWord
          jnc  ResetCS
          jmp  ErRdExeCu

ResetCS:  mov  WORD PTR sExeHead[16h], ax
          lodsw
          add  WORD PTR sExeHead[16h], ax

ReadIP:   mov  dx, WORD PTR lOldLn
          mov  cx, WORD PTR lOldLn[2]

          lodsw
          cmp  ax, -1
          je   ReadSS
          add  dx, ax
          adc  cx, 0
          call SetReadWord
          jnc  ResetIP
          jmp  ErRdExeCu

ResetIP:  mov  WORD PTR sExeHead[14h], ax
          lodsw
          add  WORD PTR sExeHead[14h], ax

ReadSS:   mov  dx, WORD PTR lOldLn
          mov  cx, WORD PTR lOldLn[2]

          lodsw
          cmp  ax, -1
          je   ReadSP
          add  dx, ax
          adc  cx, 0
          call SetReadWord
          jnc  ResetSS
          jmp  ErRdExeCu

ResetSS:  mov  WORD PTR sExeHead[0Eh], ax
          lodsw
          add  WORD PTR sExeHead[0Eh], ax

ReadSP:   mov  dx, WORD PTR lOldLn
          mov  cx, WORD PTR lOldLn[2]

          lodsw
          cmp  ax, -1
          je   ResetLen
          add  dx, ax
          adc  cx, 0
          call SetReadWord
          jnc  ResetSP
          jmp  ErRdExeCu

ResetSP:  mov  WORD PTR sExeHead[10h], ax
          lodsw
          add  WORD PTR sExeHead[10h], ax

ResetLen: mov  ax, WORD PTR lOldLn
          mov  dx, WORD PTR lOldLn[2]
          mov  cx, 200h
          div  cx
          cmp  dx, 0
          jz   NoRmnd
          inc  ax
NoRmnd:   mov  WORD PTR sExeHead[2], dx
          mov  WORD PTR sExeHead[4], ax

RprHead:  call SetFPtoStart
          mov  cx, 20h
          mov  dx, OFFSET sExeHead
          call WriteFile
          jc   ErWtExeCu

          mov  dx, WORD PTR lOldLn
          mov  cx, WORD PTR lOldLn[2]
          call AdjustFileSize
          jc   ErWtExeCu

          call CloseFile

ScCuExe:  xor  ax, ax
          mov  _wErrCode, 0

ExCuFvExe:pop  si
          pop  dx
          pop  cx
          pop  bx

          pop  bp
          ret

ErTyExe:  mov  ax, -1
          mov  _wErrCode, 1
          jmp  ExCuFvExe

ErOpExeCu:mov  ax, -1
          mov  _wErrCode, 4
          jmp  ExCuFvExe

ErRdExeCu:mov  ax, -1
          mov  _wErrCode, 5
          jmp  ExCuFvExe

ErWtExeCu:mov  ax, -1
          mov  _wErrCode, 6
          jmp  ExCuFvExe

ErAtExeCu:mov  ax, -1
          mov  _wErrCode, 7
          jmp  ExCuFvExe

ErDlExeCu:mov  ax, -1
          mov  _wErrCode, 8
          jmp  ExCuFvExe

_CureFileVirusInEXE  ENDP

;-----------------------------------------------------------

GetDosVer  PROC  NEAR

          ; Function: get DOS version
          ; Returns : AX = DOS version

          push bx
          push cx

          mov  ax, 3000h
          int  21h
          xchg ah, al

          pop  cx
          pop  bx
          ret

GetDosVer  ENDP

;-----------------------------------------------------------

CompareString  PROC  NEAR

          ; Function : compare the diagnostic string
          ; Call with: DS:SI = address of diagnostic string
          ;            ES:DI = address of buffer
          ; Returns: if string is absent,
          ;            AX    = 0
          ;          if string is present,
          ;            AX    = 1

          push cx
          push si
          push di

          lodsw
          add  di, ax

          lodsb
          xor  ch, ch
          mov  cl, al
          repz cmpsb
          je   StrMtch

          xor  ax, ax
          jmp  ExitCS

StrMtch:  mov  ax, 1

ExitCS:   pop  di
          pop  si
          pop  cx
          ret

CompareString  ENDP

;-----------------------------------------------------------

ResetIntA  PROC  NEAR

          ; Function : reset the interrupt using int vector
          ; Call with: DI    = interrupt number
          ;            DS:SI = address in virus program of
          ;                      previous interrupt vector

          push ax
          push si
          push di
          push es

          xor  ax, ax
          mov  es, ax
          shl  di, 1
          shl  di, 1

          cli
          movsw
          movsw
          sti

          pop  es
          pop  di
          pop  si
          pop  ax
          ret

ResetIntA  ENDP

;-----------------------------------------------------------

ResetIntI  PROC  NEAR

          ; Function : reset the interrupt using int number
          ; Call with: DI = interrupt number
          ;            SI = interrupt number of containing
          ;                      previous interrupt vector

          push ax
          push si
          push di
          push ds
          push es

          xor  ax, ax
          mov  ds, ax
          mov  es, ax
          shl  si, 1
          shl  si, 1
          shl  di, 1
          shl  di, 1

          cli
          movsw
          movsw
          sti

          pop  es
          pop  ds
          pop  di
          pop  si
          pop  ax
          ret

ResetIntI  ENDP

;-----------------------------------------------------------

ResetDisk  PROC  NEAR

          ; Function : reset the disk

          push ax

          mov  ah, 0Dh
          int  21h

          pop  ax
          ret


ResetDisk  ENDP

;-----------------------------------------------------------

ReadMBS  PROC  NEAR

          ; Function : read the master boot sector
          ; Call with: DL    = drive
          ;            ES:BX = address of buffer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push ax
          push cx
          push dx

          mov  al, 1
          mov  cx, 0001
          xor  dh, dh
          call ReadPhysicalSector

          pop  dx
          pop  cx
          pop  ax
          ret

ReadMBS  ENDP

;-----------------------------------------------------------

ReadPhysicalSector  PROC  NEAR

          ; Function : read the physical sector
          ; Call with: AL    = number of sector
          ;            CH    = cylinder
          ;            CL    = sector
          ;            DH    = head
          ;            DL    = drive
          ;            ES:BX = address of buffer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push si

          call ResetDisk

          xor  si, si

RPS:      mov  ah, 2
          int  13h
          jnc  ExitRPS

          cmp  si, 4
          je   ErrRPS
          xor  ah, ah
          int  13h
          inc  si
          jmp  RPS

ErrRPS:   stc

ExitRPS:  pop  si
          ret

ReadPhysicalSector  ENDP

;-----------------------------------------------------------

WriteMBS  PROC  NEAR

          ; Function : write the master boot sector
          ; Call with: DL    = drive
          ;            ES:BX = address of buffer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push cx
          push dx

          mov  al, 1
          mov  cx, 0001
          xor  dh, dh
          call WritePhysicalSector

          pop  dx
          pop  cx
          ret

WriteMBS  ENDP

;-----------------------------------------------------------

WritePhysicalSector  PROC  NEAR

          ; Function : write the physical sector
          ; Call with: AL    = number of sector
          ;            CH    = cylinder
          ;            CL    = sector
          ;            DH    = head
          ;            DL    = drive
          ;            ES:BX = address of buffer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push si

          call ResetDisk

          xor  si, si

WPS:      mov  ah, 3
          int  13h
          jnc  ExitWPS

          cmp  si, 4
          je   ErrWPS
          xor  ah, ah
          int  13h
          inc  si
          jmp  WPS

ErrWPS:   stc
          pop  si
          ret

ExitWPS:  call ResetDisk
          pop  si
          ret

WritePhysicalSector  ENDP

;-----------------------------------------------------------

ReadDBS   PROC  NEAR

          ; Function : read the DOS boot sector
          ; Call with: AL    = drive (0 = A, 1 = B, etc)
          ;            DS:BX = address of buffer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push cx
          push dx

          mov  cx, 0001
          xor  dx, dx
          call ReadLogicalSector

          pop  dx
          pop  cx
          ret

ReadDBS   ENDP

;-----------------------------------------------------------

ReadLogicalSector  PROC  NEAR

          ; Function : read the logical sector
          ; Call with: AL    = drive (0 = A, 1 = B, etc)
          ;            CX    = number of sectors
          ;            DX    = starting sector
          ;            DS:BX = address of buffer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push ax
          push bx
          push cx
          push dx
          push bp
          push si
          push di

          call ResetDisk

          push ax
          call GetDosVer
          cmp  ax, 400h
          jae  DOS4Read

          pop  ax
          int  25h
          pop  ax
          jmp  ExitRLS

DOS4Read: pop  ax
          mov  si, OFFSET ParaBlk
          mov  [si], dx
          mov  WORD PTR [si + 2], 0
          mov  [si + 4], cx
          mov  [si + 6], bx
          mov  [si + 8], ds

          mov  cx, -1
          mov  bx, si
          int  25h
          pop  ax

ExitRLS:  pop  di
          pop  si
          pop  bp
          pop  dx
          pop  cx
          pop  bx
          pop  ax
          ret

ReadLogicalSector  ENDP

;-----------------------------------------------------------

WriteDBS  PROC  NEAR

          ; Function : write the DOS boot sector
          ; Call with: AL    = drive (0 = A, 1 = B, etc)
          ;            DS:BX = address of buffer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push cx
          push dx

          mov  cx, 0001
          xor  dx, dx
          call WriteLogicalSector

          pop  dx
          pop  cx
          ret

WriteDBS  ENDP

;-----------------------------------------------------------

WriteLogicalSector  PROC  NEAR

          ; Function : write the logical sector
          ; Call with: AL    = drive (0 = A, 1 = B, etc)
          ;            CX    = number of sectors
          ;            DX    = starting sector
          ;            DS:BX = address of buffer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push ax
          push bx
          push cx
          push dx
          push bp
          push si
          push di

          call ResetDisk

          push ax
          call GetDosVer
          cmp  ax, 400h
          jae  DOS4Write

          pop  ax
          int  26h
          pop  ax
          jc   ExitWLS
          jmp  ScsWLS

DOS4Write:pop  ax
          mov  si, OFFSET ParaBlk
          mov  [si], dx
          mov  WORD PTR [si + 2], 0
          mov  [si + 4], cx
          mov  [si + 6], bx
          mov  [si + 8], ds

          mov  cx, -1
          mov  bx, si
          int  26h
          pop  ax
          jc   ExitWLS

ScsWLS:   call ResetDisk

ExitWLS:  pop  di
          pop  si
          pop  bp
          pop  dx
          pop  cx
          pop  bx
          pop  ax
          ret

WriteLogicalSector  ENDP

;-----------------------------------------------------------

OpenFileForRead  PROC  NEAR

          ; Function : open file for read
          ; Call with: DS:DX = address of ASCIIZ filename
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;            AX         = handle
          ;          if function unsuccessful,
          ;            Carry flag = set

          mov  ax, 3D00h
          int  21h
          ret

OpenFileForRead  ENDP

;-----------------------------------------------------------

OpenFileForWrite  PROC  NEAR

          ; Function : open file for read/write
          ; Call with: DS:DX = address of ASCIIZ filename
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;            AX         = handle
          ;          if function unsuccessful,
          ;            Carry flag = set

          mov  ax, 3D02h
          int  21h
          ret

OpenFileForWrite  ENDP

;-----------------------------------------------------------

ReadFile  PROC  NEAR

          ; Function : read file
          ; Call with: BX    = handle
          ;            CX    = number of bytes to read
          ;            DS:DX = address of buffer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push ax
          push di

          push cx
          mov  di, dx
          xor  al, al
          rep  stosb
          pop  cx

          mov  ah, 3Fh
          int  21h
          jnc  ExitRF

          mov  ah, 3Eh
          int  21h
          stc

ExitRF:   pop  di
          pop  ax
          ret

ReadFile  ENDP

;-----------------------------------------------------------

WriteFile  PROC  NEAR

          ; Function : write file
          ; Call with: BX    = handle
          ;            CX    = number of bytes to read
          ;            DS:DX = address of buffer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push ax

          mov  ah, 40h
          int  21h
          jnc  ExitWF

          mov  ah, 3Eh
          int  21h
          stc

ExitWF:   pop  ax
          ret

WriteFile  ENDP

;-----------------------------------------------------------

SetFilePointer  PROC  NEAR

          ; Function : set file pointer
          ; Call with: BX    = handle
          ;            CX:DX = file pointer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;            DX:AX      = file pointer
          ;          if function unsuccessful,
          ;            Carry flag = set

          push ax

          mov  ax, 4200h
          int  21h

          pop  ax
          ret

SetFilePointer  ENDP

;-----------------------------------------------------------

SetFPtoStart  PROC  NEAR

          ; Function : set file pointer to start of file
          ; Call with: BX    = handle
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push ax
          push cx
          push dx

          mov  ax, 4200h
          xor  cx, cx
          xor  dx, dx
          int  21h

          pop  dx
          pop  cx
          pop  ax
          ret

SetFPtoStart  ENDP

;-----------------------------------------------------------

SetReadWord  PROC  NEAR

          ; Function : set file pointer and read word value
          ; Call with: BX    = handle
          ;            CX:DX = file pointer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;            AX         = word value
          ;          if function unsuccessful,
          ;            Carry flag = set

          push cx
          push dx

          call SetFilePointer

          mov  cx, 2
          mov  dx, OFFSET wTemp
          call ReadFile
          jc   ExitSRW

          mov  ax, wTemp

ExitSRW:  pop  dx
          pop  cx
          ret

SetReadWord  ENDP

;-----------------------------------------------------------

AdjustFileSize  PROC  NEAR

          ; Function : adjust the size of file
          ; Call with: BX    = handle
          ;            CX:DX = file pointer
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push cx
          push dx

          call SetFilePointer

          xor  cx, cx
          call WriteFile

          pop  dx
          pop  cx
          ret

AdjustFileSize  ENDP

;-----------------------------------------------------------

CloseFile  PROC  NEAR

          ; Function : close file
          ; Call with: BX    = handle
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push ax

          mov  ah, 3Eh
          int  21h

          pop  ax
          ret

CloseFile  ENDP

;-----------------------------------------------------------

SetFileAttr  PROC  NEAR

          ; Function : set the file attribute
          ; Call with: DS:DX = address of ASCIIZ filename
          ;            CX    = file attribute
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push ax

          mov  ax, 4301h
          int  21h

          pop  ax
          ret

SetFileAttr  ENDP

;-----------------------------------------------------------

DeleteFile  PROC  NEAR

          ; Function : delete file
          ; Call with: DS:DX = address of ASCIIZ filename
          ; Returns: if function successful,
          ;            Carry flag = clear
          ;          if function unsuccessful,
          ;            Carry flag = set

          push ax

          mov  ah, 41h
          int  21h

          pop  ax
          ret

DeleteFile  ENDP

;-----------------------------------------------------------

END

