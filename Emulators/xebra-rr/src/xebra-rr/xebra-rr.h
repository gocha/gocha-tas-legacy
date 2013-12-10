/**
 * XEBRA-RR.DLL - additional code
 */

#pragma once

#define WIN32_LEAN_AND_MEAN

#include <windows.h>

#include "xebra-if.h"

//------------------------------------------------------------------------------
// Generic Definition
//------------------------------------------------------------------------------
#ifdef __cplusplus
#define EXTERN_C        extern "C"
#define START_EXTERN_C  extern "C" {
#define END_EXTERN_C    }
#else
#define EXTERN_C        extern
#define START_EXTERN_C  extern
#define END_EXTERN_C
#endif

//------------------------------------------------------------------------------
// Plugin Interfaces
//------------------------------------------------------------------------------
#ifdef XEBRARR_EXPORTS
#define XEBRARR_API	__declspec(dllexport)
#else
#define XEBRARR_API	__declspec(dllimport)
#endif

START_EXTERN_C
XEBRARR_API BOOL XRSetInterface(XEBRA_IF* pInterface);
XEBRARR_API INT_PTR XRMainDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
END_EXTERN_C
