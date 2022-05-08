//
//  SpriteSheet.swift
//  LastDay
//
//  Created by Mateusz Malczak on 17/09/16.
//  Copyright © 2016 The Pirate Cat. All rights reserved.
//

import Foundation
import UIKit

/**
 SpriteSheet class represents an image map
 */
open class SpriteSheet {
    
    typealias GridSize = (cols: Int, rows: Int)
    
    typealias ImageSize = (width: Int, height: Int)
    
    /**
     Struct stores information about a grid size, sprite size and country codes included in sprite sheet
     */
    struct SheetInfo {
        fileprivate(set) var gridSize: GridSize
        
        fileprivate(set) var spriteSize: ImageSize
        
        fileprivate(set) var codes: [String]
    }
    
    fileprivate(set) var info: SheetInfo
    
    fileprivate(set) var image: UIImage
    
    fileprivate(set) var colorSpace: CGColorSpace
    
    fileprivate var imageData: UnsafeMutableRawPointer?
    
    fileprivate var imageCache = [String:UIImage]()
    
    fileprivate var cgImage: CGImage {
        return image.cgImage!
    }
    
    var bitsPerComponent: Int {
        return cgImage.bitsPerComponent
    }
    
    var bitsPerPixel: Int {
        return bitsPerComponent * 4
    }
    
    var imageSize: CGSize {
        return image.size
    }
    
    var spriteBytesPerRow: Int {
        return 4 * info.spriteSize.width
    }
    
    var spriteBytesCount: Int {
        return spriteBytesPerRow * info.spriteSize.height
    }
    
    var sheetBytesPerRow: Int {
        return spriteBytesPerRow * info.gridSize.rows
    }
    
    var sheetBytesPerCol: Int {
        return spriteBytesCount * info.gridSize.cols
    }
    
    var sheetBytesCount: Int {
        return sheetBytesPerRow * Int(imageSize.height)
    }
    
    var bitmapInfo: CGBitmapInfo {
        let imageBitmapInfo = cgImage.bitmapInfo
        let imageAlphaInfo = cgImage.alphaInfo
        return CGBitmapInfo(rawValue:
            (imageBitmapInfo.rawValue & (CGBitmapInfo.byteOrderMask.rawValue)) |
                (imageAlphaInfo.rawValue & (CGBitmapInfo.alphaInfoMask.rawValue)))
    }
    
    var bytes: UnsafeMutablePointer<UInt8> {
        return imageData!.assumingMemoryBound(to: UInt8.self)
    }
    
    init?(sheetImage: UIImage, info sInfo: SheetInfo) {
        image = sheetImage
        info = sInfo
        guard let cgImage = sheetImage.cgImage else {
            return nil
        }
        
        guard let cgColorSpace = cgImage.colorSpace else {
            return nil
        }
        colorSpace = cgColorSpace
        
        
        let memory = sheetMemoryLayout()
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: memory.size,
                                                     alignment: memory.alignment)
        
        let imageWidth = Int(imageSize.width)
        let imageHeight = Int(imageSize.height)
        
        guard let bmpCtx = CGContext(data: bytes,
                                     width: imageWidth,
                                     height: imageHeight,
                                     bitsPerComponent: bitsPerComponent,
                                     bytesPerRow: 4 * imageWidth,
                                     space: colorSpace,
                                     bitmapInfo: bitmapInfo.rawValue) else {
                                        bytes.deallocate()
                                        return
        }
        
        imageData = bytes
        bmpCtx.draw(cgImage,
                    in: CGRect(x: 0, y: 0,
                               width: imageSize.width,
                               height: imageSize.height))
    }
    
    open func getImageFor(_ code: String, deepCopy: Bool = false, scale: CGFloat = 2) -> UIImage? {
        var cimg = imageCache[code] // cache is not thread safe
        if nil == cimg || deepCopy {
            let data = getBytesFor(code)
            
            if deepCopy {
                guard let bmpCtx = CGContext(data: nil,
                                             width: info.spriteSize.width,
                                             height: info.spriteSize.height,
                                             bitsPerComponent: bitsPerComponent,
                                             bytesPerRow: spriteBytesPerRow,
                                             space: colorSpace,
                                             bitmapInfo: bitmapInfo.rawValue) else {
                                                return nil
                }
                
                if let bmpData = bmpCtx.data {
                    var srcData = UnsafeMutablePointer<UInt8>(mutating: data.bytes)
                    var curData = bmpData.assumingMemoryBound(to: UInt8.self)
                    for _ in 0..<info.spriteSize.height {
                        curData.assign(from: srcData, count: spriteBytesPerRow)
                        curData = curData.advanced(by: spriteBytesPerRow)
                        srcData = srcData.advanced(by: sheetBytesPerRow)
                    }
                    
                    if let bmpImage = bmpCtx.makeImage() {
                        return UIImage(cgImage: bmpImage, scale: scale, orientation: UIImage.Orientation.up).withRenderingMode(.alwaysOriginal)
                    }
                }
                
                return nil
            }
            
            let expectedSize = sheetBytesPerRow * info.spriteSize.height
            let size = min(expectedSize, data.size)
            guard let provider = CGDataProvider(dataInfo: nil,
                                                data: data.bytes,
                                                size: size,
                                                releaseData: {_,_,_  in}) else {
                                                    return nil
            }
        
            guard let cgImage = CGImage(width: info.spriteSize.width,
                                        height: info.spriteSize.height,
                                        bitsPerComponent: bitsPerComponent,
                                        bitsPerPixel: bitsPerPixel,
                                        bytesPerRow: sheetBytesPerRow,
                                        space: colorSpace,
                                        bitmapInfo: bitmapInfo,
                                        provider: provider,
                                        decode: nil,
                                        shouldInterpolate: true,
                                        intent: CGColorRenderingIntent.defaultIntent) else {
                                            return nil
            }
            cimg = UIImage(cgImage: cgImage)
            imageCache[code] = cimg
        }
        
        return cimg
    }
    
    open func getBytesFor(_ code: String) -> (bytes: UnsafePointer<UInt8>, size: Int) {
        let idx = info.codes.firstIndex(of: code.lowercased()) ?? 0
        let dx = idx % info.gridSize.cols
        let dy = idx / info.gridSize.rows
        let bytesOffset = sheetBytesPerCol * dy + spriteBytesPerRow * dx
        let data = bytes.advanced(by: bytesOffset)
        let totalMemory = sheetMemoryLayout().size
        
        #if TRACK_MEMORY
        print("""
             /*********
                    code   : \(code)
                     index : \(idx)
                    d(x/y) : \(dx) x \(dy) | \(idx % info.gridSize.cols) x \(idx/info.gridSize.rows)
              bytes offset : \(bytesOffset)
                         Sheet
                   sprites : \(info.codes.count)
                 grid size : \(info.gridSize.cols) x \(info.gridSize.rows)
               sprite size : \(info.spriteSize.width) x \(info.spriteSize.height)
            bits/Component : \(bitsPerComponent)
                bits/Pixel : \(bitsPerPixel)
                         Memory
                     total : \(totalMemory)
                  provider : \(sheetBytesPerRow * info.spriteSize.height)
                    sprite : \(spriteBytesCount)
                      left : \(totalMemory - bytesOffseTRACK_MEMORYt)
        """)
        #endif
        
        return (UnsafePointer<UInt8>(data), totalMemory - bytesOffset)
    }
    
    open func flushCache() {
        imageCache.removeAll()
    }
    
    func sheetMemoryLayout() -> (size: Int, alignment: Int) {        
        return (sheetBytesCount * MemoryLayout<UInt8>.stride,
                MemoryLayout<UInt8>.alignment)
    }
    
    deinit {
        imageCache.removeAll()
        if let data = imageData {
            data.deallocate()
        }
        imageData = nil
    }
    
}
