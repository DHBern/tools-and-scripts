import os
import pytesseract
from PIL import Image
from datetime import datetime

def has_been_processed(log_folder, folder_name):
    """Check if the folder has already been processed."""
    processed_folders_file = os.path.join(log_folder, 'processed_folders.txt')
    if os.path.exists(processed_folders_file):
        with open(processed_folders_file, 'r') as file:
            processed_folders = file.read().splitlines()
            if folder_name in processed_folders:
                return True
    return False

def record_processed_folder(log_folder, folder_name):
    """Record the folder as processed."""
    processed_folders_file = os.path.join(log_folder, 'processed_folders.txt')
    with open(processed_folders_file, 'a') as file:
        file.write(folder_name + '\n')

def process_images_from_folder(folder_path, tessdata_dir, output_base_folder, log_folder, model_name='eng'):
    # Set the Tesseract command to include the tessdata directory
    pytesseract.pytesseract.tesseract_cmd = r'/opt/homebrew/bin/tesseract'  # Update the path as per your Tesseract installation
    os.environ['TESSDATA_PREFIX'] = tessdata_dir

    # Create output base and log folders if they don't exist
    os.makedirs(output_base_folder, exist_ok=True)
    os.makedirs(log_folder, exist_ok=True)

    # Create a log file
    log_file_path = os.path.join(log_folder, f'log_{datetime.now().strftime("%Y%m%d_%H%M%S")}.txt')
    with open(log_file_path, 'w') as log_file:
        log_file.write(f"Processing started for base folder: {folder_path} with model: {model_name}\n")

        # Recursively walk through the folder_path
        for subdir, dirs, files in os.walk(folder_path):
            relative_path = os.path.relpath(subdir, folder_path)
            if has_been_processed(log_folder, relative_path):
                print(f"Skipping already processed folder: {subdir}")
                continue

            for filename in files:
                if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
                    # Construct the full file path
                    image_path = os.path.join(subdir, filename)
                    print(f"Processing {image_path}")

                    # Open the image and extract text using the specified model
                    image = Image.open(image_path)
                    text = pytesseract.image_to_string(image, lang=model_name)

                    # Create a corresponding output folder
                    output_folder = os.path.join(output_base_folder, relative_path)
                    os.makedirs(output_folder, exist_ok=True)

                    # Write the extracted text to a .txt file in the output folder
                    output_file = os.path.join(output_folder, os.path.splitext(filename)[0] + '.txt')
                    with open(output_file, 'w') as file:
                        file.write(text)
                    print(f"Output written to {output_file}")

                    # Write to log file
                    log_file.write(f"Processed file: {filename} in {subdir} - Output saved to {output_file}\n")

            # Record the folder as processed
            record_processed_folder(log_folder, relative_path)

        log_file.write("Processing completed.\n")

# Usage example
process_images_from_folder('image/', '/opt/homebrew/Cellar/tesseract/5.3.3/share/tessdata', 'output/', 'log/', model_name='frak2021-09')
