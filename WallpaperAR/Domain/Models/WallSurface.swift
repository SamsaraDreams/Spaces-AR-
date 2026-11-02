// WallSurface.swift
// Representa una superficie de pared detectada por ARKit.
// Sin dependencias de ARKit → compila en Linux.

import Foundation

/// Orientación de la superficie detectada.
public enum SurfaceOrientation: String, Equatable, Sendable {
    case vertical   // pared
    case horizontal // suelo / techo
}

/// Una superficie plana detectada por ARKit con sus dimensiones estimadas.
public struct WallSurface: Identifiable, Equatable, Sendable {

    public let id: UUID

    /// Orientación de la superficie.
    public let orientation: SurfaceOrientation

    /// Ancho estimado en metros.
    public let widthM: Double

    /// Alto estimado en metros.
    public let heightM: Double

    public init(
        id: UUID = UUID(),
        orientation: SurfaceOrientation,
        widthM: Double,
        heightM: Double
    ) {
        self.id = id
        self.orientation = orientation
        self.widthM = widthM
        self.heightM = heightM
    }

    /// Área en m².
    public var areaM2: Double { widthM * heightM }
}
