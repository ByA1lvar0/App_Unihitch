$file = "lib\services\api_service.dart"
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

# Remover la última llave
$content = $content.TrimEnd()
$lastBrace = $content.LastIndexOf('}')
$content = $content.Substring(0, $lastBrace)

# Agregar nuevos métodos
$newMethods = [System.IO.File]::ReadAllText("additional_methods.txt", [System.Text.Encoding]::UTF8)
$content = $content + $newMethods

[System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
Write-Host "Métodos adicionales agregados"
