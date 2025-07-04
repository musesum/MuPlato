//  created by musesum on 2/22/23.

import Foundation

/// point along range p0...p1 at interval 0...1
struct VertexRange : @unchecked Sendable{
    let p0: Float3 // point at 0
    let p1: Float3 // point at 1
    let id: Int // unique ID
    var harmonic: Harmonic  = 0 // > 0 was created by subdividing triangle

    nonisolated(unsafe) static var ID = Plato.Max.rawValue + 1
    static func nextId() -> Int {
        ID += 1
        return ID
    }

    init(_ p0: Float3, _ p1: Float3,_ id: Int = nextId()) {
        self.p0 = p0
        self.p1 = p1
        self.id = id
    }

    init(_ p0: Float3, _ p1: Float3,_ p: Plato) {
        self.p0 = p0
        self.p1 = p1
        self.id = p.rawValue
    }

    init()  {
        self.p0 = Float3(0,0,0)
        self.p1 = Float3(0,0,0)
        self.id = 0
    }

    init(_ x: Float, _ y: Float, _ z: Float, _ p: Plato) {
        self.p0 = Float3(x,y,z)
        self.p1 = Float3(x,y,z)
        self.id = p.rawValue
    }

    init(_ a: Float3, _ p: Plato) {
        self.p0 = a
        self.p1 = a
        self.id = p.rawValue
    }

    /// new ranged point with new vertId
    init(_ a: Float3,_ b: Float3) {
        self.p0 = a
        self.p1 = b
        self.id = VertexRange.nextId()
    }

    init(_ a: Float3,_ b: VertexRange,_ p: Plato){
        self.p0 = a
        self.p1 = b.p1
        self.id = p.rawValue
    }

    /// the cardinal point have the same range where c.0 === c.1
    init(_ a: VertexRange,_ b: Float3, _ p: Plato) {
        self.p0 = a.p0
        self.p1 = b
        self.id = p.rawValue
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ a: VertexRange,_ b: VertexRange, _ p: Plato) {
        self.p0 = a.p0
        self.p1 = b.p1
        self.id = p.rawValue
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ a: VertexRange,_ b2: (VertexRange,VertexRange), _ p: Plato) {
        self.p0 = a.p0
        self.p1 = VertexRange.mid2(b2.0, b2.1).p1
        self.id = p.rawValue
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ a: VertexRange,_ b3: (VertexRange,VertexRange,VertexRange), _ p: Plato) {
        self.p0 = a.p0
        self.p1 = VertexRange.mid3(b3.0, b3.1, b3.2).p1
        self.id = p.rawValue
    }
    
    /// the Plato point have the same range where c.0 === c.1
    init(_ a2: (VertexRange,VertexRange),_ b: VertexRange, _ p: Plato) {
        self.p0 = VertexRange.mid2(a2.0, a2.1).p0
        self.p1 = b.p1
        self.id = p.rawValue
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ a3: (VertexRange,VertexRange,VertexRange),_ b: VertexRange, _ p: Plato) {
        self.p0 = VertexRange.mid3(a3.0, a3.1, a3.2).p0
        self.p1 = b.p1
        self.id = p.rawValue
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ m0: Float3,_ m1: Float3, harmonic h: Int) {
        self.p0 = m0
        self.p1 = m1
        self.id = VertexRange.nextId()
        self.harmonic = h
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ a2: (VertexRange,VertexRange),_ b2: (VertexRange,VertexRange), _ p: Plato) {
        self.p0 = VertexRange.mid2(a2.0, a2.1).p0
        self.p1 = VertexRange.mid2(b2.0, b2.1).p1
        self.id = p.rawValue
    }

    init(mid: (VertexRange,VertexRange), _ p: Plato) {
        let m = VertexRange.mid2(mid.0, mid.1)
        self.p0 = m.p0
        self.p1 = m.p1
        self.id = p.rawValue
    }
    static func mid2(_ a: Float3,_ b: Float3) -> Float3 {
        return Float3((a.x + b.x) / 2.0,
                   (a.y + b.y) / 2.0,
                   (a.z + b.z) / 2.0)
    }

    static func mid2(_ a: VertexRange,_ b: VertexRange,_ p: Plato) -> VertexRange {
        return VertexRange(mid2(a.p0, b.p0),
                   mid2(a.p1, b.p1),
                   p.rawValue)
    }
    static func mid3(_ a: Float3,_ b: Float3,_ c: Float3) -> Float3 {
        return Float3((a.x + b.x + c.x) / 3.0,
                   (a.y + b.y + c.y) / 3.0,
                   (a.z + b.z + c.z) / 3.0)
    }

    static func mid2(_ a: VertexRange,_ b: VertexRange) -> VertexRange {
        return VertexRange(mid2(a.p0, b.p0),
                   mid2(a.p1, b.p1),
                   nextId())
    }

    static func mid3(_ a: VertexRange,_ b: VertexRange,_ c: VertexRange) -> VertexRange {

        return VertexRange(mid3(a.p0, b.p0, c.p0),
                   mid3(a.p1, b.p1, c.p1),
                   nextId())
    }

    func idStr() -> String {
        if let plato = Plato(rawValue: id) {
            return "\(plato)"
        } else {
            return "\(id)"
        }

    }
    func digits(_ i: Int) -> String {
        return i == 0
        ? "(\(p0.x.digits(0...1)),\(p0.y.digits(0...1)),\(p0.z.digits(0...1)))"
        : "(\(p1.x.digits(0...1)),\(p1.y.digits(0...1)),\(p1.z.digits(0...1)))"
    }

}
