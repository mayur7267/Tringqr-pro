//
//  AppConfig.swift
//  TringQR
//
//  Created by Mayur on 05/01/25.
//

import Foundation

struct AppConfig {
    static var baseURL: String {
        return Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String ?? ""
    }
}
