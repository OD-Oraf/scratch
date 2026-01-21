#!/bin/bash

keyfile="od-oraf-test-app.2026-01-13.private-key.pem"
output_file="${keyfile%.pem}.b64"
temp_decoded="/tmp/decoded-test.pem"

echo "Encoding $keyfile to base64..."

# Detect OS and use appropriate base64 command
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    base64 -i "$keyfile" | tr -d '\n' > "$output_file"
elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Linux, Git Bash (Windows), or Cygwin
    base64 -w 0 "$keyfile" > "$output_file"
else
    # Fallback for other systems
    base64 "$keyfile" | tr -d '\n' > "$output_file"
fi

echo "✓ Base64 encoded key saved to: $output_file"
echo ""
echo "Validating encoding by decoding and comparing..."

# Decode the base64 file
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    base64 -D -i "$output_file" > "$temp_decoded"
else
    # Linux/Windows
    base64 -d "$output_file" > "$temp_decoded"
fi

# Compare original and decoded files
if diff -q "$keyfile" "$temp_decoded" > /dev/null 2>&1; then
    echo "✓ Validation successful: Decoded file matches original"
    rm "$temp_decoded"
    exit 0
else
    echo "✗ Validation failed: Decoded file does NOT match original"
    echo "Original: $keyfile"
    echo "Decoded:  $temp_decoded (kept for inspection)"
    exit 1
fi