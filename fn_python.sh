function initvenv(){
	#!/bin/bash
	set -e  # Exit if any command fails

	# Create and activate virtual environment (if not yet created)
	if [ ! -d "venv" ]; then
	  python3 -m venv venv
	fi
	source venv/bin/activate
}

function loadvenv(){
	#!/bin/bash
	set -e  # Exit if any command fails
	source venv/bin/activate
}

pyserve() {
    local port=${1:-8000}
    echo "Serving current directory: $(pwd)"
    echo "URL: http://localhost:$port"
    python -m http.server "$port"
}