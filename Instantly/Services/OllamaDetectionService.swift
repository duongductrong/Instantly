import AppKit
import Foundation

/// Service for detecting Ollama installation, running status, and available models.
enum OllamaDetectionService {
    // MARK: - Models

    struct OllamaModel: Codable, Identifiable {
        let name: String
        let size: Int64?
        let digest: String?

        var id: String {
            name
        }

        /// Display-friendly label (e.g. "llama3.1:latest" → "llama3.1")
        var displayName: String {
            if let colonIndex = name.firstIndex(of: ":") {
                let tag = name[name.index(after: colonIndex)...]
                if tag == "latest" {
                    return String(name[..<colonIndex])
                }
            }
            return name
        }
    }

    private struct TagsResponse: Codable {
        let models: [OllamaModelEntry]
    }

    private struct OllamaModelEntry: Codable {
        let name: String
        let size: Int64?
        let digest: String?
    }

    // MARK: - Installation Check

    /// Checks if the `ollama` CLI is available on the system PATH.
    static func isOllamaInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ollama"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    // MARK: - Running Check

    /// Checks if Ollama server is reachable at the given base URL.
    static func isOllamaRunning(baseURL: String = "http://localhost:11434") async -> Bool {
        await OllamaChatService.isAvailable(baseURL: baseURL)
    }

    // MARK: - Fetch Models

    /// Fetches available models from the Ollama API.
    static func fetchAvailableModels(
        baseURL: String = "http://localhost:11434"
    ) async
        -> [OllamaModel]
    {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "\(trimmed)/api/tags") else { return [] }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                return []
            }

            let decoded = try JSONDecoder().decode(TagsResponse.self, from: data)
            return decoded.models.map { entry in
                OllamaModel(name: entry.name, size: entry.size, digest: entry.digest)
            }
        } catch {
            return []
        }
    }

    // MARK: - Actions

    /// Opens the Ollama download page in the default browser.
    static func openDownloadPage() {
        guard let url = URL(string: "https://ollama.ai/download") else { return }
        NSWorkspace.shared.open(url)
    }
}
