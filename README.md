# วางแผนการเงิน (Monthly Planner)

แอปวางแผนรายรับ-รายจ่ายรายเดือน ใช้งานคนเดียว ไม่มี build step

🔗 **ใช้งาน:** เปิดผ่าน GitHub Pages ของ repo นี้

## ฟีเจอร์

- **PIN login** — ล็อกอินด้วย PIN 6 หลัก ไม่ต้องมี username
- **สลับดูรายเดือน** — เลื่อนไป/กลับด้วยปุ่ม `‹ ›`
- **รายได้ 2 โหมด** — กรอกจำนวนเอง หรือคำนวณจากค่าแรงต่อวัน × จำนวนวันทำงาน (หักภาษีอัตโนมัติ)
- **รายจ่าย** พร้อมวันครบกำหนดจ่าย (1-31) ไว้เตือนบิล
- **คัดลอกรายการ** จากเดือนก่อนหน้า หรือไปวางยังเดือนอื่น
- **เช็คถูก/ลบ/แก้ไข** รายการแบบ inline
- **สรุปยอด** รายได้/รายจ่าย/คงเหลือ พร้อมสถานะจ่ายครบหรือค้างจ่าย
- **Autosave** — บันทึกอัตโนมัติหลังแก้ไข (debounce 800ms) พร้อมแสดงสถานะ sync

## สถาปัตยกรรม

| ส่วน | เทคโนโลยี |
|---|---|
| Frontend | Static HTML/CSS/JS (`index.html`, `style.css`, `app.js`) ไม่มี framework/bundler |
| โฮสติ้ง | GitHub Pages |
| ฐานข้อมูล | Google Sheet |
| API | Google Apps Script Web App (โค้ดอยู่ใน Apps Script editor เท่านั้น ไม่อยู่ใน repo นี้) |
| Auth | PIN ตรวจสอบฝั่ง server → ออก token ชั่วคราว (6 ชม.) ทุก read/write ต้องแนบ token |

## Deploy

Push เข้า `main` → GitHub Pages build ให้อัตโนมัติ

การแก้ backend (`.gs`) ต้องไปแก้ที่ Google Apps Script editor โดยตรง แล้วกด **Deploy → Manage deployments → New version** ทุกครั้ง (แค่ save เฉยๆ ไม่พอ)
