import Foundation

public func jsonToResult(json: String) -> FineLocationTrackingFromServer {
    let result = FineLocationTrackingFromServer()
    let decoder = JSONDecoder()
    let jsonString = json
    
    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(FineLocationTrackingFromServer.self, from: data) {
        return decoded
    }
    
    return result
}

public func jsonToRecent(json: String) -> RecentResultFromServer {
    let result = RecentResultFromServer()
    let decoder = JSONDecoder()
    let jsonString = json
    
    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(RecentResultFromServer.self, from: data) {
        return decoded
    }
    
    return result
}

public func jsonForTracking(json: String) -> FineLocationTrackingResult {
    let result = FineLocationTrackingResult()
    let decoder = JSONDecoder()
    let jsonString = json
    
    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(FineLocationTrackingResult.self, from: data) {
        return decoded
    }
    
    return result
}

public func decodeMock(json: String) -> JupiterMockResult {
    let result = JupiterMockResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(JupiterMockResult.self, from: data) {
        return decoded
    }

    return result

}

public func decodeFLT(json: String) -> FineLocationTrackingFromServer {
    let result = FineLocationTrackingFromServer.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(FineLocationTrackingFromServer.self, from: data) {
        return decoded
    }

    return result
}

public func decodeOSA(json: String) -> OnSpotAuthorizationResult {
    let result = OnSpotAuthorizationResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(OnSpotAuthorizationResult.self, from: data) {
        return decoded
    }

    return result
}

public func decodeOSR(json: String) -> OnSpotRecognitionResult {
    let result = OnSpotRecognitionResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(OnSpotRecognitionResult.self, from: data) {
        return decoded
    }

    return result
}

public func decodeGeo(json: String) -> JupiterGeoResult {
    let result = JupiterGeoResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(JupiterGeoResult.self, from: data) {
        return decoded
    }

    return result
}

public func decodeTraj(json: String) -> JupiterTrajResult {
    let result = JupiterTrajResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(JupiterTrajResult.self, from: data) {
        return decoded
    }

    return result
}

public func decodeParam(json: String) -> JupiterParamResult {
    let result = JupiterParamResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(JupiterParamResult.self, from: data) {
        return decoded
    }

    return result
}


public func decodeMobileDebug(json: String) -> MobileDebugResult {
    let result = MobileDebugResult.init()
    let decoder = JSONDecoder()
    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(MobileDebugResult.self, from: data) {
        return decoded
    }

    return result
}

public func CLDtoSD(json: String) -> String {
    let decoder = JSONDecoder()
    let jsonString = json
    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CoarseLevelDetectionResult.self, from: data) {
        var result = SectorDetectionResult()
        result.mobile_time = decoded.mobile_time
        result.sector_name = decoded.sector_name
        result.calculated_time = decoded.calculated_time
        
        if (result.sector_name != "") {
            let encodedData = try! JSONEncoder().encode(result)
            if let encodedResult: String = String(data: encodedData, encoding: .utf8) {
                return encodedResult
            } else {
                return "Fail"
            }
        }
    }
    return "Fail"
}

public func CLDtoBD(json: String) -> String {
    let decoder = JSONDecoder()

    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CoarseLevelDetectionResult.self, from: data) {
        var result = BuildingDetectionResult()
        result.mobile_time = decoded.mobile_time
        result.building_name = decoded.building_name
        result.calculated_time = decoded.calculated_time
        
        if (result.building_name != "") {
            let encodedData = try! JSONEncoder().encode(result)
            if let encodedResult: String = String(data: encodedData, encoding: .utf8) {
                return encodedResult
            } else {
                return "Fail"
            }
        }
    }
    return "Fail"
}

public func CLEtoFLD(json: String) -> String {
    let decoder = JSONDecoder()

    let jsonString = json

    if let data = jsonString.data(using: .utf8), let decoded = try? decoder.decode(CoarseLocationEstimationResult.self, from: data) {
        var result = FineLevelDetectionResult()
        
        result.mobile_time = decoded.mobile_time
        result.building_name = decoded.building_name
        result.level_name = decoded.level_name
        result.scc = decoded.scc
        result.scr = decoded.scr
        result.calculated_time = decoded.calculated_time
        
        if (result.building_name != "" && result.level_name != "") {
            let encodedData = try! JSONEncoder().encode(result)
            if let encodedResult: String = String(data: encodedData, encoding: .utf8) {
                return encodedResult
            } else {
                return "Fail"
            }
        }
    }
    return "Fail"
}
