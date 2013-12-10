/**
 * XEBRA-RR.DLL - additional code
 */

#include "xebra-rr.h"

/// Host functions/data interface
XebraInterface XebraIF;

/// <summary>DLL entry point.</summary>
/// <param name='hModule'>A handle to the DLL module.</param>
/// <param name='ul_reason_for_call'>The reason code that indicates why the DLL entry-point function is being called. </param>
/// <param name='lpReserved'>If fdwReason is DLL_PROCESS_ATTACH, lpvReserved is NULL for dynamic loads and non-NULL for static loads.
/// If fdwReason is DLL_PROCESS_DETACH, lpvReserved is NULL if FreeLibrary has been called or the DLL load failed and non-NULL if the process is terminating.</param>
/// <returns>When the system calls the DllMain function with the DLL_PROCESS_ATTACH value, the function returns TRUE if it succeeds or FALSE if initialization fails.</returns>
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
	switch (ul_reason_for_call)
	{
	case DLL_PROCESS_ATTACH:
		DisableThreadLibraryCalls(hModule);
		break;

	case DLL_PROCESS_DETACH:
		break;
	}
	return TRUE;
}

/// <summary>Set native interface by host.</summary>
/// <param name='pInterface'>Native interface pointer of host.</param>
/// <returns>Return FALSE for version mismatch.</returns>
XEBRARR_API BOOL XRSetInterface(XEBRA_IF* pInterface)
{
	return XebraIF.SetInterface(pInterface) ? TRUE : FALSE;
}

/// <summary>Main dialog procedure.
/// <para>XEBRA passes messages here without handling them beforehand.</para>
/// </summary>
/// <param name='hwndDlg'>A handle to the dialog box.</param>
/// <param name='uMsg'>The message.</param>
/// <param name='wParam'>Additional message-specific information.</param>
/// <param name='lParam'>Additional message-specific information.</param>
/// <returns>The dialog box procedure should return TRUE if it processed the message, and FALSE if it did not.</returns>
XEBRARR_API INT_PTR XRMainDlgProc(HWND hwndDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	return FALSE;
}
