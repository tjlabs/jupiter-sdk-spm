import Foundation

public class NetworkManager {
    
    static let shared = NetworkManager()
    let TIMEOUT_VALUE_PUT: Double = 2.0
    let TIMEOUT_VALUE_POST: Double = 5.0
    
    func putReceivedForce(url: String, input: [ReceivedForce], completion: @escaping (Int, String) -> Void){
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
    //        print("PUT RF 데이터 :: ", input)
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
    //                print("RESPONSE RF 데이터 :: ", resultCode)
    //                print("====================================")
    //                print("")
                    completion(resultCode, "(Jupiter) Success Send RFD")
                }
            })
            dataTask.resume()
        } else {
            completion(500, "(Jupiter) Fail to encode RFD")
        }
    }

    func putUserVelocity(url: String, input: [UserVelocity], completion: @escaping (Int, String) -> Void) {
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
    //        print("PUT UV 데이터 :: ", input)
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
    //                print("RESPONSE UV 데이터 :: ", resultCode)
    //                print("====================================")
    //                print("")
                    completion(resultCode, String(input[input.count-1].index))
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
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
            sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
            let session = URLSession(configuration: sessionConfig)
            let dataTask = session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                
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
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST
            sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST
            let session = URLSession(configuration: sessionConfig)
            let dataTask = session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                
    //            print("")
    //            print("====================================")
    //            print("RESPONSE CLE 데이터 :: ", data)
    //            print("RESPONSE CLE 데이터 :: ", response)
    //            print("RESPONSE CLE 데이터 :: ", error)
    //            print("====================================")
    //            print("")
                
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
    
    func postFLT(url: String, input: FineLocationTracking, completion: @escaping (Int, String) -> Void) {
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
//            print("POST FLT URL :: ", url)
//            print("POST FLT 데이터 :: ", input)
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
//                    print("RESPONSE FLT 데이터 :: ", resultCode)
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
            
    //        print("")
    //        print("====================================")
    //        print("POST OSR 데이터 :: ", input)
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
                    completion(resultCode, resultData)
    //                print("")
    //                print("====================================")
    //                print("RESPONSE OSR 데이터 :: ", resultCode)
    //                print("                 :: ", resultData)
    //                print("====================================")
    //                print("")
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode")
        }
    }
    
    func postGEO(url: String, input: Geo, completion: @escaping (Int, String, String, String) -> Void) {
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
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForResource = TIMEOUT_VALUE_POST*2
            sessionConfig.timeoutIntervalForRequest = TIMEOUT_VALUE_POST*2
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
                    completion(resultCode, resultData, buildingName, levelName)
                }
            })
            
            // [network 통신 실행]
            dataTask.resume()
        } else {
            completion(500, "Fail to encode", "", "")
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
