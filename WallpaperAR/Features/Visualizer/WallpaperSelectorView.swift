// WallpaperSelectorView.swift
// Barra horizontal deslizable con miniaturas del catálogo, para elegir el
// tapiz activo sin salir de la vista AR. Pieza planeada en fases anteriores
// (ver Docs/arquitectura.md y el historial del proyecto) que nunca se había
// implementado: su ausencia era una de las causas de que la app "careciera
// de interfaz" para el catálogo de tapices.

import SwiftUI

struct WallpaperSelectorView: View {

    let catalog: [Wallpaper]
    let selectedWallpaper: Wallpaper
    let onSelect: (Wallpaper) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(catalog) { wallpaper in
                    thumbnail(for: wallpaper)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 92)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func thumbnail(for wallpaper: Wallpaper) -> some View {
        let isSelected = wallpaper.id == selectedWallpaper.id

        return Button {
            onSelect(wallpaper)
        } label: {
            VStack(spacing: 4) {
                Group {
                    if let uiImg = UIImage(named: wallpaper.textureFile) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(.systemGray4)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 3)
                }

                Text(wallpaper.name)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: 60)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(wallpaper.name))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    let sample = Wallpaper(
        name: "Tapiz Referencia (53 cm)",
        textureFile: "tapiz_referencia.jpg",
        patternSpec: PatternSpec(patternWidthM: 0.53, patternHeightM: 0.53)
    )
    return WallpaperSelectorView(
        catalog: [sample],
        selectedWallpaper: sample,
        onSelect: { _ in }
    )
    .padding()
    .background(Color.black)
}
