#!/bin/bash

# Usage: ./replace_placeholders.sh source_file destination_file

SOURCE_FILE="$1"
DEST_FILE="$2"

# Check if source file exists
if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "Source file '$SOURCE_FILE' does not exist!"
    exit 1
fi

template_file() {
    local content="$1"
    
    # Extract unique placeholders: match { { file.xxx } } with arbitrary spaces
    local placeholders
    placeholders=$(printf '%s' "$content" | grep -oP '\{\s*{\s*file\.(.*)\s*}\s*}' | sed -E 's/\{\s*\{\s*file\.//;s/\s*\}\s*\}//' | sort -u)

    for placeholder in $placeholders; do
        if [[ -f "$placeholder" ]]; then
            local file_content
            file_content=$(<"$placeholder")
        
            if [[ "$placeholder" == *.template.* ]]; then
                # Template further
                file_content=$(template_file "$file_content")
            fi
                       
            # Escape special characters
            local escaped_content
            local escaped_placeholder
            escaped_content=$(printf '%s' "$file_content" | perl -pe 's/([\\\/\$])/\\$1/g; s/\n/\\n/g;')
            escaped_placeholder=$(printf '%s' "$placeholder" | perl -pe 's/([\\\/])/\\$1/g; s/\n/\\n/g;')
        
            content=$(printf '%s' "$content" | perl -pe "s/{\s*{\s*file\.${escaped_placeholder}\s*}\s*}/$escaped_content/g")
        else
            content="File not found: '$placeholder'"
        fi
    done

    printf '%s' "$content"
}

# Read the entire source file into a variable
file_content=$(<"$SOURCE_FILE")

templated_content=$(template_file "$file_content")

# Write to destination file
printf '%s\n' "$templated_content" > "$DEST_FILE"

echo "Replacements complete. Output written to '$DEST_FILE'."
