@echo off
echo =============================
echo  Compilation et upload APK...
echo =============================

REM Nettoyage Flutter
flutter clean || goto :error

REM Récupération des dépendances
flutter pub get || goto :error

REM Compilation APK release
flutter build apk --release || goto :error

REM Extraction de la version depuis pubspec.yaml
for /f "tokens=2 delims=: " %%A in ('findstr /b version pubspec.yaml') do set version=%%A
set apkName=app-v%version%.apk

REM Copie de l'APK vers public/
copy /Y build\app\outputs\flutter-apk\app-release.apk public\%apkName% || goto :error

REM Déploiement Firebase
firebase deploy --only hosting || goto :error

echo =============================
echo ✅ Terminé ! APK en ligne :
echo https://jelamvp01.web.app/%apkName%
echo =============================
pause
exit /b

:error
echo ❌ Une erreur s’est produite. Vérifie les étapes ci-dessus.
pause
exit /b 1
