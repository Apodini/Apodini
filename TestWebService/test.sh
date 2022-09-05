#!/bin/bash
#
# This source file is part of the Apodini open source project
#
# SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
#
# SPDX-License-Identifier: MIT
#

set -e
INTERVAL=5
TRIES=20

# Send requests every 5 seconds
COUNTER=0
while [ $COUNTER != $TRIES ]
do
    sleep $INTERVAL
    echo "Trying..."
    curl --fail http://localhost/ &&
    curl --fail http://localhost/http &&
    exit 0
    COUNTER=$[$COUNTER + 1]
done

exit 1