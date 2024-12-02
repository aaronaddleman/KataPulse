import AVFoundation
import os.log

struct AudioCueHelper {
    private static let logger = Logger(subsystem: "cc.addleman.Kata-Pulse", category: "AudioCueHelper")
    private static var audioPlayer: AVAudioPlayer?

    // Map of items to corresponding audio file names
    private static let audioFileMap: [String: String] = [
        "handstaff a": "hand staff a.mp3",
        "handstaff b": "hand staff a.mp3",
        "Congratulations": "congratulations.mp3",
        "Strike Right": "strike_right.mp3",
        "Strike Left": "strike_left.mp3"
    ]
    
    private static func normalizeKey(_ key: String) -> String {
        return key.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func playAudio(for currentItem: String) {
        let normalizedKey = normalizeKey(currentItem)
        print("normalizedKey: \(normalizedKey)")
        guard let fileName = audioFileMap[normalizedKey] else {
            logger.error("No audio file mapped for item: \(currentItem)")
            return
        }
        let fileComponents = fileName.split(separator: ".")
        guard fileComponents.count == 2,
              let name = fileComponents.first,
              let ext = fileComponents.last else {
            logger.error("Invalid file name format: \(fileName)")
            return
        }
        playAudioFile(named: String(name), withExtension: String(ext))
    }

    private static func playAudioFile(named fileName: String, withExtension ext: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            logger.error("Audio file \(fileName).\(ext) not found.")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            logger.log("Playing audio file: \(fileName).\(ext)")
        } catch {
            logger.error("Failed to play audio file: \(error.localizedDescription)")
        }
    }

    private static func configureAudioSessionIfNeeded() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.duckOthers]
            )
            try audioSession.setActive(true)
            logger.log("Audio session configured for playback.")
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}
