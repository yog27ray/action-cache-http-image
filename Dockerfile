FROM node:20
WORKDIR /usr/action-cache-http-image
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install jq -y

ARG USERNAME=ubuntu

WORKDIR /usr/app

ENV USERNAME=${USERNAME}
ENV DEBIAN_FRONTEND=noninteractive

# Create ubuntu user with sudo permission
RUN useradd -m -s /bin/bash ${USERNAME} && \
    usermod -aG sudo ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R ${USERNAME}:${USERNAME} /usr/app

USER ${USERNAME}

COPY ./cache-http.sh ./cache-http.sh
CMD [ "/bin/bash", "/usr/action-cache-http-image/cache-http.sh" ]
