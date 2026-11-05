
from pathlib import Path
import shutil

# Grasshopper class ID in the original dataset
GRASSHOPPER_ID = 17

# Ask for original dataset location
source = Path(
    input("Enter your dataset folder path: ").strip().strip('"')
).resolve()

# Create output folder beside original dataset
output = source.parent / "grasshopper_only"

image_extensions = {
    ".jpg", ".jpeg", ".png", ".bmp", ".webp"
}

total_images = 0
total_labels = 0

for split in ["train", "valid", "test"]:

    image_folder = source / split / "images"
    label_folder = source / split / "labels"

    new_images = output / split / "images"
    new_labels = output / split / "labels"

    new_images.mkdir(parents=True, exist_ok=True)
    new_labels.mkdir(parents=True, exist_ok=True)

    if not image_folder.exists() or not label_folder.exists():
        print(f"Missing images or labels folder: {split}")
        continue

    for label_file in label_folder.glob("*.txt"):

        grasshopper_lines = []

        with open(label_file, "r") as file:
            for line in file:
                parts = line.strip().split()

                if len(parts) < 5:
                    continue

                try:
                    class_id = int(parts[0])
                except ValueError:
                    continue

                if class_id == GRASSHOPPER_ID:
                    parts[0] = "0"
                    grasshopper_lines.append(" ".join(parts))

        if not grasshopper_lines:
            continue

        matching_images = [
            image for image in image_folder.iterdir()
            if image.is_file()
            and image.stem == label_file.stem
            and image.suffix.lower() in image_extensions
        ]

        if not matching_images:
            continue

        for image in matching_images:
            shutil.copy2(image, new_images / image.name)
            total_images += 1

        with open(new_labels / label_file.name, "w") as file:
            file.write("\n".join(grasshopper_lines) + "\n")

        total_labels += 1

    print(f"{split} completed")

# Create YOLO configuration file
yaml_content = f"""path: {output.as_posix()}
train: train/images
val: valid/images
test: test/images

nc: 1
names: ['grasshopper']
"""

with open(output / "data.yaml", "w") as file:
    file.write(yaml_content)

print("\n========== COMPLETE ==========")
print("Grasshopper images:", total_images)
print("Label files:", total_labels)
print("Output folder:", output)
print("Configuration file: data.yaml")
