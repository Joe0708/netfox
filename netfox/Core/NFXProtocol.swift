import Foundation

@objc
open class NFXProtocol: URLProtocol {
    var connection: NSURLConnection?
    var model: NFXHTTPModel?
    var session: URLSession?
    
    override open class func canInit(with request: URLRequest) -> Bool{
        return canServeRequest(request)
    }
    
    override open class func canInit(with task: URLSessionTask) -> Bool
    {
        guard let request = task.currentRequest else { return false }
        return canServeRequest(request)
    }
    
    fileprivate class func canServeRequest(_ request: URLRequest) -> Bool
    {
        if !Netfox.shared.isEnabled() {
            return false
        }
        
        if let url = request.url {
            if (!(url.absoluteString.hasPrefix("http")) && !(url.absoluteString.hasPrefix("https"))) {
                return false
            }

            for ignoredURL in Netfox.shared.getIgnoredURLs() {
                if url.absoluteString.hasPrefix(ignoredURL) {
                    return false
                }
            }
            
        } else {
            return false
        }
        
        if URLProtocol.property(forKey: "NFXInternal", in: request) != nil {
            return false
        }
        
        return true
    }
    
    override open func startLoading()
    {
        self.model = NFXHTTPModel()
                
        var req: NSMutableURLRequest
        req = (NFXProtocol.canonicalRequest(for: request) as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        
        self.model?.saveRequest(req as URLRequest)
                
        URLProtocol.setProperty("1", forKey: "NFXInternal", in: req)
        
        if (session == nil) {
            session = URLSession(configuration: URLSessionConfiguration.default)
        }
        
        session!.dataTask(with: req as URLRequest, completionHandler: {data, response, error in
            
            if let error = error {
                self.model?.saveErrorResponse()
                self.loaded()
                self.client?.urlProtocol(self, didFailWithError: error)
                
            } else {
                if let data = data {
                    self.model?.saveResponse(response!, data: data)
                }
                self.loaded()
            }
            
            if let response = response, let client = self.client {
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = data {
                self.client!.urlProtocol(self, didLoad: data)
            }
            
            if let client = self.client {
                client.urlProtocolDidFinishLoading(self)
            }

        }).resume()
        

    }
    
    override open func stopLoading()
    {
        
    }
    
    override open class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
        
    func loaded() {
        if (self.model != nil) {
            NFXHTTPModelManager.sharedInstance.add(self.model!)
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "NFXReloadData"), object: nil)
    }
    
}
