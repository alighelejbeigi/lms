# Stage 1: Build the Flutter application
FROM cirrusci/flutter:stable AS build
WORKDIR /app

# 💡 گام ۱: کپی فایل‌های pubspec برای caching بهتر
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# 💡 گام ۲: کپی کردن بقیه کدها
COPY . .

# فعال کردن بیلد وب
RUN flutter config --enable-web

# گرفتن بیلد نهایی برای وب
RUN flutter build web --release

# Stage 2: Create a minimal Nginx server image
FROM nginx:alpine
# کپی تنظیمات برای هندل کردن Single Page App routing (مهم برای Flutter Web)
# اگر از Flutter Web استفاده می‌کنید، نیاز دارید Nginx را طوری تنظیم کنید که هر درخواستی را به index.html هدایت کند.
# Stage 2: Create a minimal Nginx server image
# 💡 اضافه کردن این خط برای کپی تنظیمات
COPY default.conf /etc/nginx/conf.d/default.conf
# حذف خط اصلی Nginx:
RUN rm /etc/nginx/conf.d/default.conf
# 💡 تنظیمات Nginx برای Flutter Web (باید فایل nginx.conf/default.conf را بسازید)
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]