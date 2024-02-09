//
//  ContentView.swift
//  Attractor
//
//  Created by Don Espe on 2/7/24.
//

import SwiftUI
import simd

let size = CGSize(width: 400, height: 400)

struct ContentView: View {
    let timer = Timer.publish(every: 0.005, on: .main, in: .common).autoconnect()

    var dot = [10.0, 40.0, 30.0]

    var s = 10.0
    var r = 28.0
    var b = 2.667

    var dt = 0.011

    var projMatrix:[[CGFloat]] = [
        [1.0, 0.0, 0.0],
        [0.0, 1.0, 0.0],
        [0.0, 0.0, 0.0]
    ]

    let scale = 4.0//100.0
    let ignoreScale = true

    @State var points:[CIVector] = //[]

    [CIVector(x: -0.5, y: -0.5, z: 0.5),
                         CIVector(x: 0.5, y: -0.5, z: 0.5),
                         CIVector(x: -0.5, y: 0.5, z: 0.5),
                         CIVector(x: 0.5, y: 0.5, z: 0.5),
                         CIVector(x: -0.5, y: -0.5, z: -0.5),
                         CIVector(x: 0.5, y: -0.5, z: -0.5),
                         CIVector(x: -0.5, y: 0.5, z: -0.5),
                         CIVector(x: 0.5, y: 0.5, z: -0.5)
    ]

    @State var angleX = 0.0
    @State var angleY = 0.0
    @State var angleZ = 0.0

    @State var angleXChange = 0.0
    @State var angleYChange = 0.0
    @State var angleZChange = 0.0

    @State var useCube = false


    var body: some View {
        VStack {
            Canvas { context, size in

                //This loop does the rotations and then the array is sorted by the z values so they will be drawn from front to back.
                var usePoints = points
                for (index, point) in points.enumerated() {
                    var newPoint = rotateZ(point: point, angle: angleZ)
                    newPoint = rotateX(point: newPoint, angle: angleX)
                    newPoint = rotateY(point: newPoint, angle: angleY)
                    newPoint = CIVector(x: newPoint.x, y: newPoint.y, z: newPoint.z, w: point.z)
                    usePoints[index] = newPoint
                }
                if useCube {
                    usePoints.sort {
                        $0.z < $1.z
                    }
                }
                var i = 0.0
                for point in usePoints {
                    var useColor:GraphicsContext.Shading = .color(.blue)
                    let usePoint = point.z
                    let newPoint = matrixMultiply(matrix: projMatrix, point: point)!
                    var scalePoint = (usePoint + 1.5) * (150 / 8) //(usePoint + 1.5) * (scale / 8)
                    if point.w < 0 {
                        useColor = .color(.green)
                    }
                    var useScale = 150.0
                    if ignoreScale && !useCube {
                        scalePoint = 4
                        useScale = 4
                        useColor = .color(Color(hue: i, saturation: 1, brightness: 1))
                    }

                    context.fill(
                        Path(roundedRect:
                                CGRect(origin: CGPoint(x: (newPoint.x * useScale) + (size.width / 2), y: (newPoint.y * useScale) + (size.height / 2)), size: CGSize(width:  scalePoint, height: scalePoint)),
                             cornerSize: CGSize(width: scalePoint, height: scalePoint)),
                        with: (useColor)
                    )
                    i += 0.01
                    if i > 1 {
                        i = 0
                    }
                }
            }
            .gesture(
                DragGesture().onChanged { value in
//                    print("translation: ", value.translation)
//                    print("angles: x: ", angleX, ", y: ", angleY, ", z: ", angleZ)
                    angleYChange = value.translation.width / 6000
                    angleXChange = value.translation.height / 6000
                }
                    .onEnded { value in
                        angleXChange = 0
                        angleYChange = 0
                        angleZChange = 0
                    }
            )
            Text("Number of points: \(points.count)")
            Toggle(isOn: $useCube) {
                Text("Use Cube")
            }
        }
        .padding()
        .onReceive(timer, perform: { _ in
            if !useCube  {
                if points.count < 5000 {
                    var lastPoint = CIVector(x: points.last!.x, y: points.last!.y, z: points.last!.z)
                    let lorenzPoint = lorenz(point: points.last!)
                    let usePoint = CIVector(x: lastPoint.x + lorenzPoint.x * dt, y: lastPoint.y + lorenzPoint.y * dt, z: lastPoint.z + lorenzPoint.z * dt, w: lastPoint.z)
                    points.append(usePoint)
                }
            } else {
                points = [CIVector(x: -0.5, y: -0.5, z: 0.5),
                          CIVector(x: 0.5, y: -0.5, z: 0.5),
                          CIVector(x: -0.5, y: 0.5, z: 0.5),
                          CIVector(x: 0.5, y: 0.5, z: 0.5),
                          CIVector(x: -0.5, y: -0.5, z: -0.5),
                          CIVector(x: 0.5, y: -0.5, z: -0.5),
                          CIVector(x: -0.5, y: 0.5, z: -0.5),
                          CIVector(x: 0.5, y: 0.5, z: -0.5)
                ]
            }
//            print(usePoint)

            angleX -= angleXChange
            if angleX > .pi * 2 {
                angleX -= .pi * 2
            }
            if angleX < 0 {
                angleX += .pi * 2
            }
            angleY += angleYChange
            if angleY > .pi * 2 {
                angleY -= .pi * 2
            }
            angleZ -= angleZChange
            if angleZ > .pi * 2 {
                angleZ -= .pi * 2
            }
        })
        .onAppear {
            if !useCube {
                points = []
                points.append(CIVector(x: CGFloat.random(in: -0.1...0.1), y: CGFloat.random(in: -0.1...0.1), z: CGFloat.random(in: -0.1...0.1)))
            }
        }
    }

    func lorenz(point: CIVector) -> CIVector {
        let x = point.x
        let y = point.y
        let z = point.z

        let newX = s * (y - x)
        let newY = r * x - y - x * z
        let newZ = x * y - b * z

        return CIVector(x: newX, y: newY, z: newZ)
    }

//    def lorenz(xyz, *, s=10, r=28, b=2.667):
//    """
//    Parameters
//    ----------
//    xyz : array-like, shape (3,)
//       Point of interest in three-dimensional space.
//    s, r, b : float
//       Parameters defining the Lorenz attractor.
//
//    Returns
//    -------
//    xyz_dot : array, shape (3,)
//       Values of the Lorenz attractor's partial derivatives at *xyz*.
//    """
//    x, y, z = xyz
//    x_dot = s*(y - x)
//    y_dot = r*x - y - x*z
//    z_dot = x*y - b*z
//    return np.array([x_dot, y_dot, z_dot])

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
        let usePoint = [point.x, point.y, point.z]
        let pointRows = point.count

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
