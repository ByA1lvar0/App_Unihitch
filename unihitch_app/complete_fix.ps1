$file = "lib\services\api_service.dart"
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

# Agregar parámetro aceptaEfectivo a createViaje
$content = $content -replace 'required int asientosDisponibles,', @'
required int asientosDisponibles,
    bool? aceptaEfectivo,
'@

# Agregar el campo en el body del createViaje
$content = $content -replace "'asientos_disponibles': asientosDisponibles,", @'
'asientos_disponibles': asientosDisponibles,
          if (aceptaEfectivo != null) 'acepta_efectivo': aceptaEfectivo,
'@

# Remover la última llave
$content = $content.TrimEnd()
$lastBrace = $content.LastIndexOf('}')
$content = $content.Substring(0, $lastBrace)

# Agregar métodos faltantes
$content = $content + @'

  // OBTENER CALIFICACIONES DE USUARIO
  static Future<List<dynamic>> getUserRatings(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/ratings/user/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // OBTENER WALLET
  static Future<Map<String, dynamic>> getWallet(int userId) async {
    final response = await http.get(
      Uri.parse('${Config.apiUrl}/wallet/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener wallet');
    }
  }
}
'@

[System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
Write-Host "Todos los métodos agregados correctamente"
