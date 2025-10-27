function placehold(){
	w=$1
	h=$2
	echo "https://placehold.co/$1x$2/png"
}

#!/bin/bash

curl_request() {
	# Example usage:
	# curl_request -u https://httpbin.org/get
	# curl_request -u https://httpbin.org/post -m POST -h "Content-Type: application/json" -d '{"test":"data"}'
	# curl_request -u https://api.example.com -h "Authorization: Bearer token" -o response.json

    # Default values
    local url=""
    local method="GET"
    local headers=""
    local data=""
    local output_file=""
    local timeout=30
    local follow_redirects=true
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--url)
                url="$2"
                shift 2
                ;;
            -m|--method)
                method="$2"
                shift 2
                ;;
            -h|--header)
                headers="$headers -H '$2'"
                shift 2
                ;;
            -d|--data)
                data="$2"
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -t|--timeout)
                timeout="$2"
                shift 2
                ;;
            --no-redirect)
                follow_redirects=false
                shift
                ;;
            --help)
                echo "Usage: curl_request [OPTIONS]"
                echo "Options:"
                echo "  -u, --url URL          Target URL (required)"
                echo "  -m, --method METHOD    HTTP method (default: GET)"
                echo "  -h, --header HEADER    Add header (can be used multiple times)"
                echo "  -d, --data DATA        Request body data"
                echo "  -o, --output FILE      Output file"
                echo "  -t, --timeout SECONDS  Request timeout (default: 30)"
                echo "  --no-redirect          Don't follow redirects"
                echo "  --help                 Show this help"
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    
    # Validate required parameters
    if [ -z "$url" ]; then
        echo "Error: URL is required"
        return 1
    fi
    
    # Build curl command
    local curl_cmd="curl -X $method"
    
    # Add optional parameters
    [ -n "$headers" ] && curl_cmd="$curl_cmd $headers"
    [ -n "$data" ] && curl_cmd="$curl_cmd -d '$data'"
    [ -n "$output_file" ] && curl_cmd="$curl_cmd -o '$output_file'"
    [ "$follow_redirects" = true ] && curl_cmd="$curl_cmd -L"
    
    # Add standard options
    curl_cmd="$curl_cmd --max-time $timeout -v -i '$url'"
    
    # Display and execute
    echo "Executing: $curl_cmd"
    echo "----------------------------------------"
    eval $curl_cmd
}

