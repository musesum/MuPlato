//  created by musesum on 2/28/23.
//  Copyright © 2023 DeepMuse All rights reserved.


extension PhaseTriangles {

    /// phase 0
    static func buildZeroTetra() -> PhaseTriangles {

        let Z_T0 = VertexRange(Z, T0, .Z_T0)
        let Z_T1 = VertexRange(Z, T1, .Z_T1)
        let Z_T2 = VertexRange(Z, T2, .Z_T2)
        let Z_T3 = VertexRange(Z, T3, .Z_T3)

        return PhaseTriangles([

            TriRange(Z_T0, Z_T1, Z_T2),
            TriRange(Z_T0, Z_T1, Z_T3),
            TriRange(Z_T0, Z_T2, Z_T3),
            TriRange(Z_T1, Z_T2, Z_T3)
        ])
    }

    /// phase 1
    static func buildTetraCubeA() -> PhaseTriangles {

        let T0_T012 = VertexRange(T0, (T0,T1,T2), .T0_T012)
        let T1_T013 = VertexRange(T1, (T0,T1,T3), .T1_T013)
        let T2_T023 = VertexRange(T2, (T0,T2,T3), .T2_T023)
        let T3_T123 = VertexRange(T3, (T1,T2,T3), .T3_T123)

        return PhaseTriangles([

            TriRange(T0, T0_T012, T1), // 0⟹1
            TriRange(T0, T1_T013, T1), // 0⟹1
            TriRange(T0, T2_T023, T2), // 0⟹1
            TriRange(T1, T1_T013, T3), // 0⟹1
            TriRange(T2, T3_T123, T3), // 0⟹1
            TriRange(T2, T0_T012, T0), // 0⟹1
            TriRange(T2, T2_T023, T3), // 0⟹1
            TriRange(T3, T3_T123, T1), // 0⟹1

            TriRange(T1, T0_T012, T2),
            TriRange(T1, T3_T123, T2),
            TriRange(T3, T1_T013, T0),
            TriRange(T3, T2_T023, T0),
        ])
    }

    /// phase 2
    static func buildTetraCubeB() -> PhaseTriangles {

        let T012_C0 = VertexRange((T0,T1,T2), C0, .T012_C0)
        let T013_C1 = VertexRange((T0,T1,T3), C1, .T013_C1)
        let T023_C2 = VertexRange((T0,T2,T3), C2, .T023_C2)
        let T123_C3 = VertexRange((T1,T2,T3), C3, .T123_C3)

        return PhaseTriangles([

            TriRange(T0, T012_C0, T1),
            TriRange(T0, T013_C1, T1),
            TriRange(T0, T023_C2, T2),
            TriRange(T1, T012_C0, T2),
            TriRange(T1, T013_C1, T3),
            TriRange(T1, T123_C3, T2),
            TriRange(T2, T012_C0, T0),
            TriRange(T2, T023_C2, T3),
            TriRange(T2, T123_C3, T3),
            TriRange(T3, T013_C1, T0),
            TriRange(T3, T023_C2, T0),
            TriRange(T3, T123_C3, T1),
        ])
    }

    /// phase 3
    static func buildCubeOctA() -> PhaseTriangles {

        let T0_O0 = VertexRange(T0, O0, .T0_O0)
        let T1_O1 = VertexRange(T1, O1, .T1_O1)
        let T2_O2 = VertexRange(T2, O2, .T2_O2)
        let T3_O3 = VertexRange(T2, O3, .T3_O3)
        let T1_O4 = VertexRange(T1, O4, .T1_O4)
        let T3_O5 = VertexRange(T3, O5, .T3_O5)

        return PhaseTriangles([

            TriRange(T0, T0_O0, C1), // 0⟹1
            TriRange(T0, T0_O0, C2), // 0⟹1

            TriRange(T1, T1_O1, C3), // 0⟹1
            TriRange(T1, T1_O1, C1), // 0⟹1
            TriRange(T1, T1_O4, C0), // 0⟹1
            TriRange(T1, T1_O4, C1), // 0⟹1

            TriRange(T2, T2_O2, C0), // 0⟹1
            TriRange(T2, T2_O2, C2), // 0⟹1

            TriRange(T3, T3_O5, C3), // 0⟹1
            TriRange(T3, T3_O5, C2), // 0⟹1

            TriRange(T0, T1_O4, C0),
            TriRange(T0, T2_O2, C0),
            TriRange(T0, T1_O4, C1),
            TriRange(T0, T2_O2, C2),

            TriRange(T1, T3_O3, C0),
            TriRange(T1, T3_O3, C3),

            TriRange(T2, T3_O3, C3),
            TriRange(T2, T3_O5, C3),
            TriRange(T2, T3_O3, C0),
            TriRange(T2, T3_O5, C2),

            TriRange(T3, T0_O0, C1),
            TriRange(T3, T0_O0, C2),
            TriRange(T3, T1_O1, C1),
            TriRange(T3, T1_O1, C3),
         ])
    }

    // phase 4
    static func buildCubeOctB() -> PhaseTriangles {

        let T0_O2 = VertexRange(T0, O2, .T0_O2)
        let T1_O1 = VertexRange(T1, O1, .T1_O1)
        let T2_O2 = VertexRange(T2, O2, .T2_O2)
        let T3_O1 = VertexRange(T3, O1, .T3_O1)
        let C0_O3 = VertexRange(C0, O3, .C0_O3)
        let C1_O0 = VertexRange(C1, O0, .C1_O0)
        let C2_O0 = VertexRange(C2, O0, .C2_O0)
        let C3_O3 = VertexRange(C3, O3, .C3_O3)

        return PhaseTriangles([

            TriRange(C0_O3, O2, T2_O2), // 1⟹0
            TriRange(C0_O3, O2, T0_O2), // 1⟹0
            TriRange(C0_O3, O3, T1_O1), // 1⟹0
            TriRange(C0_O3, O3, T2_O2), // 1⟹0

            TriRange(C1_O0, O1, T1_O1), // 1⟹0
            TriRange(C1_O0, O0, T0_O2), // 1⟹0
            TriRange(C1_O0, O1, T3_O1), // 1⟹0
            TriRange(C1_O0, O0, T3_O1), // 1⟹0

            TriRange(C2_O0, O0, T0_O2), // 1⟹0
            TriRange(C2_O0, O0, T3_O1), // 1⟹0
            TriRange(C2_O0, O2, T2_O2), // 1⟹0
            TriRange(C2_O0, O2, T0_O2), // 1⟹0

            TriRange(C3_O3, O3, T2_O2), // 1⟹0
            TriRange(C3_O3, O1, T1_O1), // 1⟹0
            TriRange(C3_O3, O1, T3_O1), // 1⟹0
            TriRange(C3_O3, O3, T1_O1), // 1⟹0

            TriRange(C0_O3, O4, T0_O2), //  (C0, O4, O2) ⟹ (O3, O4, O2)
            TriRange(C0_O3, O4, T1_O1), //  (C0, O4, O1) ⟹ (O3, O4, O1)
            TriRange(C1_O0, O4, T0_O2), //  (C1, O4, O2) ⟹ (O0, O4, O2)
            TriRange(C1_O0, O4, T1_O1), //  (C1, O4, O1) ⟹ (O0, O4, O1)
            TriRange(C2_O0, O5, T2_O2), //  (C2, O5, O2) ⟹ (O0, O5, O2)
            TriRange(C2_O0, O5, T3_O1), //  (C2, O5, O1) ⟹ (O0, O5, O1)
            TriRange(C3_O3, O5, T3_O1), //  (C3, O5, O1) ⟹ (O3, O5, O1)
            TriRange(C3_O3, O5, T2_O2), //  (C3, O5, O2) ⟹ (O3, O5, O2)
        ])
    }

    /// phase 5
    static func buildOctCube() -> PhaseTriangles {

        let O2_T0 = VertexRange(O2, T0, .O2_T0)
        let O1_T1 = VertexRange(O1, T1, .O1_T1)
        let O2_T2 = VertexRange(O2, T2, .O2_T2)
        let O1_T3 = VertexRange(O1, T3, .O1_T3)
        let O3_C0 = VertexRange(O3, C0, .O3_C0)
        let O0_C1 = VertexRange(O0, C1, .O0_C1)
        let O0_C2 = VertexRange(O0, C2, .O0_C2)
        let O3_C3 = VertexRange(O3, C3, .O3_C3)

        return PhaseTriangles([

            TriRange(O0_C2, O0, O2_T0), // 0⟹1
            TriRange(O0_C1, O0, O1_T3), // 0⟹1
            TriRange(O0_C1, O1, O1_T1), // 0⟹1
            TriRange(O0_C2, O2, O2_T0), // 0⟹1

            TriRange(O1_T1, O3, O3_C0), // 0⟹1
            TriRange(O1_T3, O0, O0_C2), // 0⟹1
            TriRange(O1_T1, O1, O3_C3), // 0⟹1
            TriRange(O1_T3, O1, O0_C1), // 0⟹1

            TriRange(O2_T0, O0, O0_C1), // 0⟹1
            TriRange(O2_T0, O2, O3_C0), // 0⟹1
            TriRange(O2_T2, O2, O0_C2), // 0⟹1
            TriRange(O2_T2, O3, O3_C3), // 0⟹1

            TriRange(O3_C3, O1, O1_T3), // 0⟹1
            TriRange(O3_C0, O2, O2_T2), // 0⟹1
            TriRange(O3_C0, O3, O2_T2), // 0⟹1
            TriRange(O3_C3, O3, O1_T1), // 0⟹1

            TriRange(O0_C1, O4, O2_T0), // (O0, O4, O2) ⟹ (C1, O4, T0)
            TriRange(O0_C2, O5, O2_T2), // (O0, O5, O2) ⟹ (C2, O5, T2)
            TriRange(O1_T3, O5, O0_C2), // (O1, O5, O0) ⟹ (T3, O5, C2)
            TriRange(O1_T1, O4, O0_C1), // (O1, O4, O0) ⟹ (T1, O4, C1)
            TriRange(O2_T0, O4, O3_C0), // (O2, O4, O3) ⟹ (T0, O4, C0)
            TriRange(O2_T2, O5, O3_C3), // (O2, O5, O3) ⟹ (T2, O5, C3)
            TriRange(O3_C0, O4, O1_T1), // (O3, O4, O1) ⟹ (C0, O4, T1)
            TriRange(O3_C3, O5, O1_T3), // (O3, O5, O1) ⟹ (C3, O5, T3)
        ])
    }

    /// phase 6
    static func buildCubeDodecA() -> PhaseTriangles {

        let O4_D0 = VertexRange(O4, D0, .O4_D0)
        let O4_D1 = VertexRange(O4, D1, .O4_D1)
        let O1_D2 = VertexRange(O1, D2, .O1_D2)
        let O1_D3 = VertexRange(O1, D3, .O1_D3)
        let O0_D4 = VertexRange(O0, D4, .O0_D4)
        let O0_D5 = VertexRange(O0, D5, .O0_D5)
        let O2_D6 = VertexRange(O2, D6, .O2_D6)
        let O2_D7 = VertexRange(O2, D7, .O2_D7)
        let O3_D8 = VertexRange(O3, D8, .O3_D8)
        let O3_D9 = VertexRange(O3, D9, .O3_D9)
        let O5_DA = VertexRange(O5, DA, .O5_DA)
        let O5_DB = VertexRange(O5, DB, .O5_DB)

        let O0_D45 = VertexRange(mid: (O0_D4, O0_D5), .O0_D45)
        let O1_D23 = VertexRange(mid: (O1_D2, O1_D3), .O1_D23)
        let O2_D67 = VertexRange(mid: (O2_D6, O2_D7), .O2_D67)
        let O3_D89 = VertexRange(mid: (O3_D8, O3_D9), .O3_D89)
        let O4_D01 = VertexRange(mid: (O4_D0, O4_D1), .O4_D01)
        let O5_DAB = VertexRange(mid: (O5_DA, O5_DB), .O5_DAB)

        return PhaseTriangles([
            //  m⟹n                    0⟹1
            TriRange(T0, O0_D45, C1), TriRange(T0, O0_D45, O0_D5),
            TriRange(C1, O0_D4,  T3), TriRange(C1, O0_D45, O0_D4),
            TriRange(T3, O0_D45, C2), TriRange(T3, O0_D45, O0_D4),
            TriRange(C2, O0_D5,  T0), TriRange(C2, O0_D45, O0_D5),
            TriRange(C3, O1_D23, T1), TriRange(C3, O1_D23, O1_D3),
            TriRange(T1, O1_D2,  C1), TriRange(T1, O1_D23, O1_D2),
            TriRange(C1, O1_D23, T3), TriRange(C1, O1_D23, O1_D2),
            TriRange(T3, O1_D3,  C3), TriRange(T3, O1_D23, O1_D3),
            TriRange(T2, O2_D67, C0), TriRange(T2, O2_D67, O2_D7),
            TriRange(C0, O2_D6,  T0), TriRange(C0, O2_D67, O2_D6),
            TriRange(T0, O2_D67, C2), TriRange(T0, O2_D67, O2_D6),
            TriRange(C2, O2_D7,  T2), TriRange(C2, O2_D67, O2_D7),
            TriRange(C0, O3_D89, T1), TriRange(C0, O3_D89, O3_D9),
            TriRange(T1, O3_D8,  C3), TriRange(T1, O3_D89, O3_D8),
            TriRange(C3, O3_D89, T2), TriRange(C3, O3_D89, O3_D8),
            TriRange(T2, O3_D9,  C0), TriRange(T2, O3_D89, O3_D9),
            TriRange(C0, O4_D01, T0), TriRange(C0, O4_D01, O4_D1),
            TriRange(T0, O4_D0,  C1), TriRange(T0, O4_D01, O4_D0),
            TriRange(C1, O4_D01, T1), TriRange(C1, O4_D01, O4_D0),
            TriRange(T1, O4_D1,  C0), TriRange(T1, O4_D01, O4_D1),
            TriRange(T2, O5_DAB, C2), TriRange(T2, O5_DAB, O5_DB),
            TriRange(C2, O5_DA,  T3), TriRange(C2, O5_DAB, O5_DA),
            TriRange(T3, O5_DAB, C3), TriRange(T3, O5_DAB, O5_DA),
            TriRange(C3, O5_DB,  T2), TriRange(C3, O5_DAB, O5_DB),
        ])
    }

    /// phase 7
    static func buildCubeDodecB() -> PhaseTriangles {

        let D45_D5 = VertexRange((D4,D5), D5, .D45_D5)
        let D23_D2 = VertexRange((D2,D3), D2, .D23_D2)
        let D67_D7 = VertexRange((D6,D7), D7, .D67_D7)
        let D89_D8 = VertexRange((D8,D9), D8, .D89_D8)
        let D01_D1 = VertexRange((D0,D1), D1, .D01_D1)
        let DAB_DA = VertexRange((DA,DB), DA, .DAB_DA)

        return PhaseTriangles([

            TriRange(T0, D45_D5, D5), // 1⟹0
            TriRange(T1, D01_D1, D1), // 1⟹0
            TriRange(T1, D89_D8, D8), // 1⟹0
            TriRange(T1, D23_D2, D2), // 1⟹0
            TriRange(T2, D67_D7, D7), // 1⟹0
            TriRange(T3, DAB_DA, DA), // 1⟹0
            TriRange(C0, D01_D1, D1), // 1⟹0
            TriRange(C1, D23_D2, D2), // 1⟹0
            TriRange(C2, DAB_DA, DA), // 1⟹0
            TriRange(C2, D45_D5, D5), // 1⟹0
            TriRange(C2, D67_D7, D7), // 1⟹0
            TriRange(C3, D89_D8, D8), // 1⟹0


            TriRange(T0, D45_D5, C1),
            TriRange(C1, D4,     T3),
            TriRange(T3, D45_D5, C2),
            TriRange(C2, D5,     T0),
            TriRange(C1, D45_D5, D4),
            TriRange(T3, D45_D5, D4),
            TriRange(C3, D23_D2, T1),
            TriRange(T1, D2,     C1),
            TriRange(C1, D23_D2, T3),
            TriRange(T3, D3,     C3),
            TriRange(C3, D23_D2, D3),
            TriRange(T3, D23_D2, D3),
            TriRange(T2, D67_D7, C0),
            TriRange(C0, D6,     T0),
            TriRange(T0, D67_D7, C2),
            TriRange(C2, D7,     T2),
            TriRange(C0, D67_D7, D6),
            TriRange(T0, D67_D7, D6),
            TriRange(C0, D89_D8, T1),
            TriRange(T1, D8,     C3),
            TriRange(C3, D89_D8, T2),
            TriRange(T2, D9,     C0),
            TriRange(C0, D89_D8, D9),
            TriRange(T2, D89_D8, D9),
            TriRange(C0, D01_D1, T0),
            TriRange(T0, D0,     C1),
            TriRange(C1, D01_D1, T1),
            TriRange(T1, D1,     C0),
            TriRange(T0, D01_D1, D0),
            TriRange(C1, D01_D1, D0),
            TriRange(T2, DAB_DA, C2),
            TriRange(C2, DA,     T3),
            TriRange(T3, DAB_DA, C3),
            TriRange(C3, DB,     T2),
            TriRange(T2, DAB_DA, DB),
            TriRange(C3, DAB_DA, DB),
        ])
    }

    /// phase 8
    static func buildDodecFaceA() -> PhaseTriangles {

        let T0_I0 = VertexRange(T0, I0, .T0_I0)
        let T0_I1 = VertexRange(T0, I1, .T0_I1)
        let C0_I2 = VertexRange(C0, I2, .C0_I2)
        let T2_I3 = VertexRange(T2, I3, .T2_I3)
        let T2_I4 = VertexRange(T2, I4, .T2_I4)
        let C3_I5 = VertexRange(C3, I5, .C3_I5)
        let C3_I6 = VertexRange(C3, I6, .C3_I6)
        let T3_I7 = VertexRange(T3, I7, .T3_I7)
        let C1_I8 = VertexRange(C1, I8, .C1_I8)
        let C1_I9 = VertexRange(C1, I9, .C1_I9)
        let T3_IA = VertexRange(T3, IA, .T3_IA)
        let C0_IB = VertexRange(C0, IB, .C0_IB)

        return PhaseTriangles([

            TriRange(T0, T0_I0, D0), // 0⟹1
            TriRange(T0, T0_I1, D5), // 0⟹1
            TriRange(D6, T0_I0, T0), // 0⟹1
            TriRange(D6, T0_I1, T0), // 0⟹1
            TriRange(C0, C0_I2, D9), // 0⟹1
            TriRange(C0, C0_IB, D9), // 0⟹1
            TriRange(D6, C0_I2, C0), // 0⟹1
            TriRange(D1, C0_IB, C0), // 0⟹1
            TriRange(T2, T2_I3, D7), // 0⟹1
            TriRange(T2, T2_I4, D9), // 0⟹1
            TriRange(DB, T2_I3, T2), // 0⟹1
            TriRange(DB, T2_I4, T2), // 0⟹1
            TriRange(C3, C3_I5, DB), // 0⟹1
            TriRange(C3, C3_I6, D8), // 0⟹1
            TriRange(D3, C3_I5, C3), // 0⟹1
            TriRange(D3, C3_I6, C3), // 0⟹1
            TriRange(T3, T3_I7, D4), // 0⟹1
            TriRange(T3, T3_IA, D4), // 0⟹1
            TriRange(D3, T3_I7, T3), // 0⟹1
            TriRange(DA, T3_IA, T3), // 0⟹1
            TriRange(C1, C1_I8, D2), // 0⟹1
            TriRange(C1, C1_I9, D4), // 0⟹1
            TriRange(D0, C1_I8, C1), // 0⟹1
            TriRange(D0, C1_I9, C1), // 0⟹1


            TriRange(D0, T0_I0, D1),
            TriRange(D1, T0_I0, C0),
            TriRange(C0, T0_I0, D6),
            TriRange(D5, T0_I1, C2),
            TriRange(C2, T0_I1, D7),
            TriRange(D7, T0_I1, D6),
            TriRange(D7, C0_I2, D6),
            TriRange(D9, C0_I2, T2),
            TriRange(T2, C0_I2, D7),
            TriRange(D7, T2_I3, C2),
            TriRange(C2, T2_I3, DA),
            TriRange(DA, T2_I3, DB),
            TriRange(D9, T2_I4, D8),
            TriRange(D8, T2_I4, C3),
            TriRange(C3, T2_I4, DB),
            TriRange(DB, C3_I5, DA),
            TriRange(DA, C3_I5, T3),
            TriRange(T3, C3_I5, D3),
            TriRange(D8, C3_I6, T1),
            TriRange(T1, C3_I6, D2),
            TriRange(D2, C3_I6, D3),
            TriRange(D2, T3_I7, D3),
            TriRange(D4, T3_I7, C1),
            TriRange(C1, T3_I7, D2),
            TriRange(D2, C1_I8, T1),
            TriRange(T1, C1_I8, D1),
            TriRange(D1, C1_I8, D0),
            TriRange(D4, C1_I9, D5),
            TriRange(D5, C1_I9, T0),
            TriRange(T0, C1_I9, D0),
            TriRange(D5, T3_IA, C2),
            TriRange(C2, T3_IA, DA),
            TriRange(D4, T3_IA, D5),
            TriRange(D9, C0_IB, D8),
            TriRange(D8, C0_IB, T1),
            TriRange(T1, C0_IB, D1),
        ])
    }

    /// phase 9
    static func buildDodecFaceB() -> PhaseTriangles {

        let T0_T0D0 = VertexRange(T0, (T0,D0), .T0_T0D0)
        let D0_D0D1 = VertexRange(D0, (D0,D1), .D0_D0D1)
        let D1_D1C0 = VertexRange(D1, (D1,C0), .D1_D1C0)
        let C0_C0D6 = VertexRange(C0, (C0,D6), .C0_C0D6)
        let D6_D6T0 = VertexRange(D6, (D6,T0), .D6_D6T0)
        let T0_T0D5 = VertexRange(T0, (T0,D5), .T0_T0D5)
        let D5_D5C2 = VertexRange(D5, (D5,C2), .D5_D5C2)
        let C2_C2D7 = VertexRange(C2, (D7,C2), .C2_C2D7)
        let D7_D7D6 = VertexRange(D7, (D7,D6), .D7_D7D6)
        let D6_D6C0 = VertexRange(D6, (D6,C0), .D6_D6C0)
        let C0_CoD9 = VertexRange(C0, (C0,D9), .C0_CoD9)
        let D9_D9T2 = VertexRange(D9, (D9,T2), .D9_D9T2)
        let T2_T2D7 = VertexRange(T2, (T2,D7), .T2_T2D7)
        let D7_D7C2 = VertexRange(D7, (D7,C2), .D7_D7C2)
        let C2_C2DA = VertexRange(C2, (C2,DA), .C2_C2DA)
        let DA_DADB = VertexRange(DA, (DA,DB), .DA_DADB)
        let DB_DBT2 = VertexRange(DB, (DB,T2), .DB_DBT2)
        let T2_T2D9 = VertexRange(T2, (T2,D9), .T2_T2D9)
        let D9_D9D8 = VertexRange(D9, (D9,D8), .D9_D9D8)
        let D8_D8C3 = VertexRange(D8, (D8,C3), .D8_D8C3)
        let C3_C3DB = VertexRange(C3, (C3,DB), .C3_C3DB)
        let DB_DBDA = VertexRange(DB, (DB,DA), .DB_DBDA)
        let DA_DAT3 = VertexRange(DA, (DA,T3), .DA_DAT3)
        let T3_T3D3 = VertexRange(T3, (T3,D3), .T3_T3D3)
        let D3_D3C3 = VertexRange(D3, (D3,C3), .D3_D3C3)
        let C3_C3D8 = VertexRange(C3, (C3,D8), .C3_C3D8)
        let D8_D8T1 = VertexRange(D8, (D8,T1), .D8_D8T1)
        let T1_T1D2 = VertexRange(T1, (T1,D2), .T1_T1D2)
        let D2_D2D3 = VertexRange(D2, (D2,D3), .D2_D2D3)
        let D3_D3T3 = VertexRange(D3, (D3,T3), .D3_D3T3)
        let T3_T3D4 = VertexRange(T3, (T3,D4), .T3_T3D4)
        let D4_D4C1 = VertexRange(D4, (D4,C1), .D4_D4C1)
        let C1_C1D2 = VertexRange(C1, (C1,D2), .C1_C1D2)
        let D2_D2T1 = VertexRange(D2, (D2,T1), .D2_D2T1)
        let T1_T1D1 = VertexRange(T1, (T1,D1), .T1_T1D1)
        let D1_D1D0 = VertexRange(D1, (D1,D0), .D1_D1D0)
        let D0_D0C1 = VertexRange(D0, (D0,C1), .D0_D0C1)
        let C1_C1D4 = VertexRange(C1, (C1,D4), .C1_C1D4)
        let D4_D4D5 = VertexRange(D4, (D4,D5), .D4_D4D5)
        let D5_D5T0 = VertexRange(D5, (D5,T0), .D5_D5T0)

        return PhaseTriangles([
            //  m⟹n                   0⟹1
            TriRange(T0_T0D0, I0, D0),  TriRange(T0, I0, T0_T0D0),
            TriRange(D0_D0D1, I0, D1),  TriRange(D0, I0, D0_D0D1),
            TriRange(D1_D1C0, I0, C0),  TriRange(D1, I0, D1_D1C0),
            TriRange(C0_C0D6, I0, D6),  TriRange(C0, I0, C0_C0D6),
            TriRange(D6_D6T0, I0, T0),  TriRange(D6, I0, D6_D6T0),
            TriRange(D6_D6T0, I1, T0),  TriRange(D6, I1, D6_D6T0),
            TriRange(T0_T0D5, I1, D5),  TriRange(T0, I1, T0_T0D5),
            TriRange(D5_D5C2, I1, C2),  TriRange(D5, I1, D5_D5C2),
            TriRange(C2_C2D7, I1, D7),  TriRange(C2, I1, C2_C2D7),
            TriRange(D7_D7D6, I1, D6),  TriRange(D7, I1, D7_D7D6),
            TriRange(D7_D7D6, I2, D6),  TriRange(D7, I2, D7_D7D6),
            TriRange(D6_D6C0, I2, C0),  TriRange(D6, I2, D6_D6C0),
            TriRange(C0_CoD9, I2, D9),  TriRange(C0, I2, C0_CoD9),
            TriRange(D9_D9T2, I2, T2),  TriRange(D9, I2, D9_D9T2),
            TriRange(T2_T2D7, I2, D7),  TriRange(T2, I2, T2_T2D7),
            TriRange(T2_T2D7, I3, D7),  TriRange(T2, I3, T2_T2D7),
            TriRange(D7_D7C2, I3, C2),  TriRange(D7, I3, D7_D7C2),
            TriRange(C2_C2DA, I3, DA),  TriRange(C2, I3, C2_C2DA),
            TriRange(DA_DADB, I3, DB),  TriRange(DA, I3, DA_DADB),
            TriRange(DB_DBT2, I3, T2),  TriRange(DB, I3, DB_DBT2),
            TriRange(DB_DBT2, I4, T2),  TriRange(DB, I4, DB_DBT2),
            TriRange(T2_T2D9, I4, D9),  TriRange(T2, I4, T2_T2D9),
            TriRange(D9_D9D8, I4, D8),  TriRange(D9, I4, D9_D9D8),
            TriRange(D8_D8C3, I4, C3),  TriRange(D8, I4, D8_D8C3),
            TriRange(C3_C3DB, I4, DB),  TriRange(C3, I4, C3_C3DB),
            TriRange(C3_C3DB, I5, DB),  TriRange(C3, I5, C3_C3DB),
            TriRange(DB_DBDA, I5, DA),  TriRange(DB, I5, DB_DBDA),
            TriRange(DA_DAT3, I5, T3),  TriRange(DA, I5, DA_DAT3),
            TriRange(T3_T3D3, I5, D3),  TriRange(T3, I5, T3_T3D3),
            TriRange(D3_D3C3, I5, C3),  TriRange(D3, I5, D3_D3C3),
            TriRange(D3_D3C3, I6, C3),  TriRange(D3, I6, D3_D3C3),
            TriRange(C3_C3D8, I6, D8),  TriRange(C3, I6, C3_C3D8),
            TriRange(D8_D8T1, I6, T1),  TriRange(D8, I6, D8_D8T1),
            TriRange(T1_T1D2, I6, D2),  TriRange(T1, I6, T1_T1D2),
            TriRange(D2_D2D3, I6, D3),  TriRange(D2, I6, D2_D2D3),
            TriRange(D2_D2D3, I7, D3),  TriRange(D2, I7, D2_D2D3),
            TriRange(D3_D3T3, I7, T3),  TriRange(D3, I7, D3_D3T3),
            TriRange(T3_T3D4, I7, D4),  TriRange(T3, I7, T3_T3D4),
            TriRange(D4_D4C1, I7, C1),  TriRange(D4, I7, D4_D4C1),
            TriRange(C1_C1D2, I7, D2),  TriRange(C1, I7, C1_C1D2),
            TriRange(C1_C1D2, I8, D2),  TriRange(C1, I8, C1_C1D2),
            TriRange(D2_D2T1, I8, T1),  TriRange(D2, I8, D2_D2T1),
            TriRange(T1_T1D1, I8, D1),  TriRange(T1, I8, T1_T1D1),
            TriRange(D1_D1D0, I8, D0),  TriRange(D1, I8, D1_D1D0),
            TriRange(D0_D0C1, I8, C1),  TriRange(D0, I8, D0_D0C1),
            TriRange(D0_D0C1, I9, C1),  TriRange(D0, I9, D0_D0C1),
            TriRange(C1_C1D4, I9, D4),  TriRange(C1, I9, C1_C1D4),
            TriRange(D4_D4D5, I9, D5),  TriRange(D4, I9, D4_D4D5),
            TriRange(D5_D5T0, I9, T0),  TriRange(D5, I9, D5_D5T0),
            TriRange(T0_T0D0, I9, D0),  TriRange(T0, I9, T0_T0D0),
            TriRange(D5_D5C2, IA, C2),  TriRange(D5, IA, D5_D5C2),
            TriRange(C2_C2DA, IA, DA),  TriRange(C2, IA, C2_C2DA),
            TriRange(DA_DAT3, IA, T3),  TriRange(DA, IA, DA_DAT3),
            TriRange(T3_T3D4, IA, D4),  TriRange(T3, IA, T3_T3D4),
            TriRange(D4_D4D5, IA, D5),  TriRange(D4, IA, D4_D4D5),
            TriRange(D1_D1C0, IB, C0),  TriRange(D1, IB, D1_D1C0),
            TriRange(C0_CoD9, IB, D9),  TriRange(C0, IB, C0_CoD9),
            TriRange(D9_D9D8, IB, D8),  TriRange(D9, IB, D9_D9D8),
            TriRange(D8_D8T1, IB, T1),  TriRange(D8, IB, D8_D8T1),
            TriRange(T1_T1D1, IB, D1),  TriRange(T1, IB, T1_T1D1),
        ])
    }

    ///  phase 10
    static func buildDodecIcosa() -> PhaseTriangles {

        let T0_I019 = VertexRange(T0, (I0,I1,I9), .T0_I019)
        let T1_I6B8 = VertexRange(T1, (I6,IB,I8), .T1_I6B8)
        let T2_I234 = VertexRange(T2, (I2,I3,I4), .T2_I234)
        let T3_I57A = VertexRange(T3, (I5,I7,IA), .T3_I57A)
        let C0_I02B = VertexRange(C0, (I0,I2,IB), .C0_I02B)
        let C1_I897 = VertexRange(C1, (I8,I9,I7), .C1_I897)
        let C2_I13A = VertexRange(C2, (I1,I3,IA), .C2_I13A)
        let C3_I456 = VertexRange(C3, (I4,I5,I6), .C3_I456)
        let D0_I089 = VertexRange(D0, (I0,I8,I9), .D0_I089)
        let D1_I08B = VertexRange(D1, (I0,I8,IB), .D1_I08B)
        let D2_I678 = VertexRange(D2, (I6,I7,I8), .D2_I678)
        let D3_I567 = VertexRange(D3, (I5,I6,I7), .D3_I567)
        let D4_I79A = VertexRange(D4, (I7,I9,IA), .D4_I79A)
        let D5_I19A = VertexRange(D5, (I1,I9,IA), .D5_I19A)
        let D6_I012 = VertexRange(D6, (I0,I1,I2), .D6_I012)
        let D7_I123 = VertexRange(D7, (I1,I2,I3), .D7_I123)
        let D8_I46B = VertexRange(D8, (I4,I6,IB), .D8_I46B)
        let D9_I24B = VertexRange(D9, (I2,I4,IB), .D9_I24B)
        let DA_I35A = VertexRange(DA, (I3,I5,IA), .DA_I35A)
        let DB_I345 = VertexRange(DB, (I3,I4,I5), .DB_I345)

        let T0_D0I09 = VertexRange((T0_I019, D0_I089), (I0, I9), .T0_D0I09)
        let D0_D1I08 = VertexRange((D0_I089, D1_I08B), (I0, I8), .D0_D1I08)
        let D1_C0I0B = VertexRange((D1_I08B, C0_I02B), (I0, IB), .D1_C0I0B)
        let C0_D6I02 = VertexRange((C0_I02B, D6_I012), (I0, I2), .C0_D6I02)
        let D6_T0I01 = VertexRange((D6_I012, T0_I019), (I0, I1), .D6_T0I01)
        let T0_D5I19 = VertexRange((T0_I019, D5_I19A), (I1, I9), .T0_D5I19)
        let D5_C2I1A = VertexRange((D5_I19A, C2_I13A), (I1, IA), .D5_C2I1A)
        let C2_D7I13 = VertexRange((C2_I13A, D7_I123), (I1, I3), .C2_D7I13)
        let D7_D6I12 = VertexRange((D7_I123, D6_I012), (I1, I2), .D7_D6I12)
        let D6_C0I02 = VertexRange((D6_I012, C0_I02B), (I0, I2), .D6_C0I02)
        let C0_D9I2B = VertexRange((C0_I02B, D9_I24B), (I2, IB), .C0_D9I2B)
        let D9_T2I24 = VertexRange((D9_I24B, T2_I234), (I2, I4), .D9_T2I24)
        let T2_D7I23 = VertexRange((T2_I234, D7_I123), (I2, I3), .T2_D7I23)
        let D7_C2I13 = VertexRange((D7_I123, C2_I13A), (I1, I3), .D7_C2I13)
        let C2_DAI3A = VertexRange((C2_I13A, DA_I35A), (I3, IA), .C2_DAI3A)
        let DA_DBI35 = VertexRange((DA_I35A, DB_I345), (I3, I5), .DA_DBI35)
        let DB_T2I34 = VertexRange((DB_I345, T2_I234), (I3, I4), .DB_T2I34)
        let T2_D9I24 = VertexRange((T2_I234, D9_I24B), (I2, I4), .T2_D9I24)
        let D9_D8I4B = VertexRange((D9_I24B, D8_I46B), (I4, IB), .D9_D8I4B)
        let D8_C3I46 = VertexRange((D8_I46B, C3_I456), (I4, I6), .D8_C3I46)
        let C3_DBI45 = VertexRange((C3_I456, DB_I345), (I4, I5), .C3_DBI45)
        let DB_DAI35 = VertexRange((DB_I345, DA_I35A), (I3, I5), .DB_DAI35)
        let DA_T3I5A = VertexRange((DA_I35A, T3_I57A), (I5, IA), .DA_T3I5A)
        let T3_D3I75 = VertexRange((T3_I57A, D3_I567), (I7, I5), .T3_D3I75)
        let D3_C3I56 = VertexRange((D3_I567, C3_I456), (I5, I6), .D3_C3I56)
        let C3_D8I46 = VertexRange((C3_I456, D8_I46B), (I4, I6), .C3_D8I46)
        let D8_T1I6B = VertexRange((D8_I46B, T1_I6B8), (I6, IB), .D8_T1I6B)
        let T1_D2I68 = VertexRange((T1_I6B8, D2_I678), (I6, I8), .T1_D2I68)
        let D2_D3I67 = VertexRange((D2_I678, D3_I567), (I6, I7), .D2_D3I67)
        let D3_T3I57 = VertexRange((D3_I567, T3_I57A), (I5, I7), .D3_T3I57)
        let T3_D4I7A = VertexRange((T3_I57A, D4_I79A), (I7, IA), .T3_D4I7A)
        let D4_C1I79 = VertexRange((D4_I79A, C1_I897), (I7, I9), .D4_C1I79)
        let C1_D2I78 = VertexRange((C1_I897, D2_I678), (I7, I8), .C1_D2I78)
        let D2_T1I68 = VertexRange((D2_I678, T1_I6B8), (I6, I8), .D2_T1I68)
        let T1_D1I8B = VertexRange((T1_I6B8, D1_I08B), (I8, IB), .T1_D1I8B)
        let D1_D0I08 = VertexRange((D1_I08B, D0_I089), (I0, I8), .D1_D0I08)
        let D0_C1I89 = VertexRange((D0_I089, C1_I897), (I8, I9), .D0_C1I89)
        let C1_D4I79 = VertexRange((C1_I897, D4_I79A), (I7, I9), .C1_D4I79)
        let D4_D5IA9 = VertexRange((D4_I79A, D5_I19A), (IA, I9), .D4_D5IA9)
        let D5_T0I19 = VertexRange((D5_I19A, T0_I019), (I1, I9), .D5_T0I19)

        return PhaseTriangles([
            //  m⟹n                        0⟹1
            TriRange(T0_D0I09, I0, D0_I089), TriRange(T0_I019, I0, T0_D0I09),
            TriRange(D0_D1I08, I0, D1_I08B), TriRange(D0_I089, I0, D0_D1I08),
            TriRange(D1_C0I0B, I0, C0_I02B), TriRange(D1_I08B, I0, D1_C0I0B),
            TriRange(C0_D6I02, I0, D6_I012), TriRange(C0_I02B, I0, C0_D6I02),
            TriRange(D6_T0I01, I0, T0_I019), TriRange(D6_I012, I0, D6_T0I01),
            TriRange(D6_T0I01, I1, T0_I019), TriRange(D6_I012, I1, D6_T0I01),
            TriRange(T0_D5I19, I1, D5_I19A), TriRange(T0_I019, I1, T0_D5I19),
            TriRange(D5_C2I1A, I1, C2_I13A), TriRange(D5_I19A, I1, D5_C2I1A),
            TriRange(C2_D7I13, I1, D7_I123), TriRange(C2_I13A, I1, C2_D7I13),
            TriRange(D7_D6I12, I1, D6_I012), TriRange(D7_I123, I1, D7_D6I12),
            TriRange(D7_D6I12, I2, D6_I012), TriRange(D7_I123, I2, D7_D6I12),
            TriRange(D6_C0I02, I2, C0_I02B), TriRange(D6_I012, I2, D6_C0I02),
            TriRange(C0_D9I2B, I2, D9_I24B), TriRange(C0_I02B, I2, C0_D9I2B),
            TriRange(D9_T2I24, I2, T2_I234), TriRange(D9_I24B, I2, D9_T2I24),
            TriRange(T2_D7I23, I2, D7_I123), TriRange(T2_I234, I2, T2_D7I23),
            TriRange(T2_D7I23, I3, D7_I123), TriRange(T2_I234, I3, T2_D7I23),
            TriRange(D7_C2I13, I3, C2_I13A), TriRange(D7_I123, I3, D7_C2I13),
            TriRange(C2_DAI3A, I3, DA_I35A), TriRange(C2_I13A, I3, C2_DAI3A),
            TriRange(DA_DBI35, I3, DB_I345), TriRange(DA_I35A, I3, DA_DBI35),
            TriRange(DB_T2I34, I3, T2_I234), TriRange(DB_I345, I3, DB_T2I34),
            TriRange(DB_T2I34, I4, T2_I234), TriRange(DB_I345, I4, DB_T2I34),
            TriRange(T2_D9I24, I4, D9_I24B), TriRange(T2_I234, I4, T2_D9I24),
            TriRange(D9_D8I4B, I4, D8_I46B), TriRange(D9_I24B, I4, D9_D8I4B),
            TriRange(D8_C3I46, I4, C3_I456), TriRange(D8_I46B, I4, D8_C3I46),
            TriRange(C3_DBI45, I4, DB_I345), TriRange(C3_I456, I4, C3_DBI45),
            TriRange(C3_DBI45, I5, DB_I345), TriRange(C3_I456, I5, C3_DBI45),
            TriRange(DB_DAI35, I5, DA_I35A), TriRange(DB_I345, I5, DB_DAI35),
            TriRange(DA_T3I5A, I5, T3_I57A), TriRange(DA_I35A, I5, DA_T3I5A),
            TriRange(T3_D3I75, I5, D3_I567), TriRange(T3_I57A, I5, T3_D3I75),
            TriRange(D3_C3I56, I5, C3_I456), TriRange(D3_I567, I5, D3_C3I56),
            TriRange(D3_C3I56, I6, C3_I456), TriRange(D3_I567, I6, D3_C3I56),
            TriRange(C3_D8I46, I6, D8_I46B), TriRange(C3_I456, I6, C3_D8I46),
            TriRange(D8_T1I6B, I6, T1_I6B8), TriRange(D8_I46B, I6, D8_T1I6B),
            TriRange(T1_D2I68, I6, D2_I678), TriRange(T1_I6B8, I6, T1_D2I68),
            TriRange(D2_D3I67, I6, D3_I567), TriRange(D2_I678, I6, D2_D3I67),
            TriRange(D2_D3I67, I7, D3_I567), TriRange(D2_I678, I7, D2_D3I67),
            TriRange(D3_T3I57, I7, T3_I57A), TriRange(D3_I567, I7, D3_T3I57),
            TriRange(T3_D4I7A, I7, D4_I79A), TriRange(T3_I57A, I7, T3_D4I7A),
            TriRange(D4_C1I79, I7, C1_I897), TriRange(D4_I79A, I7, D4_C1I79),
            TriRange(C1_D2I78, I7, D2_I678), TriRange(C1_I897, I7, C1_D2I78),
            TriRange(C1_D2I78, I8, D2_I678), TriRange(C1_I897, I8, C1_D2I78),
            TriRange(D2_T1I68, I8, T1_I6B8), TriRange(D2_I678, I8, D2_T1I68),
            TriRange(T1_D1I8B, I8, D1_I08B), TriRange(T1_I6B8, I8, T1_D1I8B),
            TriRange(D1_D0I08, I8, D0_I089), TriRange(D1_I08B, I8, D1_D0I08),
            TriRange(D0_C1I89, I8, C1_I897), TriRange(D0_I089, I8, D0_C1I89),
            TriRange(D0_C1I89, I9, C1_I897), TriRange(D0_I089, I9, D0_C1I89),
            TriRange(C1_D4I79, I9, D4_I79A), TriRange(C1_I897, I9, C1_D4I79),
            TriRange(D4_D5IA9, I9, D5_I19A), TriRange(D4_I79A, I9, D4_D5IA9),
            TriRange(D5_T0I19, I9, T0_I019), TriRange(D5_I19A, I9, D5_T0I19),
            TriRange(T0_D0I09, I9, D0_I089), TriRange(T0_I019, I9, T0_D0I09),
            TriRange(D5_C2I1A, IA, C2_I13A), TriRange(D5_I19A, IA, D5_C2I1A),
            TriRange(C2_DAI3A, IA, DA_I35A), TriRange(C2_I13A, IA, C2_DAI3A),
            TriRange(DA_T3I5A, IA, T3_I57A), TriRange(DA_I35A, IA, DA_T3I5A),
            TriRange(T3_D4I7A, IA, D4_I79A), TriRange(T3_I57A, IA, T3_D4I7A),
            TriRange(D4_D5IA9, IA, D5_I19A), TriRange(D4_I79A, IA, D4_D5IA9),
            TriRange(D1_C0I0B, IB, C0_I02B), TriRange(D1_I08B, IB, D1_C0I0B),
            TriRange(C0_D9I2B, IB, D9_I24B), TriRange(C0_I02B, IB, C0_D9I2B),
            TriRange(D9_D8I4B, IB, D8_I46B), TriRange(D9_I24B, IB, D9_D8I4B),
            TriRange(D8_T1I6B, IB, T1_I6B8), TriRange(D8_I46B, IB, D8_T1I6B),
            TriRange(T1_D1I8B, IB, D1_I08B), TriRange(T1_I6B8, IB, T1_D1I8B),
        ])
    }

    static func buildIcosa() -> PhaseTriangles {

        return PhaseTriangles([

            TriRange(I0, I1, I2), TriRange(I0, I2, IB),
            TriRange(I0, IB, I8), TriRange(I0, I8, I9),
            TriRange(I0, I9, I1), TriRange(I4, IB, I6),
            TriRange(IB, I6, I8), TriRange(I6, I8, I7),
            TriRange(I8, I7, I9), TriRange(I7, I9, IA),
            TriRange(I9, IA, I1), TriRange(IA, I1, I3),
            TriRange(I1, I3, I2), TriRange(I3, I2, I4),
            TriRange(I2, I4, IB), TriRange(I5, I4, I6),
            TriRange(I5, I6, I7), TriRange(I5, I7, IA),
            TriRange(I5, IA, I3), TriRange(I5, I3, I4)
        ])
    }

    static func buildCube() -> PhaseTriangles {

        return PhaseTriangles([

            TriRange(T3, C1, T0), TriRange(T0, T3, C2),
            TriRange(T0, C2, C0), TriRange(C0, C2, T2),
            TriRange(T2, C0, C3), TriRange(C3, C0, T1),
            TriRange(T1, C3, C1), TriRange(C1, C3, T3),
            TriRange(T3, C3, C2), TriRange(C3, C2, T2),
            TriRange(C1, T1, T0), TriRange(T0, C0, T1)
        ])
    }

    static func build(_ phase: Int) -> PhaseTriangles {

        switch phase {
            case  0: return buildZeroTetra ()
            case  1: return buildTetraCubeA()
            case  2: return buildTetraCubeB()
            case  3: return buildCubeOctA  ()
            case  4: return buildCubeOctB  ()
            case  5: return buildOctCube   ()
            case  6: return buildCubeDodecA()
            case  7: return buildCubeDodecB()
            case  8: return buildDodecFaceA()
            case  9: return buildDodecFaceB()
            case 10: return buildDodecIcosa()
            default: return buildZeroTetra ()
        }
    }

}
