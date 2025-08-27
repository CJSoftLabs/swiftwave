# =============================================================================
# 1. ASP.NET Core Web API Template
# File: aspnet-webapi.dockerfile
# =============================================================================

# ASP.NET Core Web API Dockerfile
# Define build arguments at the top
ARG DOTNET_VERSION
ARG PROJECT_FILE_PATH  
ARG APP_NAME
ARG ASPNETCORE_URLS
ARG HealthCheckUri=""

# --- Build Stage ---
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION} AS build
WORKDIR /src

# Copy all files and restore dependencies for the specified project
# This pattern is robust for projects in subdirectories
COPY . .
RUN dotnet restore "${PROJECT_FILE_PATH}"

# Publish the application
RUN dotnet publish "${PROJECT_FILE_PATH}" -c Release -o /app/out

# --- Final Stage ---
FROM mcr.microsoft.com/dotnet/aspnet:${DOTNET_VERSION}
WORKDIR /app

# Copy published application from build stage
COPY --from=build /app/out .

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Re-declare ARGs for the final stage (required for multi-stage builds)
ARG APP_NAME
ARG ASPNETCORE_URLS
ARG HealthCheckUri=""

# Set runtime environment variables
ENV APP_NAME=${APP_NAME}
ENV ASPNETCORE_URLS=${ASPNETCORE_URLS}

# Create and set permissions for the entrypoint script
RUN echo '#!/bin/sh' > /usr/entrypoint.sh && \
    echo "dotnet ${APP_NAME}.dll" >> /usr/entrypoint.sh && \
    chmod +x /usr/entrypoint.sh

# Expose the port the app will listen on
EXPOSE 8080

# Conditional health check - only if HealthCheckUri is provided and not empty
# Using 127.0.0.1 for more reliable IPv4 connection
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD if [ -n "${HealthCheckUri}" ] && [ "${HealthCheckUri}" != "" ]; then \
        curl -f "http://[::]:8080${HealthCheckUri}" || exit 1; \
      else \
        exit 0; \
      fi

# Setup Entrypoint
ENTRYPOINT ["sh", "-c", "/usr/entrypoint.sh"]
