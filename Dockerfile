# Stage 1: Build the React app
FROM node:18 AS build

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json first (for caching)
COPY package*.json ./

# Install dependencies
RUN apt-get update && apt-get install -y libatomic1
RUN npm ci && npm cache clean --force

# Copy the rest of the source code
COPY . .

# Build production files
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:stable-alpine

# Copy build output from Stage 1 to Nginx html folder
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# 🔍 Health Check - ensures Nginx is serving content correctly
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD wget -qO- http://localhost:80 || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
