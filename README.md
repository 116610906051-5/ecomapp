# 🛍️ แอปพลิเคชัน E-Commerce (Flutter)

แอปพลิเคชันอีคอมเมิร์ซแบบครบวงจรที่พัฒนาด้วย Flutter รองรับทั้งฝั่งลูกค้าและแอดมิน พร้อมระบบชำระเงินออนไลน์และการจัดการสินค้าที่ครบครัน

## 📋 คุณสมบัติหลัก

### 👥 ฝั่งลูกค้า (Customer)
- 🔐 **ระบบสมาชิก**: ลงทะเบียน/เข้าสู่ระบบด้วย Firebase Authentication
- 🛒 **ตะกร้าสินค้า**: เพิ่ม/ลด/ลบสินค้า พร้อมคำนวณราคาแบบเรียลไทม์
- 🏷️ **คูปองส่วนลด**: ใช้โค้ดส่วนลดและคำนวณราคาหลังหักส่วนลด
- 💳 **ชำระเงินออนไลน์**: ชำระผ่านบัตรเครดิต/เดบิต (Stripe) หรือเก็บเงินปลายทาง
- 📦 **ติดตามสถานะสินค้า**: ดูสถานะออเดอร์แบบเรียลไทม์ (กำลังแพค → กำลังจัดส่ง → จัดส่งแล้ว)
- 📍 **จัดการที่อยู่**: เพิ่ม/แก้ไข/ลบที่อยู่จัดส่ง พร้อมตั้งที่อยู่เริ่มต้น
- 💬 **แชทสดกับแอดมิน**: สอบถามข้อมูลสินค้าและส่งรูปภาพได้
- 👤 **โปรไฟล์**: แก้ไขข้อมูลส่วนตัวและรูปโปรไฟล์

### 👨‍💼 ฝั่งแอดมิน (Admin)
- 📊 **แดชบอร์ด**: ดูสถิติยอดขาย, จำนวนสินค้า, ออเดอร์ และยูสเซอร์
- 📦 **จัดการสินค้า**: เพิ่ม/แก้ไข/ลบสินค้า อัพโหลดรูปภาพหลายรูป
- 🛍️ **จัดการออเดอร์**: ดูรายละเอียดออเดอร์ อัพเดทสถานะการจัดส่ง
- 🏷️ **จัดการคูปอง**: สร้างโค้ดส่วนลดแบบเปอร์เซ็นต์หรือจำนวนเงิน
- 👥 **จัดการยูสเซอร์**: ดูรายชื่อสมาชิกและข้อมูลผู้ใช้
- 💬 **ตอบแชทลูกค้า**: รับแจ้งเตือนและตอบแชทลูกค้าแบบเรียลไทม์ พร้อมส่งรูปภาพได้

## 🛠️ เทคโนโลยีที่ใช้

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Provider** - State management
- **Image Picker** - เลือกรูปภาพจากแกลเลอรี่

### Backend & Database
- **Firebase Authentication** - ระบบยืนยันตัวตน
- **Cloud Firestore** - NoSQL Database แบบเรียลไทม์
- **Firebase Storage** - จัดเก็บไฟล์

### Payment & Services
- **Stripe** - ระบบชำระเงินออนไลน์
- **Cloudinary** - จัดเก็บและจัดการรูปภาพบนคลาวด์

## 📦 การติดตั้ง

### ความต้องการของระบบ
- Flutter SDK 3.0 หรือสูงกว่า
- Dart 2.17 หรือสูงกว่า
- Android Studio / VS Code
- Git

### ขั้นตอนการติดตั้ง

1. **โคลนโปรเจค:**
   ```bash
   git clone https://github.com/your-repo/flutter_application_1.git
   cd flutter_application_1
   ```

2. **ติดตั้ง Dependencies:**
   ```bash
   flutter pub get
   ```

3. **ตั้งค่า Firebase:**
   - สร้างโปรเจคใหม่ใน [Firebase Console](https://console.firebase.google.com/)
   - เพิ่ม Android และ iOS app
   - ดาวน์โหลด `google-services.json` (Android) และ `GoogleService-Info.plist` (iOS)
   - วาง `google-services.json` ใน `android/app/`
   - ตั้งค่า Firestore Database และ Authentication

4. **ตั้งค่า Environment Variables:**
   
   คัดลอกไฟล์ตัวอย่าง:
   ```bash
   cp .env.example .env
   ```

   แก้ไขไฟล์ `.env` และเพิ่มข้อมูลจริง:
   ```env
   # Stripe Payment
   STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
   STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxx

   # Cloudinary Image Storage
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   ```

5. **รันแอปพลิเคชัน:**

   **Windows:**
   ```cmd
   # ใช้ Batch Script
   run_with_env.bat

   # หรือใช้ PowerShell
   .\run_with_env.ps1
   ```

   **macOS/Linux:**
   ```bash
   export $(cat .env | xargs) && flutter run
   ```

   **หรือรันแบบปกติ (ใช้ค่าเริ่มต้น):**
   ```bash
   flutter run
   ```

## 📁 โครงสร้างโปรเจค

```
lib/
├── config/           # ไฟล์คอนฟิก (Cloudinary, Stripe)
├── models/          # Data models (Product, Order, User, etc.)
├── pages/           # หน้าจอต่างๆ ของแอป
│   ├── admin/       # หน้าฝั่งแอดมิน
│   └── customer/    # หน้าฝั่งลูกค้า
├── providers/       # State management (Provider)
├── services/        # API และ Firebase services
├── widgets/         # Reusable widgets
└── main.dart        # Entry point
```

## 🔐 การตั้งค่าบัญชีแอดมิน

### วิธีที่ 1: ใช้ Firebase Console
1. เข้า Firebase Console → Authentication
2. เพิ่ม User ใหม่
3. เข้า Firestore → Collection `users`
4. เพิ่มฟิลด์ `role` = `"admin"` ให้กับ user นั้น

### วิธีที่ 2: ใช้ Debug Login
- แอปมีหน้า Debug Login (`lib/debug_login.dart`) สำหรับสร้างบัญชีแอดมินในโหมด development

## 🚀 การใช้งาน

### สำหรับลูกค้า:
1. เปิดแอป → ลงทะเบียนบัญชีใหม่
2. เลือกสินค้า → เพิ่มลงตะกร้า
3. กรอกที่อยู่จัดส่ง
4. เลือกวิธีชำระเงิน (บัตรเครดิต/เก็บเงินปลายทาง)
5. ติดตามสถานะสินค้าในหน้า "คำสั่งซื้อของฉัน"

### สำหรับแอดมิน:
1. เข้าสู่ระบบด้วยบัญชีแอดมิน
2. จัดการสินค้า → เพิ่มสินค้าใหม่พร้อมรูปภาพ
3. ตรวจสอบออเดอร์ → อัพเดทสถานะการจัดส่ง
4. ตอบแชทลูกค้า → แก้ปัญหาและตอบคำถาม
5. สร้างคูปองส่วนลด → กำหนดเงื่อนไขและระยะเวลา

## 🔒 ความปลอดภัย

- ✅ API Keys เก็บใน Environment Variables
- ✅ Secret Keys ไม่ถูก commit ขึ้น Git
- ✅ Firebase Security Rules ป้องกันการเข้าถึงข้อมูล
- ✅ การชำระเงินผ่าน Stripe ที่ปลอดภัย
- ✅ Authentication ด้วย Firebase

**⚠️ คำเตือน:**
- ไฟล์ `.env` อย่า commit ขึ้น Git
- Secret Keys ควรเก็บใน Backend Server เท่านั้น
- Environment Variables ใช้สำหรับ Development เท่านั้น

## 📱 สนับสนุนแพลตฟอร์ม

- ✅ Android
- ✅ iOS
- 🚧 Web (อยู่ระหว่างพัฒนา)

## 🤝 การพัฒนาและการมีส่วนร่วม

หากต้องการพัฒนาหรือมีส่วนร่วม:

1. Fork โปรเจคนี้
2. สร้าง Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit การเปลี่ยนแปลง (`git commit -m 'Add some AmazingFeature'`)
4. Push ไปยัง Branch (`git push origin feature/AmazingFeature`)
5. เปิด Pull Request

## 📄 License

โปรเจคนี้เป็น Open Source ภายใต้ MIT License

## 📞 ติดต่อ

หากมีคำถามหรือต้องการความช่วยเหลือ กรุณาติดต่อ:
- Email: support@example.com
- GitHub Issues: [Create Issue](https://github.com/your-repo/issues)

---

**พัฒนาด้วย ❤️ ด้วย Flutter**
