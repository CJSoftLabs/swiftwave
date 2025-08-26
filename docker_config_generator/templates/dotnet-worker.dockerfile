# =============================================================================
# 6. .NET Worker Service Template
# File: dotnet-worker.dockerfile
# =============================================================================

# .NET Worker Service Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy csproj and restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app
COPY --from=build /app/out .

# Create entrypoint
ARG START_COMMAND="dotnet {{APP_NAME}}.dll"
RUN echo "${START_COMMAND}" > /usr/entrypoint.sh
RUN chmod +x /usr/entrypoint.sh

# Health check for worker services
HEALTHCHECK --interval=60s --timeout=10s --start-period=20s --retries=3 \
  CMD pgrep -f "dotnet {{APP_NAME}}.dll" || exit 1

# Setup Entrypoint
ENTRYPOINT ["sh", "-c", "/usr/entrypoint.sh"]
