
/*---------------------------------------------------------------
;
;         V-JERU2   예루살렘 바이러스용 백신 프로그램
;
;                   (저) 1994  안 철 수
;
;--------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <io.h>
#include <dos.h>
#include <dir.h>
#include <fcntl.h>
#include <ctype.h>
#include <string.h>
#include <mem.h>
#include <sys\stat.h>

#define FA_LIST (FA_RDONLY|FA_HIDDEN|FA_SYSTEM|FA_DIREC|FA_ARCH)

struct DxStr {                     /* 문자열 스트럭쳐 정의 */
    unsigned int iOffset;
    unsigned char cLen, sVirStr[10];
};
struct DxStr JeruMemDx = {         /* 기억장소 진단용 문자열 */
    0x00C5,
    10,
    {0xFC, 0x06, 0x2E, 0x8C, 0x06, 0x31, 0x00, 0x2E, 0x8C, 0x06}
};
struct DxStr JeruExeDx = {         /* EXE 파일 진단용 문자열 */
    0x0000,
    10,
    {0xFC, 0x06, 0x2E, 0x8C, 0x06, 0x31, 0x00, 0x2E, 0x8C, 0x06}
};
unsigned int iVirLn    = 0x710;    /* 바이러스 길이 */
unsigned int iEntStLn  = 0xC5;     /* 시작점 차이 길이 */
unsigned int iOffOld21 = 0x17;     /* 원래 인터럽트 저장 위치 */
unsigned int iOffOldLn = 0x11;     /* 원래 파일 길이 저장 위치 */
unsigned int iOffCS    = 0x49;     /* 원래 CS 값 저장 위치 */
unsigned int iOffIP    = 0x47;     /* 원래 IP 값 저장 위치 */
unsigned int iOffSS    = 0x45;     /* 원래 SS 값 저장 위치 */
unsigned int iOffSP    = 0x43;     /* 원래 SP 값 저장 위치 */

unsigned char cDrive;              /* 검사할 드라이브 */
char sBuffer[0x200];               /* 파일 읽어들이는 버퍼 */
unsigned int iInfFile = 0;         /* 감염 파일 수 */

char szPrgName[]  = "V-JERU2 Vaccine program for Jerusalem virus"
               "\n       (c)Copyright 1994  by Cheolsoo Ahn\n\n";
char szMsg1[]    = "Usage: V-JERU2 <drive>\n";
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

int  CheckFiles(char *szPath);
int  CheckFileType(char *szFile);
void CheckCom(char *szCom);
void CheckExe(char *szExe);

int main(int argc, char *argv[])
{
    unsigned char cOldDrive;
    char szOldDir[0x80] = {'\\',};
    char far *lpcMem;
    int i;
    int far *lpiMem;
    union REGS r;
    struct SREGS sr;

    printf("%s", szPrgName);       /* 프로그램 이름 출력 */

    if (argc == 1) {               /* 인자 없을 때 도움말 출력 */
        printf("%s", szMsg1);
        exit(0);
    }

    cDrive = toupper(*argv[1]) - 'A';

    /* 일반 기억장소 검사 */

    printf("%s", szMsg2);          /* '기억장소 검사:' 출력 */
    lpcMem = MK_FP(FP_SEG(getvect(0x21)), JeruMemDx.iOffset);
    for (i = 0; i < JeruMemDx.cLen; i++)
        if (lpcMem[i] != JeruMemDx.sVirStr[i]) break;
    if (i != JeruMemDx.cLen)
        printf("%s", szMsg4);      /* '바이러스 없음' 출력 */
    else {
        printf("%s", szMsg6);      /* '바이러스 존재' 출력 */
        r.x.ax = 0x2521;
        lpiMem = MK_FP(FP_SEG(getvect(0x21)), iOffOld21);
        r.x.dx = *lpiMem++;
        sr.ds  = *lpiMem;
        intdosx(&r, &r, &sr);      /* 21h번 인터럽트 주소 복구 */
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
    int iFirst = 1, iStatus;
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
            if (CheckFileType(szNewPath) == 0)
                CheckCom(szNewPath); /* COM 파일 검사 */
            else
                CheckExe(szNewPath); /* EXE 파일 검사 */
        }
    }
}

int CheckFileType(char *szFile)    /* 파일 종류 구별 */
{
    int hHandle;

    /* 파일 오픈 */
    if ((hHandle = open(szFile, O_RDONLY | O_BINARY)) == -1) {
        printf("%s", szErrMsg2);
        exit(1);
    }
    /* 파일 읽음 */
    if (read(hHandle, sBuffer, 0x200) == -1) {
        close(hHandle);
        printf("%s", szErrMsg3);
        exit(1);
    }
    /* 파일 닫음 */
    close(hHandle);

    if (((sBuffer[0] == 'M') && (sBuffer[1] == 'Z')) ||
        ((sBuffer[0] == 'Z') && (sBuffer[1] == 'M')))
        return 1;                  /* EXE 파일 */
    else
        return 0;                  /* COM 파일 */
}

void CheckCom(char *szCom)         /* COM 파일 검사 */
{
    int i, hHandle;
    unsigned int iOldLn, *pAlloc;

    /* 바이러스 검사 */

    for (i = 0; i < JeruMemDx.cLen; i++)
        if (sBuffer[JeruMemDx.iOffset+i] != JeruMemDx.sVirStr[i])
            break;

    /* 바이러스 치료 */

    if (i == JeruMemDx.cLen) {     /* 감염 파일 발견 */
        iInfFile++;                /* 감염 파일 수 증가 */
        printf("%c:%s", cDrive + 'A', szCom);
        printf("%s", szMsg5);
        printf("%s", szMsg6);      /* '바이러스 존재' 출력 */

        /* 원래 파일 길이 얻음 */
        memcpy(&iOldLn, sBuffer + iOffOldLn, 2);

        /* 기억장소 할당 */
        if ((pAlloc = malloc(iOldLn)) == NULL) {
            printf("%s", szErrMsg1);
            exit(1);
        }

        /* 파일 오픈 */
        chmod(szCom, S_IREAD | S_IWRITE);
        if ((hHandle = open(szCom, O_RDWR | O_BINARY)) == -1) {
            printf("%s", szErrMsg2);
            exit(1);
        }
        /* 원래 파일 내용 읽음 */
        lseek(hHandle, iVirLn, SEEK_SET);
        if (read(hHandle, pAlloc, iOldLn) != iOldLn) {
            close(hHandle);
            printf("%s", szErrMsg3);
            exit(1);
        }
        /* 원래 파일 내용 씀 */
        lseek(hHandle, 0, SEEK_SET);
        if (write(hHandle, pAlloc, iOldLn) != iOldLn) {
            close(hHandle);
            printf("%s", szErrMsg4);
            exit(1);
        }
        /* 파일 길이 복구 */
        if (chsize(hHandle, iOldLn) == -1) {
            close(hHandle);
            printf("%s", szErrMsg4);
            exit(1);
        }
        /* 파일 닫음 */
        close(hHandle);

        /* 기억장소 해제 */
        free(pAlloc);

        printf("%s", szMsg7);      /* '-> 치료' 출력 */
    }
}

void CheckExe(char *szExe)         /* EXE 파일 검사 */
{
    int i, hHandle;
    unsigned long lExeEntry, lOldLn;
    unsigned int sExeHead[0x10];

    /* 실행 시작 위치 얻음 */
    memcpy(sExeHead, sBuffer, 0x20);
    lExeEntry = (((long)sExeHead[8/2] + (long)sExeHead[0x16/2])
                               << 4L) + (long)sExeHead[0x14/2];

    /* 파일 오픈 */
    if ((hHandle = open(szExe, O_RDONLY | O_BINARY)) == -1) {
        printf("%s", szErrMsg2);
        exit(1);
    }
    /* 실행 시작 부위 읽음 */
    lseek(hHandle, lExeEntry, SEEK_SET);
    if (read(hHandle, sBuffer, 0x200) == -1) {
        close(hHandle);
        printf("%s", szErrMsg3);
        exit(1);
    }
    /* 파일 닫음 */
    close(hHandle);

    /* 바이러스 검사 */

    for (i = 0; i < JeruExeDx.cLen; i++)
        if (sBuffer[JeruExeDx.iOffset+i] != JeruExeDx.sVirStr[i])
            break;

    /* 바이러스 치료 */

    if (i == JeruExeDx.cLen) {
        iInfFile++;
        printf("%c:%s", cDrive + 'A', szExe);
        printf("%s", szMsg5);
        printf("%s", szMsg6);      /* '바이러스 존재' 출력 */

        /* 파일 오픈 */
        chmod(szExe, S_IREAD | S_IWRITE);
        if ((hHandle = open(szExe, O_RDWR | O_BINARY)) == -1) {
            printf("%s", szErrMsg2);
            exit(1);
        }
        /* 원래 CS, IP, SS, SP 값들 얻음 */
        lOldLn = lExeEntry - (long)iEntStLn;
        lseek(hHandle, lOldLn, SEEK_SET);
        if (read(hHandle, sBuffer, 0x200) == -1) {
            close(hHandle);
            printf("%s", szErrMsg3);
            exit(1);
        }
        memcpy(sExeHead + 0x16/2, sBuffer + iOffCS, 2);
        memcpy(sExeHead + 0x14/2, sBuffer + iOffIP, 2);
        memcpy(sExeHead + 0x0E/2, sBuffer + iOffSS, 2);
        memcpy(sExeHead + 0x10/2, sBuffer + iOffSP, 2);
        /* 원래 길이 계산 */
        sExeHead[2/2] = lOldLn % 0x200L;
        sExeHead[4/2] = lOldLn / 0x200L;
        if (sExeHead[2/2]) sExeHead[4/2]++;
        /* 선두영역 복구 */
        lseek(hHandle, 0, SEEK_SET);
        if (write(hHandle, sExeHead, 0x20) != 0x20) {
            close(hHandle);
            printf("%s", szErrMsg4);
            exit(1);
        }
        /* 파일 길이 복구 */
        if (chsize(hHandle, lOldLn) == -1) {
            close(hHandle);
            printf("%s", szErrMsg4);
            exit(1);
        }
        /* 파일 닫음 */
        close(hHandle);

       printf("%s", szMsg7);      /* '-> 치료' 출력 */
    }
}

