@echo off
setlocal enabledelayedexpansion

echo =====================================
echo DEBUT DU DIAGNOSTIC DEPLOIEMENT JELA
echo =====================================

REM Etape 1 : Nettoyage Flutter
echo Etape 1 - flutter clean...
flutter clean || (
  echo ECHEC flutter clean
  pause
  exit /b
)

REM Etape 2 : Récupération des packages
echo Etape 2 - flutter pub get...
flutter pub get || (
  echo ECHEC flutter pub get
  pause
  exit /b
)

REM Etape 3 : Compilation APK release
echo Etape 3 - flutter build apk --release...
flutter build apk --release || (
  echo ECHEC compilation APK
  pause
  exit /b
)

REM Etape 4 : Vérification existence APK
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk
if not exist !APK_PATH! (
  echo ECHEC - APK non genere: !APK_PATH!
  pause
  exit /b
)

REM Etape 5 : Lecture version depuis pubspec.yaml
for /f "tokens=2 delims=: " %%A in ('findstr /b version pubspec.yaml') do set version=%%A
set apkName=app-v%version%.apk

REM Etape 6 : Copie APK dans public
echo Etape 6 - copie de l APK dans public\%apkName%
copy /Y !APK_PATH! public\%apkName% || (
  echo ECHEC copie APK
  pause
  exit /b
)

REM Etape 7 : Deploiement Firebase Hosting
echo Etape 7 - firebase deploy --only hosting
firebase deploy --only hosting || (
  echo ECHEC deploy Firebase
  pause
  exit /b
)

echo =====================================
echo DEPLOIEMENT TERMINE AVEC SUCCES
echo URL : https://jelamvp01.web.app/%apkName%
echo =====================================
pause
