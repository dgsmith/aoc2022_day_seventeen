import Darwin
import Foundation

var movements = [AirMovement]()

let filePath = "/Users/grayson/code/advent_of_code/2022/day_seventeen/test.txt"
guard let filePointer = fopen(filePath, "r") else {
    preconditionFailure("Could not open file at \(filePath)")
}
var lineByteArrayPointer: UnsafeMutablePointer<CChar>?
defer {
    fclose(filePointer)
    lineByteArrayPointer?.deallocate()
}
var lineCap: Int = 0
while getline(&lineByteArrayPointer, &lineCap, filePointer) > 0 {
    let line = Array(String(cString:lineByteArrayPointer!))
    for elem in line {
        movements.append(AirMovement(character: elem))
    }
}

enum AirMovement {
    case left
    case right
    
    init(character: Character) {
        if character == "<" {
            self = .left
        } else if character == ">" {
            self = .right
        } else {
            fatalError()
        }
    }
}

class Particle: Hashable {
    enum Kind {
        case air
        case environment
        case rock
    }
    
    let id: UUID = UUID()
    let kind: Kind
    
    init(kind: Kind) {
        self.kind = kind
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Particle, rhs: Particle) -> Bool {
        return lhs.id == rhs.id
    }
}

class Shape {
    let particles: [[Particle]]
    var settled: Bool = false
    var towerPosition = (x: 0, y: 0)
    
    var height: Int {
        return particles.count
    }
    
    var width: Int {
        return particles[0].count
    }
    
    init(particles: [[Particle]]) {
        self.particles = particles
    }
    
    static func makeLine() -> Shape {
        return Shape(particles: [
            [
                Particle(kind: .rock),
                Particle(kind: .rock),
                Particle(kind: .rock),
                Particle(kind: .rock)
            ]
        ])
    }
    
    static func makePlus() -> Shape {
        return Shape(particles: [
            [
                Particle(kind: .air),
                Particle(kind: .rock),
                Particle(kind: .air)
            ], [
                Particle(kind: .rock),
                Particle(kind: .rock),
                Particle(kind: .rock)
            ], [
                Particle(kind: .air),
                Particle(kind: .rock),
                Particle(kind: .air)
            ]
        ])
    }
    
    static func makeReverseL() -> Shape {
        return Shape(particles: [
            [
                Particle(kind: .air),
                Particle(kind: .air),
                Particle(kind: .rock)
            ], [
                Particle(kind: .air),
                Particle(kind: .air),
                Particle(kind: .rock)
            ], [
                Particle(kind: .rock),
                Particle(kind: .rock),
                Particle(kind: .rock)
            ]
        ])
    }
    
    static func makeI() -> Shape {
        return Shape(particles: [
            [
                Particle(kind: .rock)
            ], [
                Particle(kind: .rock)
            ], [
                Particle(kind: .rock)
            ], [
                Particle(kind: .rock)
            ]
        ])
    }
    
    static func makeBlock() -> Shape {
        return Shape(particles: [
            [
                Particle(kind: .rock),
                Particle(kind: .rock),
            ], [
                Particle(kind: .rock),
                Particle(kind: .rock),
            ]
        ])
    }
}

//    |..@@@@.|
//    |.......|
//    |.......|
// ^  |*......|
// |  +-------+
// (0, 0) ->

struct Chamber {
    var tower = [[Particle]](repeating:
                                [Particle](repeating:
                                            Particle(kind: .air),
                                           count: 7),
                             count: 7)
    
    var tallestY: Int = -1
    var currentlyFallingShape: Shape?
    
    mutating func insert(shape: Shape) {
        let newHeight = tallestY + 3 + shape.height
        if tower.count < newHeight {
            tower.append(contentsOf:
                            [[Particle]](repeating:
                                            [Particle](repeating:
                                                        Particle(kind: .air),
                                                       count: 7),
                                         count: newHeight - tower.count))
        }
        
        for y in zip((tallestY + 3 + 1)..<newHeight, 0..<shape.height) {
            for x in zip(2..<shape.width, 0..<shape.width) {
                tower[y.0][x.0] = shape.particles[y.1][x.1]
            }
        }
        
        shape.towerPosition = (x: tallestY + 3 + 1, y: 2)
        currentlyFallingShape = shape
    }
    
    mutating func process(wind: AirMovement) {
        guard currentlyFallingShape != nil else {
            print("nothing falling")
            fatalError()
        }
        
        switch wind {
        case .left:
            // check for wall or rock, don't move if find any in way of rock on left side
            let leftTop = currentlyFallingShape!.towerPosition.y + 1
            let leftBottom = leftTop - currentlyFallingShape!.height
            let leftX = currentlyFallingShape!.towerPosition.x
            
            if leftX - 1 <= 0 {
                return
                
            } else {
                for y in zip(leftBottom..<leftTop, 0..<currentlyFallingShape!.height) {
                    let shapeMaterial = currentlyFallingShape!.particles[y.1][0].kind
                    let otherMaterial = tower[y.0][leftX - 1].kind
                    
                    if otherMaterial == .rock && shapeMaterial == .rock {
                        return
                    }
                    
                    if otherMaterial == .air || shapeMaterial == .air {
                        continue
                    }
                }
            }
            
            // we can move the shape!
            
            break
        case .right:
            <#code#>
        }
    }
}
