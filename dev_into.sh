#!/bin/bash
# dev_into.sh - Enter Wan2.1 Docker container

set -e

# Configuration
CONTAINER_NAME="wan2.1_container"
TOKEN_FILE="/workspace/Wan2.1/token"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if container exists
check_container_exists() {
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_error "Container '$CONTAINER_NAME' does not exist"
        print_info "Please create the container first: ./dev_start.sh"
        exit 1
    fi
}

# Check if container is running
check_container_running() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_warning "Container '$CONTAINER_NAME' is not running"
        read -p "Start the container? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker start "$CONTAINER_NAME"
            print_success "Container started"
        else
            exit 0
        fi
    fi
}

# Display container status
show_container_status() {
    docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Check and read HF token
check_hf_token() {
    if docker exec "$CONTAINER_NAME" test -f "$TOKEN_FILE"; then
        local token
        token=$(docker exec "$CONTAINER_NAME" cat "$TOKEN_FILE" | tr -d '[:space:]')
        if [ -n "$token" ]; then
            print_success "HF Token found in token file"
            export HF_TOKEN="$token"
            return 0
        fi
    fi
    print_warning "HF Token not found in /workspace/Wan2.1/token"
    print_info "Create a token file with your Hugging Face token to enable faster downloads"
    return 1
}

# Enter container
enter_container() {
    print_info "Entering container '$CONTAINER_NAME'..."

    # Check for HF token
    local hf_token_set=""
    if check_hf_token; then
        hf_token_set="HF_TOKEN=$HF_TOKEN "
    fi

    echo ""
    print_info "Available commands:"
    echo "  - Run T2V 1.3B demo:"
    echo "    python generate.py --task t2v-1.3B --size 832*480 --ckpt_dir /workspace/models/Wan2.1-T2V-1.3B --offload_model True --t5_cpu --sample_shift 8 --sample_guide_scale 6 --prompt 'Your prompt here' --save_file /workspace/output/output.mp4"
    echo ""
    echo "  - Run Gradio UI:"
    echo "    python gradio/t2v_1.3B_singleGPU.py"
    echo ""
    echo "  - Download model (with token for faster speed):"
    echo "    HF_TOKEN=your_token hf download Wan-AI/Wan2.1-T2V-1.3B --local-dir /workspace/models/Wan2.1-T2V-1.3B"
    echo ""
    echo "  - Directory structure:"
    echo "    /workspace/Wan2.1  - Code (mounted from host)"
    echo "    /workspace/data    - Data directory (mounted from host)"
    echo "    /workspace/models  - Models directory (mounted from host)"
    echo "    /workspace/output  - Output directory (mounted from host)"
    echo ""
    echo "  - Exit container: exit"
    echo ""

    # Enter container with HF_TOKEN if available
    if [ -n "$HF_TOKEN" ]; then
        docker exec -it \
            -e PYTHONUNBUFFERED=1 \
            -e HF_TOKEN="$HF_TOKEN" \
            "$CONTAINER_NAME" \
            /bin/bash -c "cd /workspace/Wan2.1 && /bin/bash"
    else
        docker exec -it \
            -e PYTHONUNBUFFERED=1 \
            "$CONTAINER_NAME" \
            /bin/bash -c "cd /workspace/Wan2.1 && /bin/bash"
    fi

    echo ""
    print_info "Exited container '$CONTAINER_NAME'"
    show_container_status
}

# Main function
main() {
    echo "========================================="
    echo "   Enter Wan2.1 Docker Container"
    echo "========================================="
    echo ""

    check_container_exists
    check_container_running
    enter_container
}

main
