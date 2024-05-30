import SwiftUI
import CoreGraphics

extension Path {
    func toJSON() -> String? {
        var elements: [[String: Any]] = []
        self.forEach { element in
            switch element {
            case .move(to: let point):
                elements.append(["type": "move", "point": point.toJSON() ?? ""])
            case .line(to: let point):
                elements.append(["type": "line", "point": point.toJSON() ?? ""])
            case .quadCurve(to: let point, control: let control):
                elements.append(["type": "quadCurve", "point": point.toJSON() ?? "", "control": control.toJSON() ?? ""])
            case .curve(to: let point, control1: let control1, control2: let control2):
                elements.append(["type": "curve", "point": point.toJSON() ?? "", "control1": control1.toJSON() ?? "", "control2": control2.toJSON() ?? ""])
            case .closeSubpath:
                elements.append(["type": "closeSubpath"])
                break
            }
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: elements, options: []) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }

    init?(json: String) {
        self.init()
        guard let jsonData = json.data(using: .utf8),
              let elements = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
            return nil
        }
        for element in elements {
            guard let type = element["type"] as? String else { continue }
            switch type {
            case "move":
                if let pointJSON = element["point"] as? String, let point = CGPoint(json: pointJSON) {
                    self.move(to: point)
                }
            case "line":
                if let pointJSON = element["point"] as? String, let point = CGPoint(json: pointJSON) {
                    self.addLine(to: point)
                }
            case "quadCurve":
                if let pointJSON = element["point"] as? String, let point = CGPoint(json: pointJSON),
                   let controlJSON = element["control"] as? String, let control = CGPoint(json: controlJSON) {
                    self.addQuadCurve(to: point, control: control)
                }
            case "curve":
                if let pointJSON = element["point"] as? String, let point = CGPoint(json: pointJSON),
                   let control1JSON = element["control1"] as? String, let control1 = CGPoint(json: control1JSON),
                   let control2JSON = element["control2"] as? String, let control2 = CGPoint(json: control2JSON) {
                    self.addCurve(to: point, control1: control1, control2: control2)
                }
            case "closeSubpath":
                self.closeSubpath()
            default:
                continue
            }
        }
    }
}

extension CGPoint {
    func toJSON() -> String? {
        let dict = ["x": self.x, "y": self.y]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }

    init?(json: String) {
        guard let jsonData = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: CGFloat],
              let x = dict["x"],
              let y = dict["y"] else {
            return nil
        }
        self.init(x: x, y: y)
    }
}
