//
//  ContentView.swift
//  Attractor
//
//  Created by Don Espe on 2/7/24.
//

import SwiftUI

let size = CGSize(width: 400, height: 400)

struct ContentView: View {
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var dot = [10.0, 40.0, 30.0]

    var projMatrix:[[CGFloat]] = [
        [1.0, 0.0, 0.0],
        [0.0, 1.0, 0.0],
        [0.0, 0.0, 0.0]
    ]

    let scale = 150.0

    @State var points = [CIVector(x: -0.5, y: -0.5, z: 0.5),
                         CIVector(x: 0.5, y: -0.5, z: 0.5),
                         CIVector(x: -0.5, y: 0.5, z: 0.5),
                         CIVector(x: 0.5, y: 0.5, z: 0.5),
                         CIVector(x: -0.5, y: -0.5, z: -0.5),
                         CIVector(x: 0.5, y: -0.5, z: -0.5),
                         CIVector(x: -0.5, y: 0.5, z: -0.5),
                         CIVector(x: 0.5, y: 0.5, z: -0.5)
    ]

    @State var angle = 0.0

    var body: some View {
        VStack {
            Canvas { context, size in
                for point in points {
                    var newPoint = rotateX(point: point, angle: angle)
                    newPoint = rotateZ(point: newPoint, angle: angle)
//                    newPoint = rotateX(point: newPoint, angle: angle)
                    let useZ = newPoint.z
                    newPoint = matrixMultiply(matrix: projMatrix, point: newPoint)!
                    let scalePoint = (useZ + 1.5) * 20
                    context.fill(
                        Path(roundedRect:
                                CGRect(origin: CGPoint(x: (newPoint.x * scale) + (size.width / 2), y: (newPoint.y * scale) + (size.height / 2)), size: CGSize(width:  scalePoint, height: scalePoint)),
                             cornerSize: CGSize(width: scalePoint, height: scalePoint)),
                        with: (.color(.white))
                    )
                }
            }
//            Text("\(points.description)")
        }
        .padding()
        .onReceive(timer, perform: { _ in
            angle += 0.01
            if angle > .pi * 2 {
                angle -= .pi * 2
            }
        })
        .onAppear {
        }
    }

    func rotateX(point: CIVector, angle: CGFloat) -> CIVector {
        let matrix = [[1.0, 0.0, 0.0],
                      [0.0, cos(angle), -sin(angle)],
                      [0.0, sin(angle), cos(angle)]
        ]
        return matrixMultiply(matrix: matrix, point: point) ?? CIVector(x: 0, y: 0, z: 0)
    }

    func rotateY(point: CIVector, angle: CGFloat) -> CIVector {
        let matrix = [[cos(angle), 0.0, sin(angle)],
                      [0.0, 1, 0],
                      [-sin(angle),0 , cos(angle)]
        ]
        return matrixMultiply(matrix: matrix, point: point) ?? CIVector(x: 0, y: 0, z: 0)
    }

    func rotateZ(point: CIVector, angle: CGFloat) -> CIVector {
        let matrix = [[cos(angle), sin(angle), 0],
                      [-sin(angle), cos(angle), 0],
                      [0.0, 0.0, 1.0]
        ]
        return matrixMultiply(matrix: matrix, point: point) ?? CIVector(x: 0, y: 0, z: 0)
    }

    func matrixMultiply(matrix: [[CGFloat]], point: CIVector) -> CIVector? {
        guard !matrix.isEmpty else { return nil}
        let matrixRows = matrix.count
        let matrixColumns = matrix[0].count
        let usePoint = [point.x, point.y, point.z]
        let pointRows = point.count

        guard matrixColumns == pointRows else {
            print("matrix columns must equal point rows")
            return nil
        }

        var tempArray = Array(repeating: 0.0, count: matrixRows)

        for i in 0..<matrixRows {
                var sum = 0.0
                for k in 0..<usePoint.count {
                    sum += matrix[i][k] * usePoint[k]
                }
                tempArray[i] = sum

        }
//        print("matrix: ", matrix.description)
//        print("point: ", point, " after multiply: ", tempArray)
//        print("----")

        return CIVector(x: tempArray[0], y: tempArray[1], z: tempArray[2])
    }
}

#Preview {
    ContentView()
}
