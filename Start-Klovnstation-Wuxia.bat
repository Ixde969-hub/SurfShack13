@echo off
REM Downloads the wuxia cultivation branch of Klovnstation14, builds it, and starts a local server and client.
REM Needs Git (https://git-scm.com) and the .NET 10 SDK (https://dotnet.microsoft.com/download/dotnet/10.0).
REM Run it again later to pull the newest changes and play.

setlocal
set REPO=https://github.com/Ixde969-hub/Klovnstation14.git
set BRANCH=claude/wuxia-cultivation
set FOLDER=%USERPROFILE%\Klovnstation14

where git >nul 2>nul || (echo Git is not installed. Get it from https://git-scm.com and run this again. & pause & exit /b 1)
where dotnet >nul 2>nul || (echo The .NET SDK is not installed. Get .NET 10 from https://dotnet.microsoft.com/download/dotnet/10.0 and run this again. & pause & exit /b 1)

if not exist "%FOLDER%\.git" (
    echo Downloading Klovnstation14 into %FOLDER% ...
    git clone --branch %BRANCH% %REPO% "%FOLDER%" || (echo Download failed. & pause & exit /b 1)
)

cd /d "%FOLDER%"
echo Getting the latest wuxia changes...
git fetch origin %BRANCH%
git checkout %BRANCH%
REM The folder is a play copy: always match the newest version exactly, even after history was rewritten.
git reset --hard origin/%BRANCH%

REM Only the engine: the other KS14 submodules are private.
git submodule update --init --recursive RobustToolbox || (echo Could not download the engine. & pause & exit /b 1)

echo Building (the first time takes several minutes)...
dotnet build Content.Server\Content.Server.csproj -c Release || (echo Server build failed. & pause & exit /b 1)
dotnet build Content.Client\Content.Client.csproj -c Release || (echo Client build failed. & pause & exit /b 1)

echo Starting the server...
start "Klovnstation server" dotnet run --project Content.Server --configuration Release --no-build

echo Waiting for the server to come up...
timeout /t 20 /nobreak >nul

echo Starting the game. Connect to localhost if it doesn't connect on its own.
start "Klovnstation client" dotnet run --project Content.Client --configuration Release --no-build -- --connect --connect-address localhost:1212

echo.
echo To test duels, sects and oaths alone, open a second player with:
echo   cd /d "%FOLDER%" ^&^& dotnet run --project Content.Client -c Release --no-build -- --username Tester2 --connect --connect-address localhost:1212
pause
