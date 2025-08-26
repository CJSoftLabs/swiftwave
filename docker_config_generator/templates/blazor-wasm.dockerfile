# =============================================================================
# 4. Blazor WebAssembly Template
# File: blazor-wasm.dockerfile
# =============================================================================

# Blazor WebAssembly Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy csproj files and restore dependencies
COPY *.csproj ./
COPY */*.csproj ./*/
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Build runtime image using nginx for static files
FROM nginx:alpine
COPY --from=build /app/out/wwwroot /usr/share/nginx/html

# Custom nginx config for Blazor WASM
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name localhost;
    
    location / {
        root /usr/share/nginx/html;
        try_files \$uri \$uri/ /index.html;
        
        # Blazor specific headers
        location ~ /\.blazor/ {
            add_header Cache-Control "no-cache";
            try_files \$uri =404;
        }
        
        # WebAssembly MIME type
        location ~* \.wasm$ {
            add_header Content-Type application/wasm;
        }
    }
}
EOF

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
