#include <windows.h>

static int glFuncCount = 1;
static HWND glhWnd = NULL;
static char* glFuncNames[] = { "XRSetInterface" };
static void* glhLibRR;
static void* glFuncPtrs[1];
static int glInterface;

typedef BOOL (*SetInterface)(void*);

BOOL LoadXebraRR(void)
{
	char message[128];
	HMODULE hLibXebraRR;

	// load dll
	hLibXebraRR = LoadLibrary("XEBRA-RR.DLL");
	if (hLibXebraRR == NULL)
	{
		MessageBox(glhWnd, "Unable to load XEBRA-RR.DLL", "XEBRA-RR Error", MB_ICONERROR | MB_OK);
		return FALSE;
	}
	glhLibRR = hLibXebraRR;

	// for each functions
	for (int i = 0; i < glFuncCount; i++)
	{
		// load function pointer
		void *pFunc = GetProcAddress(hLibXebraRR, glFuncNames[i]);
		if (pFunc == NULL)
		{
			wsprintf(message, "Unable to load \"%s\" from XEBRA-RR.DLL", glFuncNames[i]);
			MessageBox(glhWnd, message, "XEBRA-RR Error", MB_ICONERROR | MB_OK);
			return FALSE;
		}

		// save function pointer
		glFuncPtrs[i] = pFunc;
	}

	// invoke XRSetInterface function
	if (!((SetInterface)glFuncPtrs[0])(&glInterface))
	{
		MessageBox(glhWnd, "XEBRA-RR.DLL version not supported", "XEBRA-RR Error", MB_ICONERROR | MB_OK);
		return FALSE;
	}

	return TRUE;
}
