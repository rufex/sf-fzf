# SF FZF

A simple wrapper to use [fzf](https://github.com/junegunn/fzf) with [Silverfin CLI](https://github.com/silverfin/silverfin-cli)

It allows you to quickly (multi)select templates from your local repository and perform an action from the Silverfin CLI on them.

## Installation

- Clone this repository
- Make sure you have [fzf](https://github.com/junegunn/fzf) installed
- Make the script executable: `chmod +x sf-fzf.sh`
- (Optional) Move the script to a directory in your PATH for easier access, or create an alias in your shell configuration file (e.g., `.bashrc`, `.zshrc`):

```bash
alias sf-fzf='/path/to/sf-fzf.sh'
```

## Usage

```bash
./sf-fzf.sh [command]
```
