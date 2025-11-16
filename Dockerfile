# Stage 1: Build the Flutter application
FROM cirrusci/flutter:stable AS build
WORKDIR /app

# 💡 تنظیم Mirror Links
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 💡 به عنوان root کار می‌کنیم
USER root

# Fix git ownership issue برای Flutter SDK
RUN git config --global --add safe.directory /sdks/flutter

# 💡 گام ۱: کپی فایل‌های وابستگی
COPY pubspec.yaml pubspec.lock ./

# 💡 گام ۲: دانلود وابستگی‌ها
RUN flutter pub get

# 💡 گام ۳: کپی کردن بقیه سورس کد
COPY . .

# فعال کردن بیلد وب
RUN flutter config --enable-web

# گرفتن بیلد نهایی برای وب
RUN flutter build web --release

# Stage 2: Create a minimal Nginx server image
FROM nginx:alpine

# حذف محتوای پیش‌فرض Nginx
RUN rm -rf /usr/share/nginx/html/*

# کپی کردن خروجی بیلد Flutter Web
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]