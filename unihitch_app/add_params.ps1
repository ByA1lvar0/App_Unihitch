$file = "lib\services\api_service.dart"
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

# Agregar parámetros a getViajes
$content = $content -replace 'static Future<List<dynamic>> getViajes\(\) async \{', @'
static Future<List<dynamic>> getViajes({String? origen, String? destino}) async {
    String url = '${Config.apiUrl}/viajes';
    if (origen != null || destino != null) {
      url += '?';
      if (origen != null) url += 'origen=$origen&';
      if (destino != null) url += 'destino=$destino';
    }
'@

# Reemplazar la línea Uri.parse en getViajes
$content = $content -replace "Uri\.parse\('\$\{Config\.apiUrl\}/viajes'\)", "Uri.parse(url)"

# Agregar carreraNombre a register
$content = $content -replace 'required String correo,', @'
required String correo,
    String? carreraNombre,
'@

# Agregar carreraNombre al body del register
$content = $content -replace "'correo': correo,", @'
'correo': correo,
        if (carreraNombre != null) 'carrera_nombre': carreraNombre,
'@

[System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
Write-Host "Parámetros adicionales agregados"
