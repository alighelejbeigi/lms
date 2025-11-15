# Stage 1: Build the Flutter application
# استفاده از ایمیج رسمی Flutter برای بیلد گرفتن
FROM cirrusci/flutter:stable AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
# دانلود وابستگی‌ها
RUN flutter pub get
# کپی کردن سورس کد
COPY . .
# فعال کردن بیلد وب
RUN flutter config --enable-web
# گرفتن بیلد نهایی برای وب
RUN flutter build web --release

# Stage 2: Create a minimal Nginx server image
# استفاده از Nginx برای سرو کردن فایل‌های استاتیک وب
FROM nginx:alpine
# کپی کردن تنظیمات Nginx (اختیاری: اگر تنظیمات خاصی برای Nginx ندارید، این خط را حذف کنید)
# COPY nginx.conf /etc/nginx/conf.d/default.conf
# حذف محتوای پیش‌فرض Nginx
RUN rm -rf /usr/share/nginx/html/*
# کپی کردن خروجی بیلد Flutter Web به پوشه Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# پورت 8080 در Pipeline به پورت 80 کانتینر مپ خواهد شد
EXPOSE 80
# دستور شروع Nginx
CMD ["nginx", "-g", "daemon off;"]