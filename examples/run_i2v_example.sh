#!/usr/bin/env bash
set -euo pipefail

# Example:
#   CKPT_DIR=/workspace/models/Wan2.1-I2V-14B-480P \
#   bash examples/run_i2v_example.sh
#
# Optional args:
#   1) input image path
#   2) output video path
#   3) prompt

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

INPUT_IMAGE="${1:-examples/i2v_input.JPG}"
OUTPUT_VIDEO="${2:-output/i2v_example.mp4}"
PROMPT="${3:-A white cat wearing sunglasses sits on a surfboard at a sunny beach, with clear blue water and distant green hills in the background. Close-up shot, natural lighting, smooth camera motion.}"
CKPT_DIR="${CKPT_DIR:-./Wan2.1-I2V-14B-480P}"

# Low-VRAM defaults (override via env vars if needed)
FRAME_NUM="${FRAME_NUM:-49}"             # must be 4n+1
SAMPLE_STEPS="${SAMPLE_STEPS:-20}"       # lower = less VRAM, faster
SAMPLE_SHIFT="${SAMPLE_SHIFT:-3}"
SAMPLE_GUIDE_SCALE="${SAMPLE_GUIDE_SCALE:-5}"

if [[ ! -f "$INPUT_IMAGE" ]]; then
  echo "[ERROR] Input image not found: $INPUT_IMAGE"
  exit 1
fi

if [[ ! -d "$CKPT_DIR" ]]; then
  echo "[ERROR] Checkpoint directory not found: $CKPT_DIR"
  echo "Set CKPT_DIR first, e.g. CKPT_DIR=/workspace/models/Wan2.1-I2V-14B-480P"
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_VIDEO")"

python generate.py \
  --task i2v-14B \
  --size "832*480" \
  --ckpt_dir "$CKPT_DIR" \
  --image "$INPUT_IMAGE" \
  --prompt "$PROMPT" \
  --frame_num "$FRAME_NUM" \
  --offload_model True \
  --t5_cpu \
  --sample_steps "$SAMPLE_STEPS" \
  --sample_shift "$SAMPLE_SHIFT" \
  --sample_guide_scale "$SAMPLE_GUIDE_SCALE" \
  --save_file "$OUTPUT_VIDEO"

echo "[DONE] video saved to: $OUTPUT_VIDEO"
