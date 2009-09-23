/**
 * vbm2csv.c: write key sequence to csv text
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "vbm2csv.h"


/* application info */
#define APP_USAGE   "vbm2csv (options) [input-files]"
#define APP_NAME    "vbm2csv"
#define APP_VER     "20060822"
#define APP_AUTHOR  "gocha"

/* vbm related info */
#define VBM_MAX_CTL 4
#define VBM_HELD_NULL   '\0'
#define VBM_HELD_NONE   ' '
#define VBM_HELD_ON     '+'
#define VBM_HELD_OFF    '-'

/* options */
int  g_ctlNumber = 1;   /* controller number (1~5) */
bool g_putAddr = false; /* put controller data offset */
const char* g_xsvSep = ",";

/* private functions */
void dispatchLogMsg(const char* logMsg);
bool dispatchOptionChar(const char optChar);
bool dispatchOptionStr(const char* optString);
void showUsage(void);
int main(int argc, char* argv[]);

int fget2l(FILE* stream);
int fget3l(FILE* stream);
int fget4l(FILE* stream);
int fget2b(FILE* stream);
int fget3b(FILE* stream);
int fget4b(FILE* stream);

/* vbm2csv translation main */
bool vbmCtl2csv(const byte* ctlData, size_t numFrames, size_t baseAdr)
{
  bool result = false;
  size_t frame;
  size_t ctlOffset = 0;
  int keyHeldBit = 0;

  if(ctlData && numFrames)
  {
    if(g_putAddr)
    {
      printf("%08X%s", baseAdr + ctlOffset, g_xsvSep);
    }
    printf("%u", 0);
    printf("%s", g_xsvSep);
    puts("SOF");

    for(frame = 0; frame < numFrames; frame++)
    {
      int keyCode;
      int keyIndex;
      int nextKeyCode = 0;
      bool putSomething = false;
      const char keyName[] = { 'A', 'B', 's', 'S', '>', '<', '^', 'v', 
                               'R', 'L', 'r', '8', 'l', 'r', 'd', 'u' };

      /* read key code */
      keyCode = ctlData[ctlOffset] | (ctlData[ctlOffset + 1] * 0x0100);
      if((frame + 1) != numFrames)  /* not the last frame */
      {
        nextKeyCode = ctlData[ctlOffset + 2] | (ctlData[ctlOffset + 3] * 0x0100);
      }

      /* dispatch all keys */
      for(keyIndex = 0; keyIndex < 16; keyIndex++)
      {
        int keyCodeMask = (1 << keyIndex);
        char keyHeldState = (keyHeldBit & keyCodeMask) ? VBM_HELD_ON : VBM_HELD_NONE;

        if(keyCode & keyCodeMask)
        {
          if(keyHeldState != VBM_HELD_ON && (nextKeyCode & keyCodeMask))
          {
            keyHeldBit |= keyCodeMask;
            keyHeldState = VBM_HELD_ON;
          }
          else if(keyHeldState == VBM_HELD_ON)
          {
            if(nextKeyCode & keyCodeMask)
            {
              keyHeldState = VBM_HELD_NULL;
            }
            else
            {
              keyHeldBit &= ~keyCodeMask;
              keyHeldState = VBM_HELD_OFF;
            }
          }

          if(keyHeldState != VBM_HELD_NULL)
          {
            if(!putSomething)
            {
              if(g_putAddr)
              {
                printf("%08X%s", baseAdr + ctlOffset, g_xsvSep);
              }
              printf("%u", frame);
              printf("%s", g_xsvSep);
              putSomething = true;
            }
            printf("%c%c ", keyName[keyIndex], keyHeldState);
          }
        }
      }
      if(putSomething)
      {
        putchar('\n');
      }

      ctlOffset += 2;
    }

    if(g_putAddr)
    {
      printf("%08X%s", baseAdr + ctlOffset, g_xsvSep);
    }
    printf("%u", frame);
    printf("%s", g_xsvSep);
    puts("EOF");
    result = true;
  }
  return result;
}

/* vbm2csv main */
bool vbm2csv(const char* filename)
{
  bool result = false;
  FILE* vbmFile;

  fprintf(stderr, "%s (%dP):\n", filename, g_ctlNumber);

  /* open vbm file */
  vbmFile = fopen(filename, "rb");
  if(vbmFile)
  {
    if( (fgetc(vbmFile) == 'V') && 
        (fgetc(vbmFile) == 'B') && 
        (fgetc(vbmFile) == 'M') && 
        (fgetc(vbmFile) == 0x1a) )
    {
      int ctlNumber = g_ctlNumber - 1;
      size_t numFrames;
      size_t numStoredFrames;
      int ctlMask;
      size_t ctlOffset;

      /* read settings */
      fseek(vbmFile, 0x0c, SEEK_SET); 
      numFrames = (size_t) fget4l(vbmFile);
      numStoredFrames = numFrames;
      fseek(vbmFile, 0x15, SEEK_SET); 
      ctlMask = fgetc(vbmFile);
      fseek(vbmFile, 0x3c, SEEK_SET); 
      ctlOffset = (size_t) fget4l(vbmFile);

      /* is controller data present? */
      if(ctlMask & (1 << ctlNumber))
      {
        int i;
        int numCtls = 0;
        byte* ctlData;

        /* count number of contollers */
        for(i = 0; i < VBM_MAX_CTL; i++)
        {
          if(ctlMask & (1 << i))
          {
            numCtls++;

            /* adjust offset, if need */
            if(i < ctlNumber)
            {
              ctlOffset += 2;
            }
          }
        }

        ctlData = (byte*) malloc(numStoredFrames * 2);
        if(ctlData)
        {
          size_t frame;
          size_t sizeToNextFrame = (size_t) ((numCtls - 1) * 2);

          /* read controller data */
          fseek(vbmFile, (long) ctlOffset, SEEK_SET); 
          for(frame = 0; frame < numStoredFrames; frame++)
          {
            fread(&ctlData[frame * 2], 2, 1, vbmFile);
            fseek(vbmFile, (long) sizeToNextFrame, SEEK_CUR);
          }

          /* do vbm2csv translation */
          result = vbmCtl2csv(ctlData, numFrames, ctlOffset);

          free(ctlData);
        }
        else
        {
          fprintf(stderr, "error: memory allocation failed\n");
        }
      }
      else
      {
        fprintf(stderr, "error: controller data wasn't present\n");
      }
    }
    else
    {
      fprintf(stderr, "error: invalid file\n");
    }

    fclose(vbmFile);
  }
  else
  {
    fprintf(stderr, "error: file couldn't be opened\n");
  }

  return result;
}


/* dispatch option character */
bool dispatchOptionChar(const char optChar)
{
  switch(optChar)
  {
  case '1':
  case '2':
  case '3':
  case '4':
    g_ctlNumber = optChar - '1' + 1;
    break;

  case 'a':
    g_putAddr = true;
    break;

  default:
    return false;
  }
  return true;
}

/* dispatch option string */
bool dispatchOptionStr(const char* optString)
{
  if(strcmp(optString, "help") == 0)
  {
    showUsage();
  }
  else if(strcmp(optString, "addr") == 0)
  {
    g_putAddr = true;
  }
  else
  {
    return false;
  }
  return true;
}

/* show usage */
void showUsage(void)
{
  const char* options[] = {
    "", "--help", "show this usage", 
    "-N", "(N=1~4)", "set controller number (default:1)", 
    "-a", "--addr", "put controller data address"
  };
  int optIndex;

  puts("usage  : "APP_USAGE);
  puts("options:");
  for(optIndex = 0; optIndex < countof(options); optIndex += 3)
  {
    printf("  %-2s  %-16s  %s\n", options[optIndex], options[optIndex + 1], options[optIndex + 2]);
  }
  puts("____");
  puts(APP_NAME" ["APP_VER"] by "APP_AUTHOR);
}

/* application main */
int main(int argc, char* argv[])
{
  int argi = 1;
  int argCharIndex;

  if(argc == 1) /* no arguments */
  {
    showUsage();
  }
  else
  {
    /* options */
    while((argi < argc) && (argv[argi][0] == '-'))
    {
      if(argv[argi][1] == '-') /* --string */
      {
        dispatchOptionStr(&argv[argi][2]);
      }
      else /* -letters (alphanumeric only) */
      {
        argCharIndex = 1;
        while(argv[argi][argCharIndex] != '\0')
        {
          dispatchOptionChar(argv[argi][argCharIndex]);
          argCharIndex++;
        }
      }
      argi++;
    }

    /* input files */
    for(; argi < argc; argi++)
    {
      vbm2csv(argv[argi]);
    }
  }
  return 0;
}

/* get 2bytes as little-endian */
int fget2l(FILE* stream)
{
  int b1;
  int b2;

  b1 = fgetc(stream);
  b2 = fgetc(stream);
  if((b1 != EOF) && (b2 != EOF))
  {
    return b1 | (b2 * 0x0100);
  }
  return EOF;
}

/* get 3bytes as little-endian */
int fget3l(FILE* stream)
{
  int b1;
  int b2;
  int b3;

  b1 = fgetc(stream);
  b2 = fgetc(stream);
  b3 = fgetc(stream);
  if((b1 != EOF) && (b2 != EOF) && (b3 != EOF))
  {
    return b1 | (b2 * 0x0100) | (b3 * 0x010000);
  }
  return EOF;
}

/* get 4bytes as little-endian */
int fget4l(FILE* stream)
{
  int b1;
  int b2;
  int b3;
  int b4;

  b1 = fgetc(stream);
  b2 = fgetc(stream);
  b3 = fgetc(stream);
  b4 = fgetc(stream);
  if((b1 != EOF) && (b2 != EOF) && (b3 != EOF) && (b4 != EOF))
  {
    return b1 | (b2 * 0x0100) | (b3 * 0x010000) | (b4 * 0x01000000);
  }
  return EOF;
}

/* get 2bytes as big-endian */
int fget2b(FILE* stream)
{
  int b1;
  int b2;

  b1 = fgetc(stream);
  b2 = fgetc(stream);
  if((b1 != EOF) && (b2 != EOF))
  {
    return b2 | (b1 * 0x0100);
  }
  return EOF;
}

/* get 3bytes as big-endian */
int fget3b(FILE* stream)
{
  int b1;
  int b2;
  int b3;

  b1 = fgetc(stream);
  b2 = fgetc(stream);
  b3 = fgetc(stream);
  if((b1 != EOF) && (b2 != EOF) && (b3 != EOF))
  {
    return b3 | (b2 * 0x0100) | (b1 * 0x010000);
  }
  return EOF;
}

/* get 4bytes as big-endian */
int fget4b(FILE* stream)
{
  int b1;
  int b2;
  int b3;
  int b4;

  b1 = fgetc(stream);
  b2 = fgetc(stream);
  b3 = fgetc(stream);
  b4 = fgetc(stream);
  if((b1 != EOF) && (b2 != EOF) && (b3 != EOF) && (b4 != EOF))
  {
    return b4 | (b3 * 0x0100) | (b2 * 0x010000) | (b1 * 0x01000000);
  }
  return EOF;
}
