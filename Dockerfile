# Stage 1: Build the Flutter application
FROM cirrusci/flutter:stable AS build
WORKDIR /app

# 💡 تنظیم Mirror Links
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 💡 گام جدید: ایجاد کاربر غیر root برای اجرای Flutter
RUN groupadd -r flutter && useradd -r -g flutter -m flutter
RUN chown -R flutter:flutter /app
USER flutter

# 💡 گام ۱: کپی فایل‌های اصلی برای Caching
COPY pubspec.yaml pubspec.lock ./

# 💡 گام ۲: دانلود وابستگی‌ها
# اگر در این مرحله شکست بخوریم، مشکل از وابستگی‌ها یا کانفیگ آینه‌هاست.
# ما از git config برای دور زدن مشکلات SSL استفاده نمی‌کنیم چون pub get خودش باید هندل کند.
# اگر pub get شکست خورد، خروجی verbose را باید دقیقاً ببینیم.
RUN flutter pub get

# 💡 گام ۳: کپی کردن بقیه سورس کد (بعد از pub get برای Caching بهتر)
COPY . .

# فعال کردن بیلد وب
RUN flutter config --enable-web

# گرفتن بیلد نهایی برای وب
RUN flutter build web --release

# Stage 2: Create a minimal Nginx server image
FROM nginx:alpine
# 💡 Nginx setup is run as root by default, so we revert user for security/cleanup
USER root
COPY default.conf /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/conf.d/default.conf

# تنظیم مجوزها و سوییچ به کاربر non-root Nginx
RUN chown -R nginx:nginx /usr/share/nginx/html
USER nginx

# حذف محتوای پیش‌فرض Nginx
RUN rm -rf /usr/share/nginx/html/*

# کپی کردن خروجی بیلد Flutter Web به پوشه Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]