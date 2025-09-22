# Use official Node.js runtime as the base image
FROM node:18-alpine

# Set working directory in the container
WORKDIR /app

# Install system dependencies for PostgreSQL and other native modules
RUN apk add --no-cache \
    postgresql-client \
    python3 \
    make \
    g++ \
    curl

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install Node.js dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy the rest of the application code
COPY . .

# Create necessary directories
RUN mkdir -p uploads/profiles logs

# Set proper permissions
RUN chown -R node:node /app
USER node

# Expose the port the app runs on
EXPOSE 5000

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

# Command to run the application
CMD ["node", "server.js"]