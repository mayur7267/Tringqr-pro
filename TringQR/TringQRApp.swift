//
//  TringQRApp.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.debug)

        // Request Notification Permissions
        requestNotificationPermissions(application)
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")

        

        return true
    }

    private func requestNotificationPermissions(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to request notification permissions: \(error.localizedDescription)")
                } else {
                    UserDefaults.standard.set(granted, forKey: "notificationsEnabled")
                    print("Notification permissions granted: \(granted)")
                }
            }
        }
        application.registerForRemoteNotifications()
    }

    // MARK: - Handle Remote Notifications
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        
        print("Remote notification received: \(userInfo)")
        completionHandler(.newData)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let scheme = url.scheme, let host = url.host else { return false }
        if scheme == "app-1-318092550249-ios-ae473cdeaea44f437042f8" {
            print("URL Host: \(host)")
            if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let queryItems = urlComponents.queryItems {
                for item in queryItems {
                    print("\(item.name): \(item.value ?? "")")
                }
            }
            return true
        }
        return false
    }
}

@main
struct TringQRApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(appState: AppState())
                    .environmentObject(AppState())
            }
        }
    }
}
