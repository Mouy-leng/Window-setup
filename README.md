# Window Security Setup

A comprehensive security setup guide and automation scripts for Windows development environment, GitHub integration, VSCode, and Cursor.

## 🔒 What This Provides

This repository contains scripts, configurations, and documentation to securely set up:
- **Windows Security**: Defender, Firewall, BitLocker, and system hardening
- **GitHub Integration**: SSH keys, GPG commit signing, and secure authentication
- **VSCode Security**: Workspace trust, secure settings, and recommended extensions
- **Cursor Security**: Privacy settings and secure configuration

## 🚀 Quick Start

```powershell
# 1. Clone this repository
git clone https://github.com/Mouy-leng/Window-setup.git
cd Window-setup

# 2. Check current security status
.\setup-windows-security.ps1 -CheckOnly

# 3. Setup GitHub SSH authentication
.\setup-github-ssh.ps1

# 4. Setup GPG commit signing (recommended)
.\setup-github-gpg.ps1

# 5. Apply Windows security settings (requires admin)
.\setup-windows-security.ps1
```

See [QUICKSTART.md](QUICKSTART.md) for detailed quick start instructions.

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
- **[SECURITY_SETUP.md](SECURITY_SETUP.md)** - Complete security guide with detailed instructions
- **.vscode/** - VSCode security configuration templates
- **.cursor/** - Cursor security configuration templates

## 🛠️ Scripts

| Script | Description |
|--------|-------------|
| `setup-windows-security.ps1` | Check and configure Windows security features |
| `setup-github-ssh.ps1` | Generate and configure SSH keys for GitHub |
| `setup-github-gpg.ps1` | Generate and configure GPG keys for commit signing |

## ✅ Features

### Windows Security
- ✓ Windows Defender configuration
- ✓ Firewall management
- ✓ BitLocker encryption check
- ✓ Security status reporting

### GitHub Integration
- ✓ SSH key generation (Ed25519/RSA)
- ✓ GPG key generation and configuration
- ✓ Automatic Git configuration
- ✓ Connection testing

### Editor Configuration
- ✓ VSCode security settings
- ✓ Cursor privacy settings
- ✓ Workspace trust configuration
- ✓ Extension recommendations

## 📋 Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later
- Git for Windows
- Administrator access (for some features)

## 🔐 Security Best Practices

This setup implements security best practices including:
- Strong encryption algorithms (Ed25519, RSA 4096)
- Commit signing with GPG
- Secure credential storage
- Workspace trust in editors
- Telemetry disabled
- Firewall and antivirus enabled

## 📖 Usage

### Security Check
```powershell
# Check security status without making changes
.\setup-windows-security.ps1 -CheckOnly
```

### GitHub SSH Setup
```powershell
# Interactive SSH key generation
.\setup-github-ssh.ps1
```

### GPG Signing Setup
```powershell
# Interactive GPG key generation
.\setup-github-gpg.ps1
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests for:
- Documentation improvements
- Script enhancements
- Security recommendations
- Bug fixes

## ⚠️ Important Security Notes

- **Never commit private keys** (SSH, GPG) to repositories
- **Use strong passphrases** for all keys
- **Enable 2FA** on GitHub and other services
- **Backup your keys** securely
- **Keep software updated** regularly

## 📝 License

This is a personal security setup repository. Feel free to use and adapt for your own needs.

## 🆘 Support

For issues or questions:
1. Check the [SECURITY_SETUP.md](SECURITY_SETUP.md) guide
2. Review [QUICKSTART.md](QUICKSTART.md)
3. Search existing issues
4. Create a new issue with details

---

**Last Updated**: 2025-12-14 
