//
//  API.swift
//  OfflineDownloadWithAVFoundation
//
//  Created by Testpress on 08/09/23.
//

import Foundation
import Alamofire

class API {
    static var DRM_LICENSE_API = "https://4bc2-183-82-25-87.ngrok-free.app/api/v1/4c7zdj/assets/%@/drm_license/?access_token=%@&drm_type=fairplay&download=%@"
    
    static func getDRMLicense(_ assetID: String, _ accessToken: String, _ requestPersistentKey: Bool, _ spcData: Data, _ contentID: String, _ completion:@escaping(Data?, Error?) -> Void) -> Void {
        let url = URL(string: String(format: DRM_LICENSE_API, assetID, accessToken, requestPersistentKey.description))!
        
        let parameters = [
            "spc": spcData.base64EncodedString(),
            "assetId" : contentID
        ] as [String : String]
        
        let headers: HTTPHeaders = [
            .contentType("application/json")
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.prettyPrinted, headers: headers).responseData { response in
            switch response.result {
            case .success(let data):
                completion(data, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
