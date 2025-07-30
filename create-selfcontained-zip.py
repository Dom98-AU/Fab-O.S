#!/usr/bin/env python3
import zipfile
import os
import sys

source_dir = 'publish-selfcontained'
output_file = 'staging-selfcontained.zip'

print(f"Creating {output_file}...")

with zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            file_path = os.path.join(root, file)
            arcname = os.path.relpath(file_path, source_dir)
            zipf.write(file_path, arcname)

size = os.path.getsize(output_file) / (1024 * 1024)
print(f"Created {output_file} ({size:.2f} MB)")