# =============================================================================
# 2. ASP.NET Core MVC Template
# File: aspnet-mvc.dockerfile
# =============================================================================

# ASP.NET Core MVC Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy csproj and restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/out .

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create entrypoint
ARG START_COMMAND="dotnet {{APP_NAME}}.dll"
RUN echo "${START_COMMAND}" > /usr/entrypoint.sh
RUN chmod +x /usr/entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://[::]:8080 || exit 1

EXPOSE 8080
EXPOSE 8081
# Setup Entrypoint
ENTRYPOINT ["sh", "-c", "/usr/entrypoint.sh"]
