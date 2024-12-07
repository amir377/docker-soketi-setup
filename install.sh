#!/bin/bash

# Function to prompt user for input with a default value
prompt_user() {
    local prompt_text="$1"
    local default_value="$2"
    read -p "$prompt_text (Default: $default_value): " input
    echo "${input:-$default_value}"
}

# Prompt user for Soketi setup details
container_name=$(prompt_user "Enter the Soketi container name" "soketi")
network_name=$(prompt_user "Enter the network name" "general")
soketi_port=$(prompt_user "Enter the Soketi port" "6001")
app_id=$(prompt_user "Enter the Soketi App ID" "d1f3c2a4b5e6f")
app_key=$(prompt_user "Enter the Soketi App Key" "a3b1c2d4e5f6")
app_secret=$(prompt_user "Enter the Soketi App Secret" "f1e2d3c4b5a6")
allow_host=$(prompt_user "Enter the allowed host" "0.0.0.0")

# Generate the .env file
echo "Creating .env file for Soketi setup..."
cat > .env <<EOL
# Soketi container settings
CONTAINER_NAME=$container_name
NETWORK_NAME=$network_name
SOKETI_PORT=$soketi_port
ALLOW_HOST=$allow_host

# Soketi credentials
APP_ID=$app_id
APP_KEY=$app_key
APP_SECRET=$app_secret
EOL

echo ".env file created successfully."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully."
fi

# Create the network before building the container
echo "Creating Docker network $network_name if it does not already exist..."
docker network create $network_name || echo "Network $network_name already exists. Skipping creation."

# Use docker-compose.example.yaml to create docker-compose.yaml
echo "Generating docker-compose.yaml file from docker-compose.example.yaml..."
if [ -f "docker-compose.example.yaml" ]; then
    sed -e "s/\${CONTAINER_NAME}/$container_name/g" \
        -e "s/\${NETWORK_NAME}/$network_name/g" \
        -e "s/\${SOKETI_PORT}/$soketi_port/g" \
        -e "s/\${ALLOW_HOST}/$allow_host/g" \
        -e "s/\${APP_ID}/$app_id/g" \
        -e "s/\${APP_KEY}/$app_key/g" \
        -e "s/\${APP_SECRET}/$app_secret/g" \
        docker-compose.example.yaml > docker-compose.yaml
    echo "docker-compose.yaml file created successfully."
else
    echo "docker-compose.example.yaml file not found. Please ensure it exists in the current directory."
    exit 1
fi

# Start Docker Compose with build
echo "Starting Docker Compose with --build for Soketi..."
if docker-compose up -d --build; then
    echo "Checking container status..."
    if [ "$(docker inspect -f '{{.State.Running}}' $container_name)" = "true" ]; then
        echo "Soketi setup is complete and running on port $soketi_port."
    else
        echo "Container is not running. Fetching logs..."
        docker logs $container_name
    fi
else
    echo "Failed to start Docker Compose. Ensure Docker is running and try again."
    exit 1
fi