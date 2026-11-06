// PatternSpec.swift
// Especificación física del patrón de papel tapiz.
// Sin dependencias de ARKit/RealityKit → compila en Linux (CI).

import Foundation

/// Dimensiones físicas reales del patrón repetible.
///
/// Para el rollo de referencia del proyecto:
///   - Ancho del rollo: 53 cm  → patternWidthM  = 0.53
///   - Alto del patrón: 53 cm  → patternHeightM = 0.53
///   (la imagen de textura es 560×560 px → ~10.6 px/cm)
public struct PatternSpec: Equatable, Sendable {

    /// Ancho del patrón en metros (eje X de la pared).
    public let patternWidthM: Double

    /// Alto del patrón en metros (eje Y de la pared).
    public let patternHeightM: Double

    /// Resolución horizontal de la textura en píxeles (informativo).
    public let textureWidthPx: Int?

    /// Resolución vertical de la textura en píxeles (informativo).
    public let textureHeightPx: Int?

    public init(
        patternWidthM: Double,
        patternHeightM: Double,
        textureWidthPx: Int? = nil,
        textureHeightPx: Int? = nil
    ) {
        // Valores inválidos se normalizan a 0.53 m (ancho estándar del rollo)
        // para evitar crashes por división entre cero en UVScaleCalculator.
        self.patternWidthM  = patternWidthM  > 0 ? patternWidthM  : 0.53
        self.patternHeightM = patternHeightM > 0 ? patternHeightM : 0.53
        self.textureWidthPx = textureWidthPx
        self.textureHeightPx = textureHeightPx
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    /// Densidad horizontal en px/m (nil si no se conoce la resolución).
    public var pixelsPerMeterX: Double? {
        guard let px = textureWidthPx else { return nil }
        return Double(px) / patternWidthM
    }

    /// Densidad vertical en px/m.
    public var pixelsPerMeterY: Double? {
        guard let px = textureHeightPx else { return nil }
        return Double(px) / patternHeightM
    }
}
