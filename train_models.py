import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import os

# Función para entrenar un modelo
def train_model(dataset_path, model_name, labels):
    datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        horizontal_flip=True
    )

    train_gen = datagen.flow_from_directory(
        dataset_path,
        target_size=(224, 224),
        batch_size=32,
        subset='training',
        classes=labels
    )
    val_gen = datagen.flow_from_directory(
        dataset_path,
        target_size=(224, 224),
        batch_size=32,
        subset='validation',
        classes=labels
    )

    base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    base_model.trainable = False

    model = tf.keras.Sequential([
        base_model,
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dense(len(labels), activation='softmax')
    ])

    model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
    model.fit(train_gen, validation_data=val_gen, epochs=10)

    # Convertir a TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    with open(f'assets/ai/{model_name}.tflite', 'wb') as f:
        f.write(tflite_model)
    print(f'Modelo {model_name} guardado.')

# Entrenar modelos (necesitas datasets en carpetas)
if __name__ == '__main__':
    # Ejemplo: dataset_path = 'path/to/animal_vs_noanimal_dataset'
    # train_model('path/to/animal_vs_noanimal', 'animal_vs_noanimal', ['no_animal', 'animal'])
    # train_model('path/to/species', 'species_classifier', ['bovine', 'porcine', 'equine', 'ovine', 'caprine'])
    # train_model('path/to/diseases', 'disease_diagnostic', ['saludable', 'ulcera', 'cojera'])
    print('Ejecuta con datasets reales.')