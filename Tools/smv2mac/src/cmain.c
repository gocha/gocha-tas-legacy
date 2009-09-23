/**
 * cmain.c: a skeleton for cui application
 */


#include <stdio.h>
#include <string.h>
#include "cioutil.h"

#include <stdlib.h>
#include "smv2mac.h"


#define CAPP_NAME   "smv2mac"
#define CAPP_CMD    "smv2mac"
#define CAPP_VER    "20070527"
#define CAPP_AUTHOR "gocha"


/* options */
int  g_targetCtl = 1;   /* target controller (1-5) */
bool g_putAddr = false; /* put controller data offset */


/* prototypes */
void putLineToStdout(const char* str);


/* put line to stdout */
void putLineToStdout(const char* str)
{
//  puts(str);
  printf("%s,", str);
}

/* show application usage */
void cappShowUsage(void)
{
  const char* options[] = {
    "", "--help", "show this usage", 
    "-N", "(N=1~5)", "set controller number (default:1)", 
    "-a", "--addr", "put controller data address"
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
  case '1':
  case '2':
  case '3':
  case '4':
  case '5':
    g_targetCtl = optChar - '1' + 1;
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
bool cappDispatchOptionStr(const char* optString)
{
  if(strcmp(optString, "help") == 0)
  {
    cappShowUsage();
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

/* dispatch file path */
bool cappDispatchFilePath(const char* path)
{
  bool result = false;
  SmvToXsv* smv2xsv;

  fprintf(stderr, "%s (%dP):\n", path, g_targetCtl);
  smv2xsv = smvXsvReadFile(path);
  if(smv2xsv)
  {
    smvXsvSetProc(smv2xsv, putLineToStdout);
    smvXsvSetSepChar(smv2xsv, ',');
    smvXsvSetTargetCtl(smv2xsv, g_targetCtl - 1);
    smvXsvSetPutAddr(smv2xsv, g_putAddr);

    if(!smvXsvOutput(smv2xsv))
    {
      fprintf(stderr, "error: smvXsvOutput() failed\n");
    }

    smvXsvDelete(smv2xsv);
  }
  else
  {
    fprintf(stderr, "error: smvXsvReadFile() failed\n");
  }
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
