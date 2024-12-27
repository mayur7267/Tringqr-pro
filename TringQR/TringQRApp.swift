//
//  TringQRApp.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.debug)

        // Request Notification Permissions
        requestNotificationPermissions(application)

        // Set the delegate for Firebase Messaging
        Messaging.messaging().delegate = self

        // Configure Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")

        return true
    }

    private func requestNotificationPermissions(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self // Assign delegate for notifications
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

        // Register the APNS token with Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken

        #if DEBUG
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
        #endif
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Firebase Messaging Delegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("Failed to receive FCM token")
            return
        }
        print("FCM Token: \(fcmToken)")
    }

    // MARK: - Handle URL Schemes
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
