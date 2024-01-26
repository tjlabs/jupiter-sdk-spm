import Foundation

public class NetworkManager {
    static let shared = NetworkManager()
    let TIMEOUT_VALUE_PUT: Double = 5.0
    let TIMEOUT_VALUE_POST: Double = 5.0
    
    let rfdSession1: URLSession
    let rfdSession2: URLSession
    var rfdSessionCount: Int = 0
    
    let uvdSession1: URLSession
    let uvdSession2: URLSession
    var uvdSessionCount: Int = 0
    
    let osrSession: URLSession
    let fltSession: URLSession
    let resultSession: URLSession
    let reportSession: URLSession
    
    var rfdSessions = [URLSession]()
    var uvdSessions = [URLSession]()

    init() {
        let rfdConfig = URLSessionConfiguration.default
        rfdConfig.timeoutIntervalForResource = TIMEOUT_VALUE_PUT
        rfdConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_PUT
        self.rfdSession1 = URLSession(configuration: rfdConfig)
        self.rfdSession2 = URLSession(configuration: rfdConfig)
        self.rfdSessions.append(self.rfdSession1)
        self.rfdSessions.append(self.rfdSession2)
        
        let uvdConfig = URLSessionConfiguration.default
        uvdConfig.timeoutIntervalForResource = TIMEOUT_VALUE_PUT
        uvdConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_PUT
        self.uvdSession1 = URLSession(configuration: uvdConfig)
        self.uvdSession2 = URLSession(configuration: uvdConfig)
        self.uvdSessions.append(self.uvdSession1)
        self.uvdSessions.append(self.uvdSession2)
        
        let osrConfig = URLSessionConfiguration.default
        osrConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
        osrConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
        self.osrSession = URLSession(configuration: osrConfig)
        
        let fltConfig = URLSessionConfiguration.default
        fltConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
        fltConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
        self.fltSession = URLSession(configuration: fltConfig)
        
        let resultConfig = URLSessionConfiguration.default
        resultConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
        resultConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
        self.resultSession = URLSession(configuration: resultConfig)
        
        let reportConfig = URLSessionConfiguration.default
        reportConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
        reportConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
        self.reportSession = URLSession(configuration: reportConfig)
    }
    
    func postUser(url: String, input: UserInfo, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        requestURL.httpBody = encodingData
        requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
        requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
        
        let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            
            // [error가 존재하면 종료]
            guard error == nil else {
                // [콜백 반환]
                completion(500, error?.localizedDescription ?? "Fail")
                return
            }
            
            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
                // [콜백 반환]
                completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                return
            }
            
            // [response 데이터 획득]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
            let resultLen = data! // [데이터 길이]
            let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
            
            // [콜백 반환]
            DispatchQueue.main.async {
                completion(resultCode, resultData)
            }
        })
        
        // [network 통신 실행]
        dataTask.resume()
    }
    
    func postUserLogin(url: String, input: UserLogin, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        requestURL.httpBody = encodingData
        requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
        requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
        
        let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            
            // [error가 존재하면 종료]
            guard error == nil else {
                // [콜백 반환]
                completion(500, error?.localizedDescription ?? "Fail")
                return
            }
            
            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
                // [콜백 반환]
                completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                return
            }
            
            // [response 데이터 획득]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
            let resultLen = data! // [데이터 길이]
            let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
            
            // [콜백 반환]
            DispatchQueue.main.async {
                completion(resultCode, resultData)
            }
        })
        
        // [network 통신 실행]
        dataTask.resume()
    }
    
    func postSdkVersion(url: String, input: UserInfo, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        requestURL.httpBody = encodingData
        requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
        requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
        
        let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            
            // [error가 존재하면 종료]
            guard error == nil else {
                // [콜백 반환]
                completion(500, error?.localizedDescription ?? "Fail")
                return
            }
            
            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
                // [콜백 반환]
                completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                return
            }
            
            // [response 데이터 획득]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
            let resultLen = data! // [데이터 길이]
            let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
            
            // [콜백 반환]
            DispatchQueue.main.async {
                completion(resultCode, resultData)
            }
        })
        
        // [network 통신 실행]
        dataTask.resume()
    }
    
    func postSector(url: String, input: SectorInfo, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        requestURL.httpBody = encodingData
        requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
        requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
        
        let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            
            // [error가 존재하면 종료]
            guard error == nil else {
                // [콜백 반환]
                completion(500, error?.localizedDescription ?? "Fail")
                return
            }
            
            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
                // [콜백 반환]
                completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                return
            }
            
            // [response 데이터 획득]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
            let resultLen = data! // [데이터 길이]
            let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
            
            // [콜백 반환]
            DispatchQueue.main.async {
                completion(resultCode, resultData)
            }
        })
        
        // [network 통신 실행]
        dataTask.resume()
    }
    
    func postInfo(url: String, input: Info, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        requestURL.httpBody = encodingData
        requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
        requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
        
        // [http 요청 수행 실시]
//        print("")
//        print("====================================")
//        print("POST INFO URL :: ", url)
//        print("POST INFO 데이터 :: ", input)
//        print("====================================")
//        print("")
        
        let dataTask = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            // [error가 존재하면 종료]
            guard error == nil else {
                // [콜백 반환]
                completion(500, error?.localizedDescription ?? "Fail")
                return
            }
            
            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
                // [콜백 반환]
                completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                return
            }
            
            // [response 데이터 획득]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
            let resultLen = data! // [데이터 길이]
            let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
            
            // [콜백 반환]
            DispatchQueue.main.async {
                completion(resultCode, resultData)
            }
        })
        
        // [network 통신 실행]
        dataTask.resume()
    }
    
    func postReceivedForce(url: String, input: [ReceivedForce], completion: @escaping (Int, String, [ReceivedForce]) -> Void){
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        let inputRfd = input

        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
            // [http 요청 수행 실시]
//            print("")
//            print("====================================")
//            print("POST RF URL :: ", url)
//            print("POST RF 데이터 :: ", input)
//            print("====================================")
//            print("")

            let rfdSession = self.rfdSessions[self.rfdSessionCount%2]
            self.rfdSessionCount+=1
            let dataTask = rfdSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                let code = (response as? HTTPURLResponse)?.statusCode ?? 500
                // [error가 존재하면 종료]
                guard error == nil else {
                    if let timeoutError = error as? URLError, timeoutError.code == .timedOut {
                        DispatchQueue.main.async {
                            completion(timeoutError.code.rawValue, error?.localizedDescription ?? "timed out", inputRfd)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(code, error?.localizedDescription ?? "Fail to send bluetooth data", inputRfd)
                        }
                    }
                    return
                }

                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    DispatchQueue.main.async {
                        completion(code, (response as? HTTPURLResponse)?.description ?? "Fail to send bluetooth data", inputRfd)
                    }
                    return
                }

                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    DispatchQueue.main.async {
                        completion(code, (response as? HTTPURLResponse)?.description ?? "Fail to send bluetooth data", inputRfd)
                    }
                    return
                }

                // [콜백 반환]
                DispatchQueue.main.async {
//                    print("")
//                    print("====================================")
//                    print("RESPONSE RF 데이터 :: ", resultCode)
//                    print("====================================")
//                    print("")
                    completion(resultCode, "Fail to send bluetooth data", inputRfd)
                }
            })
            dataTask.resume()
        } else {
            DispatchQueue.main.async {
                completion(406, "Fail to encode RFD", inputRfd)
            }
        }
    }

    func postUserVelocity(url: String, input: [UserVelocity], completion: @escaping (Int, String, [UserVelocity]) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        let inputUvd = input

        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
            // [http 요청 수행 실시]
    //        print("")
    //        print("====================================")
    //        print("PUT UV 데이터 :: ", input)
    //        print("====================================")
    //        print("")
            
            let uvdSession = self.uvdSessions[self.uvdSessionCount%2]
            self.uvdSessionCount+=1
//            if (uvdSessionCount == 10 || uvdSessionCount == 15 || uvdSessionCount == 16 || uvdSessionCount == 20 || uvdSessionCount == 22) {
//                completion(500, "Fail to encode UVD", inputUvd)
//            } else {
//                let dataTask = uvdSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
//                    let code = (response as? HTTPURLResponse)?.statusCode ?? 400
//                    guard error == nil else {
//                        if let timeoutError = error as? URLError, timeoutError.code == .timedOut {
//                            DispatchQueue.main.async {
//                                completion(timeoutError.code.rawValue, error?.localizedDescription ?? "timed out", inputUvd)
//                            }
//                        } else {
//                            DispatchQueue.main.async {
//                                completion(code, error?.localizedDescription ?? "Fail to send sensor measurements", inputUvd)
//                            }
//                        }
//                        return
//                    }
//
//                    let successsRange = 200..<300
//                    guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
//                    else {
//                        DispatchQueue.main.async {
//                            completion(code, (response as? HTTPURLResponse)?.description ?? "Fail to send sensor measurements", inputUvd)
//                        }
//                        return
//                    }
//
//                    let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
//                    guard let resultLen = data else {
//                        DispatchQueue.main.async {
//                            completion(code, (response as? HTTPURLResponse)?.description ?? "Fail to send sensor measurements", inputUvd)
//                        }
//                        return
//                    }
//
//                    DispatchQueue.main.async {
//                        completion(resultCode, String(input[input.count-1].index), inputUvd)
//                    }
//                })
//                dataTask.resume()
//            }
            
            let dataTask = uvdSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                let code = (response as? HTTPURLResponse)?.statusCode ?? 400
                guard error == nil else {
                    if let timeoutError = error as? URLError, timeoutError.code == .timedOut {
                        DispatchQueue.main.async {
                            completion(timeoutError.code.rawValue, error?.localizedDescription ?? "timed out", inputUvd)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(code, error?.localizedDescription ?? "Fail to send sensor measurements", inputUvd)
                        }
                    }
                    return
                }

                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    DispatchQueue.main.async {
                        completion(code, (response as? HTTPURLResponse)?.description ?? "Fail to send sensor measurements", inputUvd)
                    }
                    return
                }

                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    DispatchQueue.main.async {
                        completion(code, (response as? HTTPURLResponse)?.description ?? "Fail to send sensor measurements", inputUvd)
                    }
                    return
                }

                DispatchQueue.main.async {
                    completion(resultCode, String(input[input.count-1].index), inputUvd)
                }
            })
            dataTask.resume()
        } else {
            DispatchQueue.main.async {
                completion(406, "Fail to encode UVD", inputUvd)
            }
        }
    }
    
    func putRssiBias(url: String, input: RssiBias, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)

        requestURL.httpMethod = "PUT"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
            // [http 요청 수행 실시]
    //        print("")
    //        print("====================================")
    //        print("PUT BIAS 데이터 :: ", input)
    //        print("====================================")
    //        print("")
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_PUT
            sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_PUT
            let session = URLSession(configuration: sessionConfig)
            let dataTask = session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                // [error가 존재하면 종료]
                guard error == nil else {
                    completion(500, error?.localizedDescription ?? "Fail")
                    return
                }

                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }

                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }

                // [콜백 반환]
                DispatchQueue.main.async {
    //                print("")
    //                print("====================================")
    //                print("RESPONSE BIAS 데이터 :: ", resultCode)
    //                print("====================================")
    //                print("")
                    completion(resultCode, "(Jupiter) Success Send RSSI Bias")
                }
            })
            dataTask.resume()
        } else {
            completion(500, "(Jupiter) Fail to encode UVD")
        }
    }
    
    // Coarse Level Detection Service
    func postCLD(url: String, input: CoarseLevelDetection, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
            let dataTask = self.fltSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                
                // [error가 존재하면 종료]
                guard error == nil else {
                    // [콜백 반환]
                    completion(500, error?.localizedDescription ?? "Fail")
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
                    completion(resultCode, resultData)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode")
        }
        
    }
    
    
    // Coarse Location Estimation Service
    func postCLE(url: String, input: CoarseLocationEstimation, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
            let dataTask = self.fltSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                // [error가 존재하면 종료]
                guard error == nil else {
                    // [콜백 반환]
                    completion(500, error?.localizedDescription ?? "Fail")
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
                    completion(resultCode, resultData)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode")
        }
    }
    
    func postOSA(url: String, input: OnSpotAuthorization, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
            let dataTask = self.fltSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                
                // [error가 존재하면 종료]
                guard error == nil else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, error?.localizedDescription ?? "Fail")
                    }
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    }
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    }
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
                    completion(resultCode, resultData)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode")
        }
    }
    
    func postFLT(url: String, input: FineLocationTracking, userTraj: [TrajectoryInfo], trajType: Int, completion: @escaping (Int, String, Int, [TrajectoryInfo], Int) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        let inputPhase: Int = input.phase
        let inputTraj: [TrajectoryInfo] = userTraj
        let inputTrajType: Int = trajType
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
//            print("")
//            print("====================================")
//            print("POST FLT URL :: ", url)
//            print("POST FLT Sector :: ", input.sector_id)
//            print("POST FLT ID :: ", input.user_id)
//            print("POST FLT 데이터 :: ", input)
//            print("====================================")
//            print("")
            
            let dataTask = self.fltSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                // [error가 존재하면 종료]
                guard error == nil else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, error?.localizedDescription ?? "Fail", inputPhase, inputTraj, inputTrajType)
                    }
                    return
                }

                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail", inputPhase, inputTraj, inputTrajType)
                    }
                    return
                }

                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail", inputPhase, inputTraj, inputTrajType)
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]

                // [콜백 반환]
                DispatchQueue.main.async {
//                    print("")
//                    print("====================================")
//                    print("RESPONSE FLT 데이터 :: ", resultData)
//                    print("====================================")
//                    print("")
                    completion(resultCode, resultData, inputPhase, inputTraj, inputTrajType)
                }
            })

            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode", inputPhase, inputTraj, inputTrajType)
        }
    }
    
    func postMock(url: String, input: JupiterMock, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
//            print("")
//            print("====================================")
//            print("POST MOCK URL :: ", url)
//            print("POST MOCK 데이터 :: ", input)
//            print("====================================")
//            print("")

            let dataTask = self.fltSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                
                // [error가 존재하면 종료]
                guard error == nil else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, error?.localizedDescription ?? "Fail")
                    }
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    }
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    }
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
                    completion(resultCode, resultData)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode")
        }
    }
    
    func postRecent(url: String, input: RecentResult, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
            sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
            let session = URLSession(configuration: sessionConfig)
            let dataTask = session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                
                // [error가 존재하면 종료]
                guard error == nil else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, error?.localizedDescription ?? "Fail")
                    }
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    }
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
                    completion(resultCode, resultData)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode")
        }
    }
    
    func postOSR(url: String, input: OnSpotRecognition, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
//            print("")
//            print("====================================")
//            print("POST OSR 데이터 :: ", input)
//            print("====================================")
//            print("")

            let dataTask = self.osrSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                // [error가 존재하면 종료]
                guard error == nil else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, error?.localizedDescription ?? "Fail")
                    }
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    }
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
//                    print("")
//                    print("====================================")
//                    print("RESPONSE OSR 데이터 :: ", resultCode)
//                    print("                 :: ", resultData)
//                    print("====================================")
//                    print("")
                    completion(resultCode, resultData)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode")
        }
    }
    
    func postGeo(url: String, input: JupiterGeo, completion: @escaping (Int, String, String, String) -> Void) {
        let buildingName: String = input.building_name
        let levelName: String = input.level_name
        
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
//            print("")
//            print("====================================")
//            print("POST Geo URL :: ", url)
//            print("POST Geo 데이터 :: ", input)
//            print("====================================")
//            print("")
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
            sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
            let session = URLSession(configuration: sessionConfig)
            let dataTask = session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                
                // [error가 존재하면 종료]
                guard error == nil else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, error?.localizedDescription ?? "Fail", buildingName, levelName)
                    }
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail", buildingName, levelName)
                    }
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail", buildingName, levelName)
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
//                    print("")
//                    print("====================================")
//                    print("RESPONSE Geo 데이터 :: ", resultCode)
//                    print("                 :: ", resultData)
//                    print("====================================")
//                    print("")
                    completion(resultCode, resultData, buildingName, levelName)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode", "", "")
        }
    }
    
    func postTraj(url: String, input: JupiterTraj, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
//            print("")
//            print("====================================")
//            print("POST Traj 데이터 :: ", input)
//            print("====================================")
//            print("")
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
            sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
            let session = URLSession(configuration: sessionConfig)
            let dataTask = session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                
                // [error가 존재하면 종료]
                guard error == nil else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, error?.localizedDescription ?? "Fail")
                    }
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    }
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
//                    print("")
//                    print("====================================")
//                    print("RESPONSE Traj 데이터 :: ", resultCode)
//                    print("                 :: ", resultData)
//                    print("====================================")
//                    print("")
                    completion(resultCode, resultData)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode")
        }
    }
    
    func getJupiterParam(url: String, input: JupiterParamGet, completion: @escaping (Int, String) -> Void) {
        var urlComponents = URLComponents(string: url)
        urlComponents?.queryItems = [URLQueryItem(name: "device_model", value: input.device_model),
                                     URLQueryItem(name: "os_version", value: String(input.os_version)),
                                     URLQueryItem(name: "sector_id", value: String(input.sector_id))]
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "GET"
        
//        print("")
//        print("====================================")
//        print("GET Bias URL :: ", url)
//        print("GET Bias 데이터 :: ", input)
//        print("====================================")
//        print("")
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
        sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
        let session = URLSession(configuration: sessionConfig)
        let dataTask = session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            
            // [error가 존재하면 종료]
            guard error == nil else {
                // [콜백 반환]
                DispatchQueue.main.async {
                    completion(500, error?.localizedDescription ?? "Fail")
                }
                return
            }
            
            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
                // [콜백 반환]
                DispatchQueue.main.async {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                }
                return
            }
            
            // [response 데이터 획득]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
            guard let resultLen = data else {
                completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                return
            }
            let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
            
            // [콜백 반환]
            DispatchQueue.main.async {
//                print("")
//                print("====================================")
//                print("RESPONSE Bias 데이터 :: ", resultCode)
//                print("                 :: ", resultData)
//                print("====================================")
//                print("")
                completion(resultCode, resultData)
            }
        })
        
        // [network 통신 실행]
        dataTask.resume()
    }
    
    func getJupiterDeviceParam(url: String, input: JupiterDeviceParamGet, completion: @escaping (Int, String) -> Void) {
        var urlComponents = URLComponents(string: url)
        urlComponents?.queryItems = [URLQueryItem(name: "device_model", value: input.device_model),
                                     URLQueryItem(name: "sector_id", value: String(input.sector_id))]
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "GET"
        
//        print("")
//        print("====================================")
//        print("GET Bias URL (Device) :: ", url)
//        print("GET Bias 데이터  (Device) :: ", input)
//        print("====================================")
//        print("")
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
        sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
        let session = URLSession(configuration: sessionConfig)
        let dataTask = session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            
            // [error가 존재하면 종료]
            guard error == nil else {
                // [콜백 반환]
                DispatchQueue.main.async {
                    completion(500, error?.localizedDescription ?? "Fail")
                }
                return
            }
            
            // [status 코드 체크 실시]
            let successsRange = 200..<300
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
            else {
                // [콜백 반환]
                DispatchQueue.main.async {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                }
                return
            }
            
            // [response 데이터 획득]
            let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
            guard let resultLen = data else {
                completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                return
            }
            let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
            
            // [콜백 반환]
            DispatchQueue.main.async {
//                print("")
//                print("====================================")
//                print("RESPONSE Bias 데이터 (Device) :: ", resultCode)
//                print("                 :: ", resultData)
//                print("====================================")
//                print("")
                completion(resultCode, resultData)
            }
        })
        
        // [network 통신 실행]
        dataTask.resume()
    }
    
    
    func postJupiterParam(url: String, input: JupiterParamPost, completion: @escaping (Int, String) -> Void){
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)

        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
            // [http 요청 수행 실시]
//            print("")
//            print("====================================")
//            print("POST Param URL :: ", url)
//            print("POST Param 데이터 :: ", input)
//            print("====================================")
//            print("")
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_PUT
            sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_PUT
            let session = URLSession(configuration: sessionConfig)
            let dataTask = session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                // [error가 존재하면 종료]
                guard error == nil else {
                    completion(500, error?.localizedDescription ?? "Fail")
                    return
                }

                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }

                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }

                // [콜백 반환]
                DispatchQueue.main.async {
//                    print("")
//                    print("====================================")
//                    print("RESPONSE Param 데이터 :: ", resultCode)
//                    print("====================================")
//                    print("")
                    completion(resultCode, "(Jupiter) Success Send Bias")
                }
            })
            dataTask.resume()
        } else {
            completion(500, "(Jupiter) Fail to encode JupiterBiasPut")
        }
    }
    
    func postMobileDebug(url: String, input: MobileDebug, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
            sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
            let session = URLSession(configuration: sessionConfig)
            let dataTask = session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                
                // [error가 존재하면 종료]
                guard error == nil else {
                    if let timeoutError = error as? URLError, timeoutError.code == .timedOut {
                        DispatchQueue.main.async {
                            completion(timeoutError.code.rawValue, error?.localizedDescription ?? "timed out")
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(500, error?.localizedDescription ?? "Fail")
                        }
                    }
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
//                    print("")
//                    print("====================================")
//                    print("RESPONSE Debug 데이터 :: ", resultCode)
//                    print("====================================")
//                    print("")
                    completion(resultCode, resultData)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode")
        }
    }
    
    func postMobileResult(url: String, input: [MobileResult], completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
//            print("")
//            print("====================================")
//            print("POST Mobile Result URL :: ", url)
//            print("POST Mobile Result 데이터 :: ", input)
//            print("====================================")
//            print("")
            
            let dataTask = self.resultSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                
                // [error가 존재하면 종료]
                guard error == nil else {
                    if let timeoutError = error as? URLError, timeoutError.code == .timedOut {
                        DispatchQueue.main.async {
                            completion(timeoutError.code.rawValue, error?.localizedDescription ?? "timed out")
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(500, error?.localizedDescription ?? "Fail")
                        }
                    }
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    }
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    DispatchQueue.main.async {
                        completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    }
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
                    completion(resultCode, resultData)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            DispatchQueue.main.async {
                completion(500, "Fail to encode")
            }
        }
    }
    
    func postMobileReport(url: String, input: MobileReport, completion: @escaping (Int, String) -> Void) {
        // [http 비동기 방식을 사용해서 http 요청 수행 실시]
        let urlComponents = URLComponents(string: url)
        var requestURL = URLRequest(url: (urlComponents?.url)!)
        
        requestURL.httpMethod = "POST"
        let encodingData = JSONConverter.encodeJson(param: input)
        if (encodingData != nil) {
            requestURL.httpBody = encodingData
            requestURL.addValue("application/json", forHTTPHeaderField: "Content-Type")
            requestURL.setValue("\(encodingData)", forHTTPHeaderField: "Content-Length")
            
//            print("")
//            print("====================================")
//            print("POST Mobile Report URL :: ", url)
//            print("POST Mobile Report 데이터 :: ", input)
//            print("====================================")
//            print("")
            
            let dataTask = self.reportSession.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                // [error가 존재하면 종료]
                guard error == nil else {
                    // [콜백 반환]
                    completion(500, error?.localizedDescription ?? "Fail")
                    return
                }
                
                // [status 코드 체크 실시]
                let successsRange = 200..<300
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, successsRange.contains(statusCode)
                else {
                    // [콜백 반환]
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                
                // [response 데이터 획득]
                let resultCode = (response as? HTTPURLResponse)?.statusCode ?? 500 // [상태 코드]
                guard let resultLen = data else {
                    completion(500, (response as? HTTPURLResponse)?.description ?? "Fail")
                    return
                }
                let resultData = String(data: resultLen, encoding: .utf8) ?? "" // [데이터 확인]
                
                // [콜백 반환]
                DispatchQueue.main.async {
//                    print("")
//                    print("====================================")
//                    print("RESPONSE Mobile Report 데이터 :: ", resultCode)
//                    print("====================================")
//                    print("")
                    completion(resultCode, resultData)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode")
        }
    }
}

extension Encodable {
    var asDictionary: [String: Any]? {
        guard let object = try? JSONEncoder().encode(self),
              let dictinoary = try? JSONSerialization.jsonObject(with: object, options: []) as? [String: Any] else { return nil }
        return dictinoary
    }
}
