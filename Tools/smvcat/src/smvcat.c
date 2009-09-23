/**
 * smvcat.c: smv concatenator
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "smvcat.h"

#define SMV_MAX_CTLS    5

/* show usage */
void cappShowUsage(void)
{
  puts("usage: smvcat [output-path] [input-files]");
  puts("presented by gocha (http://gocha.is.land.to/)");
}

/* application main */
int main(int argc, char* argv[])
{
  int argi;
  char* dstPath;
  char* srcPath;
  FILE* dstFile;
  FILE* srcFile;

  if(argc < 3)
  {
    cappShowUsage();
    return 0;
  }

  dstPath = argv[1];
  srcPath = argv[2];
  puts(srcPath);
  if(!fcopy(dstPath, srcPath))
  {
    fprintf(stderr, "error: file could not be copied\n");
    return 0;
  }

  /* concatenate movie files */
  dstFile = fopen(dstPath, "r+b");
  if(dstFile)
  {
    int ctl;
    int ctlMask;
    int numCtls;
    int version;
    int recCount;
    int numFrames;
    int numSamples;
    byte ctlType[2];
    size_t ctlOffset;
    bool catSucceed = true;

    /* read movie info */
    fseek(dstFile, 0x04, SEEK_SET);
    version = fget4l(dstFile);
    fseek(dstFile, 0x0c, SEEK_SET);
    recCount = fget4l(dstFile);
    fseek(dstFile, 0x10, SEEK_SET);
    numFrames = fget4l(dstFile);
    fseek(dstFile, 0x14, SEEK_SET);
    ctlMask = fget1(dstFile);
    if (version != 1) {
      fseek(dstFile, 0x20, SEEK_SET);
      numSamples = fget4l(dstFile);
      fseek(dstFile, 0x24, SEEK_SET);
      ctlType[0] = fget1(dstFile);
      fseek(dstFile, 0x25, SEEK_SET);
      ctlType[1] = fget1(dstFile);
    }
    else {
      numSamples = numFrames;
    }

    /* limit input movie */
    if (version != 1) {
      if (ctlType[0] > 1 || ctlType[1] > 1) {
        fprintf(stderr, "error: supports joypad input only\n");
        _exit(1);
      }
    }

    /* count the number of controllers */
    numCtls = 0;
    for(ctl = 0; ctl < SMV_MAX_CTLS; ctl++)
    {
      if(ctlMask & (1 << ctl))
      numCtls++;
    }

    fseek(dstFile, 0x1c, SEEK_SET);
    ctlOffset = (size_t) fget4l(dstFile) + (2 * numCtls);

    /* for each movie */
    for(argi = 3; catSucceed && argi < argc; argi++)
    {
      srcPath = argv[argi];
      puts(srcPath);
      srcFile = fopen(srcPath, "rb");
      if(srcFile)
      {
        int srcVersion;
        int srcCtlMask;
        int srcRecCount;
        int srcNumFrames;
        int srcNumSamples;
        size_t srcCtlOffset;
        size_t srcCtlSize;
        byte srcCtlType[2];
        byte* srcCtlData;

        fseek(srcFile, 0x04, SEEK_SET);
        srcVersion = fget4l(srcFile);
        fseek(srcFile, 0x0c, SEEK_SET);
        srcRecCount = fget4l(srcFile);
        fseek(srcFile, 0x10, SEEK_SET);
        srcNumFrames = fget4l(srcFile);
        fseek(srcFile, 0x14, SEEK_SET);
        srcCtlMask = fget1(srcFile);
        fseek(srcFile, 0x1c, SEEK_SET);
        srcCtlOffset = (size_t) fget4l(srcFile) + (2 * numCtls);
        if (srcVersion != 1) {
          fseek(srcFile, 0x20, SEEK_SET);
          srcNumSamples = fget4l(srcFile);
          fseek(srcFile, 0x24, SEEK_SET);
          srcCtlType[0] = fget1(srcFile);
          fseek(srcFile, 0x25, SEEK_SET);
          srcCtlType[1] = fget1(srcFile);
        }
        else {
          srcNumSamples = srcNumFrames;
        }

        if(srcVersion != version)
        {
          fprintf(stderr, "warning: mismatch version\n");
        }

        if(srcCtlMask != ctlMask)
        {
          fprintf(stderr, "error: controller masks are different\n");
          catSucceed = false;
          break;
        }

        srcCtlSize = numCtls * srcNumFrames * 2;
        srcCtlData = (byte*) malloc(srcCtlSize);
        if(srcCtlData)
        {
          fseek(srcFile, (long) srcCtlOffset, SEEK_SET);
          fread(srcCtlData, 1, srcCtlSize, srcFile);
          fseek(dstFile, (long) ctlOffset + (numCtls * numFrames * 2), SEEK_SET);
          fwrite(srcCtlData, 1, srcCtlSize, dstFile);
          numFrames += srcNumFrames;
          fseek(dstFile, 0x10, SEEK_SET);
          fput4l(numFrames, dstFile);
          recCount += srcRecCount;
          fseek(dstFile, 0x0c, SEEK_SET);
          fput4l(recCount, dstFile);
          if (version != 1) {
            numSamples += srcNumSamples;
            fseek(dstFile, 0x20, SEEK_SET);
            fput4l(numSamples, dstFile);
          }

          free(srcCtlData);
        }
        else
        {
          fprintf(stderr, "error: memory allocation failed\n");
          catSucceed = false;
          break;
        }

        fclose(srcFile);
      }
      else
      {
        fprintf(stderr, "error: file could not be opened [%s]\n", srcPath);
        catSucceed = false;
        break;
      }
    }

    fclose(dstFile);
  }
  else
  {
    fprintf(stderr, "error: file could not be opened [%s]\n", dstPath);
  }

  return 0;
}
