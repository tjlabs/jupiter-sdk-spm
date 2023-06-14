import Foundation

// ---------- Network ----------  //
var SERVER_TYPE = ""
var REGION = "-skrgq3jc5a-du.a.run.app"
var IMAGE_URL = "jupiter_image"

var USER_URL = "https://where-run-user" + REGION + "/user"
var SECTOR_URL = "https://where-run-user" + REGION + "/sector"
var GEO_URL = "https://where-run-param" + REGION + "/geo"
var RCR_URL = "https://where-run-param" + REGION + "/rcr"
var RC_URL = "https://where-run-param" + REGION + "/rc"
var TRAJ_URL = "https://where-run-param" + REGION + "/traj"
var DEBUG_URL = "https://where-run-param" + REGION + "/md"

var RF_URL = "https://where-run-record" + SERVER_TYPE + REGION + "/recordRF"
var UV_URL = "https://where-run-record" + SERVER_TYPE + REGION + "/recordUV"
var MR_URL = "https://where-run-record" + SERVER_TYPE + REGION + "/recordMR"
var RECENT_URL = "https://where-run-user" + REGION + "/recent"

var CALC_URL = "https://where-run-ios"
var RELEASE_URL_i = "https://where-run-ios-2" + REGION + "/"
var TEST_URL_i = "https://where-run-ios-t" + REGION + "/"

var RELEASE_URL_A = "https://where-run-aos-2" + REGION + "/"
var TEST_URL_A = "https://where-run-aos-t" + REGION + "/"

var BASE_URL = CALC_URL + SERVER_TYPE + REGION + "/"
var CLD_URL = BASE_URL + "CLD"
var CLE_URL = BASE_URL + "CLE"
var FLT_URL = BASE_URL + "FLT"
var CLC_URL = BASE_URL + "CLC"
var OSA_URL = BASE_URL + "OSA"
var OSR_URL = BASE_URL + "OSR"
// ---------- Network ----------  //

let R2D: Double = 180 / Double.pi
let D2R: Double = Double.pi / 180

let SAMPLE_HZ: Double = 40

let OUTPUT_SAMPLE_HZ: Double = 10
let OUTPUT_SAMPLE_TIME: Double = 1 / OUTPUT_SAMPLE_HZ
let MODE_QUEUE_SIZE: Double = 15
let VELOCITY_QUEUE_SIZE: Double = 10
let VELOCITY_SETTING: Double = 4.7 / VELOCITY_QUEUE_SIZE
let OUTPUT_SAMPLE_EPOCH: Double = SAMPLE_HZ / Double(OUTPUT_SAMPLE_HZ)
let FEATURE_EXTRACTION_SIZE: Double = SAMPLE_HZ/2
let OUTPUT_DISTANCE_SETTING: Double = 1
let SEND_INTERVAL_SECOND: Double = 1 / VELOCITY_QUEUE_SIZE
let VELOCITY_MIN: Double = 4
let VELOCITY_MAX: Double = 18

let AVG_ATTITUDE_WINDOW: Int = 20
let AVG_NORM_ACC_WINDOW: Int = 20
let ACC_PV_QUEUE_SIZE: Int = 3
let ACC_NORM_EMA_QUEUE_SIZE: Int = 3
let STEP_LENGTH_QUEUE_SIZE: Int = 5
let NORMAL_STEP_LOSS_CHECK_SIZE: Int = 3
let MODE_AUTO_NORMAL_STEP_COUNT_SET = 19
let AUTO_MODE_NORMAL_STEP_LOSS_CHECK_SIZE: Int = MODE_AUTO_NORMAL_STEP_COUNT_SET + 1

let ALPHA: Double = 0.45
let DIFFERENCE_PV_STANDARD: Double = 0.83
let MID_STEP_LENGTH: Double = 0.5
let DEFAULT_STEP_LENGTH: Double = 0.60
let MIN_STEP_LENGTH: Double = 0.01
let MAX_STEP_LENGTH: Double = 0.93
let MIN_DIFFERENCE_PV: Double = 0.2
let COMPENSATION_WEIGHT: Double = 0.85
let COMPENSATION_BIAS: Double = 0.1

let DIFFERENCE_PV_THRESHOLD: Double = (MID_STEP_LENGTH - DEFAULT_STEP_LENGTH) / ALPHA + DIFFERENCE_PV_STANDARD

let LOOKING_FLAG_STEP_CHECK_SIZE: Int = 3

let MODE_PDR = "pdr"
let MODE_DR = "dr"
let MODE_AUTO = "auto"


public func setRegion(regionName: String) {
    switch(regionName) {
    case "Korea":
        REGION = "-skrgq3jc5a-du.a.run.app"
        IMAGE_URL = "jupiter_image"
    case "Canada":
        REGION = "-mewcfgikga-pd.a.run.app"
        IMAGE_URL = "jupiter_image_can"
    default:
        REGION = "-skrgq3jc5a-du.a.run.app"
        IMAGE_URL = "jupiter_image"
    }
}

public func setBaseURL(url: String) {
    BASE_URL = url
    
    USER_URL = "https://where-run-user" + REGION + "/user"
    SECTOR_URL = "https://where-run-user" + REGION + "/sector"
    GEO_URL = "https://where-run-param" + REGION + "/geo"
    RCR_URL = "https://where-run-param" + REGION + "/rcr"
    RC_URL = "https://where-run-param" + REGION + "/rc"
    TRAJ_URL = "https://where-run-param" + REGION + "/traj"
    DEBUG_URL = "https://where-run-param" + REGION + "/md"
    
    RF_URL = "https://where-run-record" + SERVER_TYPE + REGION + "/recordRF"
    UV_URL = "https://where-run-record" + SERVER_TYPE + REGION + "/recordUV"
    RECENT_URL = "https://where-run-user" + SERVER_TYPE + REGION + "/recent"
//    RECENT_URL = "https://where-run-user" + REGION + "/recent"

    CLD_URL = BASE_URL + "CLD"
    CLE_URL = BASE_URL + "CLE"
    FLT_URL = BASE_URL + "FLT"
    CLC_URL = BASE_URL + "CLC"
    OSA_URL = BASE_URL + "OSA"
    OSR_URL = BASE_URL + "OSR"
}
