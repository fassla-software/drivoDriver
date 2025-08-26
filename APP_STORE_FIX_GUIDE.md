# دليل حل مشكلة App Store Connect

## المشكلة
```
Invalid Pre-Release Train. The train version '1.0.0' is closed for new build submissions
This bundle is invalid. The value for key CFBundleShortVersionString [1.0.0] must contain a higher version than that of the previously approved version [1.0.0]
```

## الحل المطبق

### 1. تحديث رقم الإصدار في pubspec.yaml
```yaml
# قبل التعديل
version: 1.0.0+8

# بعد التعديل
version: 1.0.1+9
```

### 2. شرح الأرقام
- **1.0.1**: CFBundleShortVersionString (رقم الإصدار للمستخدم)
- **9**: CFBundleVersion (رقم البناء الداخلي)

## خطوات الإصلاح

### 1. تحديث pubspec.yaml ✅
```yaml
version: 1.0.1+9
```

### 2. بناء التطبيق من جديد
```bash
# تنظيف البناء السابق
flutter clean

# الحصول على dependencies
flutter pub get

# بناء iOS
flutter build ios --release
```

### 3. رفع التطبيق مرة أخرى
- اذهب إلى App Store Connect
- ارفع الـ build الجديد
- تأكد من أن رقم الإصدار `1.0.1` أعلى من `1.0.0`

## قواعد App Store

### 1. CFBundleShortVersionString
- يجب أن يكون أعلى من الإصدار السابق
- مثال: `1.0.0` → `1.0.1` أو `1.1.0`
- لا يمكن استخدام نفس الرقم مرتين

### 2. CFBundleVersion
- رقم البناء الداخلي
- يجب أن يكون أعلى من البناء السابق
- مثال: `8` → `9`

### 3. Pre-Release Train
- كل إصدار له train منفصل
- الإصدارات المغلقة لا تقبل builds جديدة
- تحتاج لإصدار جديد لـ train جديد

## نصائح مهمة

### 1. تسمية الإصدارات
```yaml
# إصدارات صحيحة
version: 1.0.1+9    # إصلاحات بسيطة
version: 1.1.0+10   # ميزات جديدة
version: 2.0.0+11   # إصدار رئيسي

# إصدارات خاطئة
version: 1.0.0+9    # نفس الإصدار السابق
version: 1.0.0+8    # رقم بناء أقل
```

### 2. قبل كل رفع
- تأكد من زيادة رقم الإصدار
- تأكد من زيادة رقم البناء
- اختبر التطبيق محلياً
- اقرأ رسائل الخطأ بعناية

### 3. في App Store Connect
- تحقق من الإصدارات السابقة
- تأكد من أن الإصدار الجديد أعلى
- اقرأ متطلبات التحقق
- اتبع إرشادات Apple

## ملاحظات مهمة
- تم تحديث رقم الإصدار إلى `1.0.1+9`
- يجب بناء التطبيق من جديد
- يجب رفع الـ build الجديد
- تأكد من اختبار التطبيق قبل الرفع

