# Troubleshooting Guide

Common issues and solutions for Windows security setup, GitHub integration, VSCode, and Cursor.

## Table of Contents
- [Windows Security Issues](#windows-security-issues)
- [SSH Connection Problems](#ssh-connection-problems)
- [GPG Signing Issues](#gpg-signing-issues)
- [Git Configuration Problems](#git-configuration-problems)
- [VSCode/Cursor Issues](#vscodecursor-issues)
- [General Tips](#general-tips)

---

## Windows Security Issues

### Windows Defender Not Running

**Problem**: Windows Defender is disabled or not running

**Solutions**:
1. Check if third-party antivirus is installed (may disable Defender)
2. Enable Windows Defender:
   ```powershell
   Set-MpPreference -DisableRealtimeMonitoring $false
   ```
3. Run as Administrator and restart Windows Security service:
   ```powershell
   Restart-Service WinDefend
   ```

### Firewall Won't Enable

**Problem**: Windows Firewall cannot be enabled

**Solutions**:
1. Check if firewall service is running:
   ```powershell
   Get-Service mpssvc
   Start-Service mpssvc
   ```
2. Reset firewall to defaults:
   ```powershell
   netsh advfirewall reset
   ```
3. Check Group Policy settings (in enterprise environments)

### BitLocker Not Available

**Problem**: BitLocker option not showing or unavailable

**Solutions**:
1. Check Windows edition (BitLocker requires Pro, Enterprise, or Education)
2. Check if TPM is enabled in BIOS:
   ```powershell
   Get-Tpm
   ```
3. For systems without TPM, enable via Group Policy

---

## SSH Connection Problems

### "Permission denied (publickey)"

**Problem**: SSH authentication fails when connecting to GitHub

**Solutions**:
1. Verify SSH key is added to ssh-agent:
   ```powershell
   ssh-add -l
   ```
   If not listed, add it:
   ```powershell
   ssh-add C:\Users\YourName\.ssh\id_ed25519
   ```

2. Check if public key is added to GitHub:
   - Go to GitHub → Settings → SSH and GPG keys
   - Verify your key is listed

3. Test with verbose output:
   ```powershell
   ssh -vT git@github.com
   ```

4. Check SSH config file (`C:\Users\YourName\.ssh\config`):
   ```
   Host github.com
       HostName github.com
       User git
       IdentityFile ~/.ssh/id_ed25519
   ```

### "Could not open a connection to your authentication agent"

**Problem**: ssh-agent is not running

**Solutions**:
1. Start ssh-agent service:
   ```powershell
   Get-Service ssh-agent | Set-Service -StartupType Automatic
   Start-Service ssh-agent
   ```

2. Or run ssh-agent in current session:
   ```powershell
   Start-Service ssh-agent
   ```

### SSH Key Passphrase Not Saved

**Problem**: Prompted for passphrase every time

**Solutions**:
1. Add key to ssh-agent (saves passphrase):
   ```powershell
   ssh-add C:\Users\YourName\.ssh\id_ed25519
   ```

2. Configure ssh-agent to start automatically:
   ```powershell
   Set-Service ssh-agent -StartupType Automatic
   ```

---

## GPG Signing Issues

### "gpg: signing failed: No secret key"

**Problem**: Git cannot find GPG signing key

**Solutions**:
1. List available GPG keys:
   ```powershell
   gpg --list-secret-keys --keyid-format=long
   ```

2. Set the correct key in Git:
   ```powershell
   git config --global user.signingkey YOUR_KEY_ID
   ```

3. Verify email matches:
   ```powershell
   git config --global user.email
   ```
   Must match the email in your GPG key

### "gpg: skipped: No secret key"

**Problem**: GPG key not found or expired

**Solutions**:
1. Check key expiration:
   ```powershell
   gpg --list-keys
   ```

2. Extend key expiration:
   ```powershell
   gpg --edit-key YOUR_KEY_ID
   # In GPG prompt: expire, then save
   ```

3. Generate new key if expired:
   ```powershell
   .\setup-github-gpg.ps1
   ```

### "gpg failed to sign the data"

**Problem**: GPG program not found or not configured

**Solutions**:
1. Find GPG executable path:
   ```powershell
   Get-Command gpg
   ```

2. Configure Git to use GPG:
   ```powershell
   git config --global gpg.program "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
   ```

3. Or if using GPG4Win:
   ```powershell
   git config --global gpg.program "C:\Program Files (x86)\Gpg4win\bin\gpg.exe"
   ```

### GPG Passphrase Prompt Not Appearing

**Problem**: GPG commits hang or fail silently

**Solutions**:
1. Use gpg-agent for caching:
   ```powershell
   gpg-connect-agent /bye
   ```

2. Set pinentry program in `gpg-agent.conf`:
   ```
   pinentry-program "C:\Program Files (x86)\GnuPG\bin\pinentry.exe"
   ```

---

## Git Configuration Problems

### Git Commands Not Found

**Problem**: Git commands don't work in PowerShell

**Solutions**:
1. Verify Git is installed:
   ```powershell
   Get-Command git
   ```

2. Add Git to PATH:
   - System Properties → Environment Variables
   - Add `C:\Program Files\Git\cmd` to PATH

3. Reinstall Git from https://git-scm.com/download/win

### Credential Helper Issues

**Problem**: Git repeatedly asks for credentials

**Solutions**:
1. Configure Windows Credential Manager:
   ```powershell
   git config --global credential.helper wincred
   ```

2. Or use Git Credential Manager:
   ```powershell
   git config --global credential.helper manager
   ```

3. Clear stored credentials if they're wrong:
   ```powershell
   cmdkey /list
   cmdkey /delete:git:https://github.com
   ```

### Line Ending Problems

**Problem**: Files show modifications due to line ending differences

**Solutions**:
1. Configure autocrlf for Windows:
   ```powershell
   git config --global core.autocrlf true
   ```

2. Add `.gitattributes` file to repository:
   ```
   * text=auto
   *.sh text eol=lf
   *.bat text eol=crlf
   ```

---

## VSCode/Cursor Issues

### Workspace Not Trusted

**Problem**: Features disabled due to untrusted workspace

**Solutions**:
1. Click "Trust Workspace" when prompted
2. Review workspace contents before trusting
3. Configure trust settings in VSCode:
   - File → Preferences → Settings
   - Search for "workspace trust"

### GitHub Authentication Failed

**Problem**: Cannot sign in to GitHub from editor

**Solutions**:
1. Use device code flow:
   - Command Palette (Ctrl+Shift+P)
   - "GitHub: Sign in with Device Code"

2. Check firewall settings (allow VSCode/Cursor)

3. Clear VSCode/Cursor cache and retry

### Git Integration Not Working

**Problem**: Git features not available in editor

**Solutions**:
1. Ensure Git is installed and in PATH
2. Restart editor after installing Git
3. Check Git settings in editor:
   ```json
   {
     "git.enabled": true,
     "git.path": "C:\\Program Files\\Git\\cmd\\git.exe"
   }
   ```

### Extensions Won't Install

**Problem**: Security settings prevent extension installation

**Solutions**:
1. Check workspace trust settings
2. Verify internet connection
3. Check firewall rules for editor
4. Try installing from VSIX file

---

## General Tips

### PowerShell Execution Policy

If scripts won't run due to execution policy:

```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run script with bypass (one-time)
PowerShell -ExecutionPolicy Bypass -File .\script.ps1
```

### Administrator Privileges

Some operations require admin rights:

1. Right-click PowerShell → Run as Administrator
2. Or from PowerShell:
   ```powershell
   Start-Process powershell -Verb RunAs
   ```

### Check Service Status

Check if required services are running:

```powershell
# SSH Agent
Get-Service ssh-agent

# Windows Defender
Get-Service WinDefend

# Firewall
Get-Service mpssvc

# Start a service
Start-Service ssh-agent
```

### Environment Variables

Add to PATH permanently:

```powershell
# Add to user PATH
$path = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", $path + ";C:\NewPath", "User")

# Refresh environment in current session
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
```

### Log Files

Check logs for errors:

- Windows Event Viewer: `eventvwr.msc`
- Git operations: `$env:GIT_TRACE=1 git <command>`
- GPG operations: Add `--verbose` flag

### Reset Git Configuration

If configuration is corrupted:

```powershell
# View all config
git config --global --list

# Remove specific setting
git config --global --unset user.name

# Edit config file directly
git config --global --edit

# Remove all global config (careful!)
# Backup first: copy C:\Users\YourName\.gitconfig
git config --global --unset-all
```

### Backup Important Files

Always backup before major changes:

```powershell
# Backup .gitconfig
Copy-Item $HOME\.gitconfig $HOME\.gitconfig.backup

# Backup SSH keys
Copy-Item $HOME\.ssh $HOME\.ssh.backup -Recurse

# Backup GPG keys
gpg --export-secret-keys > gpg-backup.asc
```

---

## Getting More Help

If you're still having issues:

1. **Check Documentation**:
   - Review [SECURITY_SETUP.md](SECURITY_SETUP.md)
   - Review [QUICKSTART.md](QUICKSTART.md)

2. **Search Online**:
   - GitHub Docs: https://docs.github.com
   - Stack Overflow: https://stackoverflow.com
   - Git Documentation: https://git-scm.com/doc

3. **Enable Verbose Output**:
   ```powershell
   # SSH
   ssh -vvv git@github.com
   
   # Git
   $env:GIT_TRACE=1
   git <command>
   
   # GPG
   gpg --verbose <command>
   ```

4. **Create an Issue**:
   - Include error messages
   - Include steps to reproduce
   - Include your environment details (Windows version, Git version, etc.)

---

Last Updated: 2025-12-14
