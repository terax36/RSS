#if !SWIFT_PACKAGE
import BackgroundTasks
#endif
import Combine
import CoreData
import SwiftUI

#if !SWIFT_PACKAGE
@main
struct KitsuneReaderApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    @StateObject private var hub = ServiceHub()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                #if os(macOS)
                if #available(macOS 13.0, *) {
                    TabRootView()
                } else {
                    TabRootViewMac12()
                }
                #else
                TabRootView()
                #endif
            }
            .environmentObject(hub)
            .environmentObject(hub.settings)
            .environment(\.managedObjectContext, hub.persistence.viewContext)
            .preferredColorScheme(hub.settings.colorScheme)
            .task { await hub.bootstrap() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                BackgroundScheduler.shared.scheduleIfNeeded()
            }
        }
    }

    #if os(iOS)
    final class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication,
                         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
            BackgroundScheduler.shared.register()
            return true
        }
    }
    #endif
}
#endif

@MainActor
final class ServiceHub: ObservableObject {
    let persistence = PersistenceController.shared
    let httpClient = HTTPClient()
    lazy var feedFetcher = FeedFetcher(client: httpClient)
    lazy var faviconFetcher = FaviconFetcher(client: httpClient)
    let parser = FeedParserService()
    let readability = Readability()
    let sanitizer = HTMLSanitizer()
    lazy var translationService: TranslationService = TranslationCoordinator()
    lazy var subscriptionService = SubscriptionService(persistence: persistence,
                                                       parser: parser,
                                                       fetcher: feedFetcher,
                                                       faviconFetcher: faviconFetcher)
    lazy var articleService = ArticleService(persistence: persistence,
                                             readability: readability,
                                             sanitizer: sanitizer,
                                             fetcher: feedFetcher,
                                             translation: translationService)
    lazy var ruleService = RuleService(persistence: persistence)
    lazy var searchService = SearchService(persistence: persistence)
    lazy var backupService = BackupService(persistence: persistence)
    lazy var settings = SettingsStore(persistence: persistence)

    init() {
        BackgroundScheduler.shared.configure(hub: self)
    }

    func bootstrap() async {
        await subscriptionService.ensureDefaults()
        await articleService.compactIfNeeded(retentionDays: settings.retentionDays)
        await ruleService.ensureDefaults()
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    enum ThemeMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark
        var id: String { rawValue }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    @Published var themeMode: ThemeMode
    @Published var retentionDays: Int
    @Published var markReadThreshold: Double
    @Published var autoTranslateEnglishTitles: Bool
    @Published var cellularImageBlocking: Bool

    private let persistence: PersistenceController
    private let settingsObject: Settings

    init(persistence: PersistenceController) {
        self.persistence = persistence
        let context = persistence.viewContext
        let request: NSFetchRequest<Settings> = Settings.fetchRequest()
        if let obj = try? context.fetch(request).first {
            settingsObject = obj
        } else {
            let obj = Settings(context: context)
            obj.id = UUID()
            obj.themeMode = "system"
            obj.retentionDays = 30
            obj.markReadOnScrollThreshold = 0.7
            obj.autoTranslateEnglishTitles = false
            obj.cellularImageBlocking = false
            settingsObject = obj
            persistence.save()
        }
        themeMode = ThemeMode(rawValue: settingsObject.themeMode) ?? .system
        retentionDays = Int(settingsObject.retentionDays)
        markReadThreshold = settingsObject.markReadOnScrollThreshold
        autoTranslateEnglishTitles = settingsObject.autoTranslateEnglishTitles
        cellularImageBlocking = settingsObject.cellularImageBlocking
        bind()
    }

    var colorScheme: ColorScheme? { themeMode.colorScheme }

    private func bind() {
        $themeMode.dropFirst().sink { [weak self] _ in self?.persist() }.store(in: &cancellables)
        $retentionDays.dropFirst().sink { [weak self] _ in self?.persist() }.store(in: &cancellables)
        $markReadThreshold.dropFirst().sink { [weak self] _ in self?.persist() }.store(in: &cancellables)
        $autoTranslateEnglishTitles.dropFirst().sink { [weak self] _ in self?.persist() }.store(in: &cancellables)
        $cellularImageBlocking.dropFirst().sink { [weak self] _ in self?.persist() }.store(in: &cancellables)
    }

    private var cancellables: Set<AnyCancellable> = []

    private func persist() {
        settingsObject.themeMode = themeMode.rawValue
        settingsObject.retentionDays = Int32(retentionDays)
        settingsObject.markReadOnScrollThreshold = markReadThreshold
        settingsObject.autoTranslateEnglishTitles = autoTranslateEnglishTitles
        settingsObject.cellularImageBlocking = cellularImageBlocking
        persistence.save()
    }
}
