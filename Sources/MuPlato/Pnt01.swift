//  created by musesum on 2/22/23.

import Foundation

/// point along range p0...p1 at interval 0...1
struct Pnt01 {
    let p0: Pnt // point at 0
    let p1: Pnt // point at 1
    let id: Int // unique ID
    let h: Harmonic // > 0 was created by subdividing triangle

    static var ID = Plato.Max.rawValue + 1
    static func nextId() -> Int {
        ID += 1
        return ID
    }

    init(_ p0: Pnt, _ p1: Pnt,_ id: Int = nextId()) {
        self.p0 = p0
        self.p1 = p1
        self.id = id
        self.h = 0
    }

    init(_ p0: Pnt, _ p1: Pnt,_ p: Plato) {
        self.p0 = p0
        self.p1 = p1
        self.id = p.rawValue
        self.h = 0
    }

    init()  {
        self.p0 = Pnt(0,0,0)
        self.p1 = Pnt(0,0,0)
        self.id = 0
        self.h = 0
    }

    init(_ x: Float, _ y: Float, _ z: Float, _ p: Plato) {
        self.p0 = Pnt(x,y,z)
        self.p1 = Pnt(x,y,z)
        self.id = p.rawValue
        self.h = 0
    }

    init(_ a: Pnt, _ p: Plato) {
        self.p0 = a
        self.p1 = a
        self.id = p.rawValue
        self.h = 0
    }

    /// new ranged point with new vertId
    init(_ a: Pnt,_ b: Pnt) {
        self.p0 = a
        self.p1 = b
        self.id = Pnt01.nextId()
        self.h = 0
    }

    init(_ a: Pnt,_ b: Pnt01,_ p: Plato){
        self.p0 = a
        self.p1 = b.p1
        self.id = p.rawValue
        self.h = 0
    }

    /// the cardinal point have the same range where c.0 === c.1
    init(_ a: Pnt01,_ b: Pnt, _ p: Plato) {
        self.p0 = a.p0
        self.p1 = b
        self.id = p.rawValue
        self.h = 0
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ a: Pnt01,_ b: Pnt01, _ p: Plato) {
        self.p0 = a.p0
        self.p1 = b.p1
        self.id = p.rawValue
        self.h = 0
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ a: Pnt01,_ b2: (Pnt01,Pnt01), _ p: Plato) {
        self.p0 = a.p0
        self.p1 = Pnt01.mid2(b2.0, b2.1).p1
        self.id = p.rawValue
        self.h = 0
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ a: Pnt01,_ b3: (Pnt01,Pnt01,Pnt01), _ p: Plato) {
        self.p0 = a.p0
        self.p1 = Pnt01.mid3(b3.0, b3.1, b3.2).p1
        self.id = p.rawValue
        self.h = 0
    }
    
    /// the Plato point have the same range where c.0 === c.1
    init(_ a2: (Pnt01,Pnt01),_ b: Pnt01, _ p: Plato) {
        self.p0 = Pnt01.mid2(a2.0, a2.1).p0
        self.p1 = b.p1
        self.id = p.rawValue
        self.h = 0
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ a3: (Pnt01,Pnt01,Pnt01),_ b: Pnt01, _ p: Plato) {
        self.p0 = Pnt01.mid3(a3.0, a3.1, a3.2).p0
        self.p1 = b.p1
        self.id = p.rawValue
        self.h = 0
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ m0: Pnt,_ m1: Pnt, harmonic h: Int) {
        self.p0 = m0
        self.p1 = m1
        self.id = Pnt01.nextId()
        self.h = h
    }

    /// the Plato point have the same range where c.0 === c.1
    init(_ a2: (Pnt01,Pnt01),_ b2: (Pnt01,Pnt01), _ p: Plato) {
        self.p0 = Pnt01.mid2(a2.0, a2.1).p0
        self.p1 = Pnt01.mid2(b2.0, b2.1).p1
        self.id = p.rawValue
        self.h = 0
    }

    init(mid: (Pnt01,Pnt01), _ p: Plato) {
        let m = Pnt01.mid2(mid.0, mid.1)
        self.p0 = m.p0
        self.p1 = m.p1
        self.id = p.rawValue
        self.h = 0
    }
    static func mid2(_ a: Pnt,_ b: Pnt) -> Pnt {
        return Pnt((a.x + b.x) / 2.0,
                   (a.y + b.y) / 2.0,
                   (a.z + b.z) / 2.0)
    }

    static func mid2(_ a: Pnt01,_ b: Pnt01,_ p: Plato) -> Pnt01 {
        return Pnt01(mid2(a.p0, b.p0),
                   mid2(a.p1, b.p1),
                   p.rawValue)
    }
    static func mid3(_ a: Pnt,_ b: Pnt,_ c: Pnt) -> Pnt {
        return Pnt((a.x + b.x + c.x) / 3.0,
                   (a.y + b.y + c.y) / 3.0,
                   (a.z + b.z + c.z) / 3.0)
    }

    static func mid2(_ a: Pnt01,_ b: Pnt01) -> Pnt01 {
        return Pnt01(mid2(a.p0, b.p0),
                   mid2(a.p1, b.p1),
                   nextId())
    }

    static func mid3(_ a: Pnt01,_ b: Pnt01,_ c: Pnt01) -> Pnt01 {

        return Pnt01(mid3(a.p0, b.p0, c.p0),
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
    func script(_ i: Int) -> String {
        return i == 0
        ? "(\(p0.x.digits(0...1)),\(p0.y.digits(0...1)),\(p0.z.digits(0...1)))"
        : "(\(p1.x.digits(0...1)),\(p1.y.digits(0...1)),\(p1.z.digits(0...1)))"
    }

}
