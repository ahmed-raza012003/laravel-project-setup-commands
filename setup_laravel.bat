@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Define project directory and paths
SET "PROJECT_DIR=Project_Name"
SET "BASE_PATH=%CD%"
SET "WEB_ROOT=%BASE_PATH%\%PROJECT_DIR%"
SET "PHP_VERSION=8.2"
SET "MY_USER=%USERNAME%"

:: Navigate to project directory
cd /d "%WEB_ROOT%"
if %ERRORLEVEL% neq 0 (
    echo Error: Could not navigate to %WEB_ROOT%. Please check if the directory exists.
    pause
    exit /b %ERRORLEVEL%
)

:: Create necessary directories
echo Creating necessary directories...
mkdir "%WEB_ROOT%\bootstrap\cache"
mkdir "%WEB_ROOT%\storage\framework\sessions"
mkdir "%WEB_ROOT%\storage\framework\cache\data"
mkdir "%WEB_ROOT%\storage\framework\views"
mkdir "%WEB_ROOT%\storage\logs"

:: Set permissions using icacls
echo Setting permissions for cache and storage directories...
icacls "%WEB_ROOT%\bootstrap\cache" /grant:r "%MY_USER%:F" /t
icacls "%WEB_ROOT%\storage" /grant:r "%MY_USER%:F" /t
if exist "%WEB_ROOT%\.env" (
    icacls "%WEB_ROOT%\.env" /grant:r "%MY_USER%:F"
)

:: Create .env file if it doesn't exist
if not exist "%WEB_ROOT%\.env" (
    echo Copying .env.example to .env...
    copy "%WEB_ROOT%\.env.example" "%WEB_ROOT%\.env"
)

:: Create a junction (Windows equivalent of symbolic link) for assets
:: Assumes public/assets exists; adjust path if needed
if exist "%WEB_ROOT%\public\assets" (
    echo Creating junction for assets...
    mklink /J "%WEB_ROOT%\assets" "%WEB_ROOT%\public\assets"
) else (
    echo Warning: public/assets directory does not exist. Skipping junction creation.
)

:: Remove vendor directory and composer.lock if they exist
echo Cleaning up old vendor and composer.lock...
if exist "%WEB_ROOT%\vendor" (
    rmdir /s /q "%WEB_ROOT%\vendor"
)
if exist "%WEB_ROOT%\composer.lock" (
    del /q "%WEB_ROOT%\composer.lock"
)

:: Run Composer commands
echo Running Composer install...
call composer install
if %ERRORLEVEL% neq 0 (
    echo Error: Composer install failed.
    pause
    exit /b %ERRORLEVEL%
)

echo Running Composer dump-autoload...
call composer dump-autoload
if %ERRORLEVEL% neq 0 (
    echo Error: Composer dump-autoload failed.
    pause
    exit /b %ERRORLEVEL%
)

:: Generate application key
echo Generating application key...
call php artisan key:generate
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to generate application key.
    pause
    exit /b %ERRORLEVEL%
)

:: Clear and cache configuration
echo Clearing and caching configuration...
call php artisan cache:clear
call php artisan config:cache
call php artisan package:discover
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to run Artisan cache commands.
    pause
    exit /b %ERRORLEVEL%
)

echo Setup completed successfully!
pause
ENDLOCAL
