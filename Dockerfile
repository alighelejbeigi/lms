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

# 💡 کپی کردن کل Context Build (شامل pubspec.yaml/lock و source)
COPY . .

# دانلود وابستگی‌ها (با خروجی کامل برای تشخیص خطا)
RUN flutter pub get -v  #  این خط را برای خروجی کامل تغییر دادیم

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

# حذف محتوای پیش‌فرض Nginx
RUN rm -rf /usr/share/nginx/html/*

# کپی کردن خروجی بیلد Flutter Web به پوشه Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# 💡 تنظیم مجوزها و سوییچ به کاربر non-root Nginx
RUN chown -R nginx:nginx /usr/share/nginx/html
USER nginx

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]