//
//  TringQRApp.swift
//  TringQR
//
//  Created by Mayur on 30/11/24.
//
import SwiftUI
import FirebaseCore
import Firebase
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        
        #if DEBUG
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        print("Using Firebase Emulator for Auth")
        #endif

        // Register for notifications
        registerForRemoteNotifications(application)

        return true
    }

    
    private func registerForRemoteNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("Failed to request notification authorization: \(error.localizedDescription)")
            }
        }
        application.registerForRemoteNotifications()
    }

   
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
       
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }

        
        print("Received remote notification: \(userInfo)")

        completionHandler(.newData)
    }

    // MARK: - UNUserNotificationCenterDelegate Methods
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle notification when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler()
            return
        }

      
        print("User interacted with notification: \(userInfo)")

        completionHandler()
    }
}


@main
struct TringQRApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//  @StateObject private var appState = AppState()

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
              .environmentObject(AppState())
      }
    }
  }
}
//import SwiftUI
//
//@main
//struct TringQRApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}
