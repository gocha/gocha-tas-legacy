/**
 * smv2csv.c: write key sequence to csv text
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "smv2csv.h"


#define SMVXSV_MAX_CTL 5
#define SMVXSV_HELD_NULL   '\0'
#define SMVXSV_HELD_NONE   ' '
#define SMVXSV_HELD_ON     '+'
#define SMVXSV_HELD_OFF    '-'

#define MOVIE_SYNC_DATA_EXISTS  0x01
#define MOVIE_SYNC_WIP1TIMING   0x02
#define MOVIE_SYNC_LEFTRIGHT    0x04
#define MOVIE_SYNC_VOLUMEENVX   0x08
#define MOVIE_SYNC_FAKEMUTE     0x10
#define MOVIE_SYNC_SYNCSOUND    0x20
#define MOVIE_SYNC_HASROMINFO   0x40

SmvToXsv* smvXsvCreate(const byte* smv, size_t size)
{
  SmvToXsv* newSmv2xsv = NULL;

  if(smv && size >= 0x20 && 
      smv[0] == 'S' && 
      smv[1] == 'M' && 
      smv[2] == 'V' && 
      smv[3] == 0x1a )
  {
    int version;
    size_t numFrames;
    size_t numStoredFrames;
    size_t lastFrame;
    int ctlMask;
    int numCtls;
    int syncOption;
    size_t ctlOffset;
    size_t ctlDataSize;
    int i;

    /* read movie info */
    version = mget4l(&smv[0x04]);
    numFrames = (size_t) mget4l(&smv[0x10]);
    numStoredFrames = numFrames + 1;
    ctlMask = mget4l(&smv[0x14]);
    syncOption = mget1(&smv[0x17]);
    ctlOffset = (size_t) mget4l(&smv[0x1c]);
    /* others */
    lastFrame = (version == 1) ? (numFrames - 1) : numFrames;

    /* count the number of contollers */
    numCtls = 0;
    for(i = 0; i < SMVXSV_MAX_CTL; i++)
    {
      if(ctlMask & (1 << i))
      {
        numCtls++;
      }
    }

    /* read key sequences */
    ctlDataSize = numCtls * numStoredFrames * 2;
    if(size >= (ctlOffset + ctlDataSize))
    {
      byte* ctlData;

      ctlData = (byte*) malloc(ctlDataSize);
      if(ctlData)
      {
        memcpy(ctlData, &smv[ctlOffset], ctlDataSize);

        /* create new object */
        newSmv2xsv = calloc(1, sizeof(SmvToXsv));
        if(newSmv2xsv)
        {
          newSmv2xsv->targetCtl = 0;
          newSmv2xsv->putAddr = false;
          newSmv2xsv->sepChar = ',';
          newSmv2xsv->version = version;
          newSmv2xsv->ctlMask = ctlMask;
          newSmv2xsv->numCtls = numCtls;
          newSmv2xsv->syncOption = syncOption;
          newSmv2xsv->frames = numFrames;
          newSmv2xsv->lastFrame = lastFrame;
          newSmv2xsv->baseAddr = ctlOffset;
          newSmv2xsv->data = ctlData;
          newSmv2xsv->proc = NULL;
        }
        else
        {
          free(ctlData);
        }
      }
    }
  }

  return newSmv2xsv;
}

void smvXsvDelete(SmvToXsv* smv2xsv)
{
  if(smv2xsv)
  {
    free(smv2xsv->data);
    free(smv2xsv);
  }
}

SmvToXsv* smvXsvReadFile(const char* path)
{
  SmvToXsv* newSmv2xsv = NULL;
  FILE* smvFile = fopen(path, "rb");

  if(smvFile)
  {
    size_t smvFileSize;
    byte* smvBuf;

    fseek(smvFile, 0, SEEK_END);
    smvFileSize = (size_t) ftell(smvFile);
    rewind(smvFile);

    smvBuf = (byte*) malloc(smvFileSize);
    if(smvBuf)
    {
      size_t readSize;

      readSize = fread(smvBuf, 1, smvFileSize, smvFile);
      if(readSize == smvFileSize)
      {
        newSmv2xsv = smvXsvCreate(smvBuf, smvFileSize);
      }
      free(smvBuf);
    }
    fclose(smvFile);
  }
  return newSmv2xsv;
}

SmvXsvProc* smvXsvSetProc(SmvToXsv* smv2xsv, SmvXsvProc* proc)
{
  SmvXsvProc* oldProc = NULL;

  if(smv2xsv)
  {
    oldProc = smv2xsv->proc;
    smv2xsv->proc = proc;
  }
  return oldProc;
}

char smvXsvSetSepChar(SmvToXsv* smv2xsv, char sepChar)
{
  char oldSepChar = 0;

  if(smv2xsv)
  {
    oldSepChar = smv2xsv->sepChar;
    smv2xsv->sepChar = sepChar;
  }
  return oldSepChar;
}

int smvXsvSetTargetCtl(SmvToXsv* smv2xsv, int targetCtl)
{
  int oldTargetCtl = 0;

  if(smv2xsv)
  {
    oldTargetCtl = smv2xsv->targetCtl;
    smv2xsv->targetCtl = targetCtl;
  }
  return oldTargetCtl;
}

bool smvXsvSetPutAddr(SmvToXsv* smv2xsv, bool putAddr)
{
  bool oldPutAddr = false;

  if(smv2xsv)
  {
    oldPutAddr = smv2xsv->putAddr;
    smv2xsv->putAddr = putAddr;
  }
  return oldPutAddr;
}

bool smvXsvOutput(SmvToXsv* smv2xsv)
{
  bool result = false;

  if(smv2xsv)
  {
    int targetCtl = smv2xsv->targetCtl;
    bool putAddr = smv2xsv->putAddr;
    char sepChar = smv2xsv->sepChar;
    int version = smv2xsv->version;
    int ctlMask = smv2xsv->ctlMask;
    int targetMask = 1 << targetCtl;
    int syncOption = smv2xsv->syncOption;
    bool checkLeftRight = !(syncOption & MOVIE_SYNC_LEFTRIGHT);
    bool hasLeftRight = false;
    size_t numFrames = smv2xsv->frames;
    size_t lastFrame = smv2xsv->lastFrame;
    size_t baseAddr = smv2xsv->baseAddr;
    size_t sizeToNextFrame = (size_t) smv2xsv->numCtls * 2;
    byte* ctlData = smv2xsv->data;
    SmvXsvProc* putLine = smv2xsv->proc;
    int i;

    if(putLine && (ctlMask & targetMask))
    {
      char addrBuf[32];
      char keyBuf[8];
      char keysBuf[64];
      char lineBuf[112];
      size_t ctlOffsetBase;
      size_t ctlOffset;
      size_t curFrame;
      int keyHeldBit;
      int keyCode;

      /* move to input data */
      ctlOffsetBase = 0;
      for(i = 0; i < targetCtl; i++)
      {
        ctlOffsetBase += 2;
      }
      ctlOffset = ctlOffsetBase;
      curFrame = (version == 1) ? -1 : 0;

      /* put start of frames */
      strcpy(addrBuf, "");
      if(putAddr)
      {
        sprintf(addrBuf, "%08X%c", baseAddr+ctlOffset-ctlOffsetBase, sepChar);
      }
      sprintf(lineBuf, "%sSOF", addrBuf);
      putLine(lineBuf);

      /* skip first frame */
      keyCode = mget2l(&ctlData[ctlOffset]);
      if((keyCode != 0xFFFF) && (((keyCode & 0x0300) == 0x0300) || ((keyCode & 0x0C00) == 0x0C00)))
      {
        hasLeftRight = true;
      }
      ctlOffset += sizeToNextFrame;
      curFrame++;

      /* scan all frames */
      keyHeldBit = 0;
      for(; curFrame <= lastFrame; curFrame++)
      {
        int keyIndex;
        int nextKeyCode = 0;
        const char keyName[] = { '0', '1', '2', '3', 'R', 'L', 'X', 'A', 
                                 '>', '<', 'v', '^', 'S', 's', 'Y', 'B' };

        /* read key code */
        keyCode = mget2l(&ctlData[ctlOffset]);
        /* read next key code if needed */
        if((curFrame + 1) != numFrames)
        {
          nextKeyCode = mget2l(&ctlData[ctlOffset + sizeToNextFrame]);
        }

        /* dispatch all keys */
        strcpy(keysBuf, "");
        if(keyCode == 0xFFFF)
        {
          strcpy(keysBuf, "RESET");
/*
          keyHeldBit = 0;
*/
        }
        else
        {
          /* check left+right/up+down */
          if(((keyCode & 0x0300) == 0x0300) || ((keyCode & 0x0C00) == 0x0C00))
          {
            hasLeftRight = true;
          }


          for(keyIndex = 0; keyIndex < 16; keyIndex++)
          {
            int keyCodeMask = (1 << keyIndex);
            char keyHeldState = (keyHeldBit & keyCodeMask) ? SMVXSV_HELD_ON : SMVXSV_HELD_NONE;

            if(keyCode & keyCodeMask)
            {
              if(keyHeldState != SMVXSV_HELD_ON && (nextKeyCode & keyCodeMask))
              {
                keyHeldBit |= keyCodeMask;
                keyHeldState = SMVXSV_HELD_ON;
              }
              else if(keyHeldState == SMVXSV_HELD_ON)
              {
                if(nextKeyCode & keyCodeMask)
                {
                  keyHeldState = SMVXSV_HELD_NULL;
                }
                else
                {
                  keyHeldBit &= ~keyCodeMask;
                  keyHeldState = SMVXSV_HELD_OFF;
                }
              }

              if(keyHeldState != SMVXSV_HELD_NULL)
              {
                sprintf(keyBuf, "%c%c ", keyName[keyIndex], keyHeldState);
                strcat(keysBuf, keyBuf);
              }
            }
          }
        }

        if(strcmp(keysBuf, "") != 0)
        {
          strcpy(addrBuf, "");
          if(putAddr)
          {
            sprintf(addrBuf, "%08X%c", baseAddr+ctlOffset, sepChar);
          }
          sprintf(lineBuf, "%s%u%c%s", addrBuf, curFrame, sepChar, keysBuf);
          putLine(lineBuf);
        }

        ctlOffset += sizeToNextFrame;
      }

      /* put end of frames */
      strcpy(addrBuf, "");
      if(putAddr)
      {
        sprintf(addrBuf, "%08X%c", baseAddr+ctlOffset-ctlOffsetBase, sepChar);
      }
      sprintf(lineBuf, "%s%u%cEOF", addrBuf, curFrame, sepChar);
      putLine(lineBuf);

      if(checkLeftRight && hasLeftRight)
      {
        putLine("warning: left+right/up+down recorded");
      }

      result = true;
    }
  }
  return result;
}
