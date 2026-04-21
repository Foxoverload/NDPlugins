/*
 * Firecast Lua 5.4 Proxy DLL v2.0
 * Adds: globals discovery, shared state, Win32 overlay window
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef long long lua_Integer;
typedef double lua_Number;
typedef int (*lua_CFunction)(void *L);

static HMODULE hOriginal = NULL;
static FILE *logFile = NULL;

/* Lua constants */
#define LUA_TNIL       0
#define LUA_TBOOLEAN   1
#define LUA_TLIGHTUDATA 2
#define LUA_TNUMBER    3
#define LUA_TSTRING    4
#define LUA_TTABLE     5
#define LUA_TFUNCTION  6
#define LUA_TUSERDATA  7
#define LUA_TTHREAD    8
#define LUA_REGISTRYINDEX (-1001000)
#define LUA_GLOBALSINDEX  (-1001000) /* In 5.4, globals via registry */

/* Function pointer types */
typedef void  (*fn_luaL_openlibs)(void*);
typedef int   (*fn_lua_getglobal)(void*, const char*);
typedef void  (*fn_lua_setglobal)(void*, const char*);
typedef void  (*fn_lua_setfield)(void*, int, const char*);
typedef int   (*fn_lua_getfield)(void*, int, const char*);
typedef void  (*fn_lua_createtable)(void*, int, int);
typedef void  (*fn_lua_pushcclosure)(void*, lua_CFunction, int);
typedef void  (*fn_lua_pushstring)(void*, const char*);
typedef void  (*fn_lua_pushinteger)(void*, lua_Integer);
typedef void  (*fn_lua_pushboolean)(void*, int);
typedef void  (*fn_lua_pushnil)(void*);
typedef void  (*fn_lua_pushvalue)(void*, int);
typedef const char* (*fn_lua_tolstring)(void*, int, size_t*);
typedef lua_Integer (*fn_lua_tointegerx)(void*, int, int*);
typedef int   (*fn_lua_toboolean)(void*, int);
typedef int   (*fn_lua_gettop)(void*);
typedef void  (*fn_lua_settop)(void*, int);
typedef int   (*fn_lua_type)(void*, int);
typedef const char* (*fn_lua_typename)(void*, int);
typedef void  (*fn_lua_pushlstring)(void*, const char*, size_t);
typedef void  (*fn_lua_pushnumber)(void*, lua_Number);
typedef int   (*fn_lua_next)(void*, int);
typedef int   (*fn_lua_rawgeti)(void*, int, lua_Integer);
typedef void  (*fn_lua_rawseti)(void*, int, lua_Integer);
typedef size_t(*fn_lua_rawlen)(void*, int);
typedef int   (*fn_lua_gettable)(void*, int);

/* Loaded function pointers */
static fn_luaL_openlibs     orig_luaL_openlibs = NULL;
static fn_lua_createtable   orig_lua_createtable = NULL;
static fn_lua_pushcclosure  orig_lua_pushcclosure = NULL;
static fn_lua_setfield      orig_lua_setfield = NULL;
static fn_lua_getfield      orig_lua_getfield = NULL;
static fn_lua_setglobal     orig_lua_setglobal = NULL;
static fn_lua_getglobal     orig_lua_getglobal = NULL;
static fn_lua_pushstring    orig_lua_pushstring = NULL;
static fn_lua_pushinteger   orig_lua_pushinteger = NULL;
static fn_lua_pushboolean   orig_lua_pushboolean = NULL;
static fn_lua_pushnil       orig_lua_pushnil = NULL;
static fn_lua_pushvalue     orig_lua_pushvalue = NULL;
static fn_lua_tolstring     orig_lua_tolstring = NULL;
static fn_lua_tointegerx    orig_lua_tointegerx = NULL;
static fn_lua_toboolean     orig_lua_toboolean = NULL;
static fn_lua_gettop        orig_lua_gettop = NULL;
static fn_lua_settop        orig_lua_settop = NULL;
static fn_lua_type          orig_lua_type = NULL;
static fn_lua_typename      orig_lua_typename = NULL;
static fn_lua_pushlstring   orig_lua_pushlstring = NULL;
static fn_lua_pushnumber    orig_lua_pushnumber = NULL;
static fn_lua_next          orig_lua_next = NULL;
static fn_lua_rawgeti       orig_lua_rawgeti = NULL;
static fn_lua_rawseti       orig_lua_rawseti = NULL;
static fn_lua_rawlen        orig_lua_rawlen = NULL;
static fn_lua_gettable      orig_lua_gettable = NULL;

/* pcallk - used for both openForm calls and the pcallk hook */
typedef int (*fn_lua_pcallk)(void*, int, int, int, long long, void*);
static fn_lua_pcallk orig_lua_pcallk = NULL;

static const char* proxy_tostring(void *L, int idx) {
    return orig_lua_tolstring(L, idx, NULL);
}

/* ============ LOG ============ */
static void proxy_log(const char *msg) {
    if (!logFile) {
        char path[MAX_PATH];
        GetModuleFileNameA(NULL, path, MAX_PATH);
        char *slash = strrchr(path, '\\');
        if (slash) *(slash+1) = 0;
        strcat(path, "fcext_log.txt");
        logFile = fopen(path, "a");
    }
    if (logFile) {
        SYSTEMTIME st;
        GetLocalTime(&st);
        fprintf(logFile, "[%02d:%02d:%02d] %s\n", st.wHour, st.wMinute, st.wSecond, msg);
        fflush(logFile);
    }
}

/* ============ SHARED STATE (cross Lua-state KV store) ============ */
#define SHARED_MAX 256
#define SHARED_VLEN 4096
static CRITICAL_SECTION sharedLock;
static int sharedCount = 0;
static char sharedKeys[SHARED_MAX][128];
static char sharedVals[SHARED_MAX][SHARED_VLEN];

static int fcext_sharedSet(void *L) {
    const char *key = proxy_tostring(L, 1);
    const char *val = proxy_tostring(L, 2);
    if (!key || !val) return 0;
    EnterCriticalSection(&sharedLock);
    int found = -1;
    for (int i = 0; i < sharedCount; i++) {
        if (strcmp(sharedKeys[i], key) == 0) { found = i; break; }
    }
    if (found >= 0) {
        strncpy(sharedVals[found], val, SHARED_VLEN-1);
    } else if (sharedCount < SHARED_MAX) {
        strncpy(sharedKeys[sharedCount], key, 127);
        strncpy(sharedVals[sharedCount], val, SHARED_VLEN-1);
        sharedCount++;
    }
    LeaveCriticalSection(&sharedLock);
    return 0;
}

static int fcext_sharedGet(void *L) {
    const char *key = proxy_tostring(L, 1);
    if (!key) { orig_lua_pushnil(L); return 1; }
    EnterCriticalSection(&sharedLock);
    const char *result = NULL;
    for (int i = 0; i < sharedCount; i++) {
        if (strcmp(sharedKeys[i], key) == 0) { result = sharedVals[i]; break; }
    }
    LeaveCriticalSection(&sharedLock);
    if (result) orig_lua_pushstring(L, result);
    else orig_lua_pushnil(L);
    return 1;
}

/* ============ DISCOVERY: List globals ============ */
/* fcext.globals() -> writes all global names+types to fcext_globals.txt */
static int fcext_globals(void *L) {
    char path[MAX_PATH];
    GetModuleFileNameA(NULL, path, MAX_PATH);
    char *slash = strrchr(path, '\\');
    if (slash) *(slash+1) = 0;
    strcat(path, "fcext_globals.txt");
    FILE *f = fopen(path, "w");
    if (!f) { orig_lua_pushboolean(L, 0); return 1; }

    /* In Lua 5.4: globals are in registry[LUA_RIDX_GLOBALS] = registry index 2 */
    orig_lua_rawgeti(L, LUA_REGISTRYINDEX, 2); /* push _G */
    orig_lua_pushnil(L); /* first key */
    int count = 0;
    while (orig_lua_next(L, -2) != 0) {
        const char *name = proxy_tostring(L, -2);
        int tp = orig_lua_type(L, -1);
        const char *tname = orig_lua_typename(L, tp);
        if (name && tname) {
            fprintf(f, "%-30s %s", name, tname);
            /* If it's a table, list its keys too */
            if (tp == LUA_TTABLE) {
                fprintf(f, " {");
                orig_lua_pushnil(L);
                int subcount = 0;
                while (orig_lua_next(L, -2) != 0 && subcount < 20) {
                    const char *subname = proxy_tostring(L, -2);
                    if (subname) {
                        if (subcount > 0) fprintf(f, ", ");
                        int stp = orig_lua_type(L, -1);
                        fprintf(f, "%s:%s", subname, orig_lua_typename(L, stp));
                    }
                    orig_lua_settop(L, orig_lua_gettop(L) - 1);
                    subcount++;
                }
                fprintf(f, "}");
            }
            fprintf(f, "\n");
            count++;
        }
        orig_lua_settop(L, orig_lua_gettop(L) - 1); /* pop value */
    }
    orig_lua_settop(L, orig_lua_gettop(L) - 1); /* pop _G */
    fclose(f);

    char msg[128];
    snprintf(msg, sizeof(msg), "Dumped %d globals to fcext_globals.txt", count);
    proxy_log(msg);

    /* Deep dump Firecast table */
    char path2[MAX_PATH];
    GetModuleFileNameA(NULL, path2, MAX_PATH);
    slash = strrchr(path2, '\\');
    if (slash) *(slash+1) = 0;
    strcat(path2, "fcext_firecast_api.txt");
    FILE *f2 = fopen(path2, "w");
    if (f2) {
        /* Dump Firecast.* */
        orig_lua_getglobal(L, "Firecast");
        if (orig_lua_type(L, -1) == LUA_TTABLE) {
            fprintf(f2, "=== Firecast ===\n");
            orig_lua_pushnil(L);
            while (orig_lua_next(L, -2) != 0) {
                const char *k = proxy_tostring(L, -2);
                int t = orig_lua_type(L, -1);
                if (k) {
                    fprintf(f2, "  Firecast.%-25s %s", k, orig_lua_typename(L, t));
                    if (t == LUA_TSTRING) fprintf(f2, " = \"%s\"", proxy_tostring(L, -1));
                    if (t == LUA_TNUMBER) fprintf(f2, " = %g", (double)orig_lua_tointegerx(L, -1, NULL));
                    if (t == LUA_TBOOLEAN) fprintf(f2, " = %s", orig_lua_toboolean(L, -1) ? "true" : "false");
                    if (t == LUA_TTABLE) {
                        fprintf(f2, " {");
                        orig_lua_pushnil(L);
                        int sc = 0;
                        while (orig_lua_next(L, -2) != 0 && sc < 30) {
                            const char *sk = proxy_tostring(L, -2);
                            int st = orig_lua_type(L, -1);
                            if (sk) {
                                if (sc > 0) fprintf(f2, ", ");
                                fprintf(f2, "%s:%s", sk, orig_lua_typename(L, st));
                                if (st == LUA_TSTRING) fprintf(f2, "=\"%s\"", proxy_tostring(L, -1));
                            }
                            orig_lua_settop(L, orig_lua_gettop(L) - 1);
                            sc++;
                        }
                        fprintf(f2, "}");
                    }
                    fprintf(f2, "\n");
                }
                orig_lua_settop(L, orig_lua_gettop(L) - 1);
            }
        }
        orig_lua_settop(L, orig_lua_gettop(L) - 1);

        /* Dump frmDownloadedPlugin */
        fprintf(f2, "\n=== frmDownloadedPlugin ===\n");
        orig_lua_getglobal(L, "frmDownloadedPlugin");
        if (orig_lua_type(L, -1) == LUA_TTABLE) {
            orig_lua_pushnil(L);
            while (orig_lua_next(L, -2) != 0) {
                const char *k = proxy_tostring(L, -2);
                int t = orig_lua_type(L, -1);
                if (k) {
                    fprintf(f2, "  %-30s %s", k, orig_lua_typename(L, t));
                    if (t == LUA_TSTRING) fprintf(f2, " = \"%s\"", proxy_tostring(L, -1));
                    if (t == LUA_TBOOLEAN) fprintf(f2, " = %s", orig_lua_toboolean(L, -1) ? "true" : "false");
                    fprintf(f2, "\n");
                }
                orig_lua_settop(L, orig_lua_gettop(L) - 1);
            }
        }
        orig_lua_settop(L, orig_lua_gettop(L) - 1);

        /* Deep dump each form in Firecast.forms */
        fprintf(f2, "\n=== Firecast.forms (each entry) ===\n");
        orig_lua_getglobal(L, "Firecast");
        if (orig_lua_type(L, -1) == LUA_TTABLE) {
            orig_lua_getfield(L, -1, "forms");
            if (orig_lua_type(L, -1) == LUA_TTABLE) {
                orig_lua_pushnil(L);
                while (orig_lua_next(L, -2) != 0) {
                    const char *formName = proxy_tostring(L, -2);
                    if (formName) {
                        fprintf(f2, "\n  [%s]\n", formName);
                        if (orig_lua_type(L, -1) == LUA_TTABLE) {
                            orig_lua_pushnil(L);
                            while (orig_lua_next(L, -2) != 0) {
                                const char *fk = proxy_tostring(L, -2);
                                int ft = orig_lua_type(L, -1);
                                if (fk) {
                                    fprintf(f2, "    %-25s %s", fk, orig_lua_typename(L, ft));
                                    if (ft == LUA_TSTRING) fprintf(f2, " = \"%s\"", proxy_tostring(L, -1));
                                    if (ft == LUA_TBOOLEAN) fprintf(f2, " = %s", orig_lua_toboolean(L, -1) ? "true" : "false");
                                    if (ft == LUA_TNUMBER) fprintf(f2, " = %g", (double)orig_lua_tointegerx(L, -1, NULL));
                                    fprintf(f2, "\n");
                                }
                                orig_lua_settop(L, orig_lua_gettop(L) - 1);
                            }
                        }
                    }
                    orig_lua_settop(L, orig_lua_gettop(L) - 1);
                }
            }
            orig_lua_settop(L, orig_lua_gettop(L) - 1); /* pop forms */
        }
        orig_lua_settop(L, orig_lua_gettop(L) - 1); /* pop Firecast */

        /* setInterval is the timer function */
        fprintf(f2, "\n=== setInterval ===\n");
        orig_lua_getglobal(L, "setInterval");
        fprintf(f2, "  type: %s\n", orig_lua_typename(L, orig_lua_type(L, -1)));
        orig_lua_settop(L, orig_lua_gettop(L) - 1);

        fclose(f2);
        proxy_log("Deep dump written to fcext_firecast_api.txt");
    }

    orig_lua_pushstring(L, path);
    return 1;
}

/* ============ OVERLAY WINDOW ============ */
#define OVERLAY_MAX_LINES 32
#define OVERLAY_LINE_LEN  256
static HWND g_overlayHwnd = NULL;
static char g_overlayTitle[128] = "FCEXT Overlay";
static char g_overlayLines[OVERLAY_MAX_LINES][OVERLAY_LINE_LEN];
static COLORREF g_overlayColors[OVERLAY_MAX_LINES];
static int g_overlayLineCount = 0;
static CRITICAL_SECTION overlayLock;
static HFONT g_overlayFont = NULL;

static LRESULT CALLBACK OverlayWndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        RECT rc;
        GetClientRect(hwnd, &rc);
        /* Dark background */
        HBRUSH bg = CreateSolidBrush(RGB(15, 17, 26));
        FillRect(hdc, &rc, bg);
        DeleteObject(bg);
        /* Title bar area */
        RECT titleRc = {0, 0, rc.right, 28};
        HBRUSH titleBg = CreateSolidBrush(RGB(13, 59, 102));
        FillRect(hdc, &titleRc, titleBg);
        DeleteObject(titleBg);
        SetBkMode(hdc, TRANSPARENT);
        if (g_overlayFont) SelectObject(hdc, g_overlayFont);
        SetTextColor(hdc, RGB(79, 195, 247));
        RECT trc = {8, 4, rc.right-8, 26};
        DrawTextA(hdc, g_overlayTitle, -1, &trc, DT_LEFT|DT_VCENTER|DT_SINGLELINE);
        /* Content lines */
        EnterCriticalSection(&overlayLock);
        int y = 32;
        for (int i = 0; i < g_overlayLineCount && i < OVERLAY_MAX_LINES; i++) {
            SetTextColor(hdc, g_overlayColors[i]);
            RECT lr = {10, y, rc.right-10, y+18};
            DrawTextA(hdc, g_overlayLines[i], -1, &lr, DT_LEFT|DT_VCENTER|DT_SINGLELINE);
            y += 20;
        }
        LeaveCriticalSection(&overlayLock);
        EndPaint(hwnd, &ps);
        return 0;
    }
    case WM_NCHITTEST: {
        /* Allow dragging from anywhere */
        LRESULT hit = DefWindowProcA(hwnd, msg, wp, lp);
        if (hit == HTCLIENT) return HTCAPTION;
        return hit;
    }
    case WM_CLOSE:
        ShowWindow(hwnd, SW_HIDE);
        return 0;
    case WM_DESTROY:
        g_overlayHwnd = NULL;
        return 0;
    }
    return DefWindowProcA(hwnd, msg, wp, lp);
}

static DWORD WINAPI OverlayThread(LPVOID param) {
    int *dims = (int*)param;
    int w = dims[0], h = dims[1], x = dims[2], y = dims[3];
    free(param);

    WNDCLASSEXA wc = {0};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = OverlayWndProc;
    wc.hInstance = GetModuleHandleA(NULL);
    wc.lpszClassName = "FCEXTOverlay";
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    RegisterClassExA(&wc);

    g_overlayFont = CreateFontA(14, 0, 0, 0, FW_NORMAL, 0, 0, 0,
        DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, FF_SWISS, "Segoe UI");

    g_overlayHwnd = CreateWindowExA(
        WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
        "FCEXTOverlay", g_overlayTitle,
        WS_POPUP | WS_VISIBLE | WS_BORDER,
        x, y, w, h,
        NULL, NULL, GetModuleHandleA(NULL), NULL);

    MSG msg;
    while (GetMessageA(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageA(&msg);
    }
    return 0;
}

/* fcext.overlay(title, width, height [, x, y]) */
static int fcext_overlay(void *L) {
    const char *title = proxy_tostring(L, 1);
    int w = (int)orig_lua_tointegerx(L, 2, NULL);
    int h = (int)orig_lua_tointegerx(L, 3, NULL);
    int x = orig_lua_gettop(L) >= 4 ? (int)orig_lua_tointegerx(L, 4, NULL) : 100;
    int y = orig_lua_gettop(L) >= 5 ? (int)orig_lua_tointegerx(L, 5, NULL) : 100;
    if (!title) title = "FCEXT Overlay";
    if (w < 100) w = 300;
    if (h < 50) h = 400;
    strncpy(g_overlayTitle, title, sizeof(g_overlayTitle)-1);

    if (g_overlayHwnd) {
        /* Already exists - just show and update title */
        SetWindowTextA(g_overlayHwnd, title);
        ShowWindow(g_overlayHwnd, SW_SHOW);
        SetWindowPos(g_overlayHwnd, HWND_TOPMOST, x, y, w, h, SWP_SHOWWINDOW);
        InvalidateRect(g_overlayHwnd, NULL, TRUE);
    } else {
        int *dims = (int*)malloc(4 * sizeof(int));
        dims[0] = w; dims[1] = h; dims[2] = x; dims[3] = y;
        CreateThread(NULL, 0, OverlayThread, dims, 0, NULL);
        Sleep(200); /* Wait for window creation */
    }
    orig_lua_pushboolean(L, g_overlayHwnd != NULL);
    return 1;
}

/* fcext.overlaySetLine(lineIndex, text [, colorHex]) */
static int fcext_overlaySetLine(void *L) {
    int idx = (int)orig_lua_tointegerx(L, 1, NULL) - 1; /* 1-indexed from Lua */
    const char *text = proxy_tostring(L, 2);
    const char *color = orig_lua_gettop(L) >= 3 ? proxy_tostring(L, 3) : NULL;
    if (idx < 0 || idx >= OVERLAY_MAX_LINES || !text) return 0;
    EnterCriticalSection(&overlayLock);
    strncpy(g_overlayLines[idx], text, OVERLAY_LINE_LEN-1);
    /* Parse hex color like "#RRGGBB" */
    if (color && color[0] == '#' && strlen(color) >= 7) {
        int r, g, b;
        sscanf(color+1, "%02x%02x%02x", &r, &g, &b);
        g_overlayColors[idx] = RGB(r, g, b);
    } else {
        g_overlayColors[idx] = RGB(192, 192, 192);
    }
    if (idx >= g_overlayLineCount) g_overlayLineCount = idx + 1;
    LeaveCriticalSection(&overlayLock);
    if (g_overlayHwnd) InvalidateRect(g_overlayHwnd, NULL, TRUE);
    return 0;
}

/* fcext.overlayClear() */
static int fcext_overlayClear(void *L) {
    EnterCriticalSection(&overlayLock);
    g_overlayLineCount = 0;
    memset(g_overlayLines, 0, sizeof(g_overlayLines));
    LeaveCriticalSection(&overlayLock);
    if (g_overlayHwnd) InvalidateRect(g_overlayHwnd, NULL, TRUE);
    return 0;
}

/* fcext.overlayClose() */
static int fcext_overlayClose(void *L) {
    if (g_overlayHwnd) { DestroyWindow(g_overlayHwnd); g_overlayHwnd = NULL; }
    return 0;
}

/* ============ ORIGINAL v1.0 FUNCTIONS ============ */
static int fcext_log(void *L) {
    const char *msg = proxy_tostring(L, 1);
    if (msg) proxy_log(msg);
    return 0;
}

static int fcext_readFile(void *L) {
    const char *path = proxy_tostring(L, 1);
    if (!path) { orig_lua_pushnil(L); return 1; }
    FILE *f = fopen(path, "rb");
    if (!f) { orig_lua_pushnil(L); return 1; }
    fseek(f, 0, SEEK_END); long sz = ftell(f); fseek(f, 0, SEEK_SET);
    char *buf = (char*)malloc(sz);
    if (!buf) { fclose(f); orig_lua_pushnil(L); return 1; }
    fread(buf, 1, sz, f); fclose(f);
    orig_lua_pushlstring(L, buf, sz); free(buf);
    return 1;
}

static int fcext_writeFile(void *L) {
    const char *path = proxy_tostring(L, 1);
    size_t len = 0;
    const char *data = orig_lua_tolstring(L, 2, &len);
    if (!path || !data) { orig_lua_pushboolean(L, 0); return 1; }
    FILE *f = fopen(path, "wb");
    if (!f) { orig_lua_pushboolean(L, 0); return 1; }
    fwrite(data, 1, len, f); fclose(f);
    orig_lua_pushboolean(L, 1);
    return 1;
}

static int fcext_fileExists(void *L) {
    const char *path = proxy_tostring(L, 1);
    if (!path) { orig_lua_pushboolean(L, 0); return 1; }
    orig_lua_pushboolean(L, GetFileAttributesA(path) != INVALID_FILE_ATTRIBUTES);
    return 1;
}

static int fcext_listDir(void *L) {
    const char *path = proxy_tostring(L, 1);
    if (!path) { orig_lua_pushnil(L); return 1; }
    char search[MAX_PATH]; snprintf(search, MAX_PATH, "%s\\*", path);
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA(search, &fd);
    if (h == INVALID_HANDLE_VALUE) { orig_lua_pushnil(L); return 1; }
    orig_lua_createtable(L, 0, 0);
    int idx = 1;
    do {
        if (strcmp(fd.cFileName, ".") != 0 && strcmp(fd.cFileName, "..") != 0) {
            orig_lua_pushstring(L, fd.cFileName);
            orig_lua_rawseti(L, -2, idx++);
        }
    } while (FindNextFileA(h, &fd));
    FindClose(h);
    return 1;
}

static int fcext_getTime(void *L) {
    FILETIME ft; GetSystemTimeAsFileTime(&ft);
    ULARGE_INTEGER uli; uli.LowPart = ft.dwLowDateTime; uli.HighPart = ft.dwHighDateTime;
    orig_lua_pushinteger(L, (lua_Integer)((uli.QuadPart - 116444736000000000ULL) / 10000ULL));
    return 1;
}

static int fcext_sleep(void *L) {
    lua_Integer ms = orig_lua_tointegerx(L, 1, NULL);
    if (ms > 0 && ms < 10000) Sleep((DWORD)ms);
    return 0;
}

static int fcext_clipboardGet(void *L) {
    if (!OpenClipboard(NULL)) { orig_lua_pushnil(L); return 1; }
    HANDLE h = GetClipboardData(CF_TEXT);
    if (!h) { CloseClipboard(); orig_lua_pushnil(L); return 1; }
    const char *txt = (const char*)GlobalLock(h);
    if (txt) orig_lua_pushstring(L, txt); else orig_lua_pushnil(L);
    GlobalUnlock(h); CloseClipboard();
    return 1;
}

static int fcext_clipboardSet(void *L) {
    size_t len = 0;
    const char *txt = orig_lua_tolstring(L, 1, &len);
    if (!txt) { orig_lua_pushboolean(L, 0); return 1; }
    if (!OpenClipboard(NULL)) { orig_lua_pushboolean(L, 0); return 1; }
    EmptyClipboard();
    HGLOBAL hg = GlobalAlloc(GMEM_MOVEABLE, len + 1);
    if (hg) { char *p = (char*)GlobalLock(hg); memcpy(p, txt, len); p[len] = 0; GlobalUnlock(hg); SetClipboardData(CF_TEXT, hg); }
    CloseClipboard();
    orig_lua_pushboolean(L, 1);
    return 1;
}

static int fcext_exec(void *L) {
    const char *cmd = proxy_tostring(L, 1);
    if (!cmd) { orig_lua_pushboolean(L, 0); return 1; }
    STARTUPINFOA si = {0}; PROCESS_INFORMATION pi = {0}; si.cb = sizeof(si);
    char buf[1024]; strncpy(buf, cmd, sizeof(buf)-1);
    BOOL ok = CreateProcessA(NULL, buf, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi);
    if (ok) { CloseHandle(pi.hProcess); CloseHandle(pi.hThread); }
    orig_lua_pushboolean(L, ok);
    return 1;
}

static int fcext_version(void *L) {
    orig_lua_pushstring(L, "fcext 2.1.0 - Firecast Script Extender");
    return 1;
}

/* fcext.openForm(name) -> tries Firecast.forms[name]:newEditor() */
static int fcext_openForm(void *L) {
    const char *name = proxy_tostring(L, 1);
    if (!name) { orig_lua_pushboolean(L, 0); return 1; }
    char msg[256];
    snprintf(msg, sizeof(msg), "openForm: trying '%s'", name);
    proxy_log(msg);
    orig_lua_getglobal(L, "Firecast");
    if (orig_lua_type(L, -1) != LUA_TTABLE) { orig_lua_settop(L, orig_lua_gettop(L)-1); orig_lua_pushboolean(L, 0); return 1; }
    orig_lua_getfield(L, -1, "forms");
    if (orig_lua_type(L, -1) != LUA_TTABLE) { orig_lua_settop(L, orig_lua_gettop(L)-2); orig_lua_pushboolean(L, 0); return 1; }
    orig_lua_getfield(L, -1, name);
    if (orig_lua_type(L, -1) != LUA_TTABLE) { orig_lua_settop(L, orig_lua_gettop(L)-3); orig_lua_pushboolean(L, 0); return 1; }
    /* Try newEditor(formObj) */
    orig_lua_getfield(L, -1, "newEditor");
    if (orig_lua_type(L, -1) == LUA_TFUNCTION) {
        orig_lua_pushvalue(L, -2);
        int r = orig_lua_pcallk(L, 1, 1, 0, 0, NULL);
        if (r == 0) { proxy_log("openForm: newEditor success"); orig_lua_pushboolean(L, 1); return 1; }
        const char *err = proxy_tostring(L, -1);
        snprintf(msg, sizeof(msg), "newEditor error: %s", err ? err : "?");
        proxy_log(msg);
    }
    orig_lua_settop(L, 1);
    orig_lua_pushboolean(L, 0);
    return 1;
}

/* ============ REGISTER MODULE ============ */
static void register_fcext(void *L) {
    orig_lua_createtable(L, 0, 20);
    struct { const char *name; lua_CFunction fn; } funcs[] = {
        /* v1 - filesystem */
        {"log",            fcext_log},
        {"readFile",       fcext_readFile},
        {"writeFile",      fcext_writeFile},
        {"fileExists",     fcext_fileExists},
        {"listDir",        fcext_listDir},
        /* v1 - system */
        {"getTime",        fcext_getTime},
        {"sleep",          fcext_sleep},
        {"exec",           fcext_exec},
        {"version",        fcext_version},
        /* v1 - clipboard */
        {"clipboardGet",   fcext_clipboardGet},
        {"clipboardSet",   fcext_clipboardSet},
        /* v2 - discovery */
        {"globals",        fcext_globals},
        /* v2 - shared state */
        {"sharedSet",      fcext_sharedSet},
        {"sharedGet",      fcext_sharedGet},
        /* v2 - overlay window */
        {"overlay",        fcext_overlay},
        {"overlaySetLine", fcext_overlaySetLine},
        {"overlayClear",   fcext_overlayClear},
        {"overlayClose",   fcext_overlayClose},
        /* v2.1 - Firecast forms */
        {"openForm",       fcext_openForm},
        {NULL, NULL}
    };
    for (int i = 0; funcs[i].name; i++) {
        orig_lua_pushcclosure(L, funcs[i].fn, 0);
        orig_lua_setfield(L, -2, funcs[i].name);
    }
    /* Store in global */
    orig_lua_pushvalue(L, -1); /* dup table */
    orig_lua_setglobal(L, "fcext");
    /* Store in registry */
    orig_lua_pushvalue(L, -1); /* dup table */
    orig_lua_setfield(L, LUA_REGISTRYINDEX, "__fcext_module");
    /* Store in package.loaded["fcext"] so require("fcext") works in sandbox */
    orig_lua_getglobal(L, "package");
    if (orig_lua_type(L, -1) == LUA_TTABLE) {
        orig_lua_getfield(L, -1, "loaded");
        if (orig_lua_type(L, -1) == LUA_TTABLE) {
            orig_lua_pushvalue(L, -3); /* push fcext table */
            orig_lua_setfield(L, -2, "fcext");
            proxy_log("fcext stored in package.loaded");
        }
        orig_lua_settop(L, orig_lua_gettop(L) - 1); /* pop loaded */
    }
    orig_lua_settop(L, orig_lua_gettop(L) - 1); /* pop package */
    /* pop the remaining fcext table */
    orig_lua_settop(L, orig_lua_gettop(L) - 1);
    proxy_log("fcext v2.1 registered (global + registry + package.loaded)");
}

/* ============ HOOKED luaL_openlibs ============ */
__declspec(dllexport) void luaL_openlibs(void *L) {
    orig_luaL_openlibs(L);
    register_fcext(L);
}

/* ============ HOOKED lua_getglobal - intercept 'fcext' ============ */
__declspec(dllexport) int lua_getglobal(void *L, const char *name) {
    int result = orig_lua_getglobal(L, name);
    /* If the result is nil and they asked for 'fcext', serve from registry */
    if (name && strcmp(name, "fcext") == 0 && orig_lua_type(L, -1) == LUA_TNIL) {
        orig_lua_settop(L, orig_lua_gettop(L) - 1); /* pop nil */
        orig_lua_getfield(L, LUA_REGISTRYINDEX, "__fcext_module");
        return orig_lua_type(L, -1);
    }
    return result;
}

/* ============ HOOKED lua_pcallk for auto-discovery ============ */
static volatile int g_pcallCount = 0;
static volatile int g_dumpDone = 0;
static void *g_firstL = NULL;

__declspec(dllexport) int lua_pcallk(void *L, int nargs, int nresults, int errfunc, long long ctx, void *k) {
    if (!g_dumpDone) {
        g_pcallCount++;
        if (!g_firstL) g_firstL = L;
        /* After 100 pcalls, Firecast should have registered its APIs */
        if (g_pcallCount == 100 && g_firstL) {
            g_dumpDone = 1;
            fcext_globals(g_firstL);
        }
    }
    return orig_lua_pcallk(L, nargs, nresults, errfunc, ctx, k);
}

/* ============ DllMain ============ */
BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpReserved) {
    if (fdwReason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hinstDLL);
        InitializeCriticalSection(&sharedLock);
        InitializeCriticalSection(&overlayLock);
        char path[MAX_PATH];
        GetModuleFileNameA(hinstDLL, path, MAX_PATH);
        char *slash = strrchr(path, '\\');
        if (slash) *(slash+1) = 0;
        strcat(path, "lua54x64_original.dll");
        hOriginal = LoadLibraryA(path);
        if (!hOriginal) { MessageBoxA(NULL, "Failed to load lua54x64_original.dll", "FCEXT", MB_OK); return FALSE; }

        #define LOAD(name) orig_##name = (fn_##name)GetProcAddress(hOriginal, #name)
        LOAD(luaL_openlibs); LOAD(lua_createtable); LOAD(lua_pushcclosure);
        LOAD(lua_setfield); LOAD(lua_getfield); LOAD(lua_setglobal); LOAD(lua_getglobal);
        LOAD(lua_pushstring); LOAD(lua_pushinteger); LOAD(lua_pushboolean);
        LOAD(lua_pushnil); LOAD(lua_pushvalue); LOAD(lua_tolstring); LOAD(lua_tointegerx);
        LOAD(lua_toboolean); LOAD(lua_gettop); LOAD(lua_settop); LOAD(lua_type);
        LOAD(lua_typename); LOAD(lua_pushlstring); LOAD(lua_pushnumber);
        LOAD(lua_next); LOAD(lua_rawgeti); LOAD(lua_rawseti); LOAD(lua_rawlen);
        LOAD(lua_gettable); LOAD(lua_pcallk);
        #undef LOAD
        proxy_log("=== FCEXT v2.0 Proxy DLL loaded ===");
    } else if (fdwReason == DLL_PROCESS_DETACH) {
        if (g_overlayFont) DeleteObject(g_overlayFont);
        if (logFile) fclose(logFile);
        if (hOriginal) FreeLibrary(hOriginal);
        DeleteCriticalSection(&sharedLock);
        DeleteCriticalSection(&overlayLock);
    }
    return TRUE;
}
