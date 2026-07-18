@echo off
:: ==========================================
:: FlClashX Updater
::
:: Версия скрипта: v1.3.0 (тестируется)
:: Код написан: Chatgpt + Claude
::
:: Last update: 2026-07-18 (3:32 MSK)
:: Author: https://t.me/Krul69Tepes
:: Заметка: есть вероятность возникновения ошибок UAC (у меня лично вызвать не удалось), и если будет очень кривой путь с специфическими символами.
:: ==========================================

setlocal EnableDelayedExpansion

:: ---------- Self-elevation block ----------
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator privileges...
    echo Please confirm the UAC prompt to continue.
    echo.
    powershell.exe -NoProfile -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop } catch { exit 1223 }"
    if "%errorlevel%"=="1223" (
        color 0C
        echo.
        echo ==========================================
        echo [ERROR] Administrator privileges were not granted.
        echo ==========================================
        echo.
        echo FlClashX Updater requires admin rights to
        echo install the application.
        echo.
        echo Please run this script again and click "Yes"
        echo on the UAC prompt to continue.
        echo.
        pause
    )
    exit /b
)
:: -------------------------------------------

title FlClashX Updater
color 0A

set "URL=https://github.com/pluralplay/FlClashX/releases/latest/download/FlClashX-windows-amd64-setup.exe"
set "FILE=%TEMP%\FlClashX-windows-amd64-setup.exe"
:: Лог установки - фиксированное имя, перезаписывается при каждом запуске (не растет)
set "LOGFILE=%TEMP%\FlClashX-install.log"
:: Минимальный размер файла (примерно 8 МБ)
set "MIN_SIZE=8000000"
:: Путь к программе после установки (единый для всех)
set "APP=C:\Program Files\FlClashX\FlClashX.exe"

cls
echo.
echo ==========================================
echo           FlClashX Updater
echo ==========================================
echo.
echo Checking system...
echo.

:: Проверка наличия CURL
where curl.exe >nul 2>&1
if errorlevel 1 (
    color 0C
    echo [ERROR] CURL is not available.
    echo Windows 10 1803 or newer is required.
    echo.
    pause
    exit /b 1
)

:: Удаляем старый установщик, если остался с прошлого запуска
if exist "%FILE%" (
    del /f /q "%FILE%" >nul 2>&1
)

echo Downloading latest FlClashX version...
echo.

:: Скачивание с повторными попытками и таймаутами
curl.exe ^
    -L ^
    --fail ^
    --retry 10 ^
    --retry-all-errors ^
    --retry-delay 5 ^
    --connect-timeout 20 ^
    --max-time 180 ^
    --progress-bar ^
    "%URL%" ^
    -o "%FILE%"

if errorlevel 1 (
    color 0C
    echo.
    echo [ERROR] Download failed.
    del /f /q "%FILE%" >nul 2>&1
    pause
    exit /b 1
)

:: Проверка существования файла
if not exist "%FILE%" (
    color 0C
    echo.
    echo [ERROR] Installer file was not found.
    pause
    exit /b 1
)

:: Получаем размер файла
for %%A in ("%FILE%") do set "SIZE=%%~zA"

:: Проверка минимального размера
if !SIZE! LSS !MIN_SIZE! (
    color 0C
    echo.
    echo [ERROR] Downloaded file is too small.
    set /a MB=SIZE/1024/1024
    echo File size: !MB! MB
    echo Expected minimum: 8 MB
    echo.
    echo Possible corrupted download.
    del /f /q "%FILE%" >nul 2>&1
    pause
    exit /b 1
)

set /a MB=SIZE/1024/1024
echo.
echo ==========================================
echo Download completed successfully.
echo File size: !MB! MB
echo ==========================================
echo.
echo Installing FlClashX...
echo.

:: Запуск установщика (права администратора уже есть - без повторного UAC)
:: /SILENT - показывает окно установки без необходимости нажимать кнопки
:: /SUPPRESSMSGBOXES - скрывает лишние диалоги Inno Setup
:: -PassThru - позволяет получить реальный код завершения установщика
powershell.exe -NoProfile -Command ^
"$p = Start-Process -FilePath '%FILE%' -ArgumentList '/SILENT','/SUPPRESSMSGBOXES','/LOG=%LOGFILE%' -Wait -PassThru; exit $p.ExitCode"

set "INSTALL_EXIT=%errorlevel%"

if "%INSTALL_EXIT%"=="2" (
    color 0E
    echo.
    echo Installation was cancelled by the user.
    echo.
    pause
    exit /b 1
)

if not "%INSTALL_EXIT%"=="0" (
    color 0C
    echo.
    echo [ERROR] Installation failed. Exit code: %INSTALL_EXIT%
    echo.
    pause
    exit /b 1
)

echo.
echo Installation completed.
echo.
echo Waiting before starting FlClashX... 10 sec
timeout /t 10 /nobreak >nul
echo Starting FlClashX...

:: Запуск программы после завершения установки
if exist "%APP%" (
    start "" "%APP%"
) else (
    color 0C
    echo.
    echo [ERROR] FlClashX executable not found.
    echo Expected:
    echo %APP%
    pause
    exit /b 1
)

exit /b 0
