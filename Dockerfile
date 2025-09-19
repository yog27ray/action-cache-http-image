FROM node:20

# Set the working directory
WORKDIR /usr/action-cache-http-image

# Install necessary packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y jq sudo

# Define username
ARG USERNAME=node

RUN apt-get update && apt-get install -y sudo

# Create the ubuntu user with sudo permissions
RUN usermod -aG sudo ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Ensure all files in /usr/action-cache-http-image belong to ubuntu
RUN chown -R ${USERNAME}:${USERNAME} /usr/action-cache-http-image

# Switch to the ubuntu user
USER ${USERNAME}
USER root

# Java
RUN wget https://download.oracle.com/java/23/archive/jdk-23.0.2_linux-x64_bin.deb && apt install -y ./jdk-23.0.2_linux-x64_bin.deb && rm -f ./jdk-23.0.2_linux-x64_bin.deb

ENV JAVA_HOME=/usr/lib/jvm/jdk-23
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Set the working directory again to ensure permissions
WORKDIR /usr/action-cache-http-image

# Copy script and ensure correct permissions
COPY --chown=${USERNAME}:${USERNAME} ./cache-http.sh /usr/action-cache-http-image/cache-http.sh
RUN chmod +x /usr/action-cache-http-image/cache-http.sh

# Set entrypoint
CMD [ "/bin/bash", "/usr/action-cache-http-image/cache-http.sh" ]
