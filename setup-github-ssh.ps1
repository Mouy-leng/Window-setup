# GitHub SSH Setup Script
# This script helps set up SSH keys for GitHub authentication

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "GitHub SSH Key Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# SSH directory
$sshDir = "$env:USERPROFILE\.ssh"

# Create .ssh directory if it doesn't exist
if (-not (Test-Path $sshDir)) {
    Write-Host "Creating .ssh directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    Write-Host "[OK] .ssh directory created at $sshDir" -ForegroundColor Green
} else {
    Write-Host "[OK] .ssh directory already exists" -ForegroundColor Green
}

# Get user email
$email = Read-Host "Enter your GitHub email address"

if ([string]::IsNullOrWhiteSpace($email)) {
    Write-Host "[ERROR] Email address is required" -ForegroundColor Red
    exit 1
}

# Ask for key type
Write-Host ""
Write-Host "Select SSH key type:" -ForegroundColor Yellow
Write-Host "1. Ed25519 (Recommended - more secure and faster)" -ForegroundColor Gray
Write-Host "2. RSA 4096 (Compatible with older systems)" -ForegroundColor Gray
$keyType = Read-Host "Enter choice (1 or 2)"

$keyFile = ""
$keyCommand = ""

if ($keyType -eq "1") {
    $keyFile = "$sshDir\id_ed25519"
    $keyCommand = "ssh-keygen -t ed25519 -C `"$email`""
    Write-Host "[OK] Using Ed25519 key type" -ForegroundColor Green
} elseif ($keyType -eq "2") {
    $keyFile = "$sshDir\id_rsa"
    $keyCommand = "ssh-keygen -t rsa -b 4096 -C `"$email`""
    Write-Host "[OK] Using RSA 4096 key type" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Invalid choice. Exiting." -ForegroundColor Red
    exit 1
}

# Check if key already exists
if (Test-Path $keyFile) {
    Write-Host ""
    Write-Host "[WARNING] SSH key already exists at $keyFile" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (yes/no)"
    if ($overwrite -ne "yes") {
        Write-Host "[INFO] Keeping existing key. Exiting." -ForegroundColor Yellow
        exit 0
    }
}

# Generate SSH key
Write-Host ""
Write-Host "Generating SSH key..." -ForegroundColor Yellow
Write-Host "You will be prompted to enter a passphrase (recommended for security)" -ForegroundColor Gray
Write-Host ""

try {
    # Run ssh-keygen
    $process = Start-Process -FilePath "ssh-keygen" -ArgumentList "-t $(if ($keyType -eq '1') {'ed25519'} else {'rsa'})", "-b $(if ($keyType -eq '2') {'4096'})", "-C `"$email`"", "-f `"$keyFile`"" -NoNewWindow -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "[OK] SSH key generated successfully" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to generate SSH key" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERROR] Failed to generate SSH key: $_" -ForegroundColor Red
    exit 1
}

# Start SSH agent and add key
Write-Host ""
Write-Host "Starting SSH agent..." -ForegroundColor Yellow

try {
    # Check if ssh-agent service exists
    $sshAgent = Get-Service ssh-agent -ErrorAction SilentlyContinue
    
    if ($sshAgent) {
        if ($sshAgent.Status -ne 'Running') {
            Start-Service ssh-agent
            Write-Host "[OK] SSH agent started" -ForegroundColor Green
        } else {
            Write-Host "[OK] SSH agent is already running" -ForegroundColor Green
        }
        
        # Add key to agent
        Write-Host "Adding SSH key to agent..." -ForegroundColor Yellow
        ssh-add $keyFile
        Write-Host "[OK] SSH key added to agent" -ForegroundColor Green
    } else {
        Write-Host "[INFO] SSH agent service not found" -ForegroundColor Yellow
        Write-Host "You may need to install OpenSSH client feature" -ForegroundColor Gray
    }
} catch {
    Write-Host "[WARNING] Could not add key to SSH agent: $_" -ForegroundColor Yellow
}

# Display public key
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Your SSH Public Key" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$publicKey = Get-Content "$keyFile.pub"
Write-Host $publicKey -ForegroundColor Green

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan

# Copy to clipboard
try {
    $publicKey | Set-Clipboard
    Write-Host ""
    Write-Host "[OK] Public key copied to clipboard!" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "[INFO] Could not copy to clipboard. Please copy the key manually." -ForegroundColor Yellow
}

# Instructions
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Go to GitHub.com" -ForegroundColor Gray
Write-Host "2. Navigate to Settings > SSH and GPG keys" -ForegroundColor Gray
Write-Host "3. Click 'New SSH key'" -ForegroundColor Gray
Write-Host "4. Paste the public key (already copied to clipboard)" -ForegroundColor Gray
Write-Host "5. Give it a descriptive title (e.g., 'Windows-Work-PC')" -ForegroundColor Gray
Write-Host "6. Click 'Add SSH key'" -ForegroundColor Gray
Write-Host ""

# Test connection
$test = Read-Host "Do you want to test the SSH connection to GitHub? (yes/no)"
if ($test -eq "yes") {
    Write-Host ""
    Write-Host "Testing SSH connection to GitHub..." -ForegroundColor Yellow
    Write-Host "You should see a message saying you've successfully authenticated" -ForegroundColor Gray
    Write-Host ""
    
    ssh -T git@github.com
    
    Write-Host ""
    if ($LASTEXITCODE -eq 1) {
        Write-Host "[OK] SSH connection successful!" -ForegroundColor Green
    } else {
        Write-Host "[INFO] Make sure you've added the public key to GitHub first" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "SSH Setup Complete!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
