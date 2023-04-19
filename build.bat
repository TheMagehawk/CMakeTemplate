@echo off

setlocal enabledelayedexpansion
call:setESC

:: Color Codes
set BLACK=%ESC%[30m
set RED=%ESC%[31m
set GREEN=%ESC%[32m
set YELLOW=%ESC%[33m
set BLUE=%ESC%[34m
set MAGENTA=%ESC%[35m
set CYAN=%ESC%[36m
set WHITE=%ESC%[37m

set LBLACK=%ESC%[30;1m
set LRED=%ESC%[31;1m
set LGREEN=%ESC%[32;1m
set LYELLOW=%ESC%[33;1m
set LBLUE=%ESC%[34;1m
set LMAGENTA=%ESC%[35;1m
set LCYAN=%ESC%[36;1m
set LWHITE=%ESC%[37;1m

set BGBLACK=%ESC%[40m
set BGRED=%ESC%[41m
set BGGREEN=%ESC%[42m
set BGYELLOW=%ESC%[43m
set BGBLUE=%ESC%[44m
set BGMAGENTA=%ESC%[45m
set BGLCYAN=%ESC%[46m
set BGWHITE=%ESC%[47m

set NC=%ESC%[0m
set BOLD=%ESC%[1m
set UNDERLINE=%ESC%[4m
set REVERSED=%ESC%[7m

set ROOT_DIR=%CD%
set BUILD_DIRECTORY_ROOT=out/build

set RELEASE_DIRECTORY=%BUILD_DIRECTORY_ROOT%/x64-release
set DEBUG_DIRECTORY=%BUILD_DIRECTORY_ROOT%/x64-debug
set BUILD_DIRECTORY=%RELEASE_DIRECTORY%
set BIN_DIRECTORY=%BUILD_DIRECTORY%/bin

set ANDROID_NDK_PATH=
set ANDROID_RELEASE_DIRECTORY=%BUILD_DIRECTORY_ROOT%/Android/x64-release
set ANDROID_DEBUG_DIRECTORY=%BUILD_DIRECTORY_ROOT%/Android/x64-debug
set ANDROID_BUILD_DIRECTORY=%ANDROID_RELEASE_DIRECTORY%
set ANDROID_BIN_DIRECTORY=%ANDROID_BUILD_DIRECTORY%/bin

set BIN_NAME=CMakeTemplate
set CMAKE_TARGET=%BIN_NAME%
set BIN_EXTENSION=.exe
set BUILD_TYPE=Release
set BUILD_ANDROID=False

set /a INDEX= 0
for %%a in (%*) do (
    if "%%a" == "--run-now" (
        call:run_executable
        goto:exit
    ) else if "%%a" == "--help" (
        call:help
        goto:exit
    ) else if "%%a" == "-h" (
        call:help
        goto:exit
    ) else if defined CHECKING_JOB (
        echo "JOBS CHECK"
        set CHECKING_JOB=
    ) else if defined CHECKING_ANDROID_NDK (
        set ANDROID_NDK_PATH=%%a
        set CHECKING_ANDROID_NDK=
    ) else if "%%a" == "--run" ( 
        set RUN_AFTER_BUILD=True
    ) else if "%%a" == "-r" ( 
        set RUN_AFTER_BUILD=True
    ) else if "%%a" == "--release" (
        set BUILD_TYPE=Release
        if !BUILD_ANDROID! == True (
            set ANDROID_BUILD_DIRECTORY=!ANDROID_RELEASE_DIRECTORY!
            set ANDROID_BIN_DIRECTORY=!ANDROID_BUILD_DIRECTORY!/bin
        ) else (
            set BUILD_DIRECTORY=!RELEASE_DIRECTORY!
            set BIN_DIRECTORY=!BUILD_DIRECTORY!/bin
        )
    ) else if "%%a" == "--debug" ( 
        set BIN_NAME=!BIN_NAME!d
        set BUILD_TYPE=Debug
        if !BUILD_ANDROID!== True (
            set ANDROID_BUILD_DIRECTORY=!ANDROID_DEBUG_DIRECTORY!
            set ANDROID_BIN_DIRECTORY=!ANDROID_BUILD_DIRECTORY!/bin
        ) else (
            set BUILD_DIRECTORY=!DEBUG_DIRECTORY!
            set BIN_DIRECTORY=!BUILD_DIRECTORY!/bin
        )
    ) else if "%%a" == "--android" ( 
        set BUILD_ANDROID=True
        if !BUILD_TYPE! == Release (
            set ANDROID_BUILD_DIRECTORY=!ANDROID_RELEASE_DIRECTORY!
            set ANDROID_BIN_DIRECTORY=!ANDROID_BUILD_DIRECTORY!/bin
        ) else (
            set ANDROID_BUILD_DIRECTORY=!ANDROID_DEBUG_DIRECTORY!
            set ANDROID_BIN_DIRECTORY=!ANDROID_BUILD_DIRECTORY!/bin
        )
        set CHECKING_ANDROID_NDK=True
    ) else if "%%a" == "--clean" (
        set CLEAN_RELEASE=True
        set CLEAN_DEBUG=True
        set CLEAN_ANDROID_RELEASE=True
        set CLEAN_ANDROID_DEBUG=True
    ) else if "%%a" == "-c" (
        set CLEAN_RELEASE=True
        set CLEAN_DEBUG=True
        set CLEAN_ANDROID_RELEASE=True
        set CLEAN_ANDROID_DEBUG=True
    ) else if "%%a" == "--clean-native" (
        set CLEAN_RELEASE=True
        set CLEAN_DEBUG=True
    ) else if "%%a" == "--clean-android" (
        set CLEAN_ANDROID_RELEASE=True
        set CLEAN_ANDROID_DEBUG=True
    ) else if "%%a" == "--clean-release" (
        set CLEAN_RELEASE=True
    ) else if "%%a" == "--clean-debug" (
        set CLEAN_DEBUG=True
    ) else if "%%a" == "--clean-android-release" (
        set CLEAN_ANDROID_RELEASE=True
    ) else if "%%a" == "--clean-android-debug" (
        set CLEAN_ANDROID_DEBUG=True
    ) else if "%%a" == "--skip-all" (
        set SKIP_CONFIGURE=True
        set SKIP_SUBMODULES=True
    ) else if "%%a" == "-s" (
        set SKIP_CONFIGURE=True
        set SKIP_SUBMODULES=True
    ) else if "%%a" == "--skip-configure" (
        set SKIP_CONFIGURE=True
    ) else if "%%a" == "--skip-submodules" (
        set SKIP_SUBMODULES=True
    ) else if "%%a" == "-j" (
        set CHECKING_JOB=True
    ) else (
        call:invalid
        exit /b 1
    )
    set /a INDEX=INDEX+1
)

if defined CLEAN_RELEASE (
    echo Cleaning Release Folder...
    RD /S "!ROOT_DIR!/!RELEASE_DIRECTORY!"
)
if defined CLEAN_DEBUG (
    echo Cleaning Debug Folder...
    RD /S "!ROOT_DIR!/!DEBUG_DIRECTORY!"
)

if defined CLEAN_ANDROID_RELEASE (
    echo Cleaning Android Release Folder...
    RD /S "!ROOT_DIR!/!ANDROID_RELEASE_DIRECTORY!"
)
if defined CLEAN_ANDROID_DEBUG (
    echo Cleaning Android Debug Folder...
    RD /S "!ROOT_DIR!/!ANDROID_DEBUG_DIRECTORY!"
)

if not defined SKIP_SUBMODULES (
    call:setup_submodules
)

if not defined SKIP_CONFIGURE (
    call:cmake_configure
)

call:build || goto:build_fail

if defined RUN_AFTER_BUILD (
    call:run_executable
)

goto:exit

:setup_submodules
echo Checking if submodules were initialized and updated properly...
git submodule update --init --recursive --depth=1
echo %GREEN%Submodules are set up properly!%NC%
goto:eof

:cmake_configure
call vcvars64.bat
if !BUILD_ANDROID! == False (
    echo %LCYAN%Generating CMake Configuration files in !BUILD_DIRECTORY!...%NC%
    cmake -E time cmake -S . -B !BUILD_DIRECTORY! -G Ninja -DHIDE_CONSOLE=FALSE -DCMAKE_BUILD_TYPE=!BUILD_TYPE! -DCMAKE_BUILD_ANDROID=!BUILD_ANDROID!
) else (
    echo %LCYAN%Generating CMake Configuration files in !ANDROID_BUILD_DIRECTORY!...%NC%
    cmake -E time cmake -S . -B !ANDROID_BUILD_DIRECTORY! -G Ninja -DHIDE_CONSOLE=FALSE -DCMAKE_BUILD_TYPE=!BUILD_TYPE! -DCMAKE_BUILD_ANDROID=!BUILD_ANDROID! -DCMAKE_ANDROID_NDK_PATH=!ANDROID_NDK_PATH!
)

echo %GREEN%Finished generating CMake Configuration files!%NC%
goto:eof

:build
if !BUILD_ANDROID! == False (
    cd !ROOT_DIR!/!BUILD_DIRECTORY!
) else (
    cd !ROOT_DIR!/!ANDROID_BUILD_DIRECTORY!
)
call vcvars64.bat
if "%~1" == "" (
    if defined NUMBER_OF_PROCESSORS (
        echo %LCYAN%Building target %NC%%LCYAN%%UNDERLINE%!CMAKE_TARGET!%NC% %LCYAN%with environment variable...%NC%
        echo %NUMBER_OF_PROCESSORS% cores/threads used ^(Max available^)
        cmake --build . --target !CMAKE_TARGET! -j %NUMBER_OF_PROCESSORS%
    ) else (
        echo %LCYAN%Building target %NC%%LCYAN%%UNDERLINE%!CMAKE_TARGET!%NC% %LCYAN%sequentially...%NC%
        cmake --build . --target !CMAKE_TARGET!
    )
) else (
    echo %LCYAN%Building target %NC%%LCYAN%%UNDERLINE%!CMAKE_TARGET!%NC% %LCYAN%with args...%NC%
    echo %~1 cores/threads used
    cmake --build . --target !CMAKE_TARGET! -j %~1
)

if !errorlevel! neq 0 exit /b 1

echo %GREEN%Finished building target%NC% %GREEN%%UNDERLINE%!CMAKE_TARGET! Exe: !BIN_NAME!!BIN_EXTENSION!%NC%%GREEN%!%NC%
if %BUILD_ANDROID% == False (
    echo %GREEN%Executable created in%NC% %GREEN%%UNDERLINE%!ROOT_DIR!/!BIN_DIRECTORY!%NC%%GREEN%!%NC%
) else (
    echo %GREEN%Executable created in%NC% %GREEN%%UNDERLINE%!ROOT_DIR!/!ANDROID_BIN_DIRECTORY!%NC%%GREEN%!%NC%
)
goto:eof

:run_executable
cd !ROOT_DIR!/!BIN_DIRECTORY!
echo Running Executable in %CD%...
start !BIN_NAME!!BIN_EXTENSION!
goto:eof

:help
echo Usage: %~n0%~x0 [-scrh] [--debug / --release] [--android [NDK_PATH]] [-j [JOBS]]
echo;
echo Options:
echo     -h, --help                 Show this message
echo     -r, --run                  Run executable after compilation
echo     --run-now                  Run the executable inside the bin directory
echo     --release                  Build in Release mode (default)
echo     --debug                    Build in Debug mode
echo     --android [NDK_PATH]       Cross compile for Android
echo     -j [jobs]                  Set maximum number of concurrent processes for build
echo     -s --skip-all              Just run the cmake build command (Skip submodules and cmake configure command)
echo     --skip-submodules          Skip the submodules command
echo     --skip-configure           Skip the cmake configure command
echo     -c --clean                 Clean the output directory (including debug and release)
echo     --clean-native             Clean the native build directories
echo     --clean-release            Clean the release directory
echo     --clean-debug              Clean the debug directory
echo     --clean-android            Clean the Android build directories
echo     --clean-android-release    Clean the Android release directory
echo     --clean-android-debug      Clean the Android debug directory
echo;
goto:eof

:checkNumber
SET "var="&for /f "delims=0123456789" %%i in ("%~1") do set var=%%i
if defined var (
    exit /b 0
) else (
    exit /b 1
)

:setESC
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set ESC=%%b
  exit /b 0
)

:exit
echo %MAGENTA%Terminated build script^^!%NC%
set errorlevel=0
exit /b %errorlevel%

:invalid
echo %RED%Your arguments/flags are invalid^^!%NC%
call:help
call:exitcode 1
exit /b %errorlevel%

:build_fail
echo %RED%Building failed^^!%NC%
call:exitcode 2
exit /b %errorlevel%

:exitcode
set errorlevel=%~1
echo %RED%Exited build script with Error Code !errorlevel!^^!%NC%
exit /b %errorlevel%
