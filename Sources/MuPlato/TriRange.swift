//  created by musesum on 2/20/23.

import Foundation
import MuFlo

/// ranged triangle for uniform 0...1
class TriRange {

    let v0: VertexRange // ranged vertex 0...1
    let v1: VertexRange // ranged vertex 0...1
    let v2: VertexRange // ranged vertex 0...1
    var id = 0  // unique ID for triangle color

    init(_ vs: (VertexRange,VertexRange,VertexRange)) {
        self.v0 = vs.0
        self.v1 = vs.1
        self.v2 = vs.2
    }
    init(_ v0: VertexRange,_ v1: VertexRange,_ v2: VertexRange) {
        self.v0 = v0
        self.v1 = v1
        self.v2 = v2
    }

    typealias Hash = Int
    typealias Identity = Int
    typealias Phase = Int
    typealias HashIdPhase = [Hash: (Identity, Phase)]

    static var ID: Identity = 0
    static func nextId() -> Identity {
        ID += 1
        return ID
    }

    static var phaseNow: Phase = 0
    static var hashIdPhase = HashIdPhase()
    static var retiring = [Hash]()
    static var assigning = Set<Identity>()

    static func updatePhase(_ phaseNext: Phase) {
        if phaseNow != phaseNext {
            phaseNow = phaseNext
            assigning.removeAll()
            if retiring.count > 0 {

            }
            for hash in retiring {
                //tri.log("-\(tri.id)", details: true)
                hashIdPhase.removeValue(forKey: hash)
            }
            retiring.removeAll()
        }
    }

    static func reset() {
        ID = 0
        hashIdPhase.removeAll()
        retiring.removeAll()
        assigning.removeAll()
    }
    func setId(_ phase: Int) {

        TriRange.updatePhase(phase)

        let area0 = area(0)
        let area1 = area(1)
        let hasArea0 = area0 > 0.00001
        let hasArea1 = area1 > 0.00001

        let hash0 = hash(0)
        let hash1 = hash(1)

        if !(hasArea0 || hasArea1) {
            id = -1
            return log("¬⁰¹ ⁉️", details: false)
        }

        if hasArea0 {
            if let (hashId,hashPhase) = TriRange.hashIdPhase[hash0],
               phase - hashPhase < 2 {
                id = hashId
            } else {
                id = TriRange.nextId()
                TriRange.hashIdPhase[hash0] = (id,phase)
            }
            if hasArea1 {
                TriRange.hashIdPhase[hash1] = (id,phase)
                log("=\(id)⁰⁺¹")
            } else {
                // remove this tri  at end of phase
                log("=\(id)⁰⁻")
                TriRange.retiring.append(hash1)
            }
            return
        } else if hasArea1 {
            id = TriRange.nextId()
            TriRange.hashIdPhase[hash1] = (id,phase)
            log("+\(id)¹")
            return
        }
    }
    func assignId() {
        if TriRange.assigning.contains(id) {
            PrintLog("⁉️\(id)")
        } else {
            TriRange.assigning.insert(id)
        }
    }
    func log(_ str: String, details: Bool = false ) {
        if details {
            let s = str.pad(10)
            var t = ""
            t += "(\(v0.idStr()) \(v1.idStr()) \(v2.idStr()))".pad(24)
            t += "[(\(v0.digits(0)) \(v1.digits(0)) \(v2.digits(0)))".pad(54)
            t += "(\(v0.digits(1)) \(v1.digits(1)) \(v2.digits(1)))]"
            print("\(s) \(t)")
        } else {
            //print(str, terminator: "")
        }
    }

    /// hash for Triangle
    func hash(_ i: Int) -> Hash {
        // each triangle has a unique centroid
        let c = centroid(i)

        var hasher  = Hasher()
        // trunc(n*100_000) removes floating point error for hash
        hasher.combine(round(c.x * 100_000))
        hasher.combine(round(c.y * 100_000))
        hasher.combine(round(c.z * 100_000))
        return hasher.finalize()
    }
    /// area of triangle at lowerbound of range 0...1
    func area(_ i: Int) -> Float {
        let v0_ = (i == 0) ? v0.p0 : v0.p1
        let v1_ = (i == 0) ? v1.p0 : v1.p1
        let v2_ = (i == 0) ? v2.p0 : v2.p1

        let s01 = sqrt((v0_.x - v1_.x) * (v0_.x - v1_.x) +
                       (v0_.y - v1_.y) * (v0_.y - v1_.y) +
                       (v0_.z - v1_.z) * (v0_.z - v1_.z))

        let s12 = sqrt((v1_.x - v2_.x) * (v1_.x - v2_.x) +
                       (v1_.y - v2_.y) * (v1_.y - v2_.y) +
                       (v1_.z - v2_.z) * (v1_.z - v2_.z))

        let s20 = sqrt((v2_.x - v0_.x) * (v2_.x - v0_.x) +
                       (v2_.y - v0_.y) * (v2_.y - v0_.y) +
                       (v2_.z - v0_.z) * (v2_.z - v0_.z))

        let sum = (s01 + s12 + s20) / 2
        let area = sqrt(sum * (sum-s01) * (sum-s12) * (sum-s20))
        return abs(area)
    }
    func centroid(_ i: Int) -> Float3 {
        let v0_ = (i == 0) ? v0.p0 : v0.p1
        let v1_ = (i == 0) ? v1.p0 : v1.p1
        let v2_ = (i == 0) ? v2.p0 : v2.p1
        return VertexRange.mid3(v0_, v1_, v2_)
    }

}

