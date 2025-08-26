# =============================================================================
# 5. .NET Console Application Template
# File: dotnet-console.dockerfile
# =============================================================================

# .NET Console Application Dockerfile
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

# Setup Entrypoint
ENTRYPOINT ["sh", "-c", "/usr/entrypoint.sh"]
