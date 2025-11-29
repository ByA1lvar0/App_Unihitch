# Instalación de dependencias para Culqi

## Paso 1: Instalar axios (para llamadas a API de Culqi)

```powershell
cd c:\Users\USUARIO\Downloads\Unitich\App_Unihitch\unihitch_backend
npm install axios
```

## Paso 2: Configurar tus API Keys de Culqi

1. Ve a https://culqi.com y crea tu cuenta
2. En Dashboard → Desarrollo → API Keys
3. Copia tus keys:
   - **Llave Pública:** pk_test_...
   - **Llave Secreta:** sk_test_...

4. Edita el archivo `.env` y reemplaza:
```
CULQI_PUBLIC_KEY=pk_test_TU_KEY_AQUI
CULQI_SECRET_KEY=sk_test_TU_KEY_AQUI
```

## Paso 3: Reiniciar el servidor

```powershell
node server.js
```

¡Listo! El backend ya puede procesar pagos con Culqi.
