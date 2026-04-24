#!/bin/bash
# dev_start.sh - Start Wan2.1 Docker container

set -e

# Configuration
IMAGE_NAME="wan2.1:latest"
CONTAINER_NAME="wan2.1_container"
WORKSPACE_DIR="/storage/Wan2.1"
# Data and model directories on host machine (stored in /storage/Wan2.1 which is rw)
DATA_DIR="/storage/Wan2.1/data"
MODEL_DIR="/storage/Wan2.1/models"
OUTPUT_DIR="/storage/Wan2.1/output"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed, please install Docker first"
        exit 1
    fi
}

# Check NVIDIA Docker runtime
check_nvidia_docker() {
    if ! docker info | grep -q "Runtimes:.*nvidia"; then
        print_warning "NVIDIA Docker runtime not detected"
        print_warning "If using GPU, please install nvidia-docker2"
        echo ""
        echo "Installation:"
        echo "  Ubuntu/Debian:"
        echo "    sudo apt-get install nvidia-docker2"
        echo "    sudo systemctl restart docker"
        echo ""
        USE_GPU="false"
    else
        USE_GPU="true"
    fi
}

# Check if image exists
check_image() {
    if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
        print_error "Image '$IMAGE_NAME' does not exist"
        print_info "Please build the image first:"
        echo "  docker build -t $IMAGE_NAME ."
        exit 1
    fi
}

# Check if container already exists
check_existing_container() {
    # Check if container exists (running or stopped)
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        # Check if container is running
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            print_info "Container '$CONTAINER_NAME' is already running"
            print_info "Use ./dev_into.sh to enter"
            exit 0
        else
            # Container exists but is stopped
            print_warning "Container '$CONTAINER_NAME' exists but is stopped"
            print_info "Starting container..."
            docker start "$CONTAINER_NAME"
            print_success "Container started"
            print_info "Use ./dev_into.sh to enter"
            exit 0
        fi
    fi
}

# Start container in detached mode
start_container() {
    print_info "Starting Wan2.1 Docker container..."

    # Base Docker run parameters (detached mode)
    DOCKER_RUN_CMD="docker run -itd"

    # Container name
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD --name $CONTAINER_NAME"

    # GPU support
    if [ "$USE_GPU" = "true" ]; then
        DOCKER_RUN_CMD="$DOCKER_RUN_CMD --gpus all"
        print_info "GPU support enabled"
    fi

    # Create data directories on host if not exist
    mkdir -p "$DATA_DIR" "$MODEL_DIR" "$OUTPUT_DIR"

    # Shared memory (important for video generation)
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD --shm-size=16gb"

    # Volume mounts - mount code, data, models and output separately
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD \
        -v $WORKSPACE_DIR:/workspace/Wan2.1 \
        -v $DATA_DIR:/workspace/data \
        -v $MODEL_DIR:/workspace/models \
        -v $OUTPUT_DIR:/workspace/output"

    # Network settings (for Gradio)
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD -p 7860:7860"

    # Environment variables
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD \
        -e PYTHONUNBUFFERED=1 \
        -e CUDA_VISIBLE_DEVICES=0 \
        -e GRADIO_SERVER_NAME=0.0.0.0 \
        -e GRADIO_SERVER_PORT=7860 \
        -e HF_HOME=/workspace/models/.cache/huggingface \
        -e TORCH_HOME=/workspace/models/.cache/torch"

    # Add image name
    DOCKER_RUN_CMD="$DOCKER_RUN_CMD $IMAGE_NAME /bin/bash"

    # Print startup info
    echo ""
    print_info "Start command:"
    echo "$DOCKER_RUN_CMD"
    echo ""
    print_info "Container configuration:"
    echo "  - Container name: $CONTAINER_NAME"
    echo "  - Image name: $IMAGE_NAME"
    echo "  - GPU support: $USE_GPU"
    echo "  - Shared memory: 16GB"
    echo "  - Port mapping: 7860 (Gradio)"
    echo ""
    print_info "Directory mounts (stored on host):"
    echo "  - Code:    $WORKSPACE_DIR -> /workspace/Wan2.1"
    echo "  - Data:    $DATA_DIR    -> /workspace/data"
    echo "  - Models:  $MODEL_DIR   -> /workspace/models"
    echo "  - Output:  $OUTPUT_DIR  -> /workspace/output"
    echo ""

    # Execute start command
    eval "$DOCKER_RUN_CMD"

    echo ""
    print_success "Container '$CONTAINER_NAME' started successfully"
    echo ""
    print_info "To enter the container, run:"
    echo "  ./dev_into.sh"
    echo ""
    print_info "To view container status:"
    echo "  docker ps"
    echo ""
    print_info "To view container logs:"
    echo "  docker logs $CONTAINER_NAME"
    echo ""
}

# Main function
main() {
    echo "========================================="
    echo "   Wan2.1 Docker Container Start Script"
    echo "========================================="
    echo ""

    check_docker
    check_nvidia_docker
    check_image
    check_existing_container

    # If not exited, start new container
    start_container
}

# Run main function
main
