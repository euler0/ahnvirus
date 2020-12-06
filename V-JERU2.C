
/*---------------------------------------------------------------
;
;         V-JERU2   µž¬iQ ¤a·¡œá¯a¶w ¤‚¯¥ Ïa¡‹aœ‘
;
;                   (¸á) 1994  ´e Àé ®
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

struct DxStr {                     /* ¢…¸aµi ¯aËaœâÁa ¸÷· */
    unsigned int iOffset;
    unsigned char cLen, sVirStr[10];
};
struct DxStr JeruMemDx = {         /* ‹¡´â¸w­¡ »¥”e¶w ¢…¸aµi */
    0x00C5,
    10,
    {0xFC, 0x06, 0x2E, 0x8C, 0x06, 0x31, 0x00, 0x2E, 0x8C, 0x06}
};
struct DxStr JeruExeDx = {         /* EXE Ìa·© »¥”e¶w ¢…¸aµi */
    0x0000,
    10,
    {0xFC, 0x06, 0x2E, 0x8C, 0x06, 0x31, 0x00, 0x2E, 0x8C, 0x06}
};
unsigned int iVirLn    = 0x710;    /* ¤a·¡œá¯a ‹©·¡ */
unsigned int iEntStLn  = 0xC5;     /* ¯¡¸b¸ñ Àa·¡ ‹©·¡ */
unsigned int iOffOld21 = 0x17;     /* ¶¥œ ·¥ÈáœóËa ¸á¸w ¶áÃ¡ */
unsigned int iOffOldLn = 0x11;     /* ¶¥œ Ìa·© ‹©·¡ ¸á¸w ¶áÃ¡ */
unsigned int iOffCS    = 0x49;     /* ¶¥œ CS ˆt ¸á¸w ¶áÃ¡ */
unsigned int iOffIP    = 0x47;     /* ¶¥œ IP ˆt ¸á¸w ¶áÃ¡ */
unsigned int iOffSS    = 0x45;     /* ¶¥œ SS ˆt ¸á¸w ¶áÃ¡ */
unsigned int iOffSP    = 0x43;     /* ¶¥œ SP ˆt ¸á¸w ¶áÃ¡ */

unsigned char cDrive;              /* ˆñ¬aÐi —aœa·¡§a */
char sBuffer[0x200];               /* Ìa·© ·ª´á—i·¡“e ¤áÌá */
unsigned int iInfFile = 0;         /* ˆqµq Ìa·© ® */

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

    printf("%s", szPrgName);       /* Ïa¡‹aœ‘ ·¡Ÿq Â‰b */

    if (argc == 1) {               /* ·¥¸a ´ô·i ˜ •¡¶‘ i Â‰b */
        printf("%s", szMsg1);
        exit(0);
    }

    cDrive = toupper(*argv[1]) - 'A';

    /* ·©¤e ‹¡´â¸w­¡ ˆñ¬a */

    printf("%s", szMsg2);          /* '‹¡´â¸w­¡ ˆñ¬a:' Â‰b */
    lpcMem = MK_FP(FP_SEG(getvect(0x21)), JeruMemDx.iOffset);
    for (i = 0; i < JeruMemDx.cLen; i++)
        if (lpcMem[i] != JeruMemDx.sVirStr[i]) break;
    if (i != JeruMemDx.cLen)
        printf("%s", szMsg4);      /* '¤a·¡œá¯a ´ô·q' Â‰b */
    else {
        printf("%s", szMsg6);      /* '¤a·¡œá¯a ¹¥¸' Â‰b */
        r.x.ax = 0x2521;
        lpiMem = MK_FP(FP_SEG(getvect(0x21)), iOffOld21);
        r.x.dx = *lpiMem++;
        sr.ds  = *lpiMem;
        intdosx(&r, &r, &sr);      /* 21h¤å ·¥ÈáœóËa º­¡ ¥¢Š */
        printf("%s", szMsg7);      /* '-> Ã¡ža' Â‰b */
    }

    /* Ìa·©—i ˆñ¬a */

    printf("%s", szMsg3);          /* 'Ìa·©—i ˆñ¬a:' Â‰b */

    cOldDrive = getdisk();         /* Ñe¸ —aœa·¡§a ´è·q */
    getcurdir(0, szOldDir + 1);    /* Ñe¸ —¡BÉ¡Ÿ¡ ´è·q */

    setdisk(cDrive);               /* ˆñ¬aÐi —aœa·¡§a¡ ¤aŽ‘ */
    chdir("\\");                   /* º —¡BÉ¡Ÿ¡¡ ¤aŽ‘ */

    if (CheckFiles("") == 0)       /* Ìa·©—i ˆñ¬a */
        printf("%s", szMsg4);      /* '¤a·¡œá¯a ´ô·q' Â‰b */

    setdisk(cOldDrive);            /* ¶¥œ —aœa·¡§a¡ ¤aŽ‘ */
    chdir(szOldDir);               /* ¶¥œ —¡BÉ¡Ÿ¡¡ ¤aŽ‘ */

    return 0;
}

int CheckFiles(char *szPath)
{
    char szCurPath[0x80], szNewPath[0x80];
    int iFirst = 1, iStatus;
    struct ffblk FileBlock;

    strcpy(szCurPath, szPath);     /* ˆñ¬aÐi —¡BÉ¡Ÿ¡ */
    strcat(szCurPath, "\\");
    strcat(szCurPath, "*.*");

    while(1) {
        if (iFirst) {              /* Ìa·©·i Àx·q */
            iStatus = findfirst(szCurPath, &FileBlock, FA_LIST);
            iFirst  = 0;
        } else
            iStatus = findnext(&FileBlock);
        if (iStatus) return iInfFile; /* ”á ·¡¬w Ìa·©·¡ ´ô·q */

        if (strcmp(FileBlock.ff_name, ".") == 0) continue;
        if (strcmp(FileBlock.ff_name, "..") == 0) continue;

        strcpy(szNewPath, szPath); /* Àx·e Ìa·© ·¡Ÿq */
        strcat(szNewPath, "\\");
        strcat(szNewPath, FileBlock.ff_name);

        if (FileBlock.ff_attrib & FA_DIREC) {
            CheckFiles(szNewPath); /* ¸Šá Ñ¡Â‰ */
        } else {
            if (CheckFileType(szNewPath) == 0)
                CheckCom(szNewPath); /* COM Ìa·© ˆñ¬a */
            else
                CheckExe(szNewPath); /* EXE Ìa·© ˆñ¬a */
        }
    }
}

int CheckFileType(char *szFile)    /* Ìa·© ¹·ŸA Š¥i */
{
    int hHandle;

    /* Ìa·© µ¡Ïe */
    if ((hHandle = open(szFile, O_RDONLY | O_BINARY)) == -1) {
        printf("%s", szErrMsg2);
        exit(1);
    }
    /* Ìa·© ·ª·q */
    if (read(hHandle, sBuffer, 0x200) == -1) {
        close(hHandle);
        printf("%s", szErrMsg3);
        exit(1);
    }
    /* Ìa·© ”h·q */
    close(hHandle);

    if (((sBuffer[0] == 'M') && (sBuffer[1] == 'Z')) ||
        ((sBuffer[0] == 'Z') && (sBuffer[1] == 'M')))
        return 1;                  /* EXE Ìa·© */
    else
        return 0;                  /* COM Ìa·© */
}

void CheckCom(char *szCom)         /* COM Ìa·© ˆñ¬a */
{
    int i, hHandle;
    unsigned int iOldLn, *pAlloc;

    /* ¤a·¡œá¯a ˆñ¬a */

    for (i = 0; i < JeruMemDx.cLen; i++)
        if (sBuffer[JeruMemDx.iOffset+i] != JeruMemDx.sVirStr[i])
            break;

    /* ¤a·¡œá¯a Ã¡ža */

    if (i == JeruMemDx.cLen) {     /* ˆqµq Ìa·© ¤i‰e */
        iInfFile++;                /* ˆqµq Ìa·© ® »wˆa */
        printf("%c:%s", cDrive + 'A', szCom);
        printf("%s", szMsg5);
        printf("%s", szMsg6);      /* '¤a·¡œá¯a ¹¥¸' Â‰b */

        /* ¶¥œ Ìa·© ‹©·¡ ´è·q */
        memcpy(&iOldLn, sBuffer + iOffOldLn, 2);

        /* ‹¡´â¸w­¡ Ði”w */
        if ((pAlloc = malloc(iOldLn)) == NULL) {
            printf("%s", szErrMsg1);
            exit(1);
        }

        /* Ìa·© µ¡Ïe */
        chmod(szCom, S_IREAD | S_IWRITE);
        if ((hHandle = open(szCom, O_RDWR | O_BINARY)) == -1) {
            printf("%s", szErrMsg2);
            exit(1);
        }
        /* ¶¥œ Ìa·© ¶w ·ª·q */
        lseek(hHandle, iVirLn, SEEK_SET);
        if (read(hHandle, pAlloc, iOldLn) != iOldLn) {
            close(hHandle);
            printf("%s", szErrMsg3);
            exit(1);
        }
        /* ¶¥œ Ìa·© ¶w ³q */
        lseek(hHandle, 0, SEEK_SET);
        if (write(hHandle, pAlloc, iOldLn) != iOldLn) {
            close(hHandle);
            printf("%s", szErrMsg4);
            exit(1);
        }
        /* Ìa·© ‹©·¡ ¥¢Š */
        if (chsize(hHandle, iOldLn) == -1) {
            close(hHandle);
            printf("%s", szErrMsg4);
            exit(1);
        }
        /* Ìa·© ”h·q */
        close(hHandle);

        /* ‹¡´â¸w­¡ Ð¹A */
        free(pAlloc);

        printf("%s", szMsg7);      /* '-> Ã¡ža' Â‰b */
    }
}

void CheckExe(char *szExe)         /* EXE Ìa·© ˆñ¬a */
{
    int i, hHandle;
    unsigned long lExeEntry, lOldLn;
    unsigned int sExeHead[0x10];

    /* ¯©Ð— ¯¡¸b ¶áÃ¡ ´è·q */
    memcpy(sExeHead, sBuffer, 0x20);
    lExeEntry = (((long)sExeHead[8/2] + (long)sExeHead[0x16/2])
                               << 4L) + (long)sExeHead[0x14/2];

    /* Ìa·© µ¡Ïe */
    if ((hHandle = open(szExe, O_RDONLY | O_BINARY)) == -1) {
        printf("%s", szErrMsg2);
        exit(1);
    }
    /* ¯©Ð— ¯¡¸b ¦¶á ·ª·q */
    lseek(hHandle, lExeEntry, SEEK_SET);
    if (read(hHandle, sBuffer, 0x200) == -1) {
        close(hHandle);
        printf("%s", szErrMsg3);
        exit(1);
    }
    /* Ìa·© ”h·q */
    close(hHandle);

    /* ¤a·¡œá¯a ˆñ¬a */

    for (i = 0; i < JeruExeDx.cLen; i++)
        if (sBuffer[JeruExeDx.iOffset+i] != JeruExeDx.sVirStr[i])
            break;

    /* ¤a·¡œá¯a Ã¡ža */

    if (i == JeruExeDx.cLen) {
        iInfFile++;
        printf("%c:%s", cDrive + 'A', szExe);
        printf("%s", szMsg5);
        printf("%s", szMsg6);      /* '¤a·¡œá¯a ¹¥¸' Â‰b */

        /* Ìa·© µ¡Ïe */
        chmod(szExe, S_IREAD | S_IWRITE);
        if ((hHandle = open(szExe, O_RDWR | O_BINARY)) == -1) {
            printf("%s", szErrMsg2);
            exit(1);
        }
        /* ¶¥œ CS, IP, SS, SP ˆt—i ´è·q */
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
        /* ¶¥œ ‹©·¡ ‰¬e */
        sExeHead[2/2] = lOldLn % 0x200L;
        sExeHead[4/2] = lOldLn / 0x200L;
        if (sExeHead[2/2]) sExeHead[4/2]++;
        /* ¬å–µwµb ¥¢Š */
        lseek(hHandle, 0, SEEK_SET);
        if (write(hHandle, sExeHead, 0x20) != 0x20) {
            close(hHandle);
            printf("%s", szErrMsg4);
            exit(1);
        }
        /* Ìa·© ‹©·¡ ¥¢Š */
        if (chsize(hHandle, lOldLn) == -1) {
            close(hHandle);
            printf("%s", szErrMsg4);
            exit(1);
        }
        /* Ìa·© ”h·q */
        close(hHandle);

       printf("%s", szMsg7);      /* '-> Ã¡ža' Â‰b */
    }
}

