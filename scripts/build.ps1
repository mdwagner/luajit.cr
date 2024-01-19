$ErrorActionPreference = "Stop"

# Save the current directory
$currentDir = Get-Location

# Define the LuaJIT extension directory
$luaExtDir = Join-Path -Path $currentDir -ChildPath "ext\luajit"

# Build LuaJIT unless $luaExtDir\lua51.lib exists
if (-not (Test-Path -Path "$luaExtDir\lua51.lib")) {
    # Create a temporary directory
    $luaDir = New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString())

    # Clone LuaJIT
    git clone https://github.com/LuaJIT/LuaJIT.git $luaDir

    # Change directory to LuaJIT src
    Set-Location -Path (Join-Path -Path $luaDir -ChildPath "src")

    # Build LuaJIT (dynamic)
    .\msvcbuild.bat
    Rename-Item -Path lua51.lib -NewName lua51-dynamic.lib

    # Build LuaJIT (static)
    .\msvcbuild.bat static

    # Copy files to $luaExtDir
    $null = New-Item -ItemType Directory -Force -Path $luaExtDir
    Copy-Item -Path lua51-dynamic.lib -Destination $luaExtDir
    Copy-Item -Path lua51.dll -Destination $luaExtDir
    Copy-Item -Path lua51.lib -Destination $luaExtDir

    # Copy jit.* modules to $luaExtDir\lua\jit
    $null = New-Item -ItemType Directory -Force -Path "$luaExtDir\lua"
    Move-Item -Path jit -Destination "$luaExtDir\lua"

    # Return to the original directory
    Set-Location -Path $currentDir

    # Remove the temporary directory
    Remove-Item -Path $luaDir -Recurse -Force

    Write-Output "Add the following to any crystal commands:"
    Write-Output "  --link-flags=/LIBPATH:$luaExtDir"
}
