import AVFoundation
import Foundation
import WhisperKit
import os

actor TranscriptionEngine {
    private var whisperKit: WhisperKit?
    private let modelName = "large-v3"
    private let modelRepository = "argmaxinc/whisperkit-coreml"
    private let language = "cs"
    private let logger = Logger(subsystem: "com.example.dictator", category: "transcription")

    /// Aktivní slovník pro prompt biasing. Nastavuje `AppDelegate` snapshotem z `LearningEngine`
    /// (přes `dictatorLearnedTermsChanged` notifikaci) — TranscriptionEngine si o data sám neříká.
    private var vocabulary: VocabularyDictionary = .empty

    func applyVocabulary(_ snapshot: VocabularyDictionary) {
        vocabulary = snapshot
        DiagnosticsLogger.log("Vocabulary applied: entries=\(snapshot.entries.count)")
    }

    func load(progressHandler: @escaping @Sendable (ModelDownloadProgress) -> Void) async throws {
        if whisperKit != nil {
            progressHandler(ModelDownloadProgress(
                fraction: 1.0,
                downloadedBytes: ModelDownloadProgress.whisperLargeV3TotalBytes,
                totalBytes: ModelDownloadProgress.whisperLargeV3TotalBytes
            ))
            return
        }

        let cacheRoot = ModelDownloadMonitor.cacheRoot(for: modelRepository)
        progressHandler(ModelDownloadMonitor.snapshot(for: cacheRoot))
        DiagnosticsLogger.log("WhisperKit model load requested. model=\(modelName)")

        let progressTask = Task {
            let startedAt = Date()
            var lastLoggedMinute = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                progressHandler(ModelDownloadMonitor.snapshot(for: cacheRoot))

                let elapsedMinute = Int(Date().timeIntervalSince(startedAt) / 60)
                if elapsedMinute > lastLoggedMinute {
                    lastLoggedMinute = elapsedMinute
                    DiagnosticsLogger.log("WhisperKit model load still running. model=\(modelName), elapsedMinutes=\(elapsedMinute)")
                }
            }
        }

        do {
            let modelFolder = try await WhisperKit.download(
                variant: modelName,
                from: modelRepository
            ) { progress in
                progressHandler(ModelDownloadMonitor.snapshot(for: cacheRoot, progress: progress))
            }

            progressHandler(ModelDownloadMonitor.snapshot(for: cacheRoot, fraction: 1.0))

            whisperKit = try await WhisperKit(
                WhisperKitConfig(
                    modelFolder: modelFolder.path,
                    verbose: false,
                    logLevel: .none,
                    prewarm: false,
                    load: true,
                    download: false
                )
            )
            progressTask.cancel()
            progressHandler(ModelDownloadMonitor.snapshot(for: cacheRoot, fraction: 1.0))
            logger.info("WhisperKit model loaded")
            DiagnosticsLogger.log("WhisperKit model loaded")
            await warmUp()
        } catch {
            progressTask.cancel()
            DiagnosticsLogger.log("WhisperKit model load error: \(error.localizedDescription)")
            throw error
        }
    }

    func transcribe(audioURL: URL, peakRMS: Float) async throws -> RawTranscription {
        guard let whisperKit else { throw TranscriptionError.modelNotLoaded }

        DiagnosticsLogger.log("Audio file peakRMS=\(String(format: "%.4f", peakRMS))")
        guard peakRMS >= 0.002 else {
            DiagnosticsLogger.log("Transcription skipped: audio file too quiet")
            throw TranscriptionError.audioTooQuiet
        }

        let promptTokens = vocabularyPromptTokens(using: whisperKit)

        let options = DecodingOptions(
            task: .transcribe,
            language: language,
            temperature: 0.0,
            temperatureIncrementOnFallback: 0.2,
            temperatureFallbackCount: 1,
            usePrefillPrompt: true,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            wordTimestamps: false,
            promptTokens: promptTokens,
            suppressBlank: true,
            compressionRatioThreshold: 2.4,
            logProbThreshold: -1.0,
            noSpeechThreshold: 0.75
        )

        let results = try await whisperKit.transcribe(audioPath: audioURL.path, decodeOptions: options)
        let segments = results.flatMap { (result: TranscriptionResult) in result.segments }
        let raw = segments
            .map { (segment: TranscriptionSegment) in segment.text }
            .joined(separator: " ")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        DiagnosticsLogger.log("Transcription raw preview: \(raw.prefix(80))")

        guard let sanitized = TranscriptionSanitizer.sanitized(raw) else {
            DiagnosticsLogger.log("Transcription empty after sanitization (hallucination)")
            throw TranscriptionError.hallucinatedTranscript(raw)
        }

        let words = TranscriptionEngine.extractWordTokens(from: segments, fallbackText: sanitized)
        let duration = segments.last.map { Float($0.end) } ?? 0

        return RawTranscription(rawText: sanitized, words: words, durationSeconds: duration)
    }

    /// Mapuje WhisperKit `TranscriptionSegment.words` (s `WordTiming.probability`) na naše
    /// `WordToken`. Pokud `segment.words` je `nil` (Whisper word-timestamp alignment selhal),
    /// použijeme fallback: rozsekat `segment.text` po whitespace a každému slovu přiřadit
    /// confidence ze segmentového `avgLogprob`.
    private static func extractWordTokens(
        from segments: [TranscriptionSegment],
        fallbackText: String
    ) -> [WordToken] {
        var tokens: [WordToken] = []
        var hasAnyWordTiming = false

        for segment in segments {
            if let words = segment.words, !words.isEmpty {
                hasAnyWordTiming = true
                for timing in words {
                    let trimmed = timing.word.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { continue }
                    let probability = max(0, min(1, timing.probability))
                    tokens.append(WordToken(text: trimmed, confidence: probability))
                }
            } else {
                let segmentConfidence = max(0, min(1, Foundation.exp(segment.avgLogprob)))
                let pieces = segment.text
                    .split(whereSeparator: { $0.isWhitespace })
                    .map(String.init)
                for piece in pieces {
                    let trimmed = piece.trimmingCharacters(in: .punctuationCharacters)
                    guard !trimmed.isEmpty else { continue }
                    tokens.append(WordToken(text: trimmed, confidence: segmentConfidence))
                }
            }
        }

        if !hasAnyWordTiming && tokens.isEmpty {
            // Worst case: žádné segmenty s textem. Rozsekáme sanitizovaný fallback s neutrální confidence.
            let pieces = fallbackText
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
            for piece in pieces {
                let trimmed = piece.trimmingCharacters(in: .punctuationCharacters)
                guard !trimmed.isEmpty else { continue }
                tokens.append(WordToken(text: trimmed, confidence: 0.5))
            }
        }

        return tokens
    }

    /// Tokenizuje aktuální slovník pro WhisperKit `DecodingOptions.promptTokens`. Vrátí `nil`,
    /// když je slovník prázdný nebo není dostupný tokenizer.
    private func vocabularyPromptTokens(using whisperKit: WhisperKit) -> [Int]? {
        guard !vocabulary.isEmpty else { return nil }
        guard let tokenizer = whisperKit.tokenizer else { return nil }
        let prompt = vocabulary.whisperPrompt
        guard !prompt.isEmpty else { return nil }

        var tokens = tokenizer.encode(text: " " + prompt)
        // Whisper má prompt limit 224 tokenů; necháme si rezervu pro speciální tokeny.
        let maxPromptTokens = 200
        if tokens.count > maxPromptTokens {
            tokens = Array(tokens.suffix(maxPromptTokens))
        }
        DiagnosticsLogger.log("Vocabulary prompt tokens: count=\(tokens.count), preview=\(prompt.prefix(60))")
        return tokens
    }

    private func warmUp() async {
        guard let whisperKit else { return }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dictator-warmup-\(UUID().uuidString)")
            .appendingPathExtension("wav")
        defer { try? FileManager.default.removeItem(at: url) }

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        ), let silence = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 16_000) else {
            return
        }

        silence.frameLength = 16_000
        do {
            let file = try AVAudioFile(
                forWriting: url,
                settings: format.settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
            try file.write(from: silence)
            _ = try await whisperKit.transcribe(
                audioPath: url.path,
                decodeOptions: DecodingOptions(task: .transcribe, language: language)
            )
            logger.info("WhisperKit warmup completed")
            DiagnosticsLogger.log("WhisperKit warmup completed")
        } catch {
            logger.info("WhisperKit warmup skipped")
            DiagnosticsLogger.log("WhisperKit warmup skipped")
        }
    }
}

private enum ModelDownloadMonitor {
    static func cacheRoot(for repository: String) -> URL {
        let repo = HubApiWrapper.Repo(id: repository, type: .models)
        return HubApiWrapper.shared.localRepoLocation(repo)
    }

    static func snapshot(for cacheRoot: URL, progress: Progress? = nil, fraction forcedFraction: Double? = nil) -> ModelDownloadProgress {
        let totalBytes = ModelDownloadProgress.whisperLargeV3TotalBytes
        let downloadedBytes = min(directorySize(at: cacheRoot), totalBytes)
        let diskFraction = totalBytes > 0 ? Double(downloadedBytes) / Double(totalBytes) : 0
        let callbackFraction = progress?.fractionCompleted ?? 0
        let fraction = forcedFraction ?? max(diskFraction, callbackFraction)

        return ModelDownloadProgress(
            fraction: min(max(fraction, 0), 1),
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes
        )
    }

    private static func directorySize(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: []
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let fileSize = values.fileSize else {
                continue
            }
            total += Int64(fileSize)
        }
        return total
    }
}

/// Výstup `TranscriptionEngine.transcribe`. Text už prošel sanitizací (filtr halucinací ticha),
/// ale ne post-process replacement ze slovníku — ten aplikuje volající (AppDelegate) pomocí
/// `VocabularyDictionary.applyReplacementsWithTracking(to:)`, aby si zachoval `originalText`
/// pro UI tooltipy.
struct RawTranscription {
    let rawText: String
    let words: [WordToken]
    let durationSeconds: Float
}

enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case audioTooQuiet
    case hallucinatedTranscript(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "WhisperKit model is not loaded."
        case .audioTooQuiet:
            return "Audio is too quiet."
        case .hallucinatedTranscript:
            return "Whisper produced a known silence hallucination."
        }
    }
}
