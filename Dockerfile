FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
  mariadb-client \
  coreutils \
  && rm -rf /var/lib/apt/lists/*

# Copy the test script
COPY test_script.sh /test_script.sh
RUN chmod +x /test_script.sh

# Create output directory
RUN mkdir -p /output

# Default command
ENTRYPOINT ["/test_script.sh"]
