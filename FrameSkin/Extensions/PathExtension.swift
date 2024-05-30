import SwiftUI
import CoreGraphics

extension Path {
    func toData() -> Data {
        var data = Data()
        self.forEach { element in
            switch element {
            case .move(to: let point):
                var type: UInt8 = 0
                data.append(&type, count: 1)
                data.append(point.toData())
            case .line(to: let point):
                var type: UInt8 = 1
                data.append(&type, count: 1)
                data.append(point.toData())
            case .quadCurve(to: let point, control: let control):
                var type: UInt8 = 2
                data.append(&type, count: 1)
                data.append(point.toData())
                data.append(control.toData())
            case .curve(to: let point, control1: let control1, control2: let control2):
                var type: UInt8 = 3
                data.append(&type, count: 1)
                data.append(point.toData())
                data.append(control1.toData())
                data.append(control2.toData())
            case .closeSubpath:
                var type: UInt8 = 4
                data.append(&type, count: 1)
            @unknown default:
                break
            }
        }
        return data
    }
    
    init(data: Data) {
        self.init()
        var index = 0
        while index < data.count {
            let type = data[index]
            index += 1
            switch type {
            case 0:
                let point = CGPoint(data: data[index..<index+16])
                self.move(to: point)
                index += 16
            case 1:
                let point = CGPoint(data: data[index..<index+16])
                self.addLine(to: point)
                index += 16
            case 2:
                let point = CGPoint(data: data[index..<index+16])
                index += 16
                let control = CGPoint(data: data[index..<index+16])
                self.addQuadCurve(to: point, control: control)
                index += 16
            case 3:
                let point = CGPoint(data: data[index..<index+16])
                index += 16
                let control1 = CGPoint(data: data[index..<index+16])
                index += 16
                let control2 = CGPoint(data: data[index..<index+16])
                self.addCurve(to: point, control1: control1, control2: control2)
                index += 16
            case 4:
                self.closeSubpath()
            default:
                break
            }
        }
    }
}

extension CGPoint {
    func toData() -> Data {
        var data = Data()
        var x = self.x.bitPattern.littleEndian
        var y = self.y.bitPattern.littleEndian
        withUnsafeBytes(of: &x) { buffer in
            data.append(buffer.bindMemory(to: UInt8.self))
        }
        withUnsafeBytes(of: &y) { buffer in
            data.append(buffer.bindMemory(to: UInt8.self))
        }
        return data
    }
    
    init(data: Data) {
        self.init() // Initialize the CGPoint instance

        
        // Ensure the data contains at least 16 bytes (8 bytes for each coordinate)
        guard data.count >= 2 * MemoryLayout<UInt64>.size else {
            fatalError("Data is not large enough to contain two UInt64 values.")
        }
        
        let x: UInt64 = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt64.self) }
        let y: UInt64 = data.withUnsafeBytes { $0.load(fromByteOffset: MemoryLayout<UInt64>.size, as: UInt64.self) }

        
        // Convert UInt64 to CGFloat properly
        self.x = CGFloat(bitPattern: x.littleEndian)
        self.y = CGFloat(bitPattern: y.littleEndian)
    }
}

extension CGFloat {
    init(bitPattern: UInt64) {
        if MemoryLayout<CGFloat>.size == MemoryLayout<Double>.size {
            self.init(Double(bitPattern: bitPattern))
        } else {
            self.init(Float(bitPattern: UInt32(bitPattern & 0xFFFFFFFF)))
        }
    }
}
