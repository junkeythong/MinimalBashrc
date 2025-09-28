# MinimalBashrc

I'm the type of person who doesn't like fancy or redundant things.
Here is my streamlined bashrc file containing only the things I really need and nothing else.
Please get rid of anything you feel is unnecessary.

## 🚀 Key Features

### ⚙️ **Kubernetes Integration**
- **Namespace Management**: `kns` function for easy namespace switching
- **Multi-cluster Support**: `ek` function for kubeconfig switching
- **Pod Utilities**: `ctn` for container inspection, `po` for pod listing
- **Auto-initialization**: Creates default working namespace on startup
- **Safety Features**: Highlights dangerous default namespace usage

### 🔧 **Git Enhancements**
- **Smart Aliases**: `gits`, `gitb`, `gitc`, `gitl` for common operations
- **Submodule Support**: `gitp` pulls with automatic submodule updates
- **Branch Comparison**: `headsgit` compares local/remote/fetch heads
- **Safety Warnings**: Visual alerts for master/main branch usage
- **Commit Helpers**: Quick amend and change tracking functions

### 🎨 **Intelligent Prompt**
The custom prompt displays contextual information:
- 🌐/💻 **Location indicator** (VPS/Local)
- 💰 **Bitcoin price** (because why not?)
- 📊 **System stats** (Docker containers, screen sessions)
- ⏰ **Timestamp** for debugging
- 🖥️ **Hostname** for multi-server workflows
- ☸️ **Kubernetes context** (highlighted if non-default)
- 📁 **Namespace** (highlighted if dangerous)
- 🌿 **Git branch** (highlighted if master/main)
- 💬 **Last commit message** (prevents wrong amends)
- 📂 **Current directory**

### 🛠️ **Utility Functions**
- **Repository Sync**: `reposync` for main→test repo synchronization
- **Quick Navigation**: `cd1`, `cd2` for frequent directories
- **Bashrc Management**: `editbash`, `sourcebash` for quick config changes
- **System Monitoring**: Docker and screen session counters

## 📋 Function Reference

### Kubernetes Functions
```bash
kns [namespace]     # Switch to namespace or show current
ek [config]         # Switch kubeconfig or show current
ctn <pod_name>      # List all containers in a pod
ns [args]           # List namespaces by creation time
po [args]           # List pods in current namespace
```

### Git Functions
```bash
gitp [args]         # Git pull with submodule update
gitpush [args]      # Git push wrapper
gitchanges          # Show files changed in last commit
gitamend            # Amend to current commit (no edit)
headsgit            # Compare local/remote/fetch heads
```

### Utility Functions
```bash
reposync            # Sync main repo to test repo
cd1                 # Navigate to main repository
cd2                 # Navigate to test repository
editbash            # Edit bashrc file
sourcebash          # Reload bashrc configuration
```

### Useful Aliases
```bash
# Navigation
..                  # cd ..
...                 # cd ../..

# Enhanced ls
ll                  # ls -la (detailed list)
la                  # ls -A (show hidden)
l                   # ls -CF (classify)

# Git shortcuts
gits                # git status
gitb                # git branch
gitc                # git checkout
gitl                # git log --oneline

# Safe operations
cp, mv, rm          # Interactive mode by default
```

## 🔧 Installation & Setup

1. **Backup your current bashrc**:
   ```bash
   cp ~/.bashrc ~/.bashrc.backup
   ```

2. **Copy the configuration**:
   ```bash
   cp my_bashrc ~/.bashrc
   ```

3. **Customize paths** (edit these in the file):
   ```bash
   # Update these paths to match your setup
   cd1() { cd /path/to/main_repo; }
   cd2() { cd /path/to/test_repo; }

   # Update repository sync paths
   reposync() {
       local source="/your/main-repo"
       local dest="/your/test-repo"
       # ...
   }
   ```

4. **Set your default context**:
   ```bash
   export DEFAULT_CONTEXT="your_working_context"
   export DEFAULT_NS="your_working_namespace"
   ```

5. **Reload your shell**:
   ```bash
   source ~/.bashrc
   ```

## 🖥️ Terminal Screenshots

Demo from terminal on macOS:
<p align="center"><img src="terminal_output.png" alt="terminal output image"></p>

Another terminal example:
<p align="center"><img src="terminal_output-2.png" alt="terminal output image"></p>

## 🔧 Customization

### Colors
All colors are defined in the `COLOR DEFINITIONS` section. Modify these variables to match your terminal theme:
```bash
RED="\[\e[01;31m\]"
GREEN="\[\e[01;32m\]"
# ... etc
```

### Prompt Components
Enable/disable prompt components by modifying the `reload_ps()` function. Comment out unwanted elements:
```bash
# local btc_format="${GREEN}(\$(get_btc_price))${RESET}"  # Disable BTC price
```

### Platform Compatibility
- **Linux**: Works out of the box
- **macOS**: May need to adjust some commands (e.g., `ls` flags)
- **WSL**: Should work with minimal adjustments

## 🤝 Contributing

Feel free to suggest improvements or report issues. This configuration prioritizes:
1. **Functionality over aesthetics**
2. **Performance over features**
3. **Clarity over cleverness**

## 📝 Notes

- Colors are optimized for light terminal themes
- Bitcoin price requires `curl` and `jq`
- Kubernetes functions require `kubectl`
- Some functions assume specific directory structures
- The prompt updates dynamically on each command

---

*Keep it minimal, keep it functional.* ⚡
