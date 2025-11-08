import CoreData
import Foundation

actor BackupService {
    private let persistence: PersistenceController
    private let fileManager = FileManager.default

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func exportBackup() async {
        guard let storeURL = await MainActor.run(resultType: URL?.self, body: {
            persistence.viewContext.persistentStoreCoordinator?.persistentStores.first?.url
        }) else { return }
        let documents = documentsDirectory()
        let destination = documents.appendingPathComponent("KitsuneReaderBackup.zip")
        let cacheDirectory = documents.appendingPathComponent("BackupTemp", isDirectory: true)
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let sqliteURL = cacheDirectory.appendingPathComponent("KitsuneReader.sqlite")
        try? fileManager.removeItem(at: sqliteURL)
        try? fileManager.copyItem(at: storeURL, to: sqliteURL)
        let entries = [ZipEntry(filename: "KitsuneReader.sqlite", data: (try? Data(contentsOf: sqliteURL)) ?? Data())]
        do {
            let writer = ZipWriter()
            try writer.write(entries: entries, to: destination)
        } catch {
            print("バックアップ作成失敗", error)
        }
    }

    func importBackup() async {
        let documents = documentsDirectory()
        let archiveURL = documents.appendingPathComponent("KitsuneReaderBackup.zip")
        guard fileManager.fileExists(atPath: archiveURL.path) else { return }
        do {
            let reader = ZipWriter()
            let entries = try reader.unzipEntries(from: archiveURL)
        guard let sqliteData = entries.first(where: { $0.filename == "KitsuneReader.sqlite" })?.data,
              let storeURL = await MainActor.run(resultType: URL?.self, body: {
                  persistence.viewContext.persistentStoreCoordinator?.persistentStores.first?.url
              }) else { return }
            try sqliteData.write(to: storeURL, options: .atomic)
        } catch {
            print("バックアップ復元失敗", error)
        }
    }

    private func documentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

struct ZipEntry {
    let filename: String
    let data: Data
}

final class ZipWriter {
    private let localHeaderSignature: UInt32 = 0x04034b50
    private let centralHeaderSignature: UInt32 = 0x02014b50
    private let endSignature: UInt32 = 0x06054b50
    private let version: UInt16 = 20

    func write(entries: [ZipEntry], to url: URL) throws {
        var fileData = Data()
        var centralDirectory = Data()
        var offset: UInt32 = 0
        for entry in entries {
            let crc = crc32(entry.data)
            let localHeader = makeLocalHeader(crc: crc, size: UInt32(entry.data.count), name: entry.filename)
            fileData.append(localHeader)
            fileData.append(entry.data)
            let centralHeader = makeCentralDirectoryHeader(crc: crc,
                                                           size: UInt32(entry.data.count),
                                                           name: entry.filename,
                                                           offset: offset)
            centralDirectory.append(centralHeader)
            offset += UInt32(localHeader.count + entry.data.count)
        }
        let endRecord = makeEndRecord(entryCount: UInt16(entries.count),
                                      centralSize: UInt32(centralDirectory.count),
                                      centralOffset: offset)
        fileData.append(centralDirectory)
        fileData.append(endRecord)
        try fileData.write(to: url, options: .atomic)
    }

    func unzipEntries(from url: URL) throws -> [ZipEntry] {
        let data = try Data(contentsOf: url)
        var entries: [ZipEntry] = []
        var cursor = 0
        while cursor + 30 <= data.count {
            guard cursor + 30 <= data.count else { break }
            let signature = UInt32(littleEndian: data[cursor..<cursor+4].withUnsafeBytes { $0.load(as: UInt32.self) })
            if signature != localHeaderSignature { break }
            let nameLength = Int(UInt16(littleEndian: data[cursor+26..<cursor+28].withUnsafeBytes { $0.load(as: UInt16.self) }))
            let extraLength = Int(UInt16(littleEndian: data[cursor+28..<cursor+30].withUnsafeBytes { $0.load(as: UInt16.self) }))
            let nameStart = cursor + 30
            let dataStart = nameStart + nameLength + extraLength
            let size = Int(UInt32(littleEndian: data[cursor+18..<cursor+22].withUnsafeBytes { $0.load(as: UInt32.self) }))
            guard dataStart + size <= data.count else { break }
            let nameData = data[nameStart..<nameStart+nameLength]
            let filename = String(data: nameData, encoding: .utf8) ?? "file"
            let content = data[dataStart..<dataStart+size]
            entries.append(ZipEntry(filename: filename, data: Data(content)))
            cursor = dataStart + size
        }
        return entries
    }

    private func makeLocalHeader(crc: UInt32, size: UInt32, name: String) -> Data {
        var data = Data()
        data.append(uint32: localHeaderSignature)
        data.append(uint16: version)
        data.append(uint16: 0) // general flag
        data.append(uint16: 0) // compression
        data.append(uint16: 0)
        data.append(uint16: 0)
        data.append(uint32: crc)
        data.append(uint32: size)
        data.append(uint32: size)
        let nameData = name.data(using: .utf8) ?? Data()
        data.append(uint16: UInt16(nameData.count))
        data.append(uint16: 0)
        data.append(nameData)
        return data
    }

    private func makeCentralDirectoryHeader(crc: UInt32, size: UInt32, name: String, offset: UInt32) -> Data {
        var data = Data()
        data.append(uint32: centralHeaderSignature)
        data.append(uint16: version)
        data.append(uint16: version)
        data.append(uint16: 0)
        data.append(uint16: 0)
        data.append(uint16: 0)
        data.append(uint16: 0)
        data.append(uint32: crc)
        data.append(uint32: size)
        data.append(uint32: size)
        let nameData = name.data(using: .utf8) ?? Data()
        data.append(uint16: UInt16(nameData.count))
        data.append(uint16: 0)
        data.append(uint16: 0)
        data.append(uint16: 0)
        data.append(uint16: 0)
        data.append(uint32: 0)
        data.append(uint32: offset)
        data.append(nameData)
        return data
    }

    private func makeEndRecord(entryCount: UInt16, centralSize: UInt32, centralOffset: UInt32) -> Data {
        var data = Data()
        data.append(uint32: endSignature)
        data.append(uint16: 0)
        data.append(uint16: 0)
        data.append(uint16: entryCount)
        data.append(uint16: entryCount)
        data.append(uint32: centralSize)
        data.append(uint32: centralOffset)
        data.append(uint16: 0)
        return data
    }

    private func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffffffff
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xff)
            crc = (crc >> 8) ^ crcTable[index]
        }
        return crc ^ 0xffffffff
    }

    private let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                if c & 1 == 1 {
                    c = 0xedb88320 ^ (c >> 1)
                } else {
                    c >>= 1
                }
            }
            return c
        }
    }()
}

private extension Data {
    mutating func append(uint16: UInt16) {
        var value = uint16.littleEndian
        Swift.withUnsafeBytes(of: &value) { append(contentsOf: $0) }
    }

    mutating func append(uint32: UInt32) {
        var value = uint32.littleEndian
        Swift.withUnsafeBytes(of: &value) { append(contentsOf: $0) }
    }
}
