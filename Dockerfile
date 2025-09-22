# CBA Portal Docker Configuration
# Multi-stage build with backend API and frontend

# Stage 1: Backend build
FROM node:18-alpine AS backend-build

WORKDIR /app/backend
COPY backend/package*.json ./
RUN npm ci --only=production
COPY backend/ ./

# Stage 2: Production stage
FROM node:18-alpine AS production

# Install required packages
RUN apk add --no-cache nginx sqlite curl

# Create application directories
RUN mkdir -p /app/backend /app/frontend /app/uploads /app/database

# Copy backend from build stage
COPY --from=backend-build /app/backend /app/backend

# Copy frontend and database files
COPY fixed-frontend.html /app/frontend/index.html
COPY enhanced-frontend.html /app/frontend/enhanced.html
COPY api-service.js /app/frontend/api-service.js
COPY database/ /app/database/
COPY *.jpeg /app/frontend/
COPY *.jpg /app/frontend/

# Initialize database with complete data
RUN cd /app/backend && \
    sqlite3 database.sqlite < /app/database/complete-data.sql

# Create nginx configuration
RUN cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    upstream backend {
        server localhost:5000;
    }
    
    server {
        listen 80;
        server_name localhost;
        
        # Frontend
        location / {
            root /app/frontend;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
        
        # API proxy
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Create startup script
RUN cat > /start.sh << 'EOF'
#!/bin/sh

# Start backend API
cd /app/backend
node server.js &

# Start nginx
nginx -g "daemon off;" &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
EOF

RUN chmod +x /start.sh

# Set proper permissions
RUN chown -R nginx:nginx /app && \
    chmod -R 755 /app/uploads

# Add labels
LABEL maintainer="CBA Development Team"
LABEL version="1.0.0"
LABEL description="CBA Portal - Cantonment Board Administration System with Backend API"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# Expose port
EXPOSE 80

# Start services
CMD ["/start.sh"]