//
//  FileStorage.swift
//  FileStorage
//
//  Created by Xiaxuan Tan on 2/10/21.
//
import Foundation
import MetalKit
import UIKit

class FileStorage {

    private let queue: DispatchQueue
    private let documentsURL: URL
    private let applicationSupportURL: URL

    private static var instance: FileStorage?

    private init() throws {
        queue = DispatchQueue(label: "filestorage",
                              qos: .userInitiated,
                              attributes: .concurrent,
                              autoreleaseFrequency: .workItem)
        documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: false)
        // can not be seen directly by users in Files
        applicationSupportURL = try FileManager.default.url(for: .applicationSupportDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
        try FileManager.default.createDirectory(at: documentsURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        try FileManager.default.createDirectory(at: applicationSupportURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
    }

     func generatePath(_ name: String, _ visible: Bool) throws -> URL {
        let rootUrl = visible ? documentsURL : applicationSupportURL
        let segments = name.split(separator: "/").dropLast()
        if segments.count > 0 {
            let folderUrl = rootUrl.appendingPathComponent(segments.joined(separator: "/"))
            try FileManager.default.createDirectory(
                at: folderUrl,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        let fileURL = rootUrl.appendingPathComponent(name)
        print(fileURL.absoluteString)
        return fileURL
    }

    // TODO: singleton? or one manager for one session
    public static func provide() -> FileStorage? {
        if instance == nil {
            instance = try? FileStorage()
        }
        return instance
    }

    // TODO: Consider saving a concrete model instead
    public func saveDictionary(_ dic: [String: Any], _ name: String, _ visible: Bool = true) {
        if let path = try? generatePath(name, visible) {
            if let json = try? JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted) {
                queue.async {
                    try? json.write(to: path)
                }
            }
        }
    }

    // TODO: Is UIImage a proper type?
    public func saveImage(_ image: UIImage, _ name: String, _ visible: Bool = true) {
        
        // save image
        if let path = try? generatePath(name, visible) {
            let ext = path.pathExtension
            var data: Data?
            if ext == "jpg" || ext == "jpeg" {
                data = image.jpegData(compressionQuality: 1)
            } else {
                data = image.pngData()
            }

            if data != nil {
                queue.async {
                    try? data!.write(to: path)
                }
            }
        }
        

    }

    // TODO: Is UIImage a proper type?
    public func saveImageAndJson(_ image: UIImage, _ name1: String,_ dic: [String: Any], _ name2: String , _ visible: Bool = true) {
    
        // save image
        if let path = try? generatePath(name1, visible) {
            let ext = path.pathExtension
            var data: Data?
            if ext == "jpg" || ext == "jpeg" {
                data = image.jpegData(compressionQuality: 1)
            } else {
                data = image.pngData()
            }

            if data != nil {
                queue.async {
                    try? data!.write(to: path)
                }
            }
        }
        
        
        // save parameter
        if let path = try? generatePath(name2, visible) {
            if let json = try? JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted) {
                queue.async {
                    try? json.write(to: path)
                }
            }
        }
    }
    
    
    
    
    
    // TODO: Test in real environment
    // Support MDLAsset only
    public func saveMesh(_ mesh: Any, _ name: String, _ visible: Bool = true) {
        if let path = try? generatePath(name, visible) {
            let ext = path.pathExtension
            if let mdl = mesh as? MDLAsset {
                if MDLAsset.canExportFileExtension(ext) {
                    queue.async {
                        try? mdl.export(to: path)
                    }
                }
            }
        }
    }

    // For testing
    public func saveRandomBytes(_ size: Int, _ name: String, _ visible: Bool = true) {
        let data = Data(count: size)
        saveData(data, name, visible)
    }
    
    public func saveData(_ data: Data, _ name: String, _ visible: Bool = true) {
        if let path = try? generatePath(name, visible) {
            queue.async {
                try? data.write(to: path)
            }
        }
    }

    // List all files under root directory
    // TODO: 1. list a particular folder
    // TODO: 2. filter only usdz
    public func listFiles() -> [URL] {
        if let items = try? FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
            return items
        }
        return []
    }
    
    public func listModels() -> [URL] {
        var models = [URL]()
        if let all = try? FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
            let folders = all.filter {
                $0.lastPathComponent.count == 14 && $0.lastPathComponent.isNumeric
            }
            for fd in folders {
                if let all = try? FileManager.default.contentsOfDirectory(at: fd, includingPropertiesForKeys: nil) {
                    print("this is all +++",all)
                    let usdz = all.filter {
                        $0.pathExtension == "ply"
                    }
                    if usdz.count == 1 {
                        models.append(usdz[0])
                    }
                }
            }
        }
        return models
    }
    
    public func deleteModel(_ url: URL) -> Bool {
        if url.pathExtension != "ply" {
            return false
        }
        let parentURL = url.deletingLastPathComponent()
        if ((try? FileManager.default.removeItem(at: parentURL)) != nil) {
            return true
        }
        return false
    }
    
    public func renameModel(_ url: URL, _ newName: String) {
        let oldPath = url.relativePath
        let newPath = url.deletingLastPathComponent().appendingPathComponent("\(newName).ply").relativePath
        try! FileManager.default.moveItem(atPath: oldPath, toPath: newPath)
    }

}

extension String {
    var isNumeric: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
}
