//
//  NetworkRequest.swift
//  MoyaNetwork
//
//  Created by lester on 2024/2/26.
//

import Foundation
import Alamofire
import HandyJSON

public enum ResponseKit<T> {
    case success(T)
    case error(error: Any)
    
    var value: T? {
        switch self {
        case .success(let value):
            return value
        case .error:
            return nil
        }
    }
}

public let baseUrl = "https://api2-sandbox.bacon.games/api/"

public class NetworkRequest {
    

    public static let shared = NetworkRequest()
    
    // 公共参数
    private var commonParams: [String: Any] = [
        "phone_model_name" : "iPhone",
        "bundle_id" : "games.bacon.ios",
        "language" : "en",
        "app_version" : "2.0.8",
        "app_id" : 35,
        "timezone" : Int(TimeZone.current.secondsFromGMT() / 3600),
        "device_id" : "abcdefg",
    ]
    
    private var userToken: String? {
        return ""
    }
    
    public func requestJson(path: ApiPath,
                     baseUrl: String = baseUrl,
                     method: HTTPMethod = .post,
                     params: [String: Any]? = nil,
                     headers: [String: String]? = nil,
                     isNeedSign: Bool = false,
                     encoding: ParameterEncoding = JSONEncoding.default,
                     completed: ((ResponseKit<[String : Any]>) -> Void)?) {
        
        request(path: path, baseUrl: baseUrl, method: method, params: params, headers: headers, isNeedSign: isNeedSign, encoding: encoding) { response in
            switch response {
            case .success(let json):
                guard let jsonDict = json as? [String : Any] else {
                    completed?(.error(error: json))
                    return
                }
                completed?(.success(jsonDict))
                
            case .error(let error):
                completed?(.error(error: error))
            }
        }
    }
    
    /// 请求遵循协议的模型数据
    public func request<T: BaseModel>(path: ApiPath,
                               baseUrl: String = baseUrl,
                               method: HTTPMethod = .post,
                               params: [String: Any]? = nil,
                               headers: [String: String]? = nil,
                               isNeedSign: Bool = false,
                               encoding: ParameterEncoding = JSONEncoding.default,
                           completed: ((ResponseKit<T>) -> Void)?) {
        request(path: path, baseUrl: baseUrl, method: method, params: params, headers: headers, isNeedSign: isNeedSign, encoding: encoding) { response in
            switch response {
            case .success(let json):
                guard let jsonDict = json as? [String : Any],
                      let model = T().decodeModel(dict: jsonDict) else {
                    completed?(.error(error: json))
                    return
                }
                completed?(.success(model))
                
            case .error(let error):
                completed?(.error(error: error))
            }
        }
    }
    
    private func request(path: ApiPath,
                         baseUrl: String,
                         method: HTTPMethod,
                         params: [String: Any]?,
                         headers: [String: String]?,
                         isNeedSign: Bool,
                         encoding: ParameterEncoding,
                         completed: ((ResponseKit<Any>) -> Void)?) {
        
        let urlPath = URL(string: baseUrl + path.rawValue)!
        
        var parameters = params ?? [:]
        parameters.merge(commonParams) { return $1 }
        if let token = userToken {
            parameters["token"] = token
        }
        
        var headerDict = HTTPHeaders(headers ?? [:])
        if isNeedSign {
            let version = "35,iOS,2.0.8"
            headerDict.add(name: "Version", value: version)
            if let data = try? JSONSerialization.data(withJSONObject: parameters),
               let dataStr = String(data: data, encoding: .utf8) {
                let signStr = dataStr + version
                let sign: String = signStr.hmacText
                headerDict.add(name: "Sign", value: sign)
            }
        }
        
        AF.request(urlPath, method: method, parameters: parameters, encoding: encoding, headers: headerDict).responseData(completionHandler: { response in
            debugPrint("http... 请求：\(response.request?.url?.absoluteString ?? "")")
            switch response.result {
            case .success(let data):
                guard let json = try? JSONSerialization.jsonObject(with: data) else {
                    completed?(.error(error: data))
                    return
                }
                debugPrint(json)
                
                if let jsonDict = json as? [String : Any],
                   let code = jsonDict["result"] as? Int,
                   code == 3 {
                    completed?(.error(error: json))
                    return
                }
                
                completed?(.success(json))
                
            case .failure(let error):
                completed?(.error(error: error))
                debugPrint("http... 请求失败：\(error.localizedDescription)")
            }
        })
    }
    
    /// 下载数据
    func download(url: String,
                  fileName: String,
                  complete: @escaping ((ResponseKit<Bool>) -> ())) {
        
        guard let urlPath = URL(string: url) else { return }
        let destination: DownloadRequest.Destination = { _, _ in
            let saveFileUrl = downloadFolder().appendingPathComponent(String(format: "%@.%@", fileName, urlPath.pathExtension))
            debugPrint("saveFileUrl = \(saveFileUrl)")
            return (saveFileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download(url, requestModifier: { request in
            request.timeoutInterval = 60
            
        }, to: destination).response { response in
            switch response.result {
            case .success:
                complete(.success(true))
            case .failure(let error):
                complete(.error(error: error))
            }
        }
    }
    
    // 上传图片数据
    public func upload(url: String,
                data: Data,
                complete: @escaping ((ResponseKit<Bool>) -> ())) {
        AF.upload(multipartFormData: { formData in
            formData.append(data, withName: "file", fileName: "file.jpg", mimeType: "image/jpeg")
        }, to: url).response { response in
            switch response.result {
            case .success:
                complete(.success(true))
            case .failure(let error):
                complete(.error(error: error))
            }
        }
    }
    
}

public func downloadFolder() -> URL {
    let fileManagerUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let folderName = "DownloadFiles/"
    let filePathUrl = fileManagerUrl.appendingPathComponent(folderName)
    if !FileManager.default.fileExists(atPath: filePathUrl.path) {
        do {
            try FileManager.default.createDirectory(atPath: filePathUrl.path, withIntermediateDirectories: true)
        } catch {
            print("获取本地路径错误\(error.localizedDescription)")
        }
    }
    
    return filePathUrl
}

