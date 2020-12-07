
;----------------------------------------------------------------
;
;         V-LBC1    LBC 바이러스용 백신 프로그램
;
;                   (저) 1994  안 철 수
;
;----------------------------------------------------------------

          .MODEL  SMALL
          .STACK  100h
          .DATA
LbcMemDx  DW   117h
          DB   10
          DB   48h, 48h, 89h, 7, 0B1h, 6, 0D3h, 0E0h, 8Eh, 0C0h
LbcMbsDx  DW   17h
          DB   10
          DB   48h, 48h, 89h, 7, 0B1h, 6, 0D3h, 0E0h, 8Eh, 0C0h
iOffOld13 DW   178h                ; 오프셋 주소
iMemSize  DW   2                   ; 일반 기억장소 감소 크기
cDrive    DB   ?                   ; 검사할 드라이브
sBuffer   DB   200h DUP (?)        ; 부트 섹터 읽어들일 영역

szPrgName DB   'V-LBC1 Vaccine program for LBC virus'
          DB   0Dh, 0Ah
          DB   '       (c)Copyright 1994  by Cheolsoo Ahn'
          DB   0Dh, 0Ah, 0Ah, '$'
szMsg1    DB   'Usage: V-LBC1 <drive>', 0Dh, 0Ah, '$'
szMsg2    DB   'Checking the Memory : $'
szMsg3    DB   'Checking Boot Sector: $'
szMsg4    DB   'no LBC virus', 0Dh, 0Ah, '$'
szMsg5    DB   7, 'LBC virus found$'
szMsg6    DB   ' -> Cured', 0Dh, 0Ah, '$'
szErrMsg1 DB   0Dh, 0Ah, 7, 'ERROR: disk read error'
          DB   0Dh, 0Ah, '$'
szErrMsg2 DB   0Dh, 0Ah, 7, 'ERROR: disk write error'
          DB   0Dh, 0Ah, '$'

          .CODE
Start:    mov  ax, @data           ; DS 설정
          mov  ds, ax

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

ChkSpace: cmp  al, 20h             ; 공백 문자 때 재검사
          jne  ChkDrv
          inc  bx
          jmp  ChkEnd

ChkDrv:   and  al, 5Fh             ; 검사할 드라이브 알아냄
          sub  al, 'A'
          cmp  al, 2
          jb   SaveDrv
          add  al, 7Eh
SaveDrv:  mov  cDrive, al

          ; 일반 기억장소 검사

          mov  ah, 9               ; '기억장소 검사:' 출력
          mov  dx, OFFSET szMsg2
          int  21h

          xor  ax, ax
          mov  es, ax
          mov  ax, es:[0413h]      ; 일반 기억장소 크기 얻음
          mov  cl, 6
          shl  ax, cl
          mov  es, ax              ; 최상위 세그먼트 주소 얻음

          mov  si, OFFSET LbcMemDx ; 진단용 문자열
          lodsw                    ; 문자열의 위치 얻음
          mov  di, ax
          lodsb                    ; 문자열의 길이 얻음
          xor  cx, cx
          mov  cl, al
          repz cmpsb               ; 문자열 존재?
          je   TxBvMem

          mov  ah, 9               ; '바이러스 없음' 출력
          mov  dx, OFFSET szMsg4
          int  21h
          jmp  ReadMbs

          ; 일반 기억장소 치료

TxBvMem:  mov  ah, 9               ; '바이러스 존재' 출력
          mov  dx, OFFSET szMsg5
          int  21h

          push ds
          mov  ax, 2513h           ; 13h번 인터럽트 주소 복구
          mov  bx, iOffOld13
          lds  dx, es:[bx]
          int  21h
          pop  ds

          xor  ax, ax
          mov  es, ax
          mov  ax, iMemSize
          add  es:[0413h], ax      ; 일반 기억장소의 크기 복구

          mov  ah, 9               ; '-> 치료' 출력
          mov  dx, OFFSET szMsg6
          int  21h

          ; 부트 섹터 읽음

ReadMbs:  mov  ah, 9               ; '부트 섹터 검사' 출력
          mov  dx, OFFSET szMsg3
          int  21h

          mov  ah, 0Dh
          int  21h

          push ds
          pop  es
          mov  cx, 4
ReReadMbs:push cx
          mov  ax, 0201h           ; 한 섹터 읽음
          mov  cx, 0001            ; 0번 실린더, 1번 섹터
          mov  dh, 0               ; 0번 면
          mov  dl, cDrive          ; 디스크 드라이브
          mov  bx, OFFSET sBuffer  ; 버퍼 지정
          int  13h
          pop  cx
          jnc  ChkMbs              ; 디스크 읽기 성공때 점프
          xor  ah, ah              ; 디스크 리셋
          int  13h
          loop ReReadMbs           ; 다시 읽기 시도
          jmp  Err1                ; 디스크 읽기 실패때 점프

          ; 부트 섹터 검사

ChkMbs:   mov  si, OFFSET LbcMbsDx ; 진단용 문자열
          lodsw                    ; 문자열의 오프셋 주소
          mov  di, ax
          add  di, OFFSET sBuffer
          lodsb                    ; 문자열의 길이 얻음
          xor  cx, cx
          mov  cl, al
          repz cmpsb               ; 문자열 존재?
          je   TxBvMbs             ; 부트 바이러스 존재시 점프

          mov  ah, 9               ; '바이러스 없음' 출력
          mov  dx, OFFSET szMsg4
          int  21h
          jmp  Exit

          ; 원래 부트 섹터의 내용을 읽음

TxBvMbs:  mov  ah, 9               ; '바이러스 발견' 출력
          mov  dx, OFFSET szMsg5
          int  21h

          mov  ax, 0201h           ; 한 섹터 읽음
          mov  bx, OFFSET sBuffer  ; 버퍼 지정
          mov  dl, cDrive          ; 디스크 드라이브
          mov  ch, sBuffer[5Eh]    ; 원래 부트 섹터 저장 실린더
          mov  cl, sBuffer[5Dh]    ; 원래 부트 섹터 저장 섹터
          mov  dh, sBuffer[63h]    ; 원래 부트 섹터 저장 면
          int  13h
          jc   Err1                ; 디스크 읽기 실패때 점프

          ; 주 부트 섹터를 원래대로 고침

          mov  ax, 0301h           ; 한 섹터 씀
          mov  cx, 0001            ; 0번 실린더, 1번 섹터
          mov  dh, 00              ; 0번 면
          mov  dl, cDrive          ; 디스크 드라이브
          mov  bx, OFFSET sBuffer  ; 버퍼 지정
          int  13h
          jc   Err2                ; 디스크 쓰기 실패때 점프

          mov  ah, 0Dh
          int  21h

          mov  ah, 9               ; '-> 치료' 출력
          mov  dx, OFFSET szMsg6
          int  21h

          ; 실행 종료

Exit:     mov  ax, 4C00h           ; 실행 종료
          int  21h

Err1:     mov  dx, OFFSET szErrMsg1; '디스크 읽기 오류' 출력
          jmp  PrtErr
Err2:     mov  dx, OFFSET szErrMsg2; '디스크 쓰기 오류' 출력
PrtErr:   mov  ah, 9
          int  21h

          mov  ax, 4C01h           ; 실행 종료
          int  21h

          END  Start


