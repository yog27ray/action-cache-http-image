FROM node:20
WORKDIR /usr/action-cache-http-image
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install jq -y

USER ubuntu

COPY ./cache-http.sh ./cache-http.sh
CMD [ "/bin/bash", "/usr/action-cache-http-image/cache-http.sh" ]
