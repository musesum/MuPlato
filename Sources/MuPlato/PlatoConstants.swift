//  created by musesum on 2/19/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import Foundation

public enum Plato: Int { case
    // origin
    Z=0,
    // Tetrahedron
    T0, T1, T2, T3,
    // Cube, will include Tetrahedron points
    C0, C1, C2, C3,
    // Octahedron. each Pnt is middle of a Cube's face
    O0, O1, O2, O3, O4, O5,
    // Dodecahedron, will include Cube and Tetrahedron points
    D0, D1, D2, D3, D4, D5, D6, D7, D8, D9, DA, DB,
    // Icosahedron
    I0, I1, I2, I3, I4, I5, I6, I7, I8, I9, IA, IB,
    // zero ... tetra
    Z_T0, Z_T1, Z_T2, Z_T3,
    // Tetra ... Cube A
    T0_T012, T1_T013, T2_T023, T3_T123,
    // Tetra ... Cube B
    T012_C0, T013_C1, T023_C2, T123_C3,
    // Cube ... Oct A
    T0_O0, T1_O1, T2_O2, T3_O3, T1_O4, T3_O5,
    // Cube ... Oct B, includes T1_O1, T2_O2, from Oct a
    T0_O2,  T3_O1, C0_O3, C1_O0, C2_O0, C3_O3,
    // Oct ... Cube - phase 5
    O2_T0, O1_T1, O2_T2, O1_T3, O3_C0, O0_C1, O0_C2, O3_C3,
    // Cube ... Dodec A - phase 6
    O4_D0, O4_D1, O1_D2, O1_D3, O0_D4, O0_D5, O2_D6, O2_D7, O3_D8, O3_D9, O5_DA, O5_DB,
    O0_D45, O1_D23, O2_D67, O3_D89, O4_D01, O5_DAB,
    // Cube Dodec B - phase 7
    D45_D5, D23_D2, D67_D7, D89_D8, D01_D1, DAB_DA,
    // Dodec Face A - phase 8
    T0_I0, T0_I1, C0_I2, T2_I3, T2_I4, C3_I5, C3_I6, T3_I7, C1_I8, C1_I9, T3_IA, C0_IB,
    // Dodec Face B - phase 9
    T0_T0D0, D0_D0D1, D1_D1C0, C0_C0D6, D6_D6T0, T0_T0D5, D5_D5C2, C2_C2D7, D7_D7D6, D6_D6C0, C0_CoD9, D9_D9T2, T2_T2D7, D7_D7C2, C2_C2DA, DA_DADB, DB_DBT2, T2_T2D9, D9_D9D8, D8_D8C3, C3_C3DB, DB_DBDA, DA_DAT3, T3_T3D3, D3_D3C3, C3_C3D8, D8_D8T1, T1_T1D2, D2_D2D3, D3_D3T3, T3_T3D4, D4_D4C1, C1_C1D2, D2_D2T1, T1_T1D1, D1_D1D0, D0_D0C1, C1_C1D4, D4_D4D5, D5_D5T0,
    // Dodec Icosa - phase 10
    T0_I019, T1_I6B8, T2_I234, T3_I57A, C0_I02B, C1_I897, C2_I13A, C3_I456, D0_I089, D1_I08B, D2_I678, D3_I567, D4_I79A, D5_I19A, D6_I012, D7_I123, D8_I46B, D9_I24B, DA_I35A, DB_I345, T0_D0I09, D0_D1I08, D1_C0I0B, C0_D6I02, D6_T0I01, T0_D5I19, D5_C2I1A, C2_D7I13, D7_D6I12, D6_C0I02, C0_D9I2B, D9_T2I24, T2_D7I23, D7_C2I13, C2_DAI3A, DA_DBI35, DB_T2I34, T2_D9I24, D9_D8I4B, D8_C3I46, C3_DBI45, DB_DAI35, DA_T3I5A, T3_D3I75, D3_C3I56, C3_D8I46, D8_T1I6B, T1_D2I68, D2_D3I67, D3_T3I57, T3_D4I7A, D4_C1I79, C1_D2I78, D2_T1I68, T1_D1I8B, D1_D0I08, D0_C1I89, C1_D4I79, D4_D5IA9, D5_T0I19,
    Max
}

let 𝚽 : Float = (1 + sqrt(5)) / 2  // 1.6180… = 𝚽¹
let φ : Float = 1 / 𝚽              // 0.6180… = 𝚽⁻¹
let R : Float = sqrt(2 + 𝚽) * φ    // 1.175…  = √(2 + 𝚽) * 𝚽⁻¹
let Rφ: Float = sqrt(2 + 𝚽) * φ*φ  // 0.726…  = √(2 + 𝚽) * 𝚽⁻²

typealias Pnt = SIMD3<Float>
typealias Harmonic = Int
typealias Pnt4 = SIMD4<Float>

// origin
let Z = Pnt01(0, 0, 0, .Z)
// Tetrahedron
let T0 = Pnt01( 1, 1, 1, .T0)
let T1 = Pnt01(-1, 1,-1, .T1)
let T2 = Pnt01( 1,-1,-1, .T2)
let T3 = Pnt01(-1,-1, 1, .T3)
                       // Cube, will include Tetrahedron points
let C0 = Pnt01( 1, 1,-1, .C0)
let C1 = Pnt01(-1, 1, 1, .C1)
let C2 = Pnt01( 1,-1, 1, .C2)
let C3 = Pnt01(-1,-1,-1, .C3)
                       // Octahedron. each Pnt is middle of a Cube's face
let O0 = Pnt01( 0, 0, 1, .O0)
let O1 = Pnt01(-1, 0, 0, .O1)
let O2 = Pnt01( 1, 0, 0, .O2)
let O3 = Pnt01( 0, 0,-1, .O3)
let O4 = Pnt01( 0, 1, 0, .O4)
let O5 = Pnt01( 0,-1, 0, .O5)
// Dodecahedron, will include Cube and Tetrahedron points
let D0 = Pnt01( 0, 𝚽, φ, .D0)
let D1 = Pnt01( 0, 𝚽,-φ, .D1)
let D2 = Pnt01(-𝚽, φ, 0, .D2)
let D3 = Pnt01(-𝚽,-φ, 0, .D3)
let D4 = Pnt01(-φ, 0, 𝚽, .D4)
let D5 = Pnt01( φ, 0, 𝚽, .D5)
let D6 = Pnt01( 𝚽, φ, 0, .D6)
let D7 = Pnt01( 𝚽,-φ, 0, .D7)
let D8 = Pnt01(-φ ,0,-𝚽, .D8)
let D9 = Pnt01( φ, 0,-𝚽, .D9)
let DA = Pnt01( 0,-𝚽, φ, .DA)
let DB = Pnt01( 0,-𝚽,-φ, .DB)
// Icosahedron
let I0 = Pnt01( Rφ,  R,  0, .I0)
let I1 = Pnt01(  R,  0, Rφ, .I1)
let I2 = Pnt01(  R,  0,-Rφ, .I2)
let I3 = Pnt01( Rφ, -R,  0, .I3)
let I4 = Pnt01(  0,-Rφ, -R, .I4)
let I5 = Pnt01(-Rφ, -R,  0, .I5)
let I6 = Pnt01( -R,  0,-Rφ, .I6)
let I7 = Pnt01( -R,  0, Rφ, .I7)
let I8 = Pnt01(-Rφ,  R,  0, .I8)
let I9 = Pnt01(  0, Rφ,  R, .I9)
let IA = Pnt01(  0,-Rφ,  R, .IA)
let IB = Pnt01(  0, Rφ, -R, .IB)
