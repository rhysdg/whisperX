#!/bin/bash
# Full installation script for WhisperX on Jetson JetPack 6
# Handles onnxruntime and numpy compatibility automatically

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== WhisperX Jetson Installation ==="
echo ""

# Check if we're on aarch64 (Jetson)
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo "Warning: This script is designed for Jetson (aarch64), detected: $ARCH"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Python version: $PYTHON_VERSION"

if [ "$PYTHON_VERSION" != "3.10" ]; then
    echo "Warning: This script is optimized for Python 3.10, you have $PYTHON_VERSION"
fi

# Step 1: Install numpy<2 first (required for Jetson onnxruntime)
echo ""
echo "=== Step 1: Installing NumPy <2.0 ==="
pip install "numpy>=1.24.0,<2.0.0"

# Step 2: Install Jetson ONNX Runtime GPU
echo ""
echo "=== Step 2: Installing ONNX Runtime GPU for Jetson ==="
WHEEL_URL="https://nvidia.box.com/shared/static/48dtuob7meiw6ebgfsfqakc9vse62sg4.whl"
WHEEL_NAME="onnxruntime_gpu-1.19.0-cp310-cp310-linux_aarch64.whl"

# Uninstall existing onnxruntime if present
pip uninstall -y onnxruntime onnxruntime-gpu 2>/dev/null || true

# Download and install
wget -O "$WHEEL_NAME" "$WHEEL_URL"
pip install "$WHEEL_NAME"
rm -f "$WHEEL_NAME"

# Verify onnxruntime
python3 -c "import onnxruntime; print(f'ONNX Runtime: {onnxruntime.__version__}')"
python3 -c "import onnxruntime; print(f'Providers: {onnxruntime.get_available_providers()}')"

# Step 3: Install WhisperX in editable mode (skips conflicting deps on aarch64)
echo ""
echo "=== Step 3: Installing WhisperX ==="
cd "$SCRIPT_DIR"
pip install --no-build-isolation -e .

# Step 4: Verify installation
echo ""
echo "=== Verifying Installation ==="
python3 -c "import whisperx; print('WhisperX imported successfully!')"
python3 -c "import numpy; print(f'NumPy: {numpy.__version__}')"
python3 -c "import onnxruntime; print(f'ONNX Runtime: {onnxruntime.__version__}')"

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Usage: whisperx audio.wav --model large-v3 --compute_type float16"
