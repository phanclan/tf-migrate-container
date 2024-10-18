FROM alpine:latest

ARG PRODUCT
ARG VERSION

# Install dependencies
RUN apk add --update --no-cache \
    gnupg \
    bash \
    curl \
    unzip \
    git \
    github-cli \
    jq \
    && \
    cd /tmp && \
    # Download product binaries and checksums
    wget https://releases.hashicorp.com/${PRODUCT}/${VERSION}/${PRODUCT}_${VERSION}_linux_amd64.zip && \
    wget https://releases.hashicorp.com/${PRODUCT}/${VERSION}/${PRODUCT}_${VERSION}_SHA256SUMS && \
    wget https://releases.hashicorp.com/${PRODUCT}/${VERSION}/${PRODUCT}_${VERSION}_SHA256SUMS.sig && \
    # Import HashiCorp PGP key and verify the checksum
    wget -qO- https://www.hashicorp.com/.well-known/pgp-key.txt | gpg --import && \
    gpg --verify ${PRODUCT}_${VERSION}_SHA256SUMS.sig ${PRODUCT}_${VERSION}_SHA256SUMS && \
    grep ${PRODUCT}_${VERSION}_linux_amd64.zip ${PRODUCT}_${VERSION}_SHA256SUMS | sha256sum -c && \
    # Unzip the product and move it to the appropriate directory
    unzip /tmp/${PRODUCT}_${VERSION}_linux_amd64.zip -d /tmp && \
    mv /tmp/${PRODUCT} /usr/local/bin/${PRODUCT} && \
    # Clean up
    rm -f /tmp/${PRODUCT}_${VERSION}_linux_amd64.zip \
          /tmp/${PRODUCT}_${VERSION}_SHA256SUMS \
          /tmp/${PRODUCT}_${VERSION}_SHA256SUMS.sig && \
    apk del gnupg

# Set the version of tf-migrate to install
ARG TF_MIGRATE_VERSION="0.0.2-beta"

# Download and install tf-migrate
RUN curl -LO "https://releases.hashicorp.com/tf-migrate/${TF_MIGRATE_VERSION}/tf-migrate_${TF_MIGRATE_VERSION}_linux_amd64.zip" && \
    unzip "tf-migrate_${TF_MIGRATE_VERSION}_linux_amd64.zip" && \
    mv tf-migrate /usr/local/bin/ && \
    chmod +x /usr/local/bin/tf-migrate && \
    rm "tf-migrate_${TF_MIGRATE_VERSION}_linux_amd64.zip"

# Copy the script to create environments (we'll create this next)
COPY create_envs.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/create_envs.sh

# Copy the cleanup script (we'll create this later)
COPY destroy_workspaces_projects.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/destroy_workspaces_projects.sh

# Set the working directory
WORKDIR /app

# Define the command to run when the container starts
CMD ["/bin/bash"]
