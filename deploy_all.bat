@echo off
setlocal enabledelayedexpansion

echo =============================
echo  Deploiement Jela en cours...
echo =============================

REM Nettoyage Flutter
echo  flutter clean...
flutter clean || echo Erreur: echec du flutter clean

REM Recuperation des packages
echo  flutter pub get...
flutter pub get || echo Erreur: echec du flutter pub get

REM Deploiement sur telephone A
echo  Deploiement sur telephone A...
call runA.bat || echo Erreur: echec du runA.bat

REM Deploiement sur telephone B
echo  Deploiement sur telephone B...
call runB.bat || echo Erreur: echec du runB.bat

REM Compilation APK
echo Compilation APK release...
flutter build apk --release || echo Erreur: echec du build APK

REM Renommage avec numero de version (extrait depuis pubspec.yaml)
for /f "tokens=2 delims=: " %%A in ('findstr /b version pubspec.yaml') do set version=%%A
set apkName=app-v%version%.apk

echo Copie du fichier APK...
if exist build\app\outputs\flutter-apk\app-release.apk (
    copy /Y build\app\outputs\flutter-apk\app-release.apk .\public\%apkName% || echo Erreur: copie de l'APK echouee
) else (
    echo Erreur: APK non trouve
)

REM Deploiement Firebase
echo Deploiement sur Firebase Hosting...
firebase deploy --only hosting || echo Erreur: echec du deploy Firebase

echo =============================
echo Deploiement termine !
echo URL : https://jelamvp01.web.app/%apkName%
echo =============================

pause