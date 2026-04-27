# Demo Test README

This file records demo commands that were verified successfully in the `wan2.1_container`.

## 1) Text-to-Video (no `t5_cpu`)

```bash
docker exec wan2.1_container /bin/bash -lc "cd /workspace/Wan2.1 && python generate.py --task t2v-1.3B --size 832*480 --ckpt_dir /workspace/models/Wan2.1-T2V-1.3B --offload_model True --sample_shift 8 --sample_guide_scale 6 --prompt 'Two anthropomorphic cats in comfy boxing gear and bright gloves fight intensely on a spotlighted stage.' --save_file /workspace/output/generate_t2v_1_3b_no_t5_cpu.mp4"
```

Output:

```bash
/workspace/output/generate_t2v_1_3b_no_t5_cpu.mp4
```
