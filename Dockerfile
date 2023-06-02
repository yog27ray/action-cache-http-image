FROM node:18
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install jq -y
