// ContentView.swift
// Vista raíz – placeholder hasta Fase 3 (AR Visualizer).

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            Text("WallpaperAR")
                .font(.largeTitle.bold())

            Text("Visualizador de papel tapiz en realidad aumentada")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Fase 2a – Estructura lista ✓\nFase 3 – Visualizador AR próximamente")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
