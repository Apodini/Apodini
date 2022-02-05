#!/bin/bash

#                   
# This source file is part of the Apodini open source project
#
# SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
#
# SPDX-License-Identifier: MIT
#              

set -eu

executable_path=$1 # path to the built executable
output_dir=$2      # path of the directory we should copy the object files to

rm -rf "$output_dir"
mkdir -p "$output_dir"
# add the target deps based on ldd
ldd "$executable_path" | grep swift | awk '{print $3}' | xargs cp -L -t "$output_dir"
