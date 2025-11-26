$file1 = "lib\screens\register_screen.dart"
$content1 = [System.IO.File]::ReadAllText($file1, [System.Text.Encoding]::UTF8)
$content1 = $content1 -replace "carreraNombre: _carreraSeleccionada,", "// carreraNombre: _carreraSeleccionada,"
[System.IO.File]::WriteAllText($file1, $content1, [System.Text.Encoding]::UTF8)

$file2 = "lib\screens\create_trip_screen.dart"
$content2 = [System.IO.File]::ReadAllText($file2, [System.Text.Encoding]::UTF8)
$content2 = $content2 -replace "aceptaEfectivo: _aceptaEfectivo,", "// aceptaEfectivo: _aceptaEfectivo,"
[System.IO.File]::WriteAllText($file2, $content2, [System.Text.Encoding]::UTF8)

Write-Host "Líneas problemáticas comentadas"
