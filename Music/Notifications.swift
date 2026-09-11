import SwiftUI
import UserNotifications

@Observable
final class NotificationManager {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var message = "Notifications are not enabled yet."

    init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
                self.message = self.message(for: settings.authorizationStatus)
            }
        }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            Task { @MainActor in
                if let error {
                    self.message = "Permission failed: \(error.localizedDescription)"
                } else {
                    self.message = granted ? "Notifications enabled." : "Notifications denied in system settings."
                }

                self.refreshAuthorizationStatus()
            }
        }
    }

    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Music"
        content.body = "Your music notification is working."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            Task { @MainActor in
                if let error {
                    self.message = "Could not schedule notification: \(error.localizedDescription)"
                } else {
                    self.message = "Test notification scheduled."
                }
            }
        }
    }

    private func message(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized, .provisional, .ephemeral:
            "Notifications are enabled."
        case .denied:
            "Notifications are blocked in system settings."
        case .notDetermined:
            "Notifications are not enabled yet."
        @unknown default:
            "Notification status is unknown."
        }
    }
}

struct NotificationsSheet: View {
    let notificationManager: NotificationManager

    @Environment(\.dismiss) private var dismiss

    private var canSendTest: Bool {
        switch notificationManager.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            true
        default:
            false
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.10, blue: 0.09), .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        SettingsGroup(title: "Status") {
                            SettingsInfoRow(iconName: "bell.fill", title: "Notifications", value: notificationStatusText)
                            SettingsInfoRow(iconName: "info.circle.fill", title: "Message", value: notificationManager.message)
                        }

                        VStack(spacing: 12) {
                            Button {
                                notificationManager.requestPermission()
                            } label: {
                                Label("Enable Notifications", systemImage: "bell.badge.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }

                            Button {
                                notificationManager.sendTestNotification()
                            } label: {
                                Label("Send Test Notification", systemImage: "paperplane.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(canSendTest ? .white : .white.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(Color.white.opacity(canSendTest ? 0.12 : 0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .disabled(!canSendTest)
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.green)
                }
            }
            .onAppear {
                notificationManager.refreshAuthorizationStatus()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var notificationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            "Enabled"
        case .provisional:
            "Provisional"
        case .ephemeral:
            "Temporary"
        case .denied:
            "Denied"
        case .notDetermined:
            "Not requested"
        @unknown default:
            "Unknown"
        }
    }
}
