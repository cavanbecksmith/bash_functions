#!/usr/bin/env python3
"""
Screen Configuration Manager
Python helper script for managing screen sessions based on JSON configuration
"""

import json
import sys
import os
import subprocess
from pathlib import Path

class ScreenManager:
    def __init__(self, config_file="screen_configs.json"):
        self.config_file = Path(config_file)
        self.config = self.load_config()
    
    def load_config(self):
        """Load screen configurations from JSON file"""
        try:
            if not self.config_file.exists():
                print(f"Error: Configuration file {self.config_file} not found", file=sys.stderr)
                sys.exit(1)
            
            with open(self.config_file, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in {self.config_file}: {e}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error loading configuration: {e}", file=sys.stderr)
            sys.exit(1)
    
    def list_screens(self):
        """List all available screen configurations"""
        print("Available screen configurations:")
        print("-" * 40)
        for i, (name, config) in enumerate(self.config.items(), 1):
            description = config.get('description', 'No description')
            print(f"{i}. {name}: {description}")
        return list(self.config.keys())
    
    def get_screen_config(self, screen_name):
        """Get configuration for a specific screen"""
        return self.config.get(screen_name)
    
    def check_screen_exists(self, screen_name):
        """Check if a screen session already exists"""
        try:
            result = subprocess.run(['screen', '-list'], 
                                  capture_output=True, text=True, check=False)
            return screen_name in result.stdout
        except FileNotFoundError:
            print("Error: 'screen' command not found. Please install GNU screen.", file=sys.stderr)
            sys.exit(1)
    
    def generate_screen_script(self, screen_name, config):
        """Generate a screen startup script for the given configuration"""
        if not config:
            print(f"Error: No configuration found for screen '{screen_name}'", file=sys.stderr)
            return None
        
        script_lines = []
        
        # Add initial setup commands
        if 'commands' in config:
            for cmd in config['commands']:
                script_lines.append(f"stuff '{cmd}^M'")
        
        # Create windows if specified
        if 'windows' in config:
            for i, window in enumerate(config['windows']):
                if i > 0:  # Create new window for additional windows
                    script_lines.append("screen -t '{}'".format(window.get('name', f'window{i+1}')))
                else:
                    # First window - just set title
                    if 'name' in window:
                        script_lines.append(f"title '{window['name']}'")
                
                # Execute window command (if specified)
                if 'command' in window:
                    script_lines.append(f"stuff '{window['command']}^M'")
        elif 'working_directory' in config:
            # If no windows specified but working directory is set, create a default window
            script_lines.append("title 'main'")
        
        return script_lines
    
    def create_screenrc(self, screen_name, config):
        """Create a temporary .screenrc file for the session"""
        # Use appropriate temp directory for the platform
        import tempfile
        temp_dir = tempfile.gettempdir()
        screenrc_path = os.path.join(temp_dir, f"screenrc_{screen_name}")
        
        with open(screenrc_path, 'w') as f:
            # Basic screen configuration
            f.write("# Temporary screenrc for " + screen_name + "\n")
            f.write("startup_message off\n")
            f.write("hardstatus alwayslastline\n")
            f.write("hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{=kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B}%Y-%m-%d %{W}%c %{g}]'\n")
            f.write("defscrollback 10000\n")
            f.write("shell bash\n\n")
            
            # Add working directory if specified
            if 'working_directory' in config:
                f.write(f"chdir {config['working_directory']}\n")
            
            # Create windows - use screen command syntax
            if 'windows' in config and config['windows']:
                for i, window in enumerate(config['windows']):
                    window_name = window.get('name', f'window{i+1}')
                    window_cmd = window.get('command', 'bash')
                    
                    if i == 0:
                        # First window
                        f.write(f"screen -t '{window_name}' {window_cmd}\n")
                    else:
                        # Additional windows
                        f.write(f"screen -t '{window_name}' {window_cmd}\n")
            else:
                # Default single window
                f.write("screen -t 'main' bash\n")
            
            # Add initialization commands if specified
            if 'commands' in config:
                f.write("\n# Initialization commands\n")
                for cmd in config['commands']:
                    f.write(f"# Run: {cmd}\n")
        
        return screenrc_path

def main():
    if len(sys.argv) < 2:
        print("Usage: python screen_manager.py <command> [args]")
        print("Commands:")
        print("  list                    - List available screen configurations")
        print("  config <screen_name>    - Get configuration for a screen")
        print("  exists <screen_name>    - Check if screen session exists")
        print("  create <screen_name>    - Create screenrc file for screen")
        sys.exit(1)
    
    # Find config file in the same directory as this script
    script_dir = Path(__file__).parent
    config_file = script_dir / "screen_configs.json"
    
    manager = ScreenManager(config_file)
    command = sys.argv[1]
    
    if command == "list":
        screens = manager.list_screens()
        # Output screen names for bash script to parse
        print("\n__SCREEN_NAMES__")
        for screen in screens:
            print(screen)
    
    elif command == "config":
        if len(sys.argv) < 3:
            print("Error: Screen name required", file=sys.stderr)
            sys.exit(1)
        
        screen_name = sys.argv[2]
        config = manager.get_screen_config(screen_name)
        if config:
            print(json.dumps(config, indent=2))
        else:
            print(f"Error: No configuration found for '{screen_name}'", file=sys.stderr)
            sys.exit(1)
    
    elif command == "exists":
        if len(sys.argv) < 3:
            print("Error: Screen name required", file=sys.stderr)
            sys.exit(1)
        
        screen_name = sys.argv[2]
        exists = manager.check_screen_exists(screen_name)
        print("yes" if exists else "no")
    
    elif command == "create":
        if len(sys.argv) < 3:
            print("Error: Screen name required", file=sys.stderr)
            sys.exit(1)
        
        screen_name = sys.argv[2]
        config = manager.get_screen_config(screen_name)
        if config:
            screenrc_path = manager.create_screenrc(screen_name, config)
            if screenrc_path:
                print(screenrc_path)
            else:
                sys.exit(1)
        else:
            print(f"Error: No configuration found for '{screen_name}'", file=sys.stderr)
            sys.exit(1)
    
    else:
        print(f"Error: Unknown command '{command}'", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()