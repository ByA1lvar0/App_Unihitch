# 📚 Documentación del Proyecto UniHitch

## Documentación Generada

Este proyecto incluye documentación completa tanto para el frontend (Flutter) como para el backend (Node.js).

### 🎨 Frontend - DartDoc

**Ubicación:** `unihitch_app/doc/api/`

La documentación del código Dart/Flutter ha sido generada automáticamente usando DartDoc.

**Para visualizar:**
```bash
cd unihitch_app/doc/api
# Abrir index.html en tu navegador
start index.html  # Windows
open index.html   # macOS
xdg-open index.html  # Linux
```

**Contenido:**
- Todas las clases y widgets
- Métodos y funciones
- Parámetros y tipos de retorno
- Ejemplos de uso
- Dependencias entre módulos

**Regenerar documentación:**
```bash
cd unihitch_app
dart doc .
```

### ⚙️ Backend - JSDoc

**Ubicación:** `unihitch_backend/docs/`

La documentación del código Node.js ha sido generada automáticamente usando JSDoc.

**Para visualizar:**
```bash
cd unihitch_backend/docs
# Abrir index.html en tu navegador
start index.html  # Windows
open index.html   # macOS
xdg-open index.html  # Linux
```

**Contenido:**
- Controllers
- Middleware
- Routes
- Configuración
- Funciones y parámetros
- Tipos de datos

**Regenerar documentación:**
```bash
cd unihitch_backend
jsdoc -c jsdoc.json
```

## 📖 Documentación Adicional

### Manuales en Markdown

1. **README.md** - Guía principal del proyecto
2. **TECHNICAL_MANUAL.md** - Manual técnico completo
3. **USER_MANUAL.md** - Manual de usuario
4. **REQUIREMENTS_COMPLIANCE.md** - Cumplimiento de requerimientos

### Estructura de Documentación

```
App_Unihitch/
├── README.md                          # Documentación principal
├── TECHNICAL_MANUAL.md                # Manual técnico
├── USER_MANUAL.md                     # Manual de usuario
├── REQUIREMENTS_COMPLIANCE.md         # Requerimientos cumplidos
│
├── unihitch_app/
│   └── doc/
│       └── api/                       # DartDoc HTML
│           ├── index.html             # Página principal
│           ├── index.json             # Índice JSON
│           └── ...                    # Documentación generada
│
└── unihitch_backend/
    ├── docs/                          # JSDoc HTML
    │   ├── index.html                 # Página principal
    │   └── ...                        # Documentación generada
    └── jsdoc.json                     # Configuración JSDoc
```

## 🚀 Acceso Rápido

### Ver Documentación Frontend
```bash
cd unihitch_app/doc/api
start index.html
```

### Ver Documentación Backend
```bash
cd unihitch_backend/docs
start index.html
```

### Ver Todos los Manuales
Los archivos `.md` se pueden abrir con cualquier editor de texto o visor de Markdown:
- Visual Studio Code
- GitHub
- Typora
- Markdown Preview (navegador)

## 🔄 Actualizar Documentación

### Después de Cambios en el Código

**Frontend:**
```bash
cd unihitch_app
dart doc .
```

**Backend:**
```bash
cd unihitch_backend
jsdoc -c jsdoc.json
```

## 📝 Convenciones de Documentación

### DartDoc (Flutter)

```dart
/// Breve descripción de la clase o función.
///
/// Descripción más detallada que puede incluir
/// múltiples líneas y ejemplos.
///
/// **Ejemplo:**
/// ```dart
/// final service = ApiService();
/// await service.login('email@example.com', 'password');
/// ```
///
/// Ver también:
/// * [OtraClase] para funcionalidad relacionada
class MiClase {
  /// Descripción del método.
  ///
  /// [parametro1] descripción del parámetro
  /// [parametro2] descripción del parámetro
  ///
  /// Returns descripción del valor de retorno
  ///
  /// Throws [Exception] cuando ocurre un error
  Future<void> miMetodo(String parametro1, int parametro2) async {
    // implementación
  }
}
```

### JSDoc (Node.js)

```javascript
/**
 * Breve descripción de la función.
 *
 * Descripción más detallada que puede incluir
 * múltiples líneas y ejemplos.
 *
 * @param {string} parametro1 - Descripción del parámetro
 * @param {number} parametro2 - Descripción del parámetro
 * @returns {Promise<Object>} Descripción del valor de retorno
 * @throws {Error} Cuando ocurre un error
 *
 * @example
 * const resultado = await miFuncion('valor', 123);
 */
async function miFuncion(parametro1, parametro2) {
  // implementación
}
```

## 🎯 Navegación en la Documentación

### DartDoc
- **Barra lateral izquierda:** Navegación por paquetes y librerías
- **Panel central:** Documentación del elemento seleccionado
- **Búsqueda:** Campo de búsqueda en la parte superior
- **Filtros:** Por tipo (clase, función, etc.)

### JSDoc
- **Menú superior:** Navegación por módulos
- **Barra lateral:** Lista de clases y funciones
- **Panel central:** Documentación detallada
- **Búsqueda:** Campo de búsqueda en la esquina

## 📊 Cobertura de Documentación

### Frontend (DartDoc)
- ✅ Services (ApiService, etc.)
- ✅ Screens (todas las pantallas)
- ✅ Widgets (componentes reutilizables)
- ✅ Models (modelos de datos)
- ✅ Config (configuración)

### Backend (JSDoc)
- ✅ Controllers (lógica de negocio)
- ✅ Middleware (autenticación, validación)
- ✅ Routes (endpoints API)
- ✅ Config (configuración DB)

## 🔗 Enlaces Útiles

- [DartDoc Documentation](https://dart.dev/tools/dartdoc)
- [JSDoc Documentation](https://jsdoc.app/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Node.js Documentation](https://nodejs.org/docs/)

---

**Última actualización:** Diciembre 2024  
**Versión:** 1.0
