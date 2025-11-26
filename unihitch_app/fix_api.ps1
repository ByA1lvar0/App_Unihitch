(Get-Content "lib\services\api_service.dart" -Raw -Encoding UTF8) `
  -replace "Uri\.parse\('/history/',\)", "Uri.parse('`$baseUrl/history/`$userId')" `
  -replace "Uri\.parse\('/history/statistics/',\)", "Uri.parse('`$baseUrl/history/statistics/`$userId')" |
Set-Content "lib\services\api_service.dart" -Encoding UTF8 -NoNewline
