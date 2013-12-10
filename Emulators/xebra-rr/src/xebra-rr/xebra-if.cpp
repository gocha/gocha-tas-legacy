/**
 * XEBRA-RR.DLL - host interface
 */

#include "xebra-rr.h"

/// <summary>Set native interface by host.</summary>
/// <param name='pInterface'>Native interface pointer of host.</param>
/// <returns>Return FALSE for version mismatch.</returns>
bool XebraInterface::SetInterface(XEBRA_IF* pInterface)
{
	if (pInterface->interfaceVersion != XEBRA_IF_VERSION)
	{
		return false;
	}
	pNativeIF = pInterface;
	return true;
}

/// <summary>Get application instance handle.</summary>
/// <returns>Returns application instance handle.</returns>
HINSTANCE XebraInterface::GetInstance(void)
{
	return pNativeIF->hInstance;
}

/// <summary>Get main window handle.</summary>
/// <returns>Returns main window handle.</returns>
HWND XebraInterface::GetMainWindow(void)
{
	return pNativeIF->hWnd;
}

/// <summary>Get main RAM pointer.</summary>
/// <returns>Returns main RAM region os PlayStation.</returns>
BYTE* XebraInterface::GetMainMemory(void)
{
	return pNativeIF->pMainMemory;
}
