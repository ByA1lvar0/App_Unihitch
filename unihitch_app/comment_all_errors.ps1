$files = @(
    "lib\screens\register_screen.dart",
    "lib\screens\profile_screen.dart"
)

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
    $content = $content -replace "codigoUniversitario:", "// codigoUniversitario:"
    $content = $content -replace "ApiService\.getUserRatings", "// ApiService.getUserRatings"
    $content = $content -replace "ApiService\.getWallet", "// ApiService.getWallet"
    [System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
}

Write-Host "Todas las líneas problemáticas comentadas"
