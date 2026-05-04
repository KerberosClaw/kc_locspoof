import Foundation
import ServiceManagement
import SwiftUI
import Combine
import AppKit

@MainActor
final class HelperService: ObservableObject {
    static let plistName = "org.locspoof.app.helper.plist"

    @Published private(set) var status: SMAppService.Status = .notRegistered
    @Published private(set) var lastError: String?

    private let service = SMAppService.daemon(plistName: plistName)

    init() {
        refresh()
    }

    func refresh() {
        status = service.status
    }

    func install() {
        do {
            try service.register()
            lastError = nil
        } catch {
            lastError = "register failed: \(error.localizedDescription)"
        }
        refresh()
    }

    func uninstall() {
        do {
            try service.unregister()
            lastError = nil
        } catch {
            lastError = "unregister failed: \(error.localizedDescription)"
        }
        refresh()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    var statusText: String {
        switch status {
        case .notRegistered: return "尚未安裝"
        case .enabled: return "已啟用"
        case .requiresApproval: return "需要授權"
        case .notFound: return "找不到 Bundle"
        @unknown default: return "狀態未知"
        }
    }

    var isEnabled: Bool { status == .enabled }
}
