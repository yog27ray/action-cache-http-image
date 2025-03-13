#! /bin/sh

set -e
echo "Cache HTTP started"
echo RUNNER_OS: "$RUNNER_OS"
echo INPUT_VERSION: "$INPUT_VERSION"
echo INPUT_HTTP_PROXY: "$INPUT_HTTP_PROXY"
echo INPUT_DESTINATION_FOLDER: "$INPUT_DESTINATION_FOLDER"
echo INPUT_LOCK_FILE: "$INPUT_LOCK_FILE"
echo INPUT_IGNORE_FIELDS: "$INPUT_IGNORE_FIELDS"
echo INPUT_INSTALL_COMMAND: "$INPUT_INSTALL_COMMAND"
echo INPUT_CACHE_HTTP_API: "$INPUT_CACHE_HTTP_API"
echo INPUT_OPERATING_DIR: "$INPUT_OPERATING_DIR"
echo INPUT_DISABLE_COMPRESSION: "$INPUT_DISABLE_COMPRESSION"
echo INPUT_OWNERSHIP_USER_UID: "$INPUT_OWNERSHIP_USER_UID"
#echo INPUT_SSH_PRIVATE_KEY: "$INPUT_SSH_PRIVATE_KEY"
#echo INPUT_SSH_PUBLIC_KEY: "$INPUT_SSH_PUBLIC_KEY"

if [ -n "$INPUT_SSH_PRIVATE_KEY" ] || [ -n "$INPUT_SSH_PUBLIC_KEY" ]; then
    SSH_KEY_DIR="$HOME/.ssh"
    echo "SSH key setup begin";
    if [ ! -d "$SSH_KEY_DIR" ]; then
      mkdir -p "$SSH_KEY_DIR"
      chmod 700 "$SSH_KEY_DIR"
    fi
    if [ -n "$INPUT_SSH_PRIVATE_KEY" ]; then
      echo "SSH key setup private key";
      SSH_KEY_FILE="$SSH_KEY_DIR/id_rsa"
      echo "$INPUT_SSH_PRIVATE_KEY" > "$SSH_KEY_FILE"
      chmod 600 "$SSH_KEY_FILE"
    fi
    if [ -n "$INPUT_SSH_PUBLIC_KEY" ]; then
      echo "SSH key setup public key";
      SSH_PUBLIC_KEY_FILE="$SSH_KEY_DIR/id_rsa.pub"
      echo "$INPUT_SSH_PUBLIC_KEY" > "$SSH_PUBLIC_KEY_FILE"
      chmod 600 "$SSH_PUBLIC_KEY_FILE"
    fi
    echo "SSH key setup completed."
fi

if [ -z "$INPUT_LOCK_FILE" ]; then
    echo "no lock file given"
    exit;
fi

if [ -z "$INPUT_OWNERSHIP_USER_UID" ]; then
    INPUT_OWNERSHIP_USER_UID=1000
fi

if ! id -u $INPUT_OWNERSHIP_USER_UID >/dev/null 2>&1; then \
        useradd -u $INPUT_OWNERSHIP_USER_UID -m -s /bin/bash dummy-user; \
fi

if [ -n "$INPUT_OPERATING_DIR" ]; then
    cd "$INPUT_OPERATING_DIR"
fi

COMPRESS_FLAG='z'

if [ -n "$INPUT_DISABLE_COMPRESSION" ]; then
  COMPRESS_FLAG=''
fi


echo "check connection"
curl \
    -u "$INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD" \
    -X GET \
    -x "$INPUT_HTTP_PROXY" \
    "$INPUT_CACHE_HTTP_API/health"

TEMP_FILE="$(date +%s%N).file"
TEMP_FILE="temp.file"
cp "$INPUT_LOCK_FILE" "$TEMP_FILE"

# Changing some value of some fields in package.json doesn't changes node_modules content for example version.
# Below code removes field names provided in INPUT_IGNORE_FIELDS from package-lock.json file copy
if [ "$INPUT_LOCK_FILE" = "package-lock.json" ]; then
  if [ -n "$INPUT_IGNORE_FIELDS" ]; then
    export IFS=","
    for field in $INPUT_IGNORE_FIELDS; do
      jq "del(.$field)" "$TEMP_FILE" > "$TEMP_FILE.json"
      cat "$TEMP_FILE.json" > "$TEMP_FILE"
      rm "$TEMP_FILE.json"
    done
  fi
fi

shaLockfile=$(openssl sha256 "$TEMP_FILE" |awk '{print $2}')
shaInstallCommand=$(echo "$INPUT_INSTALL_COMMAND"|openssl sha256|awk '{print $2}')
shaDestinationFolder=$(echo "$INPUT_DESTINATION_FOLDER"|openssl sha256|awk '{print $2}')

tarFile="$RUNNER_OS-$INPUT_VERSION-$shaInstallCommand-$shaLockfile-$shaDestinationFolder.tar.gz"

echo tarfile: "$tarFile"

response=$(curl \
    -u "$INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD" \
    -X GET \
    -x "$INPUT_HTTP_PROXY" \
    -skI \
    "$INPUT_CACHE_HTTP_API/assets/$tarFile" \
    | head -n 1 | awk -F" " '{print $2}')

if [ "$response" = "200" ] || [ "$response" -eq 200 ]; then
    echo "Cache hit"
    curl \
        -u "$INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD" \
        -X GET \
        -x "$INPUT_HTTP_PROXY" \
        -k \
        "$INPUT_CACHE_HTTP_API/assets/$tarFile" \
        --output "$tarFile" && \
    tar "${COMPRESS_FLAG}xf" "$tarFile"
    echo "Cache hit, untar success"
else
    echo "Cache miss"
    bash -c "$INPUT_INSTALL_COMMAND"
    tar "${COMPRESS_FLAG}cf" "$tarFile" "$INPUT_DESTINATION_FOLDER"

    echo "Cache miss, uploading"

    curl \
        -u "$INPUT_BASIC_AUTH_USERNAME:$INPUT_BASIC_AUTH_PASSWORD" \
        -X POST \
        -x "$INPUT_HTTP_PROXY" \
        -k \
        --form "file=@$tarFile" \
        "$INPUT_CACHE_HTTP_API/upload"

    echo "Cache miss, upload success"
fi
rm "$TEMP_FILE"
sudo chown "$INPUT_OWNERSHIP_USER_UID:$INPUT_OWNERSHIP_USER_UID" -R ./
ls -lah
