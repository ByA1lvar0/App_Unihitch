@echo off
echo ========================================
echo   CONFIGURAR BASE DE DATOS UNIHITCH
echo ========================================
echo.

echo Conectando a PostgreSQL...
echo.

echo Por favor ingresa tu contraseña de PostgreSQL cuando te lo pida.
echo.

psql -U postgres -c "CREATE DATABASE unihitch_db;"

if %errorlevel% equ 0 (
    echo.
    echo Base de datos creada exitosamente!
    echo.
    echo Ahora ejecutando el script SQL...
    echo.
    psql -U postgres -d unihitch_db -f database_setup.sql
    
    if %errorlevel% equ 0 (
        echo.
        echo ========================================
        echo   BASE DE DATOS CONFIGURADA!
        echo ========================================
        echo.
        echo Tu base de datos esta lista.
        echo.
        echo RECUERDA:
        echo 1. Configurar el archivo .env con tu contraseña de PostgreSQL
        echo 2. Ejecutar: npm start en la carpeta unihitch_backend
        echo.
    ) else (
        echo ERROR: No se pudo ejecutar el script SQL
    )
) else (
    echo ERROR: No se pudo crear la base de datos
)

pause

