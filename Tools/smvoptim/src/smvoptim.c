/**
 * smvoptim.c: truncates redundant records in smv
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "smvoptim.h"


#define SMV_MAX_CTL    5


/* truncates redundant records in the smv movie */
bool smvoptim(const char* path)
{
  bool result = false;
  FILE* smvFile = fopen(path, "rb");

  if(smvFile)
  {
    /* simple validation */
    if((fget1(smvFile) == 'S') && (fget1(smvFile) == 'M') && (fget1(smvFile) == 'V') && (fget1(smvFile) == 0x1a))
    {
      int version;
      size_t numFrames;
      size_t numStoredFrames;
      int ctlMask;
      int numCtls;
      int syncOption;
      size_t ctlOffset;
      size_t ctlDataSize;
      size_t smvFileSize;
      byte* smvData;
      int i;

      fseek(smvFile, 0x04, SEEK_SET);
      version = fget4l(smvFile);
      if (version != 1) {
        fprintf(stderr, "error: supports 1.43 only\n");
        fclose(smvFile);
        return 1;
      }

      /* read movie info */
      fseek(smvFile, 0x10, SEEK_SET);
      numFrames = (size_t) fget4l(smvFile);
      numStoredFrames = numFrames + 1;
      fseek(smvFile, 0x14, SEEK_SET);
      ctlMask = fget4l(smvFile);
      fseek(smvFile, 0x17, SEEK_SET);
      syncOption = fget1(smvFile);
      fseek(smvFile, 0x1c, SEEK_SET);
      ctlOffset = (size_t) fget4l(smvFile);

      /* count the number of contollers */
      numCtls = 0;
      for(i = 0; i < SMV_MAX_CTL; i++)
      {
        if(ctlMask & (1 << i))
        {
          numCtls++;
        }
      }

      /* truncates */
      ctlDataSize = numCtls * numStoredFrames * 2;
      smvFileSize = ctlOffset + ctlDataSize;
      smvData = (byte*) malloc(smvFileSize);
      if(smvData)
      {
        rewind(smvFile);
        if(fread(smvData, 1, smvFileSize, smvFile) == smvFileSize)
        {
          fclose(smvFile);
          smvFile = fopen(path, "wb");
          if(smvFile)
          {
            if(fwrite(smvData, 1, smvFileSize, smvFile) == smvFileSize)
            {
              result = true;
            }
            else
            {
              fprintf(stderr, "error: movie writing error\n");
            }
            fclose(smvFile);
          }
          else
          {
            fprintf(stderr, "error: movie reopening error\n");
          }
        }
        else
        {
          fprintf(stderr, "error: movie reading error\n");
        }
      }
      else
      {
        fprintf(stderr, "error: memory allocation failed\n");
      }
      fseek(smvFile, (long) smvFileSize, SEEK_SET);
    }
    if(smvFile)
    {
      fclose(smvFile);
    }
  }
  else
  {
    fprintf(stderr, "error: movie could not be opened\n");
  }

  return result;
}
