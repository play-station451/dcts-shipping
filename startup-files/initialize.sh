#!/bin/sh

#get api keys and secrets
if ! grep -q "^keys:" "${LIVEKIT_YAML_PATH}" 2>/dev/null; then
    echo "Generating LiveKit keys..."

    OUTPUT=$(/livekit-server generate-keys)

    API_KEY=$(echo "$OUTPUT" | awk '/API Key:/ {print $3}')
    API_SECRET=$(echo "$OUTPUT" | awk '/API Secret:/ {print $3}')

    if [ -z "$API_KEY" ] || [ -z "$API_SECRET" ]; then
        echo "Key generation failed!"
        exit 1
    fi

    echo "Keys written."
else
    echo "Keys already exist."
fi

#add api keys and secrets
ENV_FILE="config.env"

if ! grep -q "^API_KEY=" "$ENV_FILE"; then
    echo "" >> "$ENV_FILE"
    echo "# SECRET KEYS DO NOT EDIT" >> "$ENV_FILE"
    
    echo "API_KEY=$API_KEY" >> "$ENV_FILE"
    echo "API_SECRET=$API_SECRET" >> "$ENV_FILE"

    echo "API keys added to $ENV_FILE"
else
    echo "API keys already exist in $ENV_FILE"
fi

# Check if the file exists first
if [ -f "${LIVEKIT_YAML_PATH}" ]; then
    # Count the number of lines
    line_count=$(wc -l < "${LIVEKIT_YAML_PATH}")
    
    if [ "$line_count" -le 1 ]; then
        echo "File exists but has 1 or 0 lines, skipping..."
        # You can use 'continue' in a loop or 'exit' depending on context
        next  # replace 'next' with your actual command
    else
        echo "File exists and has more than one line, processing..."
        # your processing logic here
    fi
else
    echo "File does not exist, skipping..."
    next  # again, replace with your actual command
fi


#livekit.yaml creation
echo "Creating base LiveKit config..."

cat <<EOF > "${LIVEKIT_YAML_PATH}"
port: 7880
rtc:
  tcp_port: 7881
  port_range_start: 7882
  port_range_end: 7882
  enable_loopback_candidate: false
redis:
  address: dcts-redis:6379
  username: ""
  password: ""
  db: 0
  use_tls: false
turn:
  enabled: true
  domain: ${LIVEKIT_URL}
  tls_port: 5349
  udp_port: 3478
  external_tls: true
keys:
  $API_KEY:$API_SECRET
EOF


exec /livekit-server --config "${LIVEKIT_YAML_PATH}"
