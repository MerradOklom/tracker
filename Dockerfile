# Use the Ubuntu image as the base image
FROM ubuntu:20.04

# Install necessary packages for the Rust application and the HTTP server
RUN apt-get update && apt-get install -y curl python3 python3-pip build-essential

# Install Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

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

# Copy the built executable to the final location
COPY /usr/src/app/target/release/release-track /usr/local/bin/release-track

# Create a simple HTTP server script
RUN echo 'import http.server\nimport socketserver\n\nPORT = 8000\nHandler = http.server.SimpleHTTPRequestHandler\n\nwith socketserver.TCPServer(("", PORT), Handler) as httpd:\n    print("serving at port", PORT)\n    httpd.serve_forever()' > server.py

# Expose port 8000 for the HTTP server
EXPOSE 8000

# Run both the cargo executable and the HTTP server
CMD ["sh", "-c", "release-track & python3 server.py"]
