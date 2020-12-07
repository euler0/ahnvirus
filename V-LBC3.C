
/*---------------------------------------------------------------
;
;         V-LBC3    LBC 바이러스용 백신 프로그램
;
;                   (저) 1994  안 철 수
;
;--------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "vtools.h"

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
struct BvMemTx0 LbcMemTx = {
    0x178, 2
};
struct BvMbsTx10 LbcMbsTx = {
    0x5E, 0x63, 0x5D, 0
};

unsigned char cDrive;
int iResult;

char szPrgName[]  = "V-LBC3 Vaccine program for LBC virus\n"
             "       (c)Copyright 1994  by Cheolsoo Ahn\n\n";
char szMsg1[]    = "Usage: V-LBC3 <drive>\n";
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

    /* 일반 기억장소 검사 */

    printf("%s", szMsg2);          /* '기억장소 검사:' 출력 */
    if (CheckBootVirusInMem(&LbcMemDx) == 0)
        printf("%s", szMsg4);      /* '바이러스 없음' 출력 */
    else {
        printf("%s", szMsg5);      /* '바이러스 존재' 출력 */
        CureBootVirusInMem(0, &LbcMemTx);
        printf("%s", szMsg6);      /* '-> 치료' 출력 */
    }

    /* 부트 섹터 읽음 */

    printf("%s", szMsg3);          /* '부트 섹터 검사:' 출력 */
    if ((iResult=CheckBootVirusInMBS(cDrive,&LbcMbsDx)) == -1) {
        printf("%s", szErrMsg1);   /* 디스크 읽기 오류 */
        exit(1);
    }
    if (iResult == 0)
        printf("%s", szMsg4);      /* '바이러스 없음' 출력 */
    else {
		printf("%s", szMsg5);      /* '바이러스 존재' 출력 */
        if (CureBootVirusInMBS(cDrive, 0x10, &LbcMbsTx) == -1) {
            switch (wErrCode) {
                case 2: printf("%s", szErrMsg1);
                        exit(1);
                case 3: printf("%s", szErrMsg2);
                        exit(1);
            }
        } else
            printf("%s", szMsg6);      /* '-> 치료' 출력 */
    }

    return 0;
}

