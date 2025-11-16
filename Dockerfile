# Stage 1: Build the Flutter application
FROM cirrusci/flutter:stable AS build
WORKDIR /app

# 💡 گام جدید: ایجاد کاربر غیر root برای اجرای Flutter
RUN groupadd -r flutter && useradd -r -g flutter -m flutter
RUN chown -R flutter:flutter /app
USER flutter

# 💡 تنظیم Mirror Links برای حل مشکلات شبکه در حین pub get
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# کپی فایل‌های pubspec برای caching بهتر
COPY pubspec.yaml pubspec.lock ./
# دانلود وابستگی‌ها (اکنون با کاربر flutter اجرا می‌شود)
RUN flutter pub get

# کپی کردن بقیه کدها
COPY . .

# فعال کردن بیلد وب
RUN flutter config --enable-web

# گرفتن بیلد نهایی برای وب
RUN flutter build web --release

# Stage 2: Create a minimal Nginx server image
FROM nginx:alpine
# کپی تنظیمات Nginx (default.conf باید در ریشه وجود داشته باشد)
COPY default.conf /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/conf.d/default.conf

# 💡 تنظیم مجدد مجوزها برای Nginx
# Nginx به صورت پیش‌فرض از کاربر root شروع می‌شود، اما سپس به کاربر nginx سوییچ می‌کند.
# ما باید مطمئن شویم که Nginx به فایل‌های بیلد دسترسی دارد.
RUN chown -R nginx:nginx /usr/share/nginx/html
USER nginx

# حذف محتوای پیش‌فرض Nginx
RUN rm -rf /usr/share/nginx/html/*

# کپی کردن خروجی بیلد Flutter Web به پوشه Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]