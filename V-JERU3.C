
/*---------------------------------------------------------------
;
;         V-JERU3   예루살렘 바이러스용 백신 프로그램
;
;                   (저) 1994  안 철 수
;
;--------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <dos.h>
#include <dir.h>
#include <ctype.h>
#include <string.h>
#include "vtools.h"

#define FA_LIST (FA_RDONLY|FA_HIDDEN|FA_SYSTEM|FA_DIREC|FA_ARCH)

struct DxStr JeruMemDx = {         /* 기억장소 진단용 문자열 */
    0x00C5,
    10,
    {0xFC, 0x06, 0x2E, 0x8C, 0x06, 0x31, 0x00, 0x2E, 0x8C, 0x06}
};
struct DxStr JeruComDx = {         /* COM 파일 진단용 문자열 */
    0x0030,
    10,
    {0xFC, 0x06, 0x2E, 0x8C, 0x06, 0x31, 0x00, 0x2E, 0x8C, 0x06}
};
struct DxStr JeruExeDx = {         /* EXE 파일 진단용 문자열 */
    0x0000,
    10,
    {0xFC, 0x06, 0x2E, 0x8C, 0x06, 0x31, 0x00, 0x2E, 0x8C, 0x06}
};
struct FvMemTx80 JeruMemTx = {
    0x17
};
struct FvComTx30 JeruComTx = {
    0x710, 0x11
};
struct FvExeTxA0 JeruExeTx = {
    0xC5, 0x49, 0, 0x47, 0, 0x45, 0, 0x43, 0
};

unsigned char cDrive;              /* 검사할 드라이브 */
unsigned int iInfFile = 0;         /* 감염 파일 수 */

char szPrgName[]  = "V-JERU Vaccine program for Jerusalem virus"
               "\n       (c)Copyright 1994  by Cheolsoo Ahn\n\n";
char szMsg1[]    = "Usage: V-JERU <drive>\n";
char szMsg2[]    = "Checking the Memory : ";
char szMsg3[]    = "Checking the Files  : ";
char szMsg4[]    = "no Jerusalem virus\n";
char szMsg5[]    = " : ";
char szMsg6[]    = "\aJerusalem virus found";
char szMsg7[]    = " -> Cured\n";
char szErrMsg1[] = "\n\aERROR: insufficient memory\n";
char szErrMsg2[] = "\n\aERROR: file open error\n";
char szErrMsg3[] = "\n\aERROR: file read error\n";
char szErrMsg4[] = "\n\aERROR: file write error\n";
char szErrMsg5[] = "\n\aERROR: cannot change file attribute\n";

int  CheckFiles(char *szPath);
void CheckCom(char *szCom);
void CheckExe(char *szExe);

int main(int argc, char *argv[])
{
    unsigned char cOldDrive;
    char szOldDir[0x80] = {'\\',};

    printf("%s", szPrgName);       /* 프로그램 이름 출력 */

    if (argc == 1) {               /* 인자 없을 때 도움말 출력 */
        printf("%s", szMsg1);
        exit(0);
    }

    cDrive = toupper(*argv[1]) - 'A';

    /* 일반 기억장소 검사 */

    printf("%s", szMsg2);          /* '기억장소 검사:' 출력 */
    if (CheckFileVirusInMem(&JeruMemDx) == 0)
        printf("%s", szMsg4);      /* '바이러스 없음' 출력 */
    else {
        printf("%s", szMsg6);      /* '바이러스 존재' 출력 */
        CureFileVirusInMem(0x80, &JeruMemTx);
        printf("%s", szMsg7);      /* '-> 치료' 출력 */
    }

    /* 파일들 검사 */

    printf("%s", szMsg3);          /* '파일들 검사:' 출력 */

    cOldDrive = getdisk();         /* 현재 드라이브 얻음 */
    getcurdir(0, szOldDir + 1);    /* 현재 디렉토리 얻음 */

    setdisk(cDrive);               /* 검사할 드라이브로 바꿈 */
    chdir("\\");                   /* 주 디렉토리로 바꿈 */

    if (CheckFiles("") == 0)       /* 파일들 검사 */
        printf("%s", szMsg4);      /* '바이러스 없음' 출력 */

    setdisk(cOldDrive);            /* 원래 드라이브로 바꿈 */
    chdir(szOldDir);               /* 원래 디렉토리로 바꿈 */

    return 0;
}

int CheckFiles(char *szPath)
{
    char szCurPath[0x80], szNewPath[0x80];
    int iFirst = 1, iStatus, iResult;
    struct ffblk FileBlock;

    strcpy(szCurPath, szPath);     /* 검사할 디렉토리 */
    strcat(szCurPath, "\\");
    strcat(szCurPath, "*.*");

    while(1) {
        if (iFirst) {              /* 파일을 찾음 */
            iStatus = findfirst(szCurPath, &FileBlock, FA_LIST);
            iFirst  = 0;
        } else
            iStatus = findnext(&FileBlock);
        if (iStatus) return iInfFile; /* 더 이상 파일이 없음 */

        if (strcmp(FileBlock.ff_name, ".") == 0) continue;
        if (strcmp(FileBlock.ff_name, "..") == 0) continue;

        strcpy(szNewPath, szPath); /* 찾은 파일 이름 */
        strcat(szNewPath, "\\");
        strcat(szNewPath, FileBlock.ff_name);

        if (FileBlock.ff_attrib & FA_DIREC) {
            CheckFiles(szNewPath); /* 재귀 호출 */
        } else {
            if ((iResult = CheckFileType(szNewPath)) == -1) {
                switch (wErrCode) {
                    case 4: printf("%s", szErrMsg2);
                            exit(1);
                    case 5: printf("%s", szErrMsg3);
                            exit(1);
                }
            }
            if (iResult == 0)
                CheckCom(szNewPath); /* COM 파일 검사 */
            else
                CheckExe(szNewPath); /* EXE 파일 검사 */
        }
    }
}

void CheckCom(char *szCom)         /* COM 파일 검사 */
{
    int iResult;

    /* 바이러스 검사 */

    if ((iResult=CheckFileVirusInCOM(szCom, &JeruComDx)) == -1) {
        switch (wErrCode) {
            case 4: printf("%s", szErrMsg2);
                    exit(1);
            case 5: printf("%s", szErrMsg3);
                    exit(1);
        }
    }

    /* 바이러스 치료 */

    if (iResult) {
        iInfFile++;                /* 감염 파일 수 증가 */
        printf("%c:%s", cDrive + 'A', szCom);
        printf("%s", szMsg5);
        printf("%s", szMsg6);      /* '바이러스 존재' 출력 */

        if (CureFileVirusInCOM(szCom, 0x30, &JeruComTx) == -1) {
            switch (wErrCode) {
                case 4: printf("%s", szErrMsg2);
                        exit(1);
                case 5: printf("%s", szErrMsg3);
                        exit(1);
                case 6: printf("%s", szErrMsg4);
                        exit(1);
                case 7: printf("%s", szErrMsg5);
                        exit(1);
                case 9: printf("%s", szErrMsg1);
                        exit(1);
            }
        }

        printf("%s", szMsg7);      /* '-> 치료' 출력 */
    }
}

void CheckExe(char *szExe)         /* EXE 파일 검사 */
{
    int iResult;

    /* 바이러스 검사 */

    if ((iResult=CheckFileVirusInEXE(szExe, &JeruExeDx)) == -1) {
        switch (wErrCode) {
            case 4: printf("%s", szErrMsg2);
                    exit(1);
            case 5: printf("%s", szErrMsg3);
                    exit(1);
        }
    }

    /* 바이러스 치료 */

    if (iResult) {
        iInfFile++;                /* 감염 파일 수 증가 */
        printf("%c:%s", cDrive + 'A', szExe);
        printf("%s", szMsg5);
        printf("%s", szMsg6);      /* '바이러스 존재' 출력 */

        if (CureFileVirusInEXE(szExe, 0xA0, &JeruExeTx) == -1) {
            switch (wErrCode) {
                case 4: printf("%s", szErrMsg2);
                        exit(1);
                case 5: printf("%s", szErrMsg3);
                        exit(1);
                case 6: printf("%s", szErrMsg4);
                        exit(1);
                case 7: printf("%s", szErrMsg5);
                        exit(1);
            }
        }

        printf("%s", szMsg7);      /* '-> 치료' 출력 */
    }
}
