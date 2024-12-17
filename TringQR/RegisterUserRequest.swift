//
//  RegisterUserRequest.swift
//  TringQR
//
//  Created by Mayur on 16/12/24.
//

import Foundation


// MARK: - Request Model
struct RegisterUserRequest: Codable {
    let first_name: String
    let last_name: String
    let dob: String
    let gender: String
    let type: String
    let email: String
    let display_name: String
    let phone_number: String
    let notificationId: String
    let deviceId: String
}

// MARK: - Response Model
struct RegisterUserResponse: Codable {
    let first_name: String?
    let last_name: String?
    let phone_number: String?
    let email: String?
}

// MARK: - API Manager
class APIManager {
    static let shared = APIManager()
    
    private init() {}
    
    func registerUser(request: RegisterUserRequest, token: String, idToken: String?, completion: @escaping (Result<RegisterUserResponse, Error>) -> Void) {
        guard let url = URL(string: "https://core-api-619357594029.asia-south1.run.app/v1/users/qr") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let idToken = idToken {
            urlRequest.addValue(idToken, forHTTPHeaderField: "idtoken")
        }
        
        do {
            let requestBody = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestBody
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(RegisterUserResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
