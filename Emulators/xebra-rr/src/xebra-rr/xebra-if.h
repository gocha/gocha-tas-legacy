/**
 * XEBRA-RR.DLL - host interface
 */

#pragma once

#define WIN32_LEAN_AND_MEAN

#include <windows.h>

//------------------------------------------------------------------------------
// Host Native Interfaces
//------------------------------------------------------------------------------
typedef void (*XNICreatePadHistoryFile)(const char *);
typedef void (*XNIOpenPadHistoryFile)(const char *);
typedef BOOL (*XNIIsPadHistoryFile)(const char *);
typedef void (*XNIClosePadHistoryFile)(void);

#define XEBRA_IF_VERSION	1
typedef struct
{
	DWORD interfaceVersion;
	DWORD hostVersion;

	HINSTANCE hInstance;
	HWND hWnd;
	BYTE* pMainMemory;
} XEBRA_IF;

//------------------------------------------------------------------------------
// High-Level Interfaces
//------------------------------------------------------------------------------
class XebraInterface
{
public:
	XebraInterface() :
		pNativeIF(NULL)
	{
	}
	virtual ~XebraInterface(){}

	bool SetInterface(XEBRA_IF* pInterface);

	HINSTANCE GetInstance(void);
	HWND GetMainWindow(void);
	BYTE* GetMainMemory(void);

private:
	XEBRA_IF* pNativeIF;
};
