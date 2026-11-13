// CatalogLoader.swift
// Carga el catálogo de papeles tapiz desde catalog.json (bundle o Data cruda).
// Sin dependencias de ARKit/RealityKit → compila y se prueba en Linux (CI).
//
// CONTEXTO: este archivo estaba planeado desde fases anteriores del proyecto
// (ver Docs/arquitectura.md y el historial de la conversación) pero nunca
// llegó a implementarse — ContentView.swift seguía usando un único Wallpaper
// hardcodeado. Esa es la causa de que la app "careciera de interfaz" para
// elegir entre varios tapices: no existía ningún código que leyera
// catalog.json ni ninguna barra de selección (ver WallpaperSelectorView.swift).
//
// IMPORTANTE: catalog.json hoy solo contiene la entrada de referencia
// (tapiz_referencia). El catálogo real DELUX (56 imágenes) sigue pendiente
// de subirse — no se inventan aquí códigos ni entradas adicionales, por
// una decisión explícita de proyecto documentada en sesiones previas
// (se detectaron y descartaron códigos DELUX fabricados anteriormente).
// Esta clase solo deja la infraestructura lista para cuando esas imágenes
// y sus metadatos reales se agreguen a catalog.json.

import Foundation

/// Carga y decodifica el catálogo de papeles tapiz (`catalog.json`) hacia
/// el modelo de dominio `Wallpaper`.
public enum CatalogLoader {

    /// Errores posibles al cargar el catálogo.
    public enum LoadError: Error, LocalizedError, Equatable {
        case resourceNotFound(String)
        case decodingFailed(String)

        public var errorDescription: String? {
            switch self {
            case .resourceNotFound(let name):
                return "No se encontró el recurso '\(name)' en el bundle."
            case .decodingFailed(let reason):
                return "No se pudo decodificar el catálogo: \(reason)"
            }
        }
    }

    /// Representación intermedia (DTO) del JSON. Deliberadamente más
    /// permisiva que el modelo de dominio: un campo faltante u opcional
    /// no debe tumbar el catálogo completo, solo esa entrada puntual
    /// (ver `loadWallpapers(from:)`).
    struct WallpaperDTO: Decodable {
        let id: String?
        let name: String
        let textureFile: String
        let patternWidthM: Double
        let patternHeightM: Double
        let textureWidthPx: Int?
        let textureHeightPx: Int?
        // rollLengthM / rollWidthM: presentes en catalog.json para uso futuro
        // (rollos con medidas distintas al estándar de 10 m × 53 cm), pero
        // el modelo de dominio Wallpaper/PatternSpec aún no los almacena.
        // Se omiten aquí deliberadamente en vez de inventarles un lugar en
        // el modelo sin que el resto del pipeline (UVScaleCalculator) los use.
        let tileable: Bool?
        let notes: String?
    }

    /// Decodifica un catálogo a partir de datos JSON crudos.
    ///
    /// Una entrada individual inválida (dimensiones ≤ 0, `textureFile`
    /// vacío) se descarta silenciosamente en vez de invalidar el catálogo
    /// entero — un único registro corrupto no debe impedir mostrar el
    /// resto de los tapices ya válidos.
    ///
    /// - Throws: `LoadError.decodingFailed` si el JSON no tiene la forma
    ///   esperada (no es un arreglo de objetos con los campos requeridos).
    public static func loadWallpapers(from data: Data) throws -> [Wallpaper] {
        let dtos: [WallpaperDTO]
        do {
            dtos = try JSONDecoder().decode([WallpaperDTO].self, from: data)
        } catch {
            throw LoadError.decodingFailed(error.localizedDescription)
        }

        return dtos.compactMap { dto -> Wallpaper? in
            guard dto.patternWidthM > 0,
                  dto.patternHeightM > 0,
                  !dto.textureFile.isEmpty else {
                #if DEBUG
                print("[CatalogLoader] Entrada de catálogo inválida descartada: \(dto.name)")
                #endif
                return nil
            }

            let id = dto.id.flatMap(UUID.init(uuidString:)) ?? UUID()

            return Wallpaper(
                id: id,
                name: dto.name,
                textureFile: dto.textureFile,
                patternSpec: PatternSpec(
                    patternWidthM: dto.patternWidthM,
                    patternHeightM: dto.patternHeightM,
                    textureWidthPx: dto.textureWidthPx,
                    textureHeightPx: dto.textureHeightPx
                ),
                tileable: dto.tileable ?? true,
                notes: dto.notes
            )
        }
    }

    /// Carga el catálogo desde un recurso JSON del bundle de la app.
    ///
    /// - Parameters:
    ///   - resourceName: Nombre del recurso sin extensión (por defecto "catalog").
    ///   - bundle: Bundle donde buscar el recurso (por defecto `.main`, el
    ///     bundle de la app en tiempo de ejecución en el dispositivo).
    /// - Throws: `LoadError.resourceNotFound` si el archivo no está en el bundle.
    public static func loadWallpapers(
        resourceName: String = "catalog",
        bundle: Bundle = .main
    ) throws -> [Wallpaper] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw LoadError.resourceNotFound("\(resourceName).json")
        }
        let data = try Data(contentsOf: url)
        return try loadWallpapers(from: data)
    }
}
