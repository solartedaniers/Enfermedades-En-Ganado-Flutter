Place the exported YOLOv8 TensorFlow Lite model here:

- `livestock_yolov8.tflite`
- `livestock_labels.txt`

The detector is wired to run fully on device and blocks remote diagnosis when
the model is missing or no livestock detection reaches the configured
confidence threshold.
