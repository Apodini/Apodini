#!/bin/bash

set -eux

# executable=$1
executable_path=$1 # path to the built executable
output_dir=$2      # path of the directory we should copy the object files to

# target=".build/lambda/$executable"
rm -rf "$output_dir"
mkdir -p "$output_dir"
# cp ".build/debug/$executable" "$target/"
# add the target deps based on ldd
ldd "$executable_path" | grep swift | awk '{print $3}' | xargs cp -Lv -t "$output_dir"
# zip lambda.zip *