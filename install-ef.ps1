# PSEUDOCODE / PLAN (detailed):
# 1. Determine the target .NET project (.csproj). If the user passed a path use it; otherwise search the current directory recursively and pick the first .csproj.
# 2. If no project is found, emit an error and exit with non-zero status.
# 3. Run `dotnet add <project>` to install EF Core 8 packages: Microsoft.EntityFrameworkCore, Microsoft.EntityFrameworkCore.SqlServer,
#    Microsoft.EntityFrameworkCore.Tools, and Microsoft.EntityFrameworkCore.Design (Design helps tooling).
# 4. Run `dotnet restore <project>` to restore packages.
# 5. Run `dotnet build <project> -c Release` to compile the project.
# 6. Exit with the dotnet build status code so CI can detect failure.
#
# USAGE:
#   .\install-ef.ps1                    # finds first .csproj under current directory
#   .\install-ef.ps1 -ProjectPath "path\to\MyProject.csproj"
#
param(
    [string] $ProjectPath = ""
)

function Fail([string] $msg) {
    Write-Error $msg
    exit 1
}

# Step 1: locate project if not provided
if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    $csproj = Get-ChildItem -Path . -Filter *.csproj -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $csproj) {
        Fail "No .csproj found in current directory or subdirectories. Provide -ProjectPath."
    }
    $ProjectPath = $csproj.FullName
}

Write-Host "Using project: $ProjectPath"

# Step 3: add EF Core packages (targeting .NET 8 / EF Core 8)
$packages = @(
    "Microsoft.EntityFrameworkCore" ,
    "Microsoft.EntityFrameworkCore.SqlServer",
    "Microsoft.EntityFrameworkCore.Tools",
    "Microsoft.EntityFrameworkCore.Design"
)

foreach ($pkg in $packages) {
    Write-Host "Adding package $pkg..."
    & dotnet add "$ProjectPath" package $pkg --version 8.0.0
    if ($LASTEXITCODE -ne 0) {
        Fail "Failed to add package $pkg"
    }
}

# Step 4: restore
Write-Host "Restoring packages..."
& dotnet restore "$ProjectPath"
if ($LASTEXITCODE -ne 0) { Fail "dotnet restore failed" }

# Step 5: build
Write-Host "Building project..."
& dotnet build "$ProjectPath" -c Release
$buildExit = $LASTEXITCODE

if ($buildExit -ne 0) {
    Fail "Build failed with exit code $buildExit"
}

Write-Host "EF Core packages installed and project compiled successfully."
exit 0