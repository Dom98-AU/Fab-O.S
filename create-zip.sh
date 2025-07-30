#!/bin/bash

cd /mnt/c/Steel\ Estimation\ Platform/SteelEstimation/publish

# Use python to create a zip file since zip command is not available
python3 -c "
import zipfile
import os

with zipfile.ZipFile('../staging-deploy.zip', 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk('.'):
        for file in files:
            file_path = os.path.join(root, file)
            arcname = os.path.relpath(file_path, '.')
            zipf.write(file_path, arcname)
print('ZIP file created successfully')
"

cd ..
ls -lh staging-deploy.zip