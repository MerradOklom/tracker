# Use the official Rust image as the base image for building
FROM rust:latest as builder

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy the Cargo.toml file first to leverage Docker cache
COPY Cargo.toml ./

# Create a dummy main.rs file to build dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build the dependencies
RUN cargo build --release

# Remove the dummy main.rs file
RUN rm -f src/main.rs

# Copy the actual source code
COPY . .

# Build the actual package
RUN cargo build --release

# Use a newer base image for the final stage
FROM debian:bullseye-slim

# Install necessary packages for the dummy HTTP server
RUN apt-get update && apt-get install -y curl netcat

# Copy the built executable from the builder stage
COPY --from=builder /usr/src/app/target/release/release-track /usr/local/bin/release-track

# Create a simple dummy HTTP server script
RUN echo '#!/bin/sh\nwhile true; do echo -e "HTTP/1.1 200 OK\n\nHello, World!" | nc -l -p 8000; done' > /usr/local/bin/dummy_server.sh && chmod +x /usr/local/bin/dummy_server.sh

# Expose port 8000 for the dummy HTTP server
EXPOSE 8000

# Run the cargo executable and the dummy HTTP server
CMD ["sh", "-c", "release-track & /usr/local/bin/dummy_server.sh"]
