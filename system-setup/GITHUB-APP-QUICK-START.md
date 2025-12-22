# GenX GitHub App - Quick Start

Quick reference for setting up the GenX GitHub App.

## 🚀 Quick Setup (5 Steps)

### 1. Create GitHub App

- Go to: GitHub Settings → Developer settings → GitHub Apps → New GitHub App
- Name: `GenX`
- Set permissions: Contents (Read & write), Metadata (Read-only)
- Subscribe to: Push, Pull request, Issues
- Generate and download private key (`.pem` file)

### 2. Install the App

- Click **Install App** on your app's page
- Select repositories to grant access
- Note the **Installation ID** from the URL

### 3. Save Credentials

```powershell
# Create secure directory
$githubDir = "$env:USERPROFILE\.github"
New-Item -ItemType Directory -Path $githubDir -Force

# Move your private key here
# Example: Move-Item "Downloads\genx-app.2025-12-19.private-key.pem" "$githubDir\genx-app-private-key.pem"
```

### 4. Update MCP Config

Edit `system-setup/mcp-config.json`:

**For GitHub App (Recommended):**

```json
"env": {
  "GITHUB_APP_ID": "123456",
  "GITHUB_APP_PRIVATE_KEY_PATH": "C:\\Users\\USER\\.github\\genx-app-private-key.pem",
  "GITHUB_APP_INSTALLATION_ID": "12345678"
}
```

**OR for Personal Access Token:**

```json
"env": {
  "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here"
}
```

### 5. Apply & Verify

```powershell
# Apply configuration
.\complete-setup.ps1

# Verify setup
.\verify-github-app.ps1

# Restart Cursor
```

## 📋 What You Need

- [ ] App ID (from GitHub App settings)
- [ ] Private Key file (`.pem` - downloaded once)
- [ ] Installation ID (from installation URL)
- [ ] Webhook Secret (if using webhooks)

## ✅ Verification

Run the verification script:

```powershell
.\verify-github-app.ps1 -Verbose
```

## 🔗 Full Guide

See `GITHUB-APP-SETUP.md` for detailed instructions.

---

**Note**: Choose EITHER GitHub App authentication OR Personal Access Token, not both.
