# Stage 1: Build the Flutter application
FROM cirrusci/flutter:stable AS build
WORKDIR /app

# 💡 افزودن Mirror Links برای حل مشکلات شبکه در چین/WSL
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# کپی فایل‌های pubspec برای caching بهتر
COPY pubspec.yaml pubspec.lock ./
# دانلود وابستگی‌ها (اکنون از Mirror Link استفاده می‌شود)
RUN flutter pub get

# کپی کردن بقیه کدها
COPY . .

# فعال کردن بیلد وب
RUN flutter config --enable-web

# گرفتن بیلد نهایی برای وب
RUN flutter build web --release

# Stage 2: Create a minimal Nginx server image
FROM nginx:alpine
# 💡 کپی کردن فایل تنظیمات Nginx (باید در ریشه پروژه وجود داشته باشد)
COPY default.conf /etc/nginx/conf.d/default.conf

# حذف فایل اصلی Nginx
RUN rm /etc/nginx/conf.d/default.conf

# حذف محتوای پیش‌فرض Nginx
RUN rm -rf /usr/share/nginx/html/*

# کپی کردن خروجی بیلد Flutter Web به پوشه Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# پورت 8080 در Pipeline به پورت 80 کانتینر مپ خواهد شد
EXPOSE 80
# دستور شروع Nginx
CMD ["nginx", "-g", "daemon off;"]