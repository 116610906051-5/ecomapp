@echo off
REM Load environment variables from .env file and run Flutter app
REM สำหรับ Windows

echo Loading environment variables from .env file...

REM อ่านไฟล์ .env และตั้งค่า environment variables
for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
    if not "%%a"=="" (
        if not "%%a:~0,1%"=="#" (
            set "%%a=%%b"
            echo Set %%a=%%b
        )
    )
)

echo.
echo Environment variables loaded successfully!
echo.
echo Running Flutter app...
flutter run
