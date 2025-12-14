# GitHub GPG Setup Script
# This script helps set up GPG keys for commit signing

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "GitHub GPG Key Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if GPG is installed
try {
    $gpgVersion = gpg --version | Select-Object -First 1
    Write-Host "[OK] GPG is installed: $gpgVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] GPG is not installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download and install GPG from:" -ForegroundColor Yellow
    Write-Host "https://www.gnupg.org/download/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "For Windows, use Gpg4win:" -ForegroundColor Yellow
    Write-Host "https://www.gpg4win.org/" -ForegroundColor Cyan
    exit 1
}

Write-Host ""

# Check for existing keys
Write-Host "Checking for existing GPG keys..." -ForegroundColor Yellow
$existingKeys = gpg --list-secret-keys --keyid-format=long 2>&1

if ($existingKeys -match "sec") {
    Write-Host "[INFO] Found existing GPG keys:" -ForegroundColor Yellow
    Write-Host $existingKeys -ForegroundColor Gray
    Write-Host ""
    $useExisting = Read-Host "Do you want to use an existing key? (yes/no)"
    
    if ($useExisting -eq "yes") {
        $keyId = Read-Host "Enter the key ID (e.g., 3AA5C34371567BD2)"
        
        if ([string]::IsNullOrWhiteSpace($keyId)) {
            Write-Host "[ERROR] Key ID is required" -ForegroundColor Red
            exit 1
        }
        
        # Export and display public key
        Write-Host ""
        Write-Host "Exporting public key..." -ForegroundColor Yellow
        $publicKey = gpg --armor --export $keyId
        
        Write-Host ""
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host "Your GPG Public Key" -ForegroundColor Cyan
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host $publicKey -ForegroundColor Green
        Write-Host ""
        
        try {
            $publicKey | Set-Clipboard
            Write-Host "[OK] Public key copied to clipboard!" -ForegroundColor Green
        } catch {
            Write-Host "[INFO] Could not copy to clipboard" -ForegroundColor Yellow
        }
        
        # Configure Git
        Write-Host ""
        $configureGit = Read-Host "Do you want to configure Git to use this key? (yes/no)"
        if ($configureGit -eq "yes") {
            git config --global user.signingkey $keyId
            git config --global commit.gpgsign true
            
            # Try to find GPG executable
            $gpgPath = (Get-Command gpg).Source
            if ($gpgPath) {
                git config --global gpg.program $gpgPath
            }
            
            Write-Host "[OK] Git configured to use GPG key $keyId" -ForegroundColor Green
        }
        
        # Instructions
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Go to GitHub.com" -ForegroundColor Gray
        Write-Host "2. Navigate to Settings > SSH and GPG keys" -ForegroundColor Gray
        Write-Host "3. Click 'New GPG key'" -ForegroundColor Gray
        Write-Host "4. Paste the public key (already copied to clipboard)" -ForegroundColor Gray
        Write-Host "5. Click 'Add GPG key'" -ForegroundColor Gray
        Write-Host ""
        
        exit 0
    }
}

# Generate new GPG key
Write-Host ""
Write-Host "Generating new GPG key..." -ForegroundColor Yellow
Write-Host ""

# Get user information
$name = Read-Host "Enter your full name (as shown on GitHub)"
$email = Read-Host "Enter your GitHub email address"

if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($email)) {
    Write-Host "[ERROR] Name and email are required" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Key configuration:" -ForegroundColor Yellow
Write-Host "- Type: RSA and RSA" -ForegroundColor Gray
Write-Host "- Key size: 4096 bits" -ForegroundColor Gray
Write-Host "- Expiration: 1 year (recommended)" -ForegroundColor Gray
Write-Host ""
Write-Host "You will be prompted to:" -ForegroundColor Yellow
Write-Host "1. Confirm the key type and size" -ForegroundColor Gray
Write-Host "2. Set key expiration (recommended: 1y)" -ForegroundColor Gray
Write-Host "3. Enter your name and email" -ForegroundColor Gray
Write-Host "4. Set a passphrase (IMPORTANT for security)" -ForegroundColor Gray
Write-Host ""

$continue = Read-Host "Continue with key generation? (yes/no)"
if ($continue -ne "yes") {
    Write-Host "[INFO] Key generation cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Starting GPG key generation..." -ForegroundColor Yellow
Write-Host "This may take a few moments..." -ForegroundColor Gray
Write-Host ""

try {
    # Interactive generation is recommended for security (prompts for passphrase)
    Write-Host "Please follow the GPG prompts:" -ForegroundColor Yellow
    Write-Host "IMPORTANT: You will be asked to set a passphrase - choose a strong one!" -ForegroundColor Red
    Write-Host ""
    gpg --full-generate-key
    
    # Get the newly created key
    Write-Host ""
    Write-Host "Retrieving new key..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    $newKeys = gpg --list-secret-keys --keyid-format=long $email 2>&1
    Write-Host $newKeys -ForegroundColor Gray
    
    # Extract key ID (supports various key algorithms and formats)
    $keyIdMatch = $newKeys -match "sec\s+[^/]+/([A-F0-9]+)"
    if ($Matches -and $Matches[1]) {
        $keyId = $Matches[1]
        Write-Host ""
        Write-Host "[OK] GPG key generated successfully!" -ForegroundColor Green
        Write-Host "Key ID: $keyId" -ForegroundColor Cyan
        
        # Export public key
        Write-Host ""
        Write-Host "Exporting public key..." -ForegroundColor Yellow
        $publicKey = gpg --armor --export $keyId
        
        Write-Host ""
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host "Your GPG Public Key" -ForegroundColor Cyan
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host $publicKey -ForegroundColor Green
        Write-Host ""
        
        try {
            $publicKey | Set-Clipboard
            Write-Host "[OK] Public key copied to clipboard!" -ForegroundColor Green
        } catch {
            Write-Host "[INFO] Could not copy to clipboard" -ForegroundColor Yellow
        }
        
        # Configure Git
        Write-Host ""
        Write-Host "Configuring Git to use GPG key..." -ForegroundColor Yellow
        
        git config --global user.name $name
        git config --global user.email $email
        git config --global user.signingkey $keyId
        git config --global commit.gpgsign true
        
        # Configure GPG program path
        $gpgPath = (Get-Command gpg).Source
        if ($gpgPath) {
            git config --global gpg.program $gpgPath
            Write-Host "[OK] Git configured successfully" -ForegroundColor Green
        }
        
        # Instructions
        Write-Host ""
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Go to GitHub.com" -ForegroundColor Gray
        Write-Host "2. Navigate to Settings > SSH and GPG keys" -ForegroundColor Gray
        Write-Host "3. Click 'New GPG key'" -ForegroundColor Gray
        Write-Host "4. Paste the public key (already copied to clipboard)" -ForegroundColor Gray
        Write-Host "5. Click 'Add GPG key'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Your commits will now be signed automatically!" -ForegroundColor Green
        Write-Host ""
        
        # Backup reminder
        Write-Host "IMPORTANT - Backup your GPG key:" -ForegroundColor Red
        Write-Host "Run this command to export your private key (keep it secure!):" -ForegroundColor Yellow
        Write-Host "gpg --armor --export-secret-keys $keyId > gpg-private-key-backup.asc" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host "[WARNING] Could not extract key ID automatically" -ForegroundColor Yellow
        Write-Host "Please run: gpg --list-secret-keys --keyid-format=long" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "[ERROR] Failed to generate GPG key: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "GPG Setup Complete!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
