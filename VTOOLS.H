
/*---------------------------------------------------------------
;
;         Header file for Vaccine Toolkit (Version 2.0)
;
;                   (저) 1994  안 철 수
;
;--------------------------------------------------------------*/

/* 컴퓨터 바이러스 자료 구조체 정의 */

struct DxStr {
    unsigned int iOffset;
    unsigned char cLen, sVirStr[10];
};
struct BvMemTx0 {
    unsigned int iOffOld13, iMemSize;
};
struct BvMemTx10 {
        unsigned int iIntOld13, iMemSize;
};
struct BvMbsTx0 {
        unsigned char cOldCyl, cOldHead, cOldSect;
};
struct BvMbsTx10 {
        unsigned int iOffOldCyl, iOffOldHead, iOffOldSect;
        unsigned char cAddSect;
};
struct BvDbsTx80 {
        unsigned char cOldCyl, cOldHead, cOldSect;
};
struct BvDbsTx90 {
        unsigned int iOffOldCyl, iOffOldHead, iOffOldSect;
        unsigned char cAddSect;
};
struct BvDbsTxA0 {
        unsigned int iOldSect;
};
struct BvDbsTxB0 {
        unsigned int iOffOldSect, iAddSect;
};

struct FvMemTx80 {
        unsigned int iOffOld21;
};
struct FvComTx10 {
        unsigned int iDiff, iOffOldStart, iStartLn;
};
struct FvComTx20 {
        unsigned int iDiff, iOffOldStart, iStartLn;
};
struct FvComTx30 {
        unsigned int iVirLn, iOffOldLn;
};
struct FvComTx40 {
        unsigned int iVirLn, iOffOldLn;
};
struct FvExeTx90 {
        unsigned int iDiff, iOffOldHead, iHeadLn;
};
struct FvExeTxA0 {
        unsigned int iDiff, iOffOldCS, iAddCS, iOffOldIP, iAddIP,
                            iOffOldSS, iAddSS, iOffOldSP, iAddSP;
};

/* 외부 변수 정의 */

extern int wErrCode;

/* 백신 툴키트 함수 정의 */

extern int CheckBootVirusInMem();
extern int CureBootVirusInMem();
extern int CheckBootVirusInMBS();
extern int CureBootVirusInMBS();
extern int CheckBootVirusInDBS();
extern int CureBootVirusInDBS();
extern int CheckFileVirusInMem();
extern int CureFileVirusInMem();
extern int CheckFileType();
extern int CheckFileVirusInCOM();
extern int CureFileVirusInCOM();
extern int CheckFileVirusInEXE();
extern int CureFileVirusInEXE();

