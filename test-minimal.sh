#!/bin/bash

echo "Creating minimal test deployment..."

# Create a minimal test folder
mkdir -p /tmp/minimal-test
cd /tmp/minimal-test

# Create a simple Program.cs
cat > Program.cs << 'EOF'
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Hello from Staging!");
app.MapGet("/health", () => Results.Ok(new { status = "healthy", environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") }));

app.Run();
EOF

# Create a project file
cat > MinimalTest.csproj << 'EOF'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
EOF

echo "Test files created in /tmp/minimal-test"