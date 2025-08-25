# PowerShell script to capture screenshots using Windows browser automation
param()

# Create a timestamp for unique filenames
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"

# Try to use Edge or Chrome from Windows
try {
    # Create COM object for Internet Explorer/Edge
    $ie = New-Object -ComObject InternetExplorer.Application
    $ie.Visible = $true
    $ie.Navigate("http://localhost:8080")
    
    # Wait for page to load
    while ($ie.Busy -or $ie.ReadyState -ne 4) {
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host "Browser opened. Please:"
    Write-Host "1. Login with admin@steelestimation.com / Admin@123"
    Write-Host "2. Take a screenshot manually (Win+Shift+S)"
    Write-Host "3. Save it to the current directory"
    
    # Keep browser open for 30 seconds for manual screenshot
    Start-Sleep -Seconds 30
    
    $ie.Quit()
} catch {
    Write-Host "Error opening browser: $_"
    Write-Host ""
    Write-Host "Please manually:"
    Write-Host "1. Open http://localhost:8080 in your browser"
    Write-Host "2. Login with admin@steelestimation.com / Admin@123"
    Write-Host "3. Take screenshots using Win+Shift+S or Snipping Tool"
    Write-Host "4. Focus on the sidebar area"
}