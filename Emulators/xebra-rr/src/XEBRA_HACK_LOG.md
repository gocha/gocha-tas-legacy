XEBRA HACK LOGS
================

Work in progress.


EXE ChangeLog
----------------

### Creating Base Image ###

1. Prepare a vanilla executable image (unpacked)
2. Create ".text-r" section and set attribute as like as ".text"
3. Create ".data-r" section and set attribute as like as ".data"
4. Create ".rdata-r" section and set attribute as like as ".rdata"

If resource editor expands ".rsrc" section, you may need to adjust the section after ".rsrc". **Make a backup before editing resources!**

Most of new things must go to "XEBRA-RR.DLL".
If you need XEBRA's native functions or variables,
you have to get their pointers in some way.

### Code/Data Maps ###

#### .text-r (0x8000 bytes) ####

- 000000: Call LoadXebraRR, abort if it failed. (called from just after CreateDialogParamA call for MAIN dialog)
- 000020: [LoadXebraRR] Load XEBRA.DLL and their functions, and call XRSetInterface at last.

#### .data-r (0x4000 bytes) ####

- 000000: XEBRA Native Interface (0x800 bytes)
- 000800: XEBRA-RR.DLL library handle, and function tables (0x800 bytes)
- 001000: Not used

#### .rdata-r (0x4000 bytes) ####

This section should have only library/function names of XEBRA-RR.DLL, and several error messages.

- 000000: Number of functions (XEBRA-RR.DLL)
- 000004: Function name pointers (XEBRA-RR.DLL)
- 000800: Function name strings (XEBRA-RR.DLL)
- 002000: Messages etc.

Analyzation Logs
----------------

Uses IDA Free 5.0 for main analyzation.
(Do not use later version that updates IDB file version.)

- unzip: xebra130815.zip
- UPX: Unpack XEBRA/ARBEX
- Note: Remember, XEBRA has some identical routines here and there, in other words, it uses *inline functions* a lot (also sometimes it is large). Find the most reusable one and extract it as a non-inline function (or make a copy of it). That is the only way.
- VS2010: Write down some menu ids. (Although I will need only a few of these, anyway I have written all the following ids)
   - File/Open/CD-ROM via SPTI... = 256 (0x0100)
   - File/Open/CD-ROM Image... = 257 (0x0101)
   - File/Open/Memory Card 1 Image... = 260 (0x0104)
   - File/Open/Memory Card 2 Image... = 261 (0x0105)
   - File/Open/Simulation Image... = 262 (0x0106)
   - File/Open/Running Image... = 263 (0x0107)
   - File/Save/Memory Card 1 Image... = 264 (0x0108)
   - File/Save/Memory Card 2 Image... = 265 (0x0109)
   - File/Save/Simulation Image... = 266 (0x010A)
   - File/Save/Running Image... = 267 (0x010B)
   - File/Export/Main Memory Image... = 268 (0x010C)
   - File/History/Read Pad... = 269 (0x010D)
   - File/History/Write Pad... = 270 (0x010E)
   - File/History/Load Pad... = 271 (0x010F)
   - File/History/Save Pad... = 272 (0x0110)
   - File/Exit = 273 (0x0111)
   - Run/Power(Run) = 274 (0x0112)
   - Run/Pause = 278 (0x0116)
   - Run/Reset = 279 (0x0117)
   - Run/Sync = 280 (0x0118)
   - Run/Open Shell = 281 (0x0119)
   - Run/Close Shell = 282 (0x011A)
   - Run/Start Card = 283 (0x011B)
   - Run/Stop Card = 284 (0x011C)
   - Run/Outer Card = 285 (0x011D)
   - Run/Misc/Blank = 286 (0x011E)
   - Run/Misc/Elapse = 287 (0x011F)
   - Run/Misc/Flush = 288 (0x0120)
   - Run/Misc/Ignore = 289 (0x0121)
   - Run/Misc/Slow = 290 (0x0122)
   - View/Video Output... = 360 (0x0168)
   - View/Sound Output... = 361 (0x0169)
   - View/CD-ROM Drive... = 362 (0x016A)
   - View/Controller... = 363 (0x016B)
   - View/Debug... = 364 (0x016C)
   - Help/About... = 389 (0x0185, the last main menu item?)
- IDA: Loading file XEBRA/ARBEX into database...
- IDA: Detected file format: Portable executable for 80386 (PE)
- IDA: The initial autoanalysis has been finished.
- IDA: Jump each xrefs to GetProcAddress and give function pointer names (which store eax, the return value of GetProcAddress).
- IDA: Option strings may be initialized wrong:
~~~~
byte_536AB6     db 2Dh
aRun1           db 'RUN1',0
~~~~
they must be fixed (hit A key at the beginning of string):
~~~~
aRun1           db '-RUN1',0
~~~~
- IDA: Some strings for CUE file may be wrong as well (I have no concern with them though).
- IDA: Jump xref to "MAIN" and find CreateDialogParamA call. Give the 4th parameter a name (eg. MainDlgProc).
- IDA: Jump to MainDlgProc. Give names as usual. (arg_0 = hwndDlg, arg_4 = uMsg, arg_8 = wParam, arg_C = lParam)
- IDA: - Main dialog seems to have only handlers of WM_INITDIALOG, WM_COMMAND, WM_DROPFILES.
- WM_COMMAND generic stuff
   - IDA: Find "case WM_COMMAND (0x0111)" out (cmp xxx, 111h). It was almost the nearest to the top of function. If you worry whether you will get lost, write down the address.
   - IDA: Find "case ID_WRITE_PAD (0x010E)" out. You may find it by searching xrefs to GetSaveFileNameA in MainDlgProc.
   - IDA: There must be CreateFileA just after GetSaveFileNameA. Give the file handle a name (eg. hPadHistoryFile).
   - IDA: Find "case ID_RUN1 (0x0112)" out in MainDlgProc. It sets 1 to a variable. Give it a name (eg. runMode, note that it is not a boolean variable!).
   - IDA: Find "case ID_SYNC (0x0118)" out in MainDlgProc. It xors 1 to a variable. Give it a name (eg. syncRequired).
   - IDA: Give similar variable names (eg. miscBlank, miscElapse, miscIgnore, miscSlowLevel).
- IDA: Find "WriteFile(hPadHistoryFile, lpBuffer, 0x10, lpNumberOfBytesWritten, NULL)" out (hint: use jump xref to!). It must be in a small subroutine (XEBRA:43BD70, ARBEX:4FFD50), which is something like "WritePadChunk(?, ?, ?)". Give the function a name.
- IDA: Find "ReadPadChunk(?, ?)" out as well.
- IDA: Back to CreateFileA of ID_WRITE_PAD. There is a call like "sub_4328D0(0xB1)" just after SetFilePointer call. The function returns a constant pointer variable address chosen by a parameter value, and it returns pad chunk read/write function pointer for parameter 0xB1. Go into the function and give the pointer variable a name (eg. fnPadChunkIO).
- IDA: Jump to the end of WritePadChunk/ReadPadChunk and switch to text view from graph view. There is an orphan subroutine which is identical to what the menu command do after GetSaveFileName/GetOpenFileName. So "create function" on it and give it a name (eg. CreatePadHistoryFile/OpenPadHistoryFile).
- IDA: There is a timeGetTime call (and a Sleep call is near from it) in the startup function (sort of, you can jump to the function by xref to "BU00" or something like that). This seems to be a part of "wait" routine of the main loop.


Misc.
----------------

Try to minimize the modification in the original ".text" section, but do not create a long __fastcall function in ".text-r" section.

You may want to use long CALL/JMP (e8/e9) for jump into the new code section. I decided to use JMP, since disassemblers may recognize the short code at destination address as "a function" if CALL is used.

Before:
~~~~
.text
mov     eax, [ebp+arg_0]
mov     esi, [ebp+arg_4]
     :
~~~~
After:
~~~~
.text
jmp     L_HACKSTART
nop
L_HACKEND:
     :

.text-r
L_HACKSTART:
; call another function, do not write own code here,
; unless if the injected code is *very short*
push    eax
push    esi
call    SomeFunction@XEBRA-RR.DLL
add     esp, 8
; restore everything and back
mov     eax, [ebp+arg_0]
mov     esi, [ebp+arg_4]
jmp     L_HACKEND
~~~~

Also, do not forget alignment things.

### TODO ###

- Add frame advance flag (need to find a frame boundary to process it)
- Add fast-forward on/off flag
- New flexible (and commonly used) timing routine
- Add WM_ENTERMENULOOP routine and add check to a toggle-type menu item.
