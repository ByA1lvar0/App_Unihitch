$file = "lib\services\api_service.dart"
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

# Remover la última llave
$content = $content.TrimEnd()
$lastBrace = $content.LastIndexOf('}')
$content = $content.Substring(0, $lastBrace)

# Agregar métodos faltantes para MyTripsScreen
$content = $content + @'

  // OBTENER MIS VIAJES (COMO CONDUCTOR)
  static Future<List<dynamic>> getMisViajes(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/viajes/conductor/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // OBTENER MIS RESERVAS (COMO PASAJERO)
  static Future<List<dynamic>> getMisReservas(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/reservas/pasajero/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }
}
'@

[System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
Write-Host "Métodos getMisViajes y getMisReservas agregados"
