@echo off
SETLOCAL

:: Define the destination path
set REL_DEST_PATH=.\ext\luajit

pushd %REL_DEST_PATH%
set DEST_PATH=%CD%
popd

:: Create a unique temporary directory for the LuaJIT repository
set LUAJIT_TEMP_DIR=%TEMP%\LuaJIT_Clone_%RANDOM%
mkdir %LUAJIT_TEMP_DIR%

:: Clone the LuaJIT repository into the temporary directory
echo Cloning LuaJIT repository into %LUAJIT_TEMP_DIR%...
git clone https://github.com/LuaJIT/LuaJIT.git %LUAJIT_TEMP_DIR%
if errorlevel 1 (
    echo Failed to clone the repository.
    exit /b 1
)

pushd %LUAJIT_TEMP_DIR%\src

:: Set up the build environment (assuming Visual Studio's vcvarsall.bat)
:: Adjust the path to vcvarsall.bat if needed
:: call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
:: if errorlevel 1 (
::     echo Failed to set up the build environment.
::     exit /b 1
:: )

:: Build LuaJIT
echo Building LuaJIT...
call msvcbuild.bat
if errorlevel 1 (
    echo Failed to build LuaJIT.
    exit /b 1
)

popd

:: Ensure the destination directory exists
if not exist %DEST_PATH% (
    mkdir %DEST_PATH%
)

:: Copy the generated files to the destination path
echo Copying files to %DEST_PATH%...
copy /Y %LUAJIT_TEMP_DIR%\src\*.dll %DEST_PATH%
copy /Y %LUAJIT_TEMP_DIR%\src\*.lib %DEST_PATH%

if errorlevel 1 (
    echo Failed to copy files.
    exit /b 1
)

echo Done!
exit /b 0
