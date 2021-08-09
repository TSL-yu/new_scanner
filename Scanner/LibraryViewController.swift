//
//  LibraryViewController.swift
//  LidarScanner
//
//  Created by Peter Tam on 4/09/21.
//
 
import Foundation

import UIKit
import Foundation
import QuickLook
import SwipeCellKit

class LibraryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, QLPreviewControllerDelegate, QLPreviewControllerDataSource, SwipeCollectionViewCellDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    let exsitingModels = ["wheelbarrow", "wateringcan", "teapot", "gramophone", "cupandsaucer", "redchair", "tulip", "plantpot"]
    var arObjects: [URL] = []
    var thumbnailIndex = 0
    var fileStorage = FileStorage.provide()!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Put it inside folder, only used for debug purpose
//        for (index, model) in exsitingModels.enumerated() {
//            let url = Bundle.main.url(forResource:model, withExtension: "usdz")!
//            if let data = try? Data(contentsOf: url) {
//                let folder = String(format: "202101010000%02d", index)
//                fileStorage.saveData(data, "\(folder)/\(model).usdz")
//            }
//        }
         
        self.reloadData()
        collectionView.dataSource = self
        collectionView.delegate = self
        self.navigationItem.setHidesBackButton(true, animated: true);
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arObjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LibraryCell", for: indexPath) as! LibraryCollectionViewCell
        cell.delegate = self
        
        let url = arObjects[indexPath.item]
        let title = url.lastPathComponent
        cell.modelTitle.text = title.capitalized
        
        let timeStamp = url.deletingLastPathComponent().lastPathComponent
        let dateFormatterInput = DateFormatter()
        let dateFormatterOutput = DateFormatter()
        dateFormatterInput.dateFormat = "yyyyMMddHHmmss"
        dateFormatterOutput.dateFormat = "yyyy-MM-dd hh:mm:ss"
        
        if let date = dateFormatterInput.date(from: timeStamp) {
            cell.date.text = dateFormatterOutput.string(from: date)
        } else {
            cell.date.text = "unknown date"
        }
        
        let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: 100, height: 100), scale: UIScreen.main.scale, representationTypes: .all)
        let generator = QLThumbnailGenerator.shared
        
        generator.generateRepresentations(for: request) { (thumbnail, type, error) in
            DispatchQueue.main.async {
                if thumbnail == nil || error != nil {
                    return
                } else {
                    cell.modelImage.image = thumbnail!.uiImage
                }
            }
        }

//        print(cell, IndexPath(), "index--------")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        thumbnailIndex = indexPath.item

        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        present(previewController, animated: true)
        print(" this is the num of item index" , indexPath.item)
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return arObjects[thumbnailIndex] as QLPreviewItem
    }

    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let editAction = SwipeAction(style: .default, title: "Edit") { action, indexPath in
            let alertController = UIAlertController(title: "Rename Model", message: "", preferredStyle: UIAlertController.Style.alert)
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Enter model name here"
            }
            let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
                let newName = (alertController.textFields![0] as UITextField).text
                if newName == nil || newName!.count == 0 {
                    return
                }
                let modelURL = self.arObjects[indexPath.row]
                self.fileStorage.renameModel(modelURL, newName!)
                self.reloadData()
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
                (action : UIAlertAction!) -> Void in })
            
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)

            self.present(alertController, animated: true, completion: nil)
        }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            // TODO: consider lazy delete here
            let modelURL = self.arObjects[indexPath.row]
            self.fileStorage.deleteModel(modelURL)
            self.reloadData()
        }

        return [editAction, deleteAction]
    }
    
    func reloadData() {
        self.arObjects = fileStorage.listModels()
        self.arObjects.sort {$0.absoluteString > $1.absoluteString}
        collectionView.reloadData()
    }
    
}
