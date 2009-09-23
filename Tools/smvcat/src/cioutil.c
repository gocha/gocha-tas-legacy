/*
 * ciotuil.c: simple i/o routines for C
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cioutil.h"


/* copy file */
bool fcopy(const char* dstPath, const char* srcPath)
{
  bool result = false;
  FILE* dstFile;
  FILE* srcFile;
  byte* buf;
  const size_t bufSize = 0x40000;

  if(strcmp(dstPath, srcPath) == 0)
  {
    return true;
  }

  buf = (byte*) malloc(bufSize);
  if(buf)
  {
    dstFile = fopen(dstPath, "wb");
    if(dstFile)
    {
      srcFile = fopen(srcPath, "rb");
      if(srcFile)
      {
        do
        {
          size_t readSize;

          readSize = fread(buf, 1, bufSize, srcFile);
          fwrite(buf, 1, readSize, dstFile);
        } while(!feof(srcFile));
        result = true;

        fclose(srcFile);
      }
      fclose(dstFile);
    }
    free(buf);
  }
  return result;
}

/* remove path extention (SUPPORTS ASCII ONLY!) */
char* removeExt(char* path)
{
  size_t i;

  i = strlen(path);
  if(i > 1)
  {
    i--;
    for(; i > 0; i--)
    {
      char c = path[i];

      if(c == '.')
      {
        path[i] = '\0';
        break;
      }
      else if(c == '/' || c == '\\')
      {
        break;
      }
    }
  }
  return path;
}
