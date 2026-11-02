# Arquitectura WallpaperAR

## Capas

```
UI (SwiftUI)
  └─ Features/Visualizer  ← vistas AR, controles
       └─ Services/AR      ← ARSession, detección de planos
       └─ Services/Rendering ← RealityKit, materiales PBR
            └─ Domain      ← modelos puros (sin ARKit)
                 ├─ Models: Wallpaper, PatternSpec, WallSurface
                 └─ Rules:  UVScaleCalculator
```

## Regla de escala UV

```
tilesX = wallWidthM  / patternWidthM
tilesY = wallHeightM / patternHeightM
```

Para el patrón de referencia (53 × 53 cm) en una pared de 3 × 2.5 m:
- tilesX = 3.0 / 0.53 ≈ **5.66 repeticiones**
- tilesY = 2.5 / 0.53 ≈ **4.72 repeticiones**

## Validación por niveles

| Nivel | Descripción | ¿Requiere dispositivo? |
|-------|-------------|----------------------|
| Implementado | Código escrito | No |
| Compilado en CI | Build verde en GitHub Actions | No |
| Validado en iPhone | Probado en el dispositivo real | **Sí** |

> El simulador de Xcode NO soporta ARKit. Nunca marcar como validado sin prueba en iPhone.

## Sin LiDAR (iPhone 12 no-Pro)

- ARKit detecta planos verticales por visión (feature points).
- No hay oclusión automática en MVP → se añade aviso en UI.
- Tracking mejora con buena iluminación y texturas visibles en la pared.
