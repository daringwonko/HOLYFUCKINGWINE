/* Fake wusa.exe - returns success without doing anything
 * This allows installers that depend on wusa.exe to bypass KB checks
 * 
 * Compile with:
 *   x86_64-w64-mingw32-gcc -o wusa.exe fake-wusa.c -mwindows
 * 
 * Place in wine's system32 folder to override
 */

#include <windows.h>

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, 
                   LPSTR lpCmdLine, int nCmdShow) {
    /* wusa.exe returns 0 for success, 3010 for "reboot required" */
    /* We return 0 (success) to make installers think KB is installed */
    return 0;
}
