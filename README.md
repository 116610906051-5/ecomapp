# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment Variables Setup 🔧

แอปใช้ Environment Variables เพื่อความปลอดภัยของ API keys:

### การตั้งค่า:
1. **คัดลอกไฟล์ตัวอย่าง:**
   ```bash
   cp .env.example .env
   ```

2. **แก้ไข .env และเพิ่มข้อมูลจริง:**
   ```env
   STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
   STRIPE_SECRET_KEY=sk_test_your_key_here
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_secret
   ```

### การรันแอป:

**สำหรับ Windows:**
```cmd
# ใช้ Batch Script
run_with_env.bat

# หรือใช้ PowerShell
.\run_with_env.ps1
```

**สำหรับ macOS/Linux:**
```bash
# โหลด environment variables และรันแอป
export $(cat .env | xargs) && flutter run
```

**หรือรันปกติ (จะใช้ default values):**
```bash
flutter run
```

### 🔒 Security Notes:
- ไฟล์ `.env` จะไม่ถูก commit ขึ้น Git
- Secret Keys ควรเก็บใน Backend Server เท่านั้น
- Environment Variables ใช้สำหรับ Development
