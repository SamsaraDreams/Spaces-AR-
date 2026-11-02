// VisualizerView.swift
// Vista del visualizador AR – placeholder de Fase 2a.
// La implementación con ARView/RealityKit llega en Fase 3.

import SwiftUI

/// Contenedor de la experiencia AR. En Fase 3 alojará el `ARViewContainer`
/// que monta la sesión de ARKit y aplica el material del papel tapiz.
struct VisualizerView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "viewfinder.rectangular")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Visualizador AR")
                .font(.title2.bold())
            Text("Disponible en Fase 3")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VisualizerView()
}
