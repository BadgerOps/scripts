#!/usr/bin/env python3
#
# This script takes the existing imagecontentsourcepolic{y,ies} in a K8s/OC cluster
# and combines with one or more new imagecontentsourcepolicies, merging them and re-applying them to the cluster
# after creating a backup of the existing policy.
# This allows you to rapidly and safely move offline OC Mirror content

import os
import yaml
import subprocess
import argparse
from datetime import datetime
import logging
import shutil


def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(levelname)s: %(message)s',
        datefmt='%Y-%m-%dT%H:%M:%S'
    )

def get_k8s_command():
    """
    Figure out if we're on an OpenShift, or K8s cluster
    :return valid command
    """
    if shutil.which("oc"):
        return "oc"
    elif shutil.which("kubectl"):
        return "kubectl"
    else:
        raise EnvironmentError("Neither oc nor kubectl command is available.")

def run_k8s_command(cmd):
    k8s_command = get_k8s_command()
    full_cmd = f"{k8s_command} {cmd}"
    logging.info(f"Running command: {full_cmd}")
    return subprocess.check_output(full_cmd, shell=True).decode()

def backup_k8s_resources(resource_type, backup_dir):
    """
    Back up the current ICSP's to ./backup-datestamp directory
    return: 
    """
    logging.info(f"Backing up {resource_type} resources")
    output = run_k8s_command(f"get {resource_type} -o yaml")

    resources = yaml.safe_load_all(output)
    os.makedirs(backup_dir, exist_ok=True)

    for resource in resources:
        if resource and 'metadata' in resource and 'name' in resource['metadata']:
            resource_name = resource['metadata']['name']
            backup_file = os.path.join(backup_dir, f"{resource_type}-{resource_name}.yaml")
            with open(backup_file, 'w') as fh:
                yaml.dump(resource, fh)
            logging.info(f"Backup created for {resource_name} at {backup_file}")

def load_yaml_data_from_file(file_path):
    logging.info(f"Loading data from {file_path}")
    with open(file_path, 'r') as fh:
        return list(yaml.safe_load_all(fh))

def load_current_k8s_resources(resource_type):
    logging.info(f"Loading current {resource_type} resources from Kubernetes")
    output = run_k8s_command(f"get {resource_type} -o yaml")
    return list(yaml.safe_load_all(output.decode()))

def merge_data(docs1, docs2):
    """
    We only want to merge the `repositoryDigestMirrors` section of the ICSP's
    So, only worry about those sections of the documents
    return: merged document list
    """
    logging.info("Merging 'repositoryDigestMirrors' from documents")
    merged_docs = {}
    for doc in docs1 + docs2:
        if doc and 'spec' in doc and 'repositoryDigestMirrors' in doc['spec']:
            for mirror in doc['spec']['repositoryDigestMirrors']:
                source = mirror['source']
                if source not in merged_docs:
                    merged_docs[source] = mirror
                else:
                    merged_docs[source]['mirrors'].extend(mirror['mirrors'])
                    # Remove duplicates if needed
                    merged_docs[source]['mirrors'] = list(set(merged_docs[source]['mirrors']))

    return [{'apiVersion': 'operator.openshift.io/v1alpha1', 'kind': 'ImageContentSourcePolicy', 'spec': {'repositoryDigestMirrors': list(merged_docs.values())}}]

def show_diff(original, new):
    logging.info("Showing diff between original and new data")
    with open('original.yaml', 'w') as fhwrite:
        yaml.dump_all(original, fhwrite)
    with open('new.yaml', 'w') as fhwrite:
        yaml.dump_all(new, fhwrite)
    cmd = "diff -u original.yaml new.yaml"
    subprocess.run(cmd, shell=True)

def update_k8s_resources(resource_type, data):
    logging.info(f"Updating {resource_type} resources in Kubernetes")
    with open('combined.yaml', 'w') as fhwrite:
        yaml.dump_all(data, fhwrite)
    output = run_k8s_command(f"apply -f combined.yaml")
    logging.info("Kubernetes resources updated")

def main():
    """
    Run the thing!
    """
    setup_logging()
    parser = argparse.ArgumentParser(description='Process ImageContentSourcePolicy files.')
    parser.add_argument('files', nargs='*', help='Space-separated list of file paths')
    args = parser.parse_args()
    # maybe do better than this? Its all we need _for now_ but might want more flexibility in the future?
    resource_type = "imagecontentsourcepolicy"
    # First, run backups of existing configs
    try:
        backup_dir = f"./backup-{datetime.now().strftime('%Y-%m-%d')}"

        backup_k8s_resources(resource_type, backup_dir)
    # Then, get the current docs
        current_docs = run_k8s_command(f"get {resource_type} -o yaml")
        current_docs = yaml.safe_load_all(current_docs)
        new_docs = []
        # iterate over the given file paths
        for file_path in args.files:
            new_docs.extend(load_yaml_documents_from_file(file_path))
        # merge the docs together, with the existing
        combined_docs = merge_documents(list(current_docs), new_docs)
        show_diff(list(current_docs), combined_docs)

        if input("Update Kubernetes resources? (y/n): ").lower() == 'y':
            update_k8s_resources(resource_type, combined_docs)
            logging.info("Resources updated successfully.")
        else:
            logging.info("Update cancelled.")

    except EnvironmentError as e:
        logging.error(e)

if __name__ == "__main__":
    main()
