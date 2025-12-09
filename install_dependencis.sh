#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root or with sudo
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        if ! command -v sudo &> /dev/null; then
            log_error "This script requires root privileges. Please run as root."
            exit 1
        fi
        SUDO="sudo"
    else
        SUDO=""
    fi
}

# Install k3s
install_k3s() {
    if command -v k3s &> /dev/null; then
        log_info "k3s already installed: $(k3s --version | head -1)"
        return 0
    fi
    
    log_info "Installing k3s..."
    curl -sfL https://get.k3s.io | sh -
    
    # Wait for node to be ready
    log_info "Waiting for k3s node to be ready..."
    $SUDO k3s kubectl wait --for=condition=Ready node --all --timeout=60s || true
    $SUDO k3s kubectl get node
    log_info "k3s installed successfully"
}

# Install Go
install_golang() {
    if command -v go &> /dev/null; then
        log_info "Go already installed: $(go version)"
        return 0
    fi
    
    log_info "Installing Go..."
    GO_VERSION="1.22.4"  # Update as needed
    
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) GO_ARCH="amd64" ;;
        aarch64) GO_ARCH="arm64" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    $SUDO rm -rf /usr/local/go
    $SUDO tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    rm "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    
    # Add to PATH if not already there
    if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi
    if ! grep -q '$HOME/go/bin' ~/.bashrc; then
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    fi
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    
    log_info "Go installed: $(go version)"
}

# Install Python
install_python() {
    if command -v python3 &> /dev/null; then
        log_info "Python already installed: $(python3 --version)"
        # Ensure pip is installed
        if ! command -v pip3 &> /dev/null; then
            log_info "Installing pip..."
            $SUDO apt-get update && $SUDO apt-get install -y python3-pip
        fi
        return 0
    fi
    
    log_info "Installing Python..."
    $SUDO apt-get update
    $SUDO apt-get install -y python3 python3-pip python3-venv
    log_info "Python installed: $(python3 --version)"
}

# Install Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log_info "Docker already installed: $(docker --version)"
        return 0
    fi
    
    log_info "Installing Docker..."
    
    # Add Docker's official GPG key:
    sudo apt update
    sudo apt install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    sudo apt update
    
    # Install Docker
    $SUDO apt-get update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    $SUDO usermod -aG docker $USER || true
    
    log_info "Docker installed: $(docker --version)"
    log_warn "You may need to log out and back in for docker group permissions to take effect"
}

# Main
main() {
    log_info "Starting pre-install script..."
    check_sudo
    
    install_k3s
    install_golang
    install_python
    install_docker
    
    log_info "All installations complete!"
    echo ""
    echo "Installed versions:"
    command -v k3s &> /dev/null && echo "  k3s: $(k3s --version 2>/dev/null | head -1)"
    command -v go &> /dev/null && echo "  Go: $(go version)"
    command -v python3 &> /dev/null && echo "  Python: $(python3 --version)"
    command -v docker &> /dev/null && echo "  Docker: $(docker --version)"
}

main "$@"
