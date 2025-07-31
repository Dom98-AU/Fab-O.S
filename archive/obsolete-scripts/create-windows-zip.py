import zipfile
import os

# Create a zip file from the publish-fixed directory
zip_path = "/mnt/c/Steel Estimation Platform/SteelEstimation/production-fix.zip"
source_dir = "/mnt/c/Steel Estimation Platform/SteelEstimation/publish-fixed"

with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            file_path = os.path.join(root, file)
            arcname = os.path.relpath(file_path, source_dir)
            zipf.write(file_path, arcname)

print(f"Created {zip_path}")
print(f"Size: {os.path.getsize(zip_path)} bytes")