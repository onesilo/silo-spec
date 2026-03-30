import Foundation

public struct SiloPackage {
    public let manifest: SiloManifest
    public let content: SiloContent
    public let refFiles: [String: Data]

    public static func open(at url: URL) throws -> SiloPackage {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("silo-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try unzip(source: url, destination: tempDir)

        let decoder = JSONDecoder()

        let manifestURL = tempDir.appendingPathComponent("manifest.json")
        let manifest = try decoder.decode(SiloManifest.self, from: Data(contentsOf: manifestURL))

        let siloURL = tempDir.appendingPathComponent("silo.json")
        let content = try decoder.decode(SiloContent.self, from: Data(contentsOf: siloURL))

        var refFiles: [String: Data] = [:]
        let refsDir = tempDir.appendingPathComponent("refs")
        if FileManager.default.fileExists(atPath: refsDir.path) {
            let files = try FileManager.default.contentsOfDirectory(
                at: refsDir, includingPropertiesForKeys: nil
            )
            for file in files {
                refFiles[file.lastPathComponent] = try Data(contentsOf: file)
            }
        }

        return SiloPackage(manifest: manifest, content: content, refFiles: refFiles)
    }

    private static func unzip(source: URL, destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", source.path, "-d", destination.path]
        process.standardOutput = nil
        process.standardError = nil
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "SiloPackage", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to unzip .silo package"])
        }
    }
}
