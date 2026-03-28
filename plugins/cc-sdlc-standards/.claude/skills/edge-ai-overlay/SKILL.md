---
name: edge-ai-overlay
description: Domain overlay for edge AI and ML deployment. Extends language standards with model lifecycle, inference optimization, and data pipeline rules.
---

# Edge AI Overlay

> Activates when `sdlc-config.md` sets `domain.primary: edge-ai` or `domain.secondary` includes it.

## Additional ERROR Rules
- All model artifacts must be versioned with training metadata (dataset hash, hyperparameters, metrics)
- Model inputs must be validated for shape, dtype, and range before inference
- Never load models from untrusted sources without integrity verification (checksum/signature)
- Memory budget for inference must be documented and verified on target hardware
- All data pipelines must be reproducible — pin random seeds, document transforms, version datasets

## Additional WARNING Rules
- Use ONNX, TFLite, or framework-native formats for deployment — not pickled Python objects
- Quantize models (INT8/FP16) for edge deployment — document accuracy impact
- Implement graceful degradation when model confidence is below threshold
- Pre/post-processing must match training pipeline exactly — test with golden samples
- Monitor inference latency and throughput in production — alert on drift
- Use batch inference where latency constraints allow

## Additional RECOMMENDATION Rules
- Consider model distillation for resource-constrained targets
- Use TensorRT, OpenVINO, or Core ML for hardware-specific optimization
- Implement A/B testing infrastructure for model updates
- Consider federated learning for privacy-sensitive training
- Use feature stores for consistent feature computation between training and serving

## MLOps Checklist
- [ ] Training data versioned and documented
- [ ] Model card with performance metrics, limitations, and bias analysis
- [ ] Inference benchmark on target hardware
- [ ] Rollback plan if model update degrades performance
- [ ] Monitoring for data drift and concept drift
- [ ] Audit trail for model decisions (explainability)
