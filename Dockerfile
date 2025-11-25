# Stage 1: Build Flutter Web App
# تغییر ۱: استفاده از ایمیج داکر هاب به جای ghcr.io
FROM mobiledevops/flutter-sdk-image:latest AS build

WORKDIR /app

# Environment variables
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
ENV FLUTTER_SUPPRESS_ROOT_WARNING=1

# Fix git ownership
USER root
# تغییر ۲: استفاده از متغیر محیطی به جای آدرس ثابت /sdks/flutter
RUN git config --global --add safe.directory $FLUTTER_ROOT

# Show versions for debugging
RUN echo "Flutter Version:" && flutter --version

# Copy dependency files first (for better caching)
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN flutter pub get

# Copy all source code
COPY . .

# Build web application
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Remove default content
RUN rm -rf /usr/share/nginx/html/*

# Copy built app
COPY --from=build /app/build/web /usr/share/nginx/html

# Create custom nginx config
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]