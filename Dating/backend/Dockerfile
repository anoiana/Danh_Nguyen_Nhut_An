# =============================================
# Stage 1: Build the application
# =============================================
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app

# Copy Maven wrapper and pom.xml first for better Docker layer caching.
# Dependencies are only re-downloaded when pom.xml changes.
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Ensure the Maven wrapper script is executable
RUN chmod +x mvnw

# Download dependencies (cached unless pom.xml changes)
RUN ./mvnw dependency:go-offline -B

# Copy the source code
COPY src src

# Build the application, skipping tests for faster builds
RUN ./mvnw clean package -DskipTests -B

# =============================================
# Stage 2: Create a lightweight runtime image
# =============================================
FROM eclipse-temurin:17-jre
WORKDIR /app

# Copy only the built JAR from the build stage
COPY --from=build /app/target/*.jar app.jar

# Expose the port (Render will set the PORT env var)
EXPOSE 8080

# Run the application
# Render sets the PORT environment variable; Spring Boot reads it from application.properties
ENTRYPOINT ["java", "-jar", "app.jar"]
