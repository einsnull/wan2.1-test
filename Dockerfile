# Wan2.1 Docker Image
# Based on PyTorch with CUDA support

FROM pytorch/pytorch:2.5.1-cuda12.4-cudnn9-devel

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV TZ=Asia/Shanghai

# Set working directory
WORKDIR /workspace/Wan2.1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Basic tools
    wget \
    git \
    vim \
    curl \
    cmake \
    # OpenCV required system libraries
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libxcb1 \
    libxcb-shm0 \
    # Image format libraries
    libpng16-16 \
    libjpeg-turbo8 \
    libjpeg8 \
    libtiff5 \
    # Build tools
    build-essential \
    # Video processing
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Configure pip to use Tsinghua mirror (optional, for faster download in China)
RUN mkdir -p /root/.pip && \
    echo "[global]\n\
index-url = https://pypi.tuna.tsinghua.edu.cn/simple\n\
trusted-host = pypi.tuna.tsinghua.edu.cn" > /root/.pip/pip.conf

# Set CUDA environment variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Upgrade pip first
RUN pip install --no-cache-dir --upgrade pip

# Install Python dependencies
RUN pip install --no-cache-dir \
    torch>=2.4.0 \
    torchvision>=0.19.0 \
    opencv-python>=4.9.0.80 \
    diffusers>=0.31.0 \
    transformers>=4.49.0 \
    tokenizers>=0.20.3 \
    accelerate>=1.1.1 \
    tqdm \
    imageio \
    easydict \
    ftfy \
    dashscope \
    imageio-ffmpeg \
    gradio>=5.0.0 \
    "numpy>=1.23.5,<2" \
    huggingface-hub \
    modelscope \
    einops

# Install flash-attn (may take a while to compile)
# Note: flash-attn requires specific CUDA version, skip if compilation fails
RUN pip install --no-cache-dir flash-attn || echo "flash-attn installation skipped"

# Set CUDA architecture for various GPUs
ENV TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0+PTX"

# Verify CUDA environment
RUN nvcc --version && \
    echo "CUDA_HOME: ${CUDA_HOME}" && \
    echo "TORCH_CUDA_ARCH_LIST: ${TORCH_CUDA_ARCH_LIST}" && \
    python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda}')"

# Set default command
CMD ["/bin/bash"]
