//
//  RegisterUserRequest.swift
//  TringQR
//
//  Created by Mayur on 16/12/24.
//
import Foundation


struct RegisterUserRequest: Codable {
    let type: String
    let email: String?
    let display_name: String
    let phone_number: String?
    let notificationId: String
    let deviceId: String
}

struct PostActivityRequest: Codable {
    let activity: String
}


struct RegisterUserResponse: Codable {
    let phone_number: String?
    let email: String?
}

struct PostActivityResponse: Codable {
    let message: String
    let success: Bool
}

struct GetActivityResponse: Codable {
    let activities: [String]
}



class APIManager {
    static let shared = APIManager()
    private init() {}

   
    private let baseURL = AppConfig.baseURL

    
    private var config: [String: Any] {
        guard let path = Bundle.main.path(forResource: "config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return [:]
        }
        return dict
    }

   
    func sendIDTokenToBackend(idToken: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/v1/qr-pro/validateToken") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

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
                let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let success = responseDict?["success"] as? Bool ?? false
                completion(.success(success))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    
    func registerUser(request: RegisterUserRequest, token: String, completion: @escaping (Result<RegisterUserResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/v1/qr-pro/users") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let idToken = config["idToken"] as? String {
            urlRequest.addValue(idToken, forHTTPHeaderField: "idtoken")
        }

        urlRequest.addValue(config["deviceId"] as? String ?? "", forHTTPHeaderField: "deviceId")

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

    
    func postActivity(request: PostActivityRequest, token: String, completion: @escaping (Result<PostActivityResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/postActivity") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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
                let decodedResponse = try JSONDecoder().decode(PostActivityResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    
    func getActivities(token: String, completion: @escaping (Result<GetActivityResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/getActivity") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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
                let decodedResponse = try JSONDecoder().decode(GetActivityResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}



