//
//  TringQRApp.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.debug)

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request notification permissions: \(error.localizedDescription)")
            } else {
                print("Notification permissions granted: \(granted)")
            }
        }
        application.registerForRemoteNotifications()

        return true
    }


    // MARK: - Handle Remote Notifications (Optional for Firebase Auth)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        completionHandler(.newData)
    }
    
    // MARK: - Handle Deep Linking (Optional)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
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
                ContentView()
                    .environmentObject(AppState())
            }
        }
    }
}
