@echo off
echo =============================
echo DEPLOIEMENT JELA EN COURS...
echo =============================

echo Etape 1 - flutter clean...
flutter clean

echo Etape 2 - flutter pub get...
flutter pub get

echo Etape 3 - build apk...
flutter build apk --release

echo Etape 4 - firebase deploy...
firebase deploy --only hosting

echo =============================
echo TERMINE.
echo =============================

pause
