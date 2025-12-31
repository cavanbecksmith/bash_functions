# Local lazygit Installation

This repository includes a local lazygit installer that downloads and installs lazygit to the `bin/` directory within this repo.

## Installation

Run the installer script:

```bash
./install_lazygit.sh
```

Or with full path:

```bash
~/bash_functions/install_lazygit.sh
```

## Usage

After installation, you can use lazygit in several ways:

### 1. Using the `lg` alias (recommended)
The `fn_git.sh` file includes a `lazygit_local()` function and `lg` alias:

```bash
source ~/bash_functions/fn_git.sh
lg
```

### 2. Direct execution

```bash
~/bash_functions/bin/lazygit
```

### 3. Add to your PATH

Add this to your `.bashrc` or `.bash_profile`:

```bash
export PATH="$HOME/bash_functions/bin:$PATH"
```

Then simply run:

```bash
lazygit
```

## Features

- ✅ Cross-platform (Windows, Linux, macOS)
- ✅ Automatic OS and architecture detection
- ✅ Local installation (no system-wide changes)
- ✅ Fallback to system lazygit if local version not found
- ✅ Easy to update (just run the installer again)

## Updating

To update lazygit:

1. Edit `LAZYGIT_VERSION` in `install_lazygit.sh`
2. Run the installer again: `./install_lazygit.sh`

## Version

Current version configured: **v0.44.1**

Check for latest releases at: https://github.com/jesseduffield/lazygit/releases
