@echo off
echo =========================================
echo  VERIFICATION ENVIRONNEMENT FLUTTER
echo =========================================

where flutter
if %errorlevel% neq 0 (
    echo  Flutter non trouve dans le PATH
    pause
    exit /b
) else (
    echo  Flutter est detecte
)

flutter --version

echo.
echo  Test environnement termine
pause
