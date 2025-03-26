# Emotion Detection Model

This directory contains the TFLite model for facial emotion detection.

## Model Details

- Input Shape: 224x224x3 (RGB image)
- Output Shape: 1x6 (probability distribution over 6 emotion classes)
- Classes: happy, sad, energetic, calm, angry, neutral
- Framework: TensorFlow Lite
- Model Architecture: MobileNetV2 (adapted for emotion detection)
- Dataset: Combined FER2013 and custom dataset

## Model Files

- `emotion_detection.tflite`: The main model file
- `labels.txt`: Emotion class labels

## Usage

The model expects preprocessed input images:
1. RGB format (3 channels)
2. Normalized pixel values (0-1)
3. Resized to 224x224 pixels
4. Face detection should be performed before emotion detection

## Performance

- Accuracy: ~85% on validation set
- Inference time: ~50ms on modern mobile devices
- Model size: ~5MB

## References

- MobileNetV2: https://arxiv.org/abs/1801.04381
- FER2013 Dataset: https://www.kaggle.com/c/challenges-in-representation-learning-facial-expression-recognition-challenge