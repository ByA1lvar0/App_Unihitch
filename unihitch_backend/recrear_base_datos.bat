@echo off
echo ========================================
echo   RECREAR BASE DE DATOS UNIHITCH
echo ========================================
echo.

echo PASO 1: Eliminando base de datos existente...
psql -U postgres -c "DROP DATABASE IF EXISTS unihitch_db;"
echo.

echo PASO 2: Creando nueva base de datos...
psql -U postgres -c "CREATE DATABASE unihitch_db;"
echo.

echo PASO 3: Ejecutando script SQL con las universidades de Piura...
psql -U postgres -d unihitch_db -f database_setup.sql
echo.

echo ========================================
echo   BASE DE DATOS RECREADA EXITOSAMENTE!
echo ========================================
echo.
echo UNIVERSIDADES AGREGADAS:
echo - Universidad de Piura (UDEP)
echo - Universidad Nacional de Piura (UNP)
echo - Universidad Cesar Vallejo (UCV)
echo - Universidad Privada del Norte (UPN)
echo - Universidad de San Martin de Porres
echo.
echo Ahora ejecuta: npm start
echo.

pause

