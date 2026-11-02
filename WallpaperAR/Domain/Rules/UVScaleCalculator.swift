// UVScaleCalculator.swift
// Reglas de escala UV para proyectar el patrón a tamaño físico real.
// Sin dependencias de ARKit/RealityKit → testeable en CI Linux.
//
// Fórmula:
//   tilesX = wallWidthM  / patternWidthM
//   tilesY = wallHeightM / patternHeightM
//
// RealityKit interpreta el tiling como número de repeticiones
// sobre la superficie; 1.0 = el patrón ocupa toda la cara.

import Foundation

/// Calcula cuántas veces se repite el patrón sobre una superficie.
public struct UVScaleCalculator {

    /// Número de repeticiones del patrón en cada eje.
    public struct TilingResult: Equatable {
        /// Repeticiones horizontales (eje X / ancho de pared).
        public let tilesX: Double
        /// Repeticiones verticales (eje Y / alto de pared).
        public let tilesY: Double

        /// Devuelve `true` si el patrón no está estirado
        /// (la relación de aspecto se preserva dentro de ±1%).
        public var isProportional: Bool {
            guard tilesX > 0, tilesY > 0 else { return false }
            let ratio = tilesX / tilesY
            return abs(ratio - 1.0) < 0.01  // patrón cuadrado: tilesX ≈ tilesY
        }
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: – API principal
    // ────────────────────────────────────────────────────────────────────

    /// Calcula el tiling para cubrir `surface` con el patrón de `wallpaper`.
    ///
    /// - Parameters:
    ///   - surface: Superficie de pared detectada (dimensiones en metros).
    ///   - patternSpec: Especificación física del patrón.
    /// - Returns: `TilingResult` listo para aplicar a `PhysicallyBasedMaterial`.
    public static func tiling(
        for surface: WallSurface,
        patternSpec: PatternSpec
    ) -> TilingResult {
        return tiling(
            wallWidthM: surface.widthM,
            wallHeightM: surface.heightM,
            patternSpec: patternSpec
        )
    }

    /// Variante con dimensiones explícitas (útil en tests y previews).
    public static func tiling(
        wallWidthM: Double,
        wallHeightM: Double,
        patternSpec: PatternSpec
    ) -> TilingResult {
        precondition(wallWidthM > 0,  "wallWidthM debe ser > 0")
        precondition(wallHeightM > 0, "wallHeightM debe ser > 0")

        let tilesX = wallWidthM  / patternSpec.patternWidthM
        let tilesY = wallHeightM / patternSpec.patternHeightM

        return TilingResult(tilesX: tilesX, tilesY: tilesY)
    }

    // ────────────────────────────────────────────────────────────────────
    // MARK: – Helpers de diagnóstico
    // ────────────────────────────────────────────────────────────────────

    /// Número de rollos enteros necesarios para cubrir la pared (redondeado al alza).
    /// Útil para la estimación de materiales.
    ///
    /// - Parameters:
    ///   - rollLengthM: Largo lineal del rollo (por defecto 10 m, estándar del proyecto).
    ///   - rollWidthM:  Ancho del rollo (por defecto 0.53 m, estándar del proyecto).
    public static func rollsNeeded(
        for surface: WallSurface,
        rollLengthM: Double = 10.0,
        rollWidthM: Double = 0.53
    ) -> Int {
        // Franjas verticales completas
        let strips = Int(ceil(surface.widthM / rollWidthM))
        // Cortes por franja (pared de 2.5 m → ⌈2.5/10⌉ = 1 por franja)
        let cutsPerStrip = Int(ceil(surface.heightM / rollLengthM))
        // Metros por franja dividido por largo del rollo
        let stripsPerRoll = max(1, Int(floor(rollLengthM / surface.heightM)))
        let totalCuts = strips * cutsPerStrip
        return Int(ceil(Double(totalCuts) / Double(stripsPerRoll)))
    }
}
