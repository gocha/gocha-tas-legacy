/**
 * smv2csv.h: write key sequence to csv text
 */

#ifndef SMV2CSV_H
#define SMV2CSV_H


#include "cioutil.h"


typedef void (SmvXsvProc)(const char*);

typedef struct TagSmvToXsv
{
  int targetCtl;    /* target controller (1-5) */
  bool putAddr;     /* put controller data offset */
  char sepChar;     /* separator */
  int version;      /* smv version */
  int ctlMask;      /* controller mask */
  int numCtls;      /* count of controllers */
  int syncOption;   /* sync options */
  size_t frames;    /* length of smv movie */
  size_t lastFrame; /* last frame # */
  size_t baseAddr;  /* base address */
  byte* data;       /* key sequences */
  SmvXsvProc* proc; /* output proc */
} SmvToXsv;

SmvToXsv* smvXsvCreate(const byte* smv, size_t size);
void smvXsvDelete(SmvToXsv* smv2xsv);
SmvToXsv* smvXsvReadFile(const char* path);
SmvXsvProc* smvXsvSetProc(SmvToXsv* smv2xsv, SmvXsvProc* proc);
char smvXsvSetSepChar(SmvToXsv* smv2xsv, char sepChar);
int smvXsvSetTargetCtl(SmvToXsv* smv2xsv, int targetCtl);
bool smvXsvSetPutAddr(SmvToXsv* smv2xsv, bool putAddr);
bool smvXsvOutput(SmvToXsv* smv2xsv);


#endif /* !SMV2CSV_H */
