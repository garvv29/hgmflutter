# Flutter Project Setup Script
# Run this in PowerShell to properly initialize the Flutter project

Write-Host "Setting up Har Ghar Munga Flutter Project..." -ForegroundColor Green

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version
    Write-Host "Flutter found: $($flutterVersion.Split("`n")[0])" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Navigate to project directory
Set-Location "c:\Users\garvc\Desktop\hargharmungaapkfinal7app\hgmflutter"

# Create a new Flutter project (this will setup proper structure)
Write-Host "Creating Flutter project structure..." -ForegroundColor Yellow
flutter create --project-name hgmflutter --org com.ssipmt.hargharmunga .

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
flutter pub get

# Run analysis
Write-Host "Running Flutter analysis..." -ForegroundColor Yellow
flutter analyze

Write-Host "`nProject setup complete!" -ForegroundColor Green
Write-Host "To run the app:" -ForegroundColor Cyan
Write-Host "  cd hgmflutter" -ForegroundColor White
Write-Host "  flutter run" -ForegroundColor White

Write-Host "`nTo build APK:" -ForegroundColor Cyan
Write-Host "  flutter build apk --release" -ForegroundColor White
