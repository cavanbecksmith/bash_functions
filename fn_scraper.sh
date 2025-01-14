#!/bin/bash
# Function to search YouTube using a web scraper
scrape_youtube_links() {
    local url="$1"
    
    # Fetch the webpage content
    content=$(curl -s "$url")

    # Extract YouTube video links using grep and sed
    echo "$content" | grep -oP 'https?://(www\.)?youtube\.com/watch\?v=[^"&]+' | sort -u
}
