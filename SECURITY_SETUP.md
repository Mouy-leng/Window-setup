# Windows Security Setup Guide

This guide provides comprehensive security setup instructions for Windows development environment, GitHub integration, VSCode, and Cursor.

## Table of Contents
1. [Windows Security Configuration](#windows-security-configuration)
2. [GitHub Security Setup](#github-security-setup)
3. [VSCode Security Configuration](#vscode-security-configuration)
4. [Cursor Security Configuration](#cursor-security-configuration)
5. [Best Practices](#best-practices)

---

## Windows Security Configuration

### 1. Enable Windows Security Features

#### Windows Defender
```powershell
# Verify Windows Defender is enabled
Get-MpComputerStatus

# Update Windows Defender definitions
Update-MpSignature

# Run a quick scan
Start-MpScan -ScanType QuickScan
```

#### Windows Firewall
```powershell
# Check firewall status
Get-NetFirewallProfile | Select-Object Name, Enabled

# Enable firewall for all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
```

#### BitLocker (Drive Encryption)
```powershell
# Check BitLocker status
Get-BitLockerVolume

# Enable BitLocker on C: drive (requires admin)
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly
```

### 2. Windows Updates
```powershell
# Install PSWindowsUpdate module
Install-Module PSWindowsUpdate -Force

# Check for updates
Get-WindowsUpdate

# Install all available updates
Install-WindowsUpdate -AcceptAll -AutoReboot
```

### 3. User Account Control (UAC)
- Keep UAC enabled at recommended level
- Never disable UAC for security reasons

### 4. Secure Credential Storage
```powershell
# Use Windows Credential Manager for storing credentials
cmdkey /add:github.com /user:your-username /pass:your-token

# List stored credentials
cmdkey /list
```

---

## GitHub Security Setup

### 1. SSH Key Setup

#### Generate SSH Key (Ed25519 - Recommended)
```powershell
# Open PowerShell and run:
ssh-keygen -t ed25519 -C "your-email@example.com"

# When prompted, save to default location: C:\Users\YourUsername\.ssh\id_ed25519
# Set a strong passphrase
```

#### Alternative: RSA Key (if Ed25519 not supported)
```powershell
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

#### Add SSH Key to SSH Agent
```powershell
# Start SSH Agent
Start-Service ssh-agent

# Add your SSH key
ssh-add C:\Users\YourUsername\.ssh\id_ed25519
```

#### Add SSH Public Key to GitHub
1. Copy your public key:
```powershell
Get-Content C:\Users\YourUsername\.ssh\id_ed25519.pub | Set-Clipboard
```
2. Go to GitHub → Settings → SSH and GPG keys → New SSH key
3. Paste the key and give it a descriptive title (e.g., "Windows-Work-Laptop")
4. Save the key

#### Test SSH Connection
```powershell
ssh -T git@github.com
```

### 2. GPG Signing Setup

#### Install GPG for Windows
Download and install from: https://www.gnupg.org/download/

#### Generate GPG Key
```powershell
gpg --full-generate-key

# Select:
# - Key type: RSA and RSA
# - Key size: 4096
# - Expiration: 1y (yearly renewal recommended)
# - Enter your name and email (must match GitHub email)
```

#### List GPG Keys
```powershell
gpg --list-secret-keys --keyid-format=long
```

#### Export GPG Public Key
```powershell
# Replace KEY_ID with your key ID from the list
gpg --armor --export KEY_ID | Set-Clipboard
```

#### Add GPG Key to GitHub
1. Go to GitHub → Settings → SSH and GPG keys → New GPG key
2. Paste the GPG public key
3. Save the key

#### Configure Git to Use GPG
```powershell
# Set GPG key for signing
git config --global user.signingkey KEY_ID

# Enable commit signing by default
git config --global commit.gpgsign true

# Configure GPG program path
git config --global gpg.program "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
```

### 3. Personal Access Tokens (PAT)

#### Create a PAT
1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Select scopes based on needs:
   - `repo` - Full control of private repositories
   - `workflow` - Update GitHub Action workflows
   - `read:org` - Read org and team membership
   - `gist` - Create gists

#### Secure Storage of PAT
```powershell
# Store in Windows Credential Manager
git config --global credential.helper wincred

# Or use Git Credential Manager
# Download from: https://github.com/git-ecosystem/git-credential-manager
```

### 4. Two-Factor Authentication (2FA)
1. Go to GitHub → Settings → Password and authentication
2. Enable Two-factor authentication
3. Use authenticator app (Microsoft Authenticator, Google Authenticator, Authy)
4. Save recovery codes in a secure location

### 5. Git Configuration Security
```powershell
# Set your identity
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"

# Verify email is the one added to GitHub
git config --global user.email

# Prevent accidental commits to main/master
git config --global init.defaultBranch main

# Enable credential storage (Windows)
git config --global credential.helper wincred

# Or use Git Credential Manager (recommended)
git config --global credential.helper manager
```

---

## VSCode Security Configuration

### 1. Install VSCode Security Extensions
```json
{
  "recommendations": [
    "ms-vscode.vscode-github-authentication",
    "github.vscode-pull-request-github",
    "eamodio.gitlens",
    "donjayamanne.githistory",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

### 2. VSCode Settings for Security

Create or update `.vscode/settings.json` in your workspace:
```json
{
  "security.workspace.trust.enabled": true,
  "security.workspace.trust.startupPrompt": "always",
  "security.workspace.trust.emptyWindow": false,
  
  "git.confirmSync": true,
  "git.enableCommitSigning": true,
  "git.autofetch": false,
  "git.confirmEmptyCommits": true,
  
  "files.exclude": {
    "**/.git": true,
    "**/.env": true,
    "**/*.key": true,
    "**/*.pem": true
  },
  
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/node_modules/**": true
  },
  
  "terminal.integrated.enablePersistentSessions": false,
  "terminal.integrated.shellIntegration.enabled": true,
  
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": true,
  
  "telemetry.telemetryLevel": "off",
  
  "http.proxyStrictSSL": true,
  
  "editor.formatOnSave": false
}
```

### 3. VSCode User Settings for Security

Update user settings (File → Preferences → Settings → settings.json):
```json
{
  "security.workspace.trust.enabled": true,
  "git.enableCommitSigning": true,
  "telemetry.telemetryLevel": "off",
  "extensions.ignoreRecommendations": false,
  "update.mode": "manual"
}
```

### 4. GitHub Integration in VSCode
1. Install "GitHub Pull Requests and Issues" extension
2. Sign in to GitHub: Ctrl+Shift+P → "GitHub: Sign in"
3. Authorize VSCode to access GitHub
4. Use device flow authentication for better security

### 5. Workspace Trust
- Always review workspace settings before trusting
- Only open projects from trusted sources
- Review .vscode folder contents before trusting workspace

---

## Cursor Security Configuration

### 1. Cursor Settings for Security

Create or update Cursor settings:
```json
{
  "security.workspace.trust.enabled": true,
  "security.workspace.trust.startupPrompt": "always",
  
  "cursor.privacy.enableTelemetry": false,
  "cursor.privacy.shareData": false,
  
  "git.confirmSync": true,
  "git.enableCommitSigning": true,
  "git.autofetch": false,
  
  "files.exclude": {
    "**/.git": true,
    "**/.env": true,
    "**/*.key": true,
    "**/*.pem": true,
    "**/*.token": true
  },
  
  "terminal.integrated.enablePersistentSessions": false,
  
  "editor.suggest.showSnippets": true,
  "editor.suggest.showWords": false
}
```

### 2. GitHub Integration in Cursor
1. Cursor uses same authentication as VSCode
2. Sign in to GitHub through Cursor
3. Verify SSH keys are configured correctly
4. Test git operations from Cursor terminal

### 3. API Key Security for Cursor AI
- Store Cursor API keys securely
- Never commit API keys to repositories
- Use environment variables or secure vaults for API keys
- Regularly rotate API keys

### 4. Cursor Privacy Settings
1. Go to Settings → Privacy
2. Disable telemetry if not needed
3. Review data sharing settings
4. Configure AI model preferences

---

## Best Practices

### 1. Password Management
- Use a password manager (1Password, LastPass, Bitwarden)
- Enable password manager browser extension
- Use unique, strong passwords for each service
- Enable password manager CLI tools for development

### 2. Regular Security Updates
```powershell
# Update Windows
Install-WindowsUpdate -AcceptAll

# Update VSCode extensions
code --update-extensions

# Update Git
winget upgrade --id Git.Git

# Update Node.js (if used)
winget upgrade --id OpenJS.NodeJS
```

### 3. Backup Strategy
- Backup SSH keys securely
- Backup GPG keys with passphrase protection
- Store recovery codes in multiple secure locations
- Use encrypted backup solutions (OneDrive, Dropbox with encryption)

### 4. Code Scanning and Secrets Detection
```powershell
# Install git-secrets to prevent committing secrets
# Download from: https://github.com/awslabs/git-secrets

# Initialize git-secrets in a repository
git secrets --install

# Add patterns to detect
git secrets --register-aws
git secrets --add 'github_pat_[a-zA-Z0-9]+'
git secrets --add 'ghp_[a-zA-Z0-9]+'
```

### 5. Network Security
- Use VPN when on public networks
- Avoid public WiFi for sensitive operations
- Enable Windows Firewall
- Review and restrict network access for applications

### 6. Browser Security
- Use browser with good security (Edge, Chrome, Firefox)
- Install security extensions (uBlock Origin, HTTPS Everywhere)
- Enable password manager extension
- Clear browser data regularly

### 7. Environment Variables Security
```powershell
# Never commit .env files
# Add to .gitignore
echo ".env" >> .gitignore

# Use dotenv for local development
# Store production secrets in secure vaults (Azure Key Vault, AWS Secrets Manager)
```

### 8. Code Review and Signing
- Always review code before committing
- Sign all commits with GPG
- Verify signatures on pulled changes
- Enable branch protection on important repositories

### 9. Regular Security Audits
- Review GitHub security alerts weekly
- Check Dependabot alerts
- Update dependencies regularly
- Review access tokens and remove unused ones
- Review SSH keys and remove old/unused keys

### 10. Incident Response
- If credentials are compromised:
  1. Immediately revoke the compromised credential
  2. Generate new credentials
  3. Review recent activity for unauthorized access
  4. Update all affected services
  5. Enable additional security measures (2FA if not enabled)

---

## Quick Setup Checklist

- [ ] Enable Windows Defender and Firewall
- [ ] Enable BitLocker encryption
- [ ] Install Windows updates
- [ ] Generate SSH key (Ed25519)
- [ ] Add SSH key to GitHub
- [ ] Generate GPG key
- [ ] Add GPG key to GitHub
- [ ] Configure Git for GPG signing
- [ ] Enable GitHub 2FA
- [ ] Create and store GitHub PAT securely
- [ ] Install Git Credential Manager
- [ ] Configure VSCode security settings
- [ ] Configure Cursor security settings
- [ ] Install security extensions
- [ ] Setup git-secrets or similar tool
- [ ] Create .gitignore for sensitive files
- [ ] Backup SSH and GPG keys securely
- [ ] Setup password manager
- [ ] Review and configure firewall rules

---

## Additional Resources

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [VSCode Security](https://code.visualstudio.com/docs/editor/workspace-trust)
- [Git Security](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
- [Windows Security Documentation](https://docs.microsoft.com/en-us/windows/security/)
- [SSH Key Management](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [GPG Signing](https://docs.github.com/en/authentication/managing-commit-signature-verification)

---

## Support and Issues

If you encounter any issues during setup:
1. Check the error messages carefully
2. Verify all prerequisites are installed
3. Review the relevant documentation
4. Search for similar issues on GitHub/Stack Overflow
5. Create an issue in this repository if needed

Last Updated: 2025-12-14
