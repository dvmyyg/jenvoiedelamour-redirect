@echo off
setlocal
echo =============================
echo DEBUT DU DIAGNOSTIC JELA
echo =============================

REM Etape 1 - flutter clean
echo Etape 1 - flutter clean...
flutter clean
echo Code retour : %ERRORLEVEL%
pause

REM Etape 2 - flutter pub get
echo Etape 2 - flutter pub get...
flutter pub get
echo Code retour : %ERRORLEVEL%
pause

REM Etape 3 - build apk release
echo Etape 3 - flutter build apk --release...
flutter build apk --release
echo Code retour : %ERRORLEVEL%
pause

REM Etape 4 - verif fichier APK
if exist build\app\outputs\flutter-apk\app-release.apk (
    echo APK compile avec succes.
) else (
    echo ERREUR : APK non genere !
)
pause
