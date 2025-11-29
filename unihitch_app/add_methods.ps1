# Leer el archivo actual
$content = Get-Content "lib\services\api_service.dart" -Raw -Encoding UTF8

# Remover la última llave de cierre
$content = $content.TrimEnd()
$lastBrace = $content.LastIndexOf('}')
$content = $content.Substring(0, $lastBrace)

# Leer los nuevos métodos
$newMethods = Get-Content "missing_methods.txt" -Raw -Encoding UTF8

# Combinar
$finalContent = $content + $newMethods

# Guardar
Set-Content "lib\services\api_service.dart" -Value $finalContent -Encoding UTF8 -NoNewline

Write-Host "Métodos agregados exitosamente"
