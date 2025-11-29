$file = "lib\services\api_service.dart"
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
$content = $content.Replace('$baseUrl', '${Config.apiUrl}')
[System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
Write-Host "Reemplazo completado"
