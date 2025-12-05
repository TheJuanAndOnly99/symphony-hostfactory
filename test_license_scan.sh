#!/bin/bash
# Test script to identify which package depends on nose
# Run this with Python 3.12 available

set -e

echo "=== Setting up virtual environment ==="
python3.12 -m venv .venv-test
.venv-test/bin/python -m pip install --upgrade pip

echo ""
echo "=== Installing dependencies ==="
.venv-test/bin/pip install -r constraints.txt

echo ""
echo "=== Installing project ==="
.venv-test/bin/pip install -e .

echo ""
echo "=== Installing pipdeptree ==="
.venv-test/bin/pip install pipdeptree

echo ""
echo "=== Dependency tree showing nose ==="
.venv-test/bin/pipdeptree | grep -A 5 -B 5 nose || echo "nose not found in dependency tree"

echo ""
echo "=== All packages that depend on nose ==="
.venv-test/bin/pipdeptree --json | python3.12 -c "
import json
import sys

data = json.load(sys.stdin)
found = False

def find_nose_deps(pkg, deps, path=[]):
    global found
    pkg_name = pkg.get('package', {}).get('key', '').lower()
    current_path = path + [pkg_name]
    
    # Check if this package is nose
    if 'nose' in pkg_name:
        found = True
        print(f'Found nose in dependency chain: {\" -> \".join(current_path)}')
        return
    
    # Check dependencies
    for dep in deps:
        dep_name = dep.get('package', {}).get('key', '').lower()
        if 'nose' in dep_name:
            found = True
            print(f'Found nose dependency: {\" -> \".join(current_path + [dep_name])}')
        find_nose_deps(dep, dep.get('dependencies', []), current_path)

for pkg in data:
    find_nose_deps(pkg, pkg.get('dependencies', []))

if not found:
    print('nose not found in dependency tree')
"

echo ""
echo "=== Checking if nose is installed ==="
.venv-test/bin/pip list | grep -i nose || echo "nose is not installed"

echo ""
echo "=== Cleaning up ==="
rm -rf .venv-test
echo "Done!"

