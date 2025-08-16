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
import FirebaseCrashlytics
import GoogleSignIn
import AppTrackingTransparency
import FirebaseAuth
import UIKit
import Firebase
import FirebaseAnalytics

class AuthUIDelegateHandler: NSObject, AuthUIDelegate {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        
        UIApplication.shared.windows.first?.rootViewController?.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        
        UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: flag, completion: completion)
    }
}
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        if let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String {
                    print("Base URL: \(baseURL)")
                } else {
                    print("Base URL not found in Info.plist")
                }
        
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        
        Analytics.setAnalyticsCollectionEnabled(true)

        Crashlytics.crashlytics()
        


        Messaging.messaging().delegate = self

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")

        
       

        return true
    }

    
   

    private func requestNotificationPermissions(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
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

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("Failed to receive FCM token")
            return
        }
        print("FCM Token: \(fcmToken)")
    }

  
@main
struct TringQRApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            NavigationView {

                SplashView()
                    .environmentObject(appState)
            }
        }
    }
}
