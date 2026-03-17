import Foundation
import UIKit

class AuthService {
    static let shared = AuthService()
    
    private let baseURL = "http://172.20.10.4:8000"
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Accept": "application/json"]
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = 5
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Register user and return user ID
    func tempRegister(email: String, password: String, name: String, faceImage: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        print("AuthService - Starting registration")
        
        guard let url = URL(string: "\(baseURL)/register"),
              let imageData = faceImage.jpegData(compressionQuality: 0.8) else {
            print("AuthService - Registration failed: Invalid input")
            completion(.failure(NSError(domain: "Invalid input", code: 0)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add name
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n")
        body.append(name + "\r\n")

        // Add email
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"email\"\r\n\r\n")
        body.append(email + "\r\n")

        // Add password
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"password\"\r\n\r\n")
        body.append(password + "\r\n")

        // Add face image
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"face_image\"; filename=\"face.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")

        print("AuthService - Sending registration request")
        session.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("AuthService - Registration error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("AuthService - Registration failed: No data received")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            print("AuthService - Registration response: \(String(data: data, encoding: .utf8) ?? "invalid")")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let userID = json?["user_id"] as? String {
                    print("AuthService - Registration successful")
                    completion(.success(userID))
                } else {
                    print("AuthService - Registration failed: Invalid response format")
                    completion(.failure(NSError(domain: "Invalid response", code: 0)))
                }
            } catch {
                print("AuthService - Registration JSON parse error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Upload face image
    func uploadFace(userID: String, image: UIImage, completion: @escaping (Bool) -> Void) {
        print("AuthService - Starting face upload")
        
        guard let url = URL(string: "\(baseURL)/upload-face/\(userID)"),
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("AuthService - Face upload failed: Invalid input")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"face.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")

        print("AuthService - Sending face upload request")
        session.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("AuthService - Face upload error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("AuthService - Face upload response status: \(httpResponse.statusCode)")
            }
            
            print("AuthService - Face upload successful")
            completion(true)
        }.resume()
    }

    // MARK: - Generate embedding
    func generateEmbedding(userID: String, completion: @escaping (Bool) -> Void) {
        print("AuthService - Starting embedding generation")
        
        guard let url = URL(string: "\(baseURL)/generate-embedding/\(userID)") else {
            print("AuthService - Embedding generation failed: Invalid URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        print("AuthService - Sending embedding generation request")
        session.dataTask(with: request) { _, response, error in
            if let error = error {
                print("AuthService - Embedding generation error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("AuthService - Embedding generation response status: \(httpResponse.statusCode)")
                completion(httpResponse.statusCode == 200)
            } else {
                completion(false)
            }
        }.resume()
    }

    // MARK: - Login user
    func login(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("AuthService - Starting login")
        
        guard let url = URL(string: "\(baseURL)/login") else {
            print("AuthService - Login failed: Invalid URL")
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }

        let body: [String: String] = ["email": email, "password": password]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("AuthService - Sending login request")
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("AuthService - Login error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    print("AuthService - Login failed: No data received")
                    completion(.failure(NSError(domain: "No data", code: 0)))
                    return
                }
                
                print("AuthService - Login response: \(String(data: data, encoding: .utf8) ?? "invalid")")
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let userID = json?["user_id"] as? String {
                        print("AuthService - Login successful")
                        completion(.success(userID))
                    } else {
                        print("AuthService - Login failed: Invalid credentials")
                        completion(.failure(NSError(domain: "Invalid credentials", code: 401)))
                    }
                } catch {
                    print("AuthService - Login JSON parse error: \(error)")
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            print("AuthService - Login request creation error: \(error)")
            completion(.failure(error))
        }
    }

    // MARK: - Liveness detection
    func checkLiveness(image: UIImage, completion: @escaping (Result<Bool, Error>) -> Void) {
        print("AuthService - Starting liveness check")
        
        guard let url = URL(string: "\(baseURL)/liveness-check") else {
            print("AuthService - Liveness check failed: Invalid URL")
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("AuthService - Liveness check failed: Couldn't convert image to data")
            completion(.failure(NSError(domain: "Invalid image data", code: 0)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"face.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")

        print("AuthService - Sending liveness check request")
        session.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("AuthService - Liveness check error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("AuthService - Liveness check failed: No data received")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            print("AuthService - Liveness response: \(String(data: data, encoding: .utf8) ?? "invalid")")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("AuthService - Liveness JSON: \(json ?? [:])")
                
                if let isLive = json?["liveness"] as? Bool {
                    print("AuthService - Liveness result: \(isLive)")
                    completion(.success(isLive))
                } else {
                    print("AuthService - Liveness check failed: Invalid response format")
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                print("AuthService - Liveness JSON parse error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Verify face (during login)
    func verifyFace(userID: String, image: UIImage, completion: @escaping (Result<Bool, Error>) -> Void) {
        print("AuthService - Starting face verification")
        
        guard let url = URL(string: "\(baseURL)/verify-face/\(userID)"),
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("AuthService - Face verification failed: Invalid input")
            completion(.failure(NSError(domain: "Invalid input", code: 0)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"face.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")

        print("AuthService - Sending face verification request")
        session.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("AuthService - Face verification error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("AuthService - Face verification failed: No data received")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            print("AuthService - Face verification response: \(String(data: data, encoding: .utf8) ?? "invalid")")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let match = json?["match"] as? Bool {
                    print("AuthService - Face verification result: \(match)")
                    completion(.success(match))
                } else {
                    print("AuthService - Face verification failed: Invalid response format")
                    completion(.failure(NSError(domain: "Invalid response", code: 0)))
                }
            } catch {
                print("AuthService - Face verification JSON parse error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Multipart Helper
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
