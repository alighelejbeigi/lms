# Stage 1: Build the Flutter application
FROM ghcr.io/cirruslabs/flutter:latest AS build

WORKDIR /app

# 💡 تنظیم Mirror Links برای دانلود سریع‌تر از چین
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 💡 اول به عنوان root برای تنظیمات اولیه
USER root

# 💡 حل مشکل git ownership برای Flutter SDK
RUN git config --global --add safe.directory /sdks/flutter

# 💡 ایجاد کاربر flutter و تنظیم مجوزها
RUN if ! id flutter >/dev/null 2>&1; then \
        addgroup -S flutter && adduser -S flutter -G flutter; \
    fi && \
    chown -R flutter:flutter /app && \
    chown -R flutter:flutter /sdks/flutter 2>/dev/null || true

# 💡 سوییچ به کاربر flutter
USER flutter

# 💡 نمایش نسخه Flutter و Dart
RUN flutter --version && dart --version

# 💡 گام ۱: کپی فایل‌های وابستگی
COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./

# 💡 گام ۲: دانلود وابستگی‌ها
RUN flutter pub get

# 💡 گام ۳: کپی کردن تمام سورس کد
COPY --chown=flutter:flutter . .

# 💡 فعال کردن پلتفرم وب
RUN flutter config --enable-web

# 💡 گام ۴: بیلد گرفتن از اپلیکیشن برای وب
RUN flutter build web --release --web-renderer canvaskit

# Stage 2: سرو کردن با Nginx
FROM nginx:alpine

# 💡 حذف فایل‌های پیش‌فرض Nginx
RUN rm -rf /usr/share/nginx/html/*

# 💡 کپی کردن خروجی بیلد Flutter به Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# 💡 تنظیم مجوزهای صحیح
RUN chown -R nginx:nginx /usr/share/nginx/html

# 💡 سوییچ به کاربر nginx برای امنیت
USER nginx

# 💡 باز کردن پورت 80
EXPOSE 80

# 💡 اجرای Nginx
CMD ["nginx", "-g", "daemon off;"]