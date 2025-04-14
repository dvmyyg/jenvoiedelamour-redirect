@echo off
echo =============================
echo  Deploiement Jela en cours...
echo =============================

REM Nettoyage Flutter
echo.
echo flutter clean...
flutter clean
IF %ERRORLEVEL% NEQ 0 (
  echo Erreur lors de flutter clean. Abandon.
  pause
  exit /b %ERRORLEVEL%
)

REM Recuperation des packages
echo.
echo flutter pub get...
flutter pub get
IF %ERRORLEVEL% NEQ 0 (
  echo Erreur lors de flutter pub get. Abandon.
  pause
  exit /b %ERRORLEVEL%
)

REM Deploiement sur telephone A
echo.
echo Deploiement sur telephone A...
call runA.bat
IF %ERRORLEVEL% NEQ 0 (
  echo Erreur runA.bat. Abandon.
  pause
  exit /b %ERRORLEVEL%
)

REM Deploiement sur telephone B
echo.
echo Deploiement sur telephone B...
call runB.bat
IF %ERRORLEVEL% NEQ 0 (
  echo Erreur runB.bat. Abandon.
  pause
  exit /b %ERRORLEVEL%
)

REM Compilation APK
echo.
echo Compilation APK release...
flutter build apk --release
IF %ERRORLEVEL% NEQ 0 (
  echo Erreur compilation APK. Abandon.
  pause
  exit /b %ERRORLEVEL%
)

REM Renommage avec numero de version (extrait depuis pubspec.yaml)
for /f "tokens=2 delims=: " %%A in ('findstr /b version pubspec.yaml') do set version=%%A
set apkName=app-v%version%.apk

echo.
echo Copie du fichier APK...
copy /Y build\app\outputs\flutter-apk\app-release.apk .\public\%apkName%
IF %ERRORLEVEL% NEQ 0 (
  echo Erreur lors de la copie de l'APK. Abandon.
  pause
  exit /b %ERRORLEVEL%
)

REM Deploiement Firebase
echo.
echo Deploiement sur Firebase Hosting...
firebase deploy --only hosting
IF %ERRORLEVEL% NEQ 0 (
  echo Erreur lors du deploiement Firebase. Abandon.
  pause
  exit /b %ERRORLEVEL%
)

echo.
echo =============================
echo Deploiement termine !
echo URL : https://jelamvp01.web.app/%apkName%
echo =============================

pause