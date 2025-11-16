# Stage 1: Build Flutter Web App
FROM ghcr.io/cirruslabs/flutter:latest AS build

WORKDIR /app

# Environment variables for Flutter
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
ENV FLUTTER_SUPPRESS_ROOT_WARNING=1

# Run as root and fix git ownership
USER root
RUN git config --global --add safe.directory /sdks/flutter

# Show Flutter version
RUN flutter --version

# Copy dependency files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build web app
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy Flutter web build
COPY --from=build /app/build/web /usr/share/nginx/html

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html

# Run as nginx user
USER nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]