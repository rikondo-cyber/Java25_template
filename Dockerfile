# Build stage
FROM eclipse-temurin:25-jdk AS build
WORKDIR /app

# gradlew を使う前提（Wrapperを必ずrepoに含める）
COPY gradlew .
COPY gradle ./gradle
COPY build.gradle settings.gradle ./

RUN chmod +x ./gradlew
# 依存を先に落としてキャッシュを効かせる
RUN ./gradlew --no-daemon dependencies

# ソースコピー
COPY src ./src

# 本番jar作成（テストは必要なら外す）
RUN ./gradlew --no-daemon clean bootJar -x test

# Runtime stage
FROM eclipse-temurin:25-jre-alpine
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

COPY --from=build /app/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

