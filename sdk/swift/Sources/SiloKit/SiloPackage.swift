import Foundation

public struct SiloPackage: Sendable {
    public let manifest: SiloManifest
    public let content: SiloContent
    public let refFiles: [String: Data]

    public init(manifest: SiloManifest, content: SiloContent, refFiles: [String: Data] = [:]) {
        self.manifest = manifest
        self.content = content
        self.refFiles = refFiles
    }

    // MARK: - Open (read .silo package)

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
            let files = try FileManager.default.contentsOfDirectory(at: refsDir, includingPropertiesForKeys: nil)
            for file in files {
                refFiles[file.lastPathComponent] = try Data(contentsOf: file)
            }
        }

        return SiloPackage(manifest: manifest, content: content, refFiles: refFiles)
    }

    // MARK: - Create (write .silo package)

    /// Creates a .silo zip package from a manifest, content, and optional ref files directory.
    ///
    /// - Parameters:
    ///   - manifest: The silo manifest.
    ///   - content: The silo content (silo.json).
    ///   - refsDirectory: Optional URL to a directory of ref files to include.
    /// - Returns: URL of the created .silo file in a temporary directory.
    public static func create(
        manifest: SiloManifest,
        content: SiloContent,
        refsDirectory: URL? = nil
    ) throws -> URL {
        let stagingDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("silo-build-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: stagingDir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let manifestData = try encoder.encode(manifest)
        try manifestData.write(to: stagingDir.appendingPathComponent("manifest.json"))

        let contentData = try encoder.encode(content)
        try contentData.write(to: stagingDir.appendingPathComponent("silo.json"))

        let refsTarget = stagingDir.appendingPathComponent("refs")
        try FileManager.default.createDirectory(at: refsTarget, withIntermediateDirectories: true)

        if let refsDir = refsDirectory, FileManager.default.fileExists(atPath: refsDir.path) {
            let files = try FileManager.default.contentsOfDirectory(at: refsDir, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.copyItem(
                    at: file,
                    to: refsTarget.appendingPathComponent(file.lastPathComponent)
                )
            }
        }

        return try zip(directory: stagingDir, name: manifest.title)
    }

    // MARK: - Zip (NSFileCoordinator — iOS compatible)

    private static func zip(directory: URL, name: String) throws -> URL {
        var error: NSError?
        var resultURL: URL?

        let coordinator = NSFileCoordinator()
        coordinator.coordinate(
            readingItemAt: directory,
            options: .forUploading,
            error: &error
        ) { zipURL in
            let destDir = FileManager.default.temporaryDirectory
            let sanitized = name.replacingOccurrences(of: "/", with: "-")
            let dest = destDir.appendingPathComponent("\(sanitized).silo")
            try? FileManager.default.removeItem(at: dest)
            try? FileManager.default.copyItem(at: zipURL, to: dest)
            resultURL = dest
        }

        if let error { throw error }
        guard let result = resultURL else {
            throw SiloPackageError.zipFailed
        }
        return result
    }

    // MARK: - Unzip (minimal PKZip local header parser)

    private static func unzip(source: URL, destination: URL) throws {
        let data = try Data(contentsOf: source)
        var offset = 0

        while offset + 30 <= data.count {
            let sig = data.subdata(in: offset..<offset + 4)
            guard sig == Data([0x50, 0x4B, 0x03, 0x04]) else { break }

            let compressionMethod = data.uint16(at: offset + 8)
            let compressedSize = Int(data.uint32(at: offset + 18))
            let uncompressedSize = Int(data.uint32(at: offset + 22))
            let fileNameLength = Int(data.uint16(at: offset + 26))
            let extraFieldLength = Int(data.uint16(at: offset + 28))

            let fileNameStart = offset + 30
            guard fileNameStart + fileNameLength <= data.count else { break }

            let fileNameData = data.subdata(in: fileNameStart..<fileNameStart + fileNameLength)
            guard let fileName = String(data: fileNameData, encoding: .utf8) else {
                offset = fileNameStart + fileNameLength + extraFieldLength + compressedSize
                continue
            }

            let dataStart = fileNameStart + fileNameLength + extraFieldLength

            // Skip macOS resource forks and hidden metadata
            if fileName.hasPrefix("__MACOSX") || fileName.contains("/.") {
                offset = dataStart + compressedSize
                continue
            }

            let fileURL = destination.appendingPathComponent(fileName)

            if fileName.hasSuffix("/") {
                try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
            } else {
                let parentDir = fileURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)

                guard dataStart + compressedSize <= data.count else { break }
                let fileData = data.subdata(in: dataStart..<dataStart + compressedSize)

                if compressionMethod == 0 {
                    try fileData.write(to: fileURL)
                } else if compressionMethod == 8 {
                    let decompressed = try decompress(fileData, expectedSize: uncompressedSize)
                    try decompressed.write(to: fileURL)
                } else {
                    throw SiloPackageError.unsupportedCompression(method: Int(compressionMethod))
                }
            }

            offset = dataStart + compressedSize
        }
    }

    private static func decompress(_ data: Data, expectedSize: Int) throws -> Data {
        // Raw DEFLATE decompression via Foundation's built-in support
        let decompressed = try (data as NSData).decompressed(using: .zlib) as Data
        return decompressed
    }
}

// MARK: - Data Helpers

private extension Data {
    func uint16(at offset: Int) -> UInt16 {
        withUnsafeBytes { buffer in
            buffer.load(fromByteOffset: offset, as: UInt16.self).littleEndian
        }
    }

    func uint32(at offset: Int) -> UInt32 {
        withUnsafeBytes { buffer in
            buffer.load(fromByteOffset: offset, as: UInt32.self).littleEndian
        }
    }
}

// MARK: - Errors

public enum SiloPackageError: LocalizedError {
    case zipFailed
    case unsupportedCompression(method: Int)

    public var errorDescription: String? {
        switch self {
        case .zipFailed:
            return "Failed to create .silo zip package"
        case .unsupportedCompression(let method):
            return "Unsupported ZIP compression method: \(method)"
        }
    }
}
