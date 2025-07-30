# Test if basic Razor structure works

Write-Host "Testing basic Razor structure..." -ForegroundColor Cyan

# Create a minimal test file
$testContent = @'
@page "/test"

@if (true)
{
    <div>Loading...</div>
}
else
{
    <div>Content</div>
}

@code {
    private bool test = true;
}
'@

$testContent | Set-Content "TestPage.razor" -Encoding UTF8

Write-Host "Created TestPage.razor" -ForegroundColor Green

# Try to build
cd ..
$output = dotnet build --no-restore 2>&1 | Out-String
$testErrors = $output -split "`n" | Where-Object { $_ -match "TestPage.razor.*error" }

if ($testErrors.Count -eq 0) {
    Write-Host "Test page compiles successfully!" -ForegroundColor Green
    Write-Host "This confirms the build system is working." -ForegroundColor Gray
} else {
    Write-Host "Test page has errors:" -ForegroundColor Red
    $testErrors | ForEach-Object { Write-Host $_ }
}

# Clean up
Remove-Item "Pages\Package\TestPage.razor" -ErrorAction SilentlyContinue