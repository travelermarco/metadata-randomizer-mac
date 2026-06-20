import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Color palette

extension Color {
    static let appBg        = Color(red: 0.059, green: 0.059, blue: 0.102)  // #0F0F1A
    static let appAccent    = Color(red: 0.486, green: 0.302, blue: 1.000)  // #7C4DFF
    static let appSuccess   = Color(red: 0.298, green: 0.686, blue: 0.314)  // #4CAF50
    static let appSecondary = Color(red: 0.565, green: 0.565, blue: 0.690)  // #9090B0
    static let appCard      = Color(red: 0.102, green: 0.122, blue: 0.200)  // #1A1F33
    static let appDivider   = Color(red: 0.165, green: 0.184, blue: 0.290)  // #2A2F4A
    static let appUpdate    = Color(red: 0.1,   green: 0.18,  blue: 0.30)   // update bar bg
}

// MARK: - Ghost icon (same SVG path as Android vector drawable)

struct GhostShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width  / 108.0
        let sy = rect.height / 108.0
        func pt(_ x: Double, _ y: Double) -> CGPoint { .init(x: x * sx, y: y * sy) }
        var p = Path()
        p.move(to: pt(54, 16))
        p.addCurve(to: pt(28, 44), control1: pt(38, 16), control2: pt(28, 28))
        p.addLine(to: pt(28, 76))
        p.addLine(to: pt(36, 68))
        p.addLine(to: pt(44, 76))
        p.addLine(to: pt(54, 66))
        p.addLine(to: pt(64, 76))
        p.addLine(to: pt(72, 68))
        p.addLine(to: pt(80, 76))
        p.addLine(to: pt(80, 44))
        p.addCurve(to: pt(54, 16), control1: pt(80, 28), control2: pt(70, 16))
        p.closeSubpath()
        return p
    }
}

struct GhostView: View {
    var size: CGFloat = 72
    var body: some View {
        ZStack {
            GhostShape().fill(Color.white).frame(width: size, height: size)
            Circle().fill(Color.appAccent)
                .frame(width: size * 12/108, height: size * 12/108)
                .offset(x: (38 - 54) / 108 * size, y: (40 - 54) / 108 * size)
            Circle().fill(Color.appAccent)
                .frame(width: size * 12/108, height: size * 12/108)
                .offset(x: (70 - 54) / 108 * size, y: (40 - 54) / 108 * size)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - App model

struct ResultItem: Identifiable {
    let id      = UUID()
    let url: URL
    let summary: String
}

@MainActor
final class AppModel: ObservableObject {

    enum State { case idle, processing(String), done([ResultItem]), failed(String) }

    @Published var state: State      = .idle
    @Published var updateInfo: UpdateInfo? = nil
    @Published var updateDismissed  = false
    @Published var isCheckingUpdate = false

    var showUpdateBanner: Bool { updateInfo != nil && !updateDismissed }

    // MARK: File processing

    func processFiles(_ urls: [URL]) async {
        let supported = urls.filter { isSupported($0) }
        guard !supported.isEmpty else {
            state = .failed("No supported files dropped.\nAccepted: JPG · HEIC · PNG · MP4 · MOV")
            return
        }

        var results: [ResultItem] = []
        for (index, url) in supported.enumerated() {
            state = .processing(supported.count == 1
                ? "Anonymizing metadata…"
                : "Processing \(index + 1) of \(supported.count)…")
            do {
                let (outURL, summary) = isVideo(url)
                    ? try await VideoProcessor.process(url: url)
                    : try ImageProcessor.process(url: url)
                results.append(ResultItem(url: outURL, summary: summary))
            } catch {
                print("[MetaRandom] \(url.lastPathComponent): \(error)")
            }
        }
        state = results.isEmpty
            ? .failed("Could not process any files. Check Console for details.")
            : .done(results)
    }

    func reset() { state = .idle }

    // MARK: Update check

    func checkForUpdates() async {
        isCheckingUpdate = true
        updateDismissed  = false
        updateInfo       = await UpdateChecker.check(current: AppVersion.current)
        isCheckingUpdate = false
    }

    // MARK: Install update

    enum InstallState { case idle, downloading, replacing }
    @Published var installState: InstallState = .idle
    @Published var installError: String?      = nil

    func installUpdate(_ info: UpdateInfo) async {
        guard let assetURL = info.assetURL else {
            // No binary attached — open browser as fallback
            NSWorkspace.shared.open(info.releaseURL)
            return
        }

        installState = .downloading
        installError = nil

        do {
            // 1. Download the ZIP
            let (localZip, _) = try await URLSession.shared.download(from: assetURL)

            // 2. Unzip into a temp directory
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("metarandom-update-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            let unzip = Process()
            unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            unzip.arguments     = ["-o", localZip.path, "-d", tempDir.path]
            unzip.standardOutput = FileHandle.nullDevice
            unzip.standardError  = FileHandle.nullDevice
            try unzip.run()
            unzip.waitUntilExit()

            // 3. Find the .app in the unzipped contents
            let contents = try FileManager.default.contentsOfDirectory(
                at: tempDir, includingPropertiesForKeys: nil)
            guard let newApp = contents.first(where: { $0.pathExtension == "app" }) else {
                throw NSError(domain: "UpdateInstaller", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "No .app found in ZIP"])
            }

            // 4. Determine current app path
            let currentApp = Bundle.main.bundleURL

            // 5. Write a detached shell script that replaces the app after this process exits
            let script = """
            #!/bin/bash
            # Wait for the app to fully quit
            sleep 2
            rm -rf '\(currentApp.path)'
            cp -R '\(newApp.path)' '\(currentApp.path)'
            # Remove quarantine so macOS doesn't block the updated app
            xattr -rd com.apple.quarantine '\(currentApp.path)' 2>/dev/null || true
            codesign --force --deep --sign - '\(currentApp.path)' 2>/dev/null || true
            open '\(currentApp.path)'
            rm -rf '\(tempDir.path)'
            """

            let scriptURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("metarandom_install.sh")
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

            // 6. Run detached (don't wait — we're about to quit)
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/bash")
            proc.arguments     = [scriptURL.path]
            proc.standardOutput = FileHandle.nullDevice
            proc.standardError  = FileHandle.nullDevice
            try proc.run()

            // 7. Quit so the script can replace the bundle
            installState = .replacing
            try await Task.sleep(nanoseconds: 300_000_000)  // brief pause for UI to show "Updating…"
            NSApplication.shared.terminate(nil)

        } catch {
            installState = .idle
            installError = "Update failed: \(error.localizedDescription)"
        }
    }

    // MARK: Helpers

    private func isVideo(_ url: URL) -> Bool {
        VideoProcessor.supportedExtensions.contains(url.pathExtension.lowercased())
    }
    private func isSupported(_ url: URL) -> Bool {
        let e = url.pathExtension.lowercased()
        return ImageProcessor.supportedExtensions.contains(e)
            || VideoProcessor.supportedExtensions.contains(e)
    }
}

// MARK: - Main view

struct ContentView: View {
    @StateObject private var model = AppModel()
    @State private var isTargeted  = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Update banner — pinned at the very top
                if model.showUpdateBanner, let info = model.updateInfo {
                    updateBanner(info)
                }

                // Main content
                VStack(spacing: 16) {
                    GhostView(size: 64).padding(.top, 16)

                    Text("Metadata Randomizer")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(0.4)

                    Group {
                        switch model.state {
                        case .idle:              idleView
                        case .processing(let m): processingView(m)
                        case .done(let items):   doneView(items)
                        case .failed(let m):     failedView(m)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 0)

                    Text("Developed by Marco and Yoshi 🗺️🙏🏼")
                        .font(.system(size: 10))
                        .foregroundColor(Color.appSecondary.opacity(0.55))
                        .padding(.bottom, 4)
                }
                .padding(32)
            }
        }
        .frame(width: 460, height: 560)
        .task { await model.checkForUpdates() }
        .onReceive(NotificationCenter.default.publisher(for: .checkForUpdates)) { _ in
            Task { await model.checkForUpdates() }
        }
    }

    // MARK: Update banner

    private func updateBanner(_ info: UpdateInfo) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(Color.appAccent)
                .font(.system(size: 14))

            // Label changes based on install state
            Group {
                switch model.installState {
                case .idle:
                    Text("Update v\(info.version) available")
                case .downloading:
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.6).tint(.white)
                        Text("Downloading…")
                    }
                case .replacing:
                    Text("Updating… closing app")
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)

            if let err = model.installError {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }

            Spacer()

            if model.installState == .idle {
                Button(info.assetURL != nil ? "Install" : "Download") {
                    Task { await model.installUpdate(info) }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.appAccent)
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.appAccent, lineWidth: 1))

                Button {
                    model.updateDismissed = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.appSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appUpdate)
        .overlay(Divider().foregroundColor(Color.appDivider), alignment: .bottom)
    }

    // MARK: Drop zone

    private var idleView: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isTargeted ? Color.appAccent : Color.appDivider,
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isTargeted ? Color.appAccent.opacity(0.08) : Color.appCard.opacity(0.5))
                    )
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 36))
                        .foregroundColor(isTargeted ? Color.appAccent : Color.appSecondary)
                    Text("Drop photos or videos here")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isTargeted ? .white : Color.appSecondary)
                    Text("JPG · HEIC · PNG · MP4 · MOV")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.appSecondary.opacity(0.7))
                        .tracking(1.2)
                }
                .padding()
            }
            .frame(height: 200)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                Task {
                    var urls: [URL] = []
                    for p in providers { if let u = await resolveURL(p) { urls.append(u) } }
                    await model.processFiles(urls)
                }
                return true
            }

            Text("GPS location, device, date and filename\nare replaced with randomized fake data.")
                .font(.system(size: 12))
                .foregroundColor(Color.appSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            // Manual update check
            Button {
                Task { await model.checkForUpdates() }
            } label: {
                HStack(spacing: 5) {
                    if model.isCheckingUpdate {
                        ProgressView().scaleEffect(0.6).tint(Color.appSecondary)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(model.isCheckingUpdate ? "Checking…" : "Check for updates")
                }
                .font(.system(size: 11))
                .foregroundColor(Color.appSecondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    // MARK: Processing

    private func processingView(_ message: String) -> some View {
        VStack(spacing: 20) {
            ProgressView().progressViewStyle(.circular).scaleEffect(1.3).tint(Color.appAccent)
            Text(message).font(.system(size: 14)).foregroundColor(Color.appSecondary)
        }
        .frame(height: 260)
    }

    // MARK: Done

    private func doneView(_ items: [ResultItem]) -> some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Anonymized", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.appSuccess)
                    .tracking(0.6)
                Divider().background(Color.appDivider)
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: item.url.pathExtension == "mp4" ? "video.fill" : "photo.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.appAccent)
                            .padding(.top, 2)
                        Text(item.summary)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white)
                            .lineSpacing(2)
                        Spacer()
                        Button {
                            NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: "")
                        } label: {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color.appSecondary)
                        }
                        .buttonStyle(.plain)
                        .help("Reveal in Finder")
                    }
                }
            }
            .padding(16)
            .background(Color.appCard)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.appDivider, lineWidth: 1))
            .cornerRadius(12)

            Text("Saved alongside original files.\nSend as File (not Photo) in Telegram to preserve metadata.")
                .font(.system(size: 11))
                .foregroundColor(Color.appSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Button(action: { model.reset() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Process more files")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.appAccent)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.appAccent, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Failed

    private func failedView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32)).foregroundColor(.orange)
            Text(message).font(.system(size: 13)).foregroundColor(Color.appSecondary)
                .multilineTextAlignment(.center).lineSpacing(3)
            Button(action: { model.reset() }) {
                Text("Try again")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.appAccent)
                    .padding(.horizontal, 20).padding(.vertical, 8)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.appAccent, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .frame(height: 260)
    }

    // MARK: URL resolution

    private func resolveURL(_ provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { cont in
            _ = provider.loadObject(ofClass: NSURL.self) { obj, _ in
                cont.resume(returning: obj as? URL)
            }
        }
    }
}
