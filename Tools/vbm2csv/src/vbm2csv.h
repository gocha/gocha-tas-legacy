/**
 * vbm2csv.h: write key sequence to csv text
 */

#ifndef VBM2CSV_H
#define VBM2CSV_H


#include <stddef.h>


#ifndef countof
#define countof(a)  (sizeof(a) / sizeof(a[0]))
#endif

#if !defined(bool) && !defined(__cplusplus)
  typedef int bool;
  #define true    1
  #define false   0
#endif /* !bool */

#ifndef byte
  typedef unsigned char byte;
#endif /* !byte */


bool vbm2csv(const char* filename);
bool vbmCtl2csv(const byte* ctlData, size_t numFrames, size_t baseAdr);


#endif /* !VBM2CSV_H */
