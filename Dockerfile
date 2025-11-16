# Stage 1: Build the Flutter application
FROM cirrusci/flutter:stable AS build
WORKDIR /app

# 💡 تنظیم Mirror Links
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 💡 به عنوان root اجرا می‌کنیم
USER root

# Fix git ownership issue برای Flutter SDK
RUN git config --global --add safe.directory /sdks/flutter

# 💡 ایجاد کاربر غیر root با دستورات Alpine
RUN addgroup -S flutter && adduser -S flutter -G flutter && \
    chown -R flutter:flutter /app && \
    chown -R flutter:flutter /sdks/flutter

# حالا به کاربر flutter سوییچ می‌کنیم
USER flutter

# 💡 گام ۱: کپی فایل‌های وابستگی
COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./

# 💡 گام ۲: دانلود وابستگی‌ها
RUN flutter pub get

# 💡 گام ۳: کپی کردن بقیه سورس کد
COPY --chown=flutter:flutter . .

# فعال کردن بیلد وب
RUN flutter config --enable-web

# گرفتن بیلد نهایی برای وب
RUN flutter build web --release

# Stage 2: Create a minimal Nginx server image
FROM nginx:alpine

# 💡 همه کارها را به عنوان root انجام می‌دهیم
USER root

# حذف محتوای پیش‌فرض Nginx
RUN rm -rf /usr/share/nginx/html/*

# کپی کردن خروجی بیلد Flutter Web
COPY --from=build /app/build/web /usr/share/nginx/html

# تنظیم مجوزها
RUN chown -R nginx:nginx /usr/share/nginx/html

# سوییچ به کاربر nginx برای امنیت بیشتر
USER nginx

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]