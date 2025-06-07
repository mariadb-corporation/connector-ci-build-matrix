#!/bin/bash

if [ "$RUNNER_OS" == "Windows" ]; then
  echo "127.0.0.1 mariadb.example.com" >> /c/Windows/System32/drivers/etc/hosts
else
  echo "127.0.0.1 mariadb.example.com" | sudo tee -a /etc/hosts
fi

# Load the base test matrix
BASE_MATRIX=$(cat "$GITHUB_ACTION_PATH/test-matrix.json")

# Check if ADDITIONAL_MATRIX is provided and not empty
if [ -n "${ADDITIONAL_MATRIX}" ]; then
    # Combine the matrices by merging the include arrays
    FINAL_MATRIX=$(echo "$BASE_MATRIX" "$ADDITIONAL_MATRIX" | jq -s '
        {
            include: (.[0].include + .[1].include)
        }
    ')
else
    # Use the base matrix as-is
    FINAL_MATRIX="$BASE_MATRIX"
fi

# Filter the matrix based on GitHub event type
if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
    # Filter out enterprise db-type entries for pull requests
    FILTERED_MATRIX=$(echo "$FINAL_MATRIX" | jq '{
        include: [.include[] | select(.["db-type"] != "enterprise")]
    }')
else
    # Use the full matrix for other events
    FILTERED_MATRIX="$FINAL_MATRIX"
fi

# Output the final matrix (compact JSON)
echo "final-matrix=$(echo "$FILTERED_MATRIX" | jq -c .)" >> "$GITHUB_OUTPUT"
