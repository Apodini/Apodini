#!/bin/bash
#
# This source file is part of the Apodini open source project
#
# SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
#
# SPDX-License-Identifier: MIT
#

set -e
curl --fail --insecure https://localhost/
curl --fail --insecure https://localhost/http
curl --fail --insecure --request GET --data-binary "@teststreamingrequest" -H "Content-Type: application/data" --http2-prior-knowledge --output /dev/null https://localhost/http/countdown