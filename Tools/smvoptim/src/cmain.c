/**
 * cmain.c: a skeleton for cui application
 */


#include <stdio.h>
#include <string.h>
#include "cioutil.h"

#include <stdlib.h>
#include "smvoptim.h"


#define CAPP_NAME   "smvoptim"
#define CAPP_CMD    "smvoptim"
#define CAPP_VER    "20070527"
#define CAPP_AUTHOR "gocha"


/* show application usage */
void cappShowUsage(void)
{
  const char* options[] = {
    "", "--help", "show this usage", 
  };
  int optIndex;

  puts("usage  : "CAPP_CMD" (options) [input-files]");
  puts("options:");
  for(optIndex = 0; optIndex < countof(options); optIndex += 3)
  {
    printf("  %-2s  %-16s  %s\n", options[optIndex], options[optIndex + 1], options[optIndex + 2]);
  }
  puts("____");
  puts(CAPP_NAME" ["CAPP_VER"] by "CAPP_AUTHOR);
}

/* dispatch option char */
bool cappDispatchOptionChar(const char optChar)
{
  switch(optChar)
  {
  default:
    return false;
  }
  return true;
}

/* dispatch option string */
bool cappDispatchOptionStr(const char* optString)
{
  if(strcmp(optString, "help") == 0)
  {
    cappShowUsage();
  }
  else
  {
    return false;
  }
  return true;
}

/* dispatch file path */
bool cappDispatchFilePath(const char* path)
{
  bool result;

  fprintf(stderr, "%s: ", path);
  result = smvoptim(path);
  fprintf(stderr, "%s\n", result ? "done" : "");
  return result;
}

/* application main */
int main(int argc, char* argv[])
{
  int argi = 1;
  int argci;

  if(argc == 1) /* no arguments */
  {
    cappShowUsage();
  }
  else
  {
    /* options */
    while((argi < argc) && (argv[argi][0] == '-'))
    {
      if(argv[argi][1] == '-') /* --string */
      {
        cappDispatchOptionStr(&argv[argi][2]);
      }
      else /* -letters (alphanumeric only) */
      {
        argci = 1;
        while(argv[argi][argci] != '\0')
        {
          cappDispatchOptionChar(argv[argi][argci]);
          argci++;
        }
      }
      argi++;
    }

    /* input files */
    for(; argi < argc; argi++)
    {
      cappDispatchFilePath(argv[argi]);
    }
  }
  return 0;
}
