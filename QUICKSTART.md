# Quick Start Guide

This guide will help you quickly set up security for your Windows development environment, GitHub, VSCode, and Cursor.

## Prerequisites

- Windows 10/11
- Administrator access (for some operations)
- Internet connection

## Quick Setup (5 Minutes)

### Step 1: Run Security Check
Open PowerShell and run:
```powershell
.\setup-windows-security.ps1 -CheckOnly
```

This will check your current security status without making changes.

### Step 2: Setup GitHub SSH
```powershell
.\setup-github-ssh.ps1
```

Follow the prompts to:
1. Generate an SSH key
2. Copy the public key
3. Add it to GitHub

### Step 3: Setup GPG Signing (Optional but Recommended)
```powershell
.\setup-github-gpg.ps1
```

Follow the prompts to:
1. Generate a GPG key
2. Copy the public key
3. Add it to GitHub
4. Configure Git to sign commits

### Step 4: Apply Security Settings
```powershell
.\setup-windows-security.ps1
```

This will enable Windows security features (requires admin).

## What Gets Configured?

### Windows Security
✓ Windows Defender enabled and updated
✓ Windows Firewall enabled
✓ Security settings verified

### GitHub Integration
✓ SSH keys for secure authentication
✓ GPG keys for commit signing
✓ Git configured with your identity

### VSCode/Cursor
✓ Security settings applied
✓ Workspace trust enabled
✓ Telemetry disabled
✓ Recommended extensions

## Verification

### Test SSH Connection
```powershell
ssh -T git@github.com
```

You should see: "Hi [username]! You've successfully authenticated..."

### Test GPG Signing
```powershell
# Make a test commit
git commit --allow-empty -m "Test signed commit"

# Verify it's signed
git log --show-signature -1
```

You should see "Good signature from..."

## Troubleshooting

### SSH Issues
- Ensure SSH keys are in `C:\Users\[YourName]\.ssh\`
- Check that ssh-agent service is running
- Verify public key is added to GitHub

### GPG Issues
- Install GPG from https://www.gnupg.org/download/
- Ensure GPG is in your PATH
- Check Git config: `git config --global --list`

### VSCode/Cursor
- Restart the editor after applying settings
- Check workspace trust settings
- Verify GitHub authentication

## Next Steps

1. Review the full [SECURITY_SETUP.md](SECURITY_SETUP.md) guide
2. Enable GitHub 2FA if not already enabled
3. Create a Personal Access Token for HTTPS operations
4. Set up your preferred development tools
5. Configure additional security measures as needed

## Security Checklist

- [ ] Windows Defender enabled
- [ ] Windows Firewall enabled
- [ ] SSH key generated and added to GitHub
- [ ] GPG key generated and added to GitHub
- [ ] Git configured for signing
- [ ] GitHub 2FA enabled
- [ ] VSCode/Cursor security settings applied
- [ ] SSH connection tested
- [ ] GPG signing tested
- [ ] Backup of SSH and GPG keys created

## Support

For detailed instructions and advanced configuration, see:
- [SECURITY_SETUP.md](SECURITY_SETUP.md) - Complete security guide
- [GitHub Docs](https://docs.github.com/en/authentication)
- [Git Security](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)

## Important Notes

⚠️ **Never commit private keys to Git**
⚠️ **Always use strong passphrases for SSH/GPG keys**
⚠️ **Keep recovery codes in a secure location**
⚠️ **Regularly update Windows and security software**

---

Last Updated: 2025-12-14
