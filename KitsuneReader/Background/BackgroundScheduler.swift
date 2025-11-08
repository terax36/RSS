import Foundation

#if os(iOS)
import BackgroundTasks
#endif

@MainActor
final class BackgroundScheduler: Sendable {
    static let shared = BackgroundScheduler()
    private init() {}

    private weak var hub: ServiceHub?

    func configure(hub: ServiceHub) {
        self.hub = hub
    }

    func register() {
        #if os(iOS)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.pengin.KitsuneReader.refresh", using: nil) { task in
            self.handle(task)
        }
        #endif
    }
    
    func scheduleIfNeeded() {
        #if os(iOS)
        let request = BGAppRefreshTaskRequest(identifier: "com.pengin.KitsuneReader.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 30)
        try? BGTaskScheduler.shared.submit(request)
        #endif
    }

    #if os(iOS)
    private func handle(_ task: BGTask) {
        scheduleIfNeeded()
        task.setTaskCompleted(success: true)
    }
    #endif
}
