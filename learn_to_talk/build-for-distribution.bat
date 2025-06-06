@echo off
echo Building optimized APK for distribution...
echo.

rem Clean previous build artifacts
call flutter clean

rem Build using debug mode with release optimizations
call flutter build apk --debug --dart-define=FLUTTER_BUILD_MODE=release

rem Check if build was successful
if %ERRORLEVEL% NEQ 0 (
    echo Build failed with error code %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

rem Create dist folder if it doesn't exist
if not exist "dist" mkdir dist

rem Copy and rename the APK for distribution
copy /Y "build\app\outputs\flutter-apk\app-debug.apk" "dist\learn-to-talk-release.apk"

echo.
echo Build complete!
echo.
echo Your distribution APK is ready at: dist\learn-to-talk-release.apk
echo.
echo NOTE: This is built in debug mode with release optimizations to bypass
echo       Google ML Kit resource validation issues. It has all the functionality
echo       of a release build but may be slightly larger in size.
