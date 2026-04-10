import Foundation

enum BundleJSONLoader {
    static func loadArray<T: Decodable>(
        _ type: T.Type,
        named fileName: String,
        bundle: Bundle = .main
    ) -> [T]? {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            print("Failed to load \(fileName).json: \(error)")
            return nil
        }
    }
}
