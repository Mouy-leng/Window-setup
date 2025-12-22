# Setting Up GitHub Secrets

## Your OAuth Credentials
- **Client ID**: `Ov23liVH34OCl6XkcrH6`
- **Client Secret**: `666665669ac851c05533d8ee472d64cbd2061eba`

## Repository
- **Repository**: `Mouy-leng/ZOLO-A6-9VxNUNA-`

## Method 1: Using GitHub CLI (Recommended)

1. **Authenticate with GitHub CLI:**
   ```bash
   gh auth login
   ```
   Follow the prompts to authenticate via web browser.

2. **Set the secrets:**
   ```bash
   gh secret set CLIENT_ID --body "Ov23liVH34OCl6XkcrH6" --repo Mouy-leng/ZOLO-A6-9VxNUNA-
   gh secret set CLIENT_SECRET --body "666665669ac851c05533d8ee472d64cbd2061eba" --repo Mouy-leng/ZOLO-A6-9VxNUNA-
   ```
   
   **Note:** Secret names cannot start with `GITHUB_` as that prefix is reserved by GitHub.

3. **Verify the secrets were added:**
   ```bash
   gh secret list
   ```

## Method 2: Using GitHub Web Interface

1. Go to your repository: https://github.com/Mouy-leng/ZOLO-A6-9VxNUNA-
2. Click on **Settings** (in the repository navigation bar)
3. In the left sidebar, click on **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add the first secret:
   - **Name**: `CLIENT_ID`
   - **Secret**: `Ov23liVH34OCl6XkcrH6`
   - Click **Add secret**
6. Click **New repository secret** again
7. Add the second secret:
   - **Name**: `CLIENT_SECRET`
   - **Secret**: `666665669ac851c05533d8ee472d64cbd2061eba`
   - Click **Add secret**
   
   **Note:** Secret names cannot start with `GITHUB_` as that prefix is reserved by GitHub.

## Using the Secrets in GitHub Actions

Once set, you can use these secrets in your GitHub Actions workflows like this:

```yaml
env:
  CLIENT_ID: ${{ secrets.CLIENT_ID }}
  CLIENT_SECRET: ${{ secrets.CLIENT_SECRET }}
```

Or directly:
```yaml
- name: Use OAuth credentials
  run: |
    echo "Client ID: ${{ secrets.CLIENT_ID }}"
    # Use the secrets in your scripts
```

## ✅ Status

**Secrets have been successfully set!**
- ✓ `CLIENT_ID` - Set for repository `Mouy-leng/ZOLO-A6-9VxNUNA-`
- ✓ `CLIENT_SECRET` - Set for repository `Mouy-leng/ZOLO-A6-9VxNUNA-`

