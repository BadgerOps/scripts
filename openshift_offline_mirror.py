#!/usr/bin/env python3

import subprocess
import yaml
import argparse
from pathlib import Path
import logging
import time


# IMPORTANT: replace with your actual offline Quay URL
OFFLINE_QUAY_URL = "offline-quay.local"

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

# Define the CLI arguments for the script
parser = argparse.ArgumentParser(description='Export images and generate mapping and ImageContentSourcePolicy for offline repository.')
parser.add_argument('-f', '--file', type=str, required=True, help='File with image mappings')
parser.add_argument('--authfile', type=str, required=False, help='Path to the authentication file for registry')
args = parser.parse_args()

# Load the image mappings from the file
image_mappings = []
with open(args.file, 'r') as f:
    for line in f:
        src, dst = line.strip().split('=')
        image_mappings.append((src, dst))

# Create a directory for the exported images
exported_images_dir = Path("exported-images")
exported_images_dir.mkdir(exist_ok=True)

# Prepare the imageContentSourcePolicy structure
icsp = {
    'apiVersion': 'operator.openshift.io/v1alpha1',
    'kind': 'ImageContentSourcePolicy',
    'metadata': {
        'name': 'offline-repo-mirror'
    },
    'spec': {
        'repositoryDigestMirrors': []
    }
}

# Function to check if the image is already mirrored
def is_image_already_mirrored(archive_path):
    return archive_path.is_file()

# Skopeo copy command with optional arguments
def skopeo_copy_command(src, dest, authfile=None):
    cmd = ["skopeo", "copy"]
    if authfile:
        cmd += ["--authfile", authfile]
    # since we're doing a docker archive, we cannot have signatures, remove if they exists
    cmd.append("--remove-signatures")
    cmd += [f"docker://{src}", f"docker-archive:{dest}"]
    return cmd

# Record the total script start time
script_start_time = time.time()

# Process each image mapping
for src, dst in image_mappings:
    dst_path = dst.replace('/', '_').replace(':', '_')
    archive_path = exported_images_dir / f"{dst_path}.tar"

    # Check if the image is already mirrored
    if is_image_already_mirrored(archive_path):
        logging.info(f"Image already mirrored, skipping: {src}")
        continue

    # Measure the time to download the image
    image_start_time = time.time()

    # Use skopeo to copy the image to a docker-archive
    try:
        subprocess.run(
            skopeo_copy_command(
                src,
                archive_path,
                authfile=args.authfile
            ),
            check=True
        )
        elapsed_time = time.time() - image_start_time
        logging.info(f"Successfully mirrored image: {src} in {elapsed_time:.2f} seconds")
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to mirror image: {src} with error: {e}")
        continue

    # Prepare the data for ImageContentSourcePolicy
    source_repo = '/'.join(src.split('/')[:-1])
    icsp['spec']['repositoryDigestMirrors'].append({
        'source': source_repo,
        'mirrors': [f"{OFFLINE_QUAY_URL}/{source_repo}"]
    })

# Write the new mapping file
with open('mapping.txt', 'w') as mapping_file:
    for _, dst in image_mappings:
        mapping_file.write(f"{OFFLINE_QUAY_URL}/{dst}={dst}\n")
    logging.info("Mapping file created: mapping.txt")

# Write the ImageContentSourcePolicy YAML file
with open('imageContentSourcePolicy.yaml', 'w') as icsp_file:
    yaml.dump(icsp, icsp_file, default_flow_style=False)
    logging.info("ImageContentSourcePolicy file created: imageContentSourcePolicy.yaml")

# Calculate the total script time
script_elapsed_time = time.time() - script_start_time
logging.info(f"Export process completed in {script_elapsed_time:.2f} seconds.")
