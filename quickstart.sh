#!/bin/bash
# Quick Start Script for Window-setup
# This script provides an interactive menu for easy setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "═══════════════════════════════════════════════════════"
echo "    🛡️  Window Setup - Security Enhanced Trading     "
echo "═══════════════════════════════════════════════════════"
echo -e "${NC}"

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    echo -e "${GREEN}✓ Detected Linux system${NC}"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    OS="windows"
    echo -e "${GREEN}✓ Detected Windows system${NC}"
else
    echo -e "${YELLOW}⚠ Unknown OS type: $OSTYPE${NC}"
    OS="unknown"
fi

echo ""

# Main menu
while true; do
    echo -e "${BLUE}═══ Main Menu ═══${NC}"
    echo "1. Run Full Setup (Security + MQL5)"
    echo "2. Run Security Setup Only"
    echo "3. Start Security Monitoring"
    echo "4. Open Browser Dashboard"
    echo "5. View Documentation"
    echo "6. Run Tests/Verification"
    echo "7. Exit"
    echo ""
    read -p "Select option [1-7]: " choice
    
    case $choice in
        1)
            echo -e "${GREEN}Starting full setup...${NC}"
            if [ "$OS" == "linux" ]; then
                if [ "$EUID" -eq 0 ]; then
                    ./scripts/linux/setup.sh --install-mql5
                else
                    sudo ./scripts/linux/setup.sh --install-mql5
                fi
            elif [ "$OS" == "windows" ]; then
                powershell -File scripts/windows/setup.ps1 -SecurityMode -InstallMQL5
            fi
            echo -e "${GREEN}✓ Setup completed!${NC}"
            ;;
        2)
            echo -e "${GREEN}Starting security setup...${NC}"
            if [ "$OS" == "linux" ]; then
                if [ "$EUID" -eq 0 ]; then
                    ./scripts/linux/setup.sh
                else
                    sudo ./scripts/linux/setup.sh
                fi
            elif [ "$OS" == "windows" ]; then
                powershell -File scripts/windows/setup.ps1 -SecurityMode
            fi
            echo -e "${GREEN}✓ Security setup completed!${NC}"
            ;;
        3)
            echo -e "${GREEN}Starting security monitoring...${NC}"
            if [ "$OS" == "linux" ]; then
                ./scripts/security/monitor.sh --browser-mode --interval 60 &
                echo -e "${GREEN}✓ Monitoring started in background (PID: $!)${NC}"
            elif [ "$OS" == "windows" ]; then
                powershell -File scripts/security/monitor.ps1 -LocalMode -BrowserMode &
                echo -e "${GREEN}✓ Monitoring started${NC}"
            fi
            ;;
        4)
            echo -e "${GREEN}Opening browser dashboard...${NC}"
            echo "Starting local server on port 8080..."
            cd browser-support
            
            # Try Python 3 first
            if command -v python3 &> /dev/null; then
                echo -e "${GREEN}Using Python 3...${NC}"
                python3 -m http.server 8080 &
                SERVER_PID=$!
            elif command -v python &> /dev/null; then
                echo -e "${GREEN}Using Python...${NC}"
                python -m http.server 8080 &
                SERVER_PID=$!
            else
                echo -e "${YELLOW}⚠ Python not found. Opening file directly...${NC}"
            fi
            
            sleep 2
            
            # Try to open browser
            if command -v xdg-open &> /dev/null; then
                xdg-open http://localhost:8080/dashboard.html
            elif command -v open &> /dev/null; then
                open http://localhost:8080/dashboard.html
            else
                echo -e "${YELLOW}Please open http://localhost:8080/dashboard.html in your browser${NC}"
            fi
            
            cd ..
            echo -e "${GREEN}✓ Dashboard server running (PID: $SERVER_PID)${NC}"
            echo "Press Ctrl+C to stop the server"
            wait $SERVER_PID
            ;;
        5)
            echo -e "${BLUE}═══ Documentation ═══${NC}"
            echo "1. Installation Guide: docs/INSTALLATION.md"
            echo "2. Security Guide: docs/SECURITY.md"
            echo "3. Browser Mode: browser-support/README.md"
            echo "4. Main README: README.md"
            echo ""
            read -p "Enter number to view (or press Enter to skip): " doc_choice
            
            case $doc_choice in
                1) less docs/INSTALLATION.md || cat docs/INSTALLATION.md ;;
                2) less docs/SECURITY.md || cat docs/SECURITY.md ;;
                3) less browser-support/README.md || cat browser-support/README.md ;;
                4) less README.md || cat README.md ;;
                *) echo "Skipping..." ;;
            esac
            ;;
        6)
            echo -e "${GREEN}Running verification tests...${NC}"
            
            # Check directory structure
            echo -e "\n${BLUE}Checking directory structure...${NC}"
            for dir in scripts/windows scripts/linux scripts/security mql5/security mql5/configs browser-support docs; do
                if [ -d "$dir" ]; then
                    echo -e "${GREEN}✓ $dir exists${NC}"
                else
                    echo -e "${RED}✗ $dir missing${NC}"
                fi
            done
            
            # Check files
            echo -e "\n${BLUE}Checking important files...${NC}"
            files=(
                "scripts/windows/setup.ps1"
                "scripts/linux/setup.sh"
                "scripts/security/monitor.ps1"
                "scripts/security/monitor.sh"
                "mql5/security/SecureTrading.mq5"
                "mql5/configs/security.ini"
                "browser-support/dashboard.html"
                "docs/INSTALLATION.md"
                "docs/SECURITY.md"
            )
            
            for file in "${files[@]}"; do
                if [ -f "$file" ]; then
                    echo -e "${GREEN}✓ $file exists${NC}"
                else
                    echo -e "${RED}✗ $file missing${NC}"
                fi
            done
            
            # Check script permissions (Linux only)
            if [ "$OS" == "linux" ]; then
                echo -e "\n${BLUE}Checking script permissions...${NC}"
                for script in scripts/linux/*.sh scripts/security/*.sh; do
                    if [ -x "$script" ]; then
                        echo -e "${GREEN}✓ $script is executable${NC}"
                    else
                        echo -e "${YELLOW}⚠ $script is not executable${NC}"
                    fi
                done
            fi
            
            echo -e "\n${GREEN}Verification completed!${NC}"
            ;;
        7)
            echo -e "${BLUE}Exiting... Stay secure! 🛡️${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1-7.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    echo ""
done
