import Foundation
import UIKit

extension String {
    public func appendingPathComponent(_ path: String) -> String {
        return NSString(string: self).appendingPathComponent(path)
    }
    
    public func appendingPathExtension(_ ext: String) -> String? {
        return NSString(string: self).appendingPathExtension(ext)
    }
    
    public var deletingPathExtension: String {
        return NSString(string: self).deletingPathExtension
    }
    
    public var lastPathComponent: String {
        return NSString(string: self).lastPathComponent
    }
    
    public var deletingLastPathComponent: String {
        return NSString(string: self).deletingLastPathComponent
    }
}

extension FileManager {
    public class var document: String {
        get {
            return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        }
    }
    
    public class var debugger: String {
        get {
            return document.appendingPathComponent("debugger")
        }
    }
    
    public class var logger: String {
        get {
            return debugger.appendingPathComponent("Logs")
        }
    }
    
    @discardableResult public class func save(content: String, savePath: String) -> Error? {
        if FileManager.default.fileExists(atPath: savePath) {
            do {
                try FileManager.default.removeItem(atPath: savePath)
            } catch {
                return error
            }
        }
        do {
            try content.write(to: URL(fileURLWithPath: savePath), atomically: true, encoding: .utf8)
        } catch {
            return error
        }
        return nil
    }
    
    @discardableResult public class func create(at path: String) -> Error? {
        if (!FileManager.default.fileExists(atPath: path)) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("error:\(error)")
                return error
            }
        }
        return nil
    }
}

extension Date {
    func isGreaterThanDate(_ dateToCompare: Date) -> Bool {
        return compare(dateToCompare) == ComparisonResult.orderedDescending
    }
}


extension String {
    func appendToFile(filePath: String) {
        let contentToAppend = self
        
        if let fileHandle = FileHandle(forWritingAtPath: filePath) {
            /* Append to file */
            fileHandle.seekToEndOfFile()
            fileHandle.write(contentToAppend.data(using: String.Encoding.utf8)!)
        } else {
            /* Create new file */
            do {
                try contentToAppend.write(toFile: filePath, atomically: true, encoding: .utf8)
            } catch {
                print("Error creating \(filePath)")
            }
        }
    }
}
