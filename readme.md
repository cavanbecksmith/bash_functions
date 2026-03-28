# BUNK: Bash Utility & Navigation Kit

```
██████╗ ██╗   ██╗███╗   ██╗██╗  ██╗
██╔══██╗██║   ██║████╗  ██║██║ ██╔╝
██████╔╝██║   ██║██╔██╗ ██║█████╔╝ 
██╔══██╗██║   ██║██║╚██╗██║██╔═██╗ 
██████╔╝╚██████╔╝██║ ╚████║██║  ██╗
╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝
```

Just my personal collection of bash scripts and shortcuts.

## What's Inside

A bunch of modular `fn_*.sh` files that hold functions for Git, Docker, network, and file navigation. It scopes everything under the `bunk` command so the global namespace stays somewhat clean.

## Setup

1. **Clone it**
   ```bash
   git clone https://github.com/your-username/bash_functions.git ~/bash_functions
   ```

2. **Source it**
   Add this to your `.bashrc` or `.zshrc`:
   ```bash
   source ~/bash_functions/bash.sh
   ```

3. **Init**
   ```bash
   bunk generate_env_file
   ```

## Usage

Run `bunk` to see what functions are available:
```bash
bunk
```

**Private functions:**
If you have private scripts, you can point to them in a `.env` file:
`PRIVATE_BASH_FUNCTIONS="/path/to/your/private_repo/bash.sh"`