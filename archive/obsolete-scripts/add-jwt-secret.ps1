# Add JWT secret to Key Vault
param(
    [string]$KeyVaultName = "NWIDev"
)

Write-Host "Adding JWT secret to Key Vault..." -ForegroundColor Green

# Generate a secure JWT secret
$jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 64 | ForEach-Object {[char]$_})

try {
    # Set the secret in Key Vault
    $secret = Set-AzKeyVaultSecret -VaultName $KeyVaultName `
                                   -Name "jwt-secret" `
                                   -SecretValue (ConvertTo-SecureString $jwtSecret -AsPlainText -Force)
    
    Write-Host "JWT secret added successfully to Key Vault!" -ForegroundColor Green
    Write-Host "Secret Name: jwt-secret" -ForegroundColor Yellow
    Write-Host "Key Vault: $KeyVaultName" -ForegroundColor Yellow
    
    # Also add other required secrets while we're at it
    Write-Host "`nAdding email configuration secrets..." -ForegroundColor Green
    
    # Email settings (placeholder values - update with your SMTP settings)
    Set-AzKeyVaultSecret -VaultName $KeyVaultName `
                         -Name "email-smtp-host" `
                         -SecretValue (ConvertTo-SecureString "smtp.sendgrid.net" -AsPlainText -Force) | Out-Null
    
    Set-AzKeyVaultSecret -VaultName $KeyVaultName `
                         -Name "email-smtp-port" `
                         -SecretValue (ConvertTo-SecureString "587" -AsPlainText -Force) | Out-Null
    
    Set-AzKeyVaultSecret -VaultName $KeyVaultName `
                         -Name "email-smtp-username" `
                         -SecretValue (ConvertTo-SecureString "apikey" -AsPlainText -Force) | Out-Null
    
    Set-AzKeyVaultSecret -VaultName $KeyVaultName `
                         -Name "email-smtp-password" `
                         -SecretValue (ConvertTo-SecureString "your-sendgrid-api-key" -AsPlainText -Force) | Out-Null
    
    Write-Host "Email configuration secrets added (with placeholder values)" -ForegroundColor Yellow
    
    Write-Host "`nAll secrets added successfully!" -ForegroundColor Green
    Write-Host "`nNote: Update the email SMTP password with your actual SendGrid API key when available." -ForegroundColor Yellow
    
} catch {
    Write-Error "Failed to add secret to Key Vault: $_"
    exit 1
}

Write-Host "`nRestarting App Service to pick up new configuration..." -ForegroundColor Green
Restart-AzWebApp -ResourceGroupName "NWIApps" -Name "app-steel-estimation-prod"

Write-Host "App Service restarted. The application should now be able to start successfully." -ForegroundColor Green