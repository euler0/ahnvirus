
/*---------------------------------------------------------------
;
;         V-MICH2   £¡ÅIœe¹I¡ ¤a·¡œá¯a¶w ¤‚¯¥ Ïa¡‹aœ‘
;
;                   (¸á) 1994  ´e Àé ®
;
;--------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <bios.h>
#include <dos.h>

struct DxStr {                     /* ¢…¸aµi ¯aËaœâÁa ¸÷· */
    unsigned int iOffset;
    unsigned char cLen, sVirStr[10];
} MichDx = {                       /* »¥”e¶w ¢…¸aµi */
    0x000E,
    10,
    {0x1E, 0x50, 0x0A, 0xD2, 0x75, 0x1B, 0x33, 0xC0, 0x8E, 0xD8}
};
unsigned int iOffOld13 = 0x0A;     /* µ¡Ïa­U º­¡ */
unsigned int iMemSize = 2;         /* ·©¤e ‹¡´â¸w­¡ ˆq­¡ Ça‹¡ */
unsigned char i, cDrive, sBuffer[0x200];
char far *lpcMem;
int  far *lpiMem;
union REGS r;
struct SREGS sr;

char szPrgName[]  = "V-MICH2 Vaccine program for Michelangelo "
        "virus\n       (c)Copyright 1994  by Cheolsoo Ahn\n\n";
char szMsg1[]    = "Usage: V-MICH2 <drive>\n";
char szMsg2[]    = "Checking the Memory : ";
char szMsg3[]    = "Checking Boot Sector: ";
char szMsg4[]    = "no Michelangelo virus\n";
char szMsg5[]    = "\aMichelangelo virus found";
char szMsg6[]    = " -> Cured\n";
char szErrMsg1[] = "\n\aERROR: disk read error\n";
char szErrMsg2[] = "\n\aERROR: disk write error\n";

int main(int argc, char *argv[])
{
    printf("%s", szPrgName);       /* Ïa¡‹aœ‘ ·¡Ÿq Â‰b */

    if (argc == 1) {               /* ·¥¸a ´ô·i ˜ •¡¶‘ i Â‰b */
        printf("%s", szMsg1);
        exit(0);
    }

    cDrive = toupper(*argv[1]) - 'A';
    if (cDrive >= 2)
        cDrive += 0x7E;            /* ˆñ¬aÐi —aœa·¡§a ´i´a‘ */

    /* ·©¤e ‹¡´â¸w­¡ ˆñ¬a */

    printf("%s", szMsg2);          /* '‹¡´â¸w­¡ ˆñ¬a:' Â‰b */
    lpcMem = MK_FP(biosmemory() << 6, MichDx.iOffset);
    for (i = 0; i < MichDx.cLen; i++)
        if (lpcMem[i] != MichDx.sVirStr[i]) break;
    if (i != MichDx.cLen)
        printf("%s", szMsg4);      /* '¤a·¡œá¯a ´ô·q' Â‰b */
    else {
        printf("%s", szMsg5);      /* '¤a·¡œá¯a ¹¥¸' Â‰b */
        r.x.ax = 0x2513;
        lpiMem = MK_FP(biosmemory() << 6, iOffOld13);
        r.x.dx = *lpiMem++;
        sr.ds  = *lpiMem;
        intdosx(&r, &r, &sr);      /* 13h¤å ·¥ÈáœóËa º­¡ ¥¢Š */
        lpiMem = MK_FP(0x0000, 0x0413);
        *lpiMem += iMemSize;       /* ·©¤e ‹¡´â¸w­¡· Ça‹¡ ¥¢Š */
        printf("%s", szMsg6);      /* '-> Ã¡ža' Â‰b */
    }

    /* ¦Ëa ­BÈá ·ª·q */

    printf("%s", szMsg3);          /* '¦Ëa ­BÈá ˆñ¬a:' Â‰b */

    r.h.ah = 0x0D;
    intdos(&r, &r);

    for (i = 0; i < 4; i++) {
        if (biosdisk(2, cDrive, 0, 0, 1, 1, sBuffer) == 0) break;
        biosdisk(0, cDrive, 0, 0, 1, 1, sBuffer);
    }
    if (i == 4) {
        printf("%s", szErrMsg1);   /* —¡¯aÇa ·ª‹¡ µ¡ŸA */
        exit(1);
    }

    /* ¦Ëa ­BÈá ˆñ¬a */

    for (i = 0; i < MichDx.cLen; i++)
        if (sBuffer[MichDx.iOffset + i] != MichDx.sVirStr[i])
            break;
    if (i != MichDx.cLen)
        printf("%s", szMsg4);      /* '¤a·¡œá¯a ´ô·q' Â‰b */
    else {
        printf("%s", szMsg5);      /* '¤a·¡œá¯a ¹¥¸' Â‰b */
        if (cDrive < 0x80) {       /* ¶¥œ ¦Ëa ­BÈá ·ª·q */
            if (biosdisk(2, cDrive, 1, sBuffer[0x9],
                          sBuffer[0x8], 1, sBuffer)) {
                printf("%s", szErrMsg1); /* —¡¯aÇa ·ª‹¡ µ¡ŸA */
                exit(1);
            }
        }
        else {
            if (biosdisk(2, cDrive, 0, 0, 7, 1, sBuffer)) {
                printf("%s", szErrMsg1); /* —¡¯aÇa ·ª‹¡ µ¡ŸA */
                exit(1);
            }
        }
        /* ¦Ëa ­BÈá Ã¡ža */
        if (biosdisk(3, cDrive, 0, 0, 1, 1, sBuffer)) {
            printf("%s", szErrMsg2); /* —¡¯aÇa ³a‹¡ µ¡ŸA */
            exit(1);
        }

        r.h.ah = 0x0D;
        intdos(&r, &r);

        printf("%s", szMsg6);      /* '-> Ã¡ža' Â‰b */
    }

    return 0;
}

