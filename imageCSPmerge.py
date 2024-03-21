#!/usr/bin/env python3
#
# Found.... somewhere.

# usage
# ./imageCSPmerge.py $(find . -name imageContentSourcePolicy.yaml)
# should merge and output a unified ICSP.

import sys
import yaml
from copy import deepcopy
mirrors = {}
merged_manifest = None
while len(sys.argv) > 1:
arg = sys.argv.pop()
if arg == __file__:
break
with open(arg) as f:
print('using: ' + arg, file=sys.stderr)
for manifest in yaml.safe_load_all(f):
print('- manifest: ' + manifest['metadata']['name'], file=sys.stderr)
if merged_manifest is None:
merged_manifest = deepcopy(manifest)
manifest_mirrors = manifest.get('spec', {})
manifest_mirrors = manifest_mirrors.get('repositoryDigestMirrors', [])
for mirror in manifest_mirrors:
mirrors[mirror['source']] = mirror
mirrors = sorted([mirror for _, mirror in mirrors.items()], key=lambda x: x['source'])
merged_manifest['metadata']['name'] = 'merged-0'
merged_manifest['spec']['repositoryDigestMirrors'] = mirrors
print('---\n' + yaml.dump(merged_manifest, indent=2, default_flow_style=False))