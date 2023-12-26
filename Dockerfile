FROM node:20
WORKDIR /usr/action-cache-http-image
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install jq -y
COPY ./ ./
CMD [ "/bin/bash", "/usr/action-cache-http-image/cache-http.sh" ]
