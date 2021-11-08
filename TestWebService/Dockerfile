#                   
# This source file is part of the Apodini open source project
# 
# SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
# 
# SPDX-License-Identifier: MIT
# 

# ================================
# Build image
# ================================
FROM swift:focal as build

# Install OS updates and, if needed, sqlite3
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# Copy all source files
COPY . .

# Build everything, with optimizations
RUN swift build --package-path /build/TestWebService -c release

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN cp "$(swift build --package-path /build/TestWebService -c release --show-bin-path)/TestWebService" ./

# Copy resources from the resources directory if the directories exist
# Ensure that by default, neither the directory nor any of its contents are writable.
RUN [ -d "$(swift build --package-path /build/TestWebService -c release --show-bin-path)/Apodini_ApodiniOpenAPI.resources" ] \
    && mv "$(swift build --package-path /build/TestWebService -c release --show-bin-path)/Apodini_ApodiniOpenAPI.resources" ./ \
    && chmod -R a-w ./Apodini_ApodiniOpenAPI.resources \
    || echo No resources to copy
RUN [ -d "$(swift build --package-path /build/TestWebService -c release --show-bin-path)/TestWebService_TestWebService.resources" ] \
    && mv "$(swift build --package-path /build/TestWebService -c release --show-bin-path)/TestWebService_TestWebService.resources" ./ \
    && chmod -R a-w ./TestWebService_TestWebService.resources \
    || echo No resources to copy

# ================================
# Run image
# ================================
FROM swift:focal-slim as run

# Make sure all system packages are up to date.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && rm -r /var/lib/apt/lists/*

# Create a apodini user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app apodini

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=apodini:apodini /staging /app

# Ensure all further commands run as the apodini user
USER apodini:apodini

# Start the Apodini service when the image is run.
ENTRYPOINT ["./TestWebService"]
