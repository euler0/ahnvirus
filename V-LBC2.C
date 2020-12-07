
/*---------------------------------------------------------------
;
;         V-LBC2    LBC 바이러스용 백신 프로그램
;
;                   (저) 1994  안 철 수
;
;--------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <bios.h>
#include <dos.h>

struct DxStr {                     /* 문자열 스트럭쳐 정의 */
    unsigned int iOffset;
    unsigned char cLen, sVirStr[10];
};
struct DxStr LbcMemDx = {          /* 기억장소 진단용 문자열 */
    0x117,
    10,
    {0x48, 0x48, 0x89, 0x07, 0xB1, 0x06, 0xD3, 0xE0, 0x8E, 0xC0}
};
struct DxStr LbcMbsDx = {          /* 부트 섹터 진단용 문자열 */
    0x17,
    10,
    {0x48, 0x48, 0x89, 0x07, 0xB1, 0x06, 0xD3, 0xE0, 0x8E, 0xC0}
};
unsigned int iOffOld13 = 0x178;    /* 오프셋 주소 */
unsigned int iMemSize = 2;         /* 일반 기억장소 감소 크기 */
unsigned char i, cDrive, sBuffer[0x200];
char far *lpcMem;
int  far *lpiMem;
union REGS r;
struct SREGS sr;

char szPrgName[]  = "V-LBC2 Vaccine program for LBC virus\n"
                "      (c)Copyright 1994  by Cheolsoo Ahn\n\n";
char szMsg1[]    = "Usage: V-LBC2 <drive>\n";
char szMsg2[]    = "Checking the Memory : ";
char szMsg3[]    = "Checking Boot Sector: ";
char szMsg4[]    = "no LBC virus\n";
char szMsg5[]    = "\aLBC virus found";
char szMsg6[]    = " -> Cured\n";
char szErrMsg1[] = "\n\aERROR: disk read error\n";
char szErrMsg2[] = "\n\aERROR: disk write error\n";

int main(int argc, char *argv[])
{
    printf("%s", szPrgName);       /* 프로그램 이름 출력 */

    if (argc == 1) {               /* 인자 없을 때 도움말 출력 */
        printf("%s", szMsg1);
        exit(0);
    }

    cDrive = toupper(*argv[1]) - 'A';
    if (cDrive >= 2)
        cDrive += 0x7E;            /* 검사할 드라이브 알아냄 */

    /* 일반 기억장소 검사 */

    printf("%s", szMsg2);          /* '기억장소 검사:' 출력 */
    lpcMem = MK_FP(biosmemory() << 6, LbcMemDx.iOffset);
    for (i = 0; i < LbcMemDx.cLen; i++)
        if (lpcMem[i] != LbcMemDx.sVirStr[i]) break;
    if (i != LbcMemDx.cLen)
        printf("%s", szMsg4);      /* '바이러스 없음' 출력 */
    else {
        printf("%s", szMsg5);      /* '바이러스 존재' 출력 */
        r.x.ax = 0x2513;
        lpiMem = MK_FP(biosmemory() << 6, iOffOld13);
        r.x.dx = *lpiMem++;
        sr.ds  = *lpiMem;
        intdosx(&r, &r, &sr);      /* 13h번 인터럽트 주소 복구 */
        lpiMem = MK_FP(0x0000, 0x0413);
        *lpiMem += iMemSize;       /* 일반 기억장소의 크기 복구 */
        printf("%s", szMsg6);      /* '-> 치료' 출력 */
    }

    /* 부트 섹터 읽음 */

    printf("%s", szMsg3);          /* '부트 섹터 검사:' 출력 */

    r.h.ah = 0x0D;
    intdos(&r, &r);

    for (i = 0; i < 4; i++) {
        if (biosdisk(2, cDrive, 0, 0, 1, 1, sBuffer) == 0) break;
        biosdisk(0, cDrive, 0, 0, 1, 1, sBuffer);
    }
    if (i == 4) {
        printf("%s", szErrMsg1);   /* 디스크 읽기 오류 */
        exit(1);
    }

    /* 부트 섹터 검사 */

    for (i = 0; i < LbcMbsDx.cLen; i++)
        if (sBuffer[LbcMbsDx.iOffset + i] != LbcMbsDx.sVirStr[i])
            break;
    if (i != LbcMbsDx.cLen)
        printf("%s", szMsg4);      /* '바이러스 없음' 출력 */
    else {
        printf("%s", szMsg5);      /* '바이러스 존재' 출력 */

        /* 원래 부트 섹터 읽음 */
        if (biosdisk(2, cDrive, sBuffer[0x63], sBuffer[0x5E],
                      sBuffer[0x5D], 1, sBuffer)) {
            printf("%s", szErrMsg1); /* 디스크 읽기 오류 */
            exit(1);
        }

        /* 부트 섹터 치료 */
        if (biosdisk(3, cDrive, 0, 0, 1, 1, sBuffer)) {
            printf("%s", szErrMsg2); /* 디스크 쓰기 오류 */
            exit(1);
        }

        r.h.ah = 0x0D;
        intdos(&r, &r);

        printf("%s", szMsg6);      /* '-> 치료' 출력 */
    }

    return 0;
}


