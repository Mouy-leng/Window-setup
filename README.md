# Window-setup

🛡️ **Secure Window Setup for MQL5 Trading with Enhanced Security Features**

A comprehensive setup repository for Windows and Linux systems to run MQL5 (MetaTrader 5) trading platform with advanced security features for user and agent protection. Supports both local execution and browser-based monitoring.

## 🌟 Features

- ✅ **Windows & Linux Support**: Cross-platform setup scripts
- 🔒 **Security-First Design**: Comprehensive security configurations for user and agent operations
- 📊 **MQL5 Trading**: Secure Expert Advisor (EA) implementation with risk management
- 🌐 **Browser Mode**: Web-based monitoring dashboard for real-time security tracking
- 🤖 **Agent Security**: Sandboxed agent execution with resource limits
- 📝 **Comprehensive Logging**: Detailed audit trails for all operations
- 🔍 **Security Monitoring**: Real-time monitoring scripts for threat detection
- 🎯 **Risk Management**: Built-in trading risk controls and position limits

## 📋 Quick Start

### Windows

```powershell
# Clone the repository
git clone https://github.com/Mouy-leng/Window-setup.git
cd Window-setup

# Run setup script (requires Administrator privileges)
.\scripts\windows\setup.ps1 -SecurityMode -InstallMQL5

# Start security monitoring
.\scripts\security\monitor.ps1 -LocalMode -BrowserMode
```

### Linux

```bash
# Clone the repository
git clone https://github.com/Mouy-leng/Window-setup.git
cd Window-setup

# Make scripts executable
chmod +x scripts/linux/*.sh scripts/security/*.sh

# Run setup script
sudo ./scripts/linux/setup.sh --install-mql5

# Start security monitoring
./scripts/security/monitor.sh --browser-mode --interval 60 &
```

### Browser Dashboard

```bash
# Serve the dashboard locally
cd browser-support
python -m http.server 8080

# Open in browser
# Navigate to: http://localhost:8080/dashboard.html
```

## 📁 Repository Structure

```
Window-setup/
├── scripts/
│   ├── windows/          # Windows setup scripts (PowerShell)
│   │   └── setup.ps1     # Main Windows setup script
│   ├── linux/            # Linux setup scripts (Bash)
│   │   └── setup.sh      # Main Linux setup script
│   └── security/         # Security monitoring scripts
│       ├── monitor.ps1   # Windows security monitor
│       └── monitor.sh    # Linux security monitor
├── mql5/
│   ├── security/         # Secure MQL5 Expert Advisors
│   │   └── SecureTrading.mq5  # Security-enhanced EA
│   └── configs/          # MQL5 configurations
│       └── security.ini  # Security configuration file
├── browser-support/
│   ├── dashboard.html    # Web-based monitoring dashboard
│   └── README.md         # Browser mode documentation
└── docs/
    ├── INSTALLATION.md   # Detailed installation guide
    └── SECURITY.md       # Security best practices
```

## 🔐 Security Features

### User Security
- Windows Defender / Antivirus configuration
- Firewall setup and hardening
- User Account Control (UAC) enforcement
- Secure folder creation with restricted permissions
- Network security hardening

### Agent Security
- Sandboxed execution environment
- Resource limits (CPU, Memory)
- Network access restrictions
- Comprehensive logging and auditing
- Process monitoring and threat detection

### MQL5 Trading Security
- DLL import restrictions
- Web request whitelisting
- Risk management controls (max risk, daily limits)
- Secure position sizing
- Trading operation logging
- Account verification

### Browser Mode Security
- Content Security Policy (CSP) enforcement
- No external dependencies
- Local execution only
- Real-time security monitoring
- Secure communication protocols

## 📖 Documentation

- **[Installation Guide](docs/INSTALLATION.md)**: Step-by-step setup instructions
- **[Security Guide](docs/SECURITY.md)**: Comprehensive security best practices
- **[Browser Mode](browser-support/README.md)**: Browser dashboard documentation

## 🎯 Use Cases

1. **Automated Trading**: Run MQL5 Expert Advisors with enhanced security
2. **Local Research**: Conduct trading research in a secure environment
3. **Remote Monitoring**: Monitor trading activity via browser dashboard
4. **Security Auditing**: Track and audit all trading operations
5. **Job Automation**: Run automated trading jobs with safety controls

## ⚙️ Configuration

### Basic Security Configuration

```ini
[Security]
EnableSecurity=true
AllowDllImports=false
AllowWebRequests=true
AllowedURLs=localhost,127.0.0.1
MaxDailyTrades=50
MaxRiskPerTrade=2.0
```

### Agent Configuration

```ini
[Agent]
SandboxEnabled=true
MaxMemoryMB=512
MaxCPUPercent=50
AllowedDomains=localhost,api.tradingview.com
```

## 🚀 Requirements

- **Windows**: Windows 10/11, PowerShell 5.1+, 4GB RAM
- **Linux**: Ubuntu 20.04+/Debian 11+, Bash, 4GB RAM
- **MQL5**: MetaTrader 5 platform, Trading account
- **Browser**: Modern web browser (Chrome, Firefox, Edge, Safari)

## 🛠️ Advanced Features

### Security Monitoring

Real-time monitoring of:
- Process integrity
- Network connections
- File system changes
- Agent activity
- Browser security

### Risk Management

Built-in controls:
- Maximum risk per trade
- Daily trade limits
- Position size limits
- Balance thresholds
- Automated stop-loss

### Logging & Auditing

Comprehensive logging:
- All trading operations
- Security events
- Agent activities
- System changes
- Network access

## 🤝 Contributing

Contributions are welcome! Please read the contribution guidelines before submitting pull requests.

## ⚠️ Disclaimer

This software is provided for educational and research purposes. Always test on demo accounts before using with real money. Trading involves risk, and you should never trade with money you cannot afford to lose. The authors are not responsible for any financial losses.

## 📄 License

This project is provided as-is for personal and educational use. See LICENSE file for details.

## 🔗 Resources

- [MetaTrader 5 Documentation](https://www.metatrader5.com/)
- [MQL5 Language Reference](https://www.mql5.com/en/docs)
- [Windows Security Best Practices](https://docs.microsoft.com/en-us/security/)
- [Linux Security Guide](https://www.linux.org/docs/)

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Mouy-leng/Window-setup/issues)
- **Documentation**: Check the `docs/` directory
- **Community**: [MQL5 Community](https://www.mql5.com/)

---

**Made with ❤️ for secure trading**
