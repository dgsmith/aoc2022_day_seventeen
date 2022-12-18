import Darwin
import Foundation

let log = false

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
        if elem == "\n" {
            break
        }
        movements.append(AirMovement(character: elem))
    }
}

enum AirMovement: String {
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

class Particle: Hashable, CustomStringConvertible {
    enum Kind {
        case air
        case environment
        case rock
    }
    
    let id: UUID = UUID()
    let kind: Kind
    var settled = false
    
    var description: String {
        switch kind {
        case .air: return "."
        case .environment: return "^"
        case .rock: return settled ? "#" : "@"
        }
    }
    
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

class Shape: CustomStringConvertible {
    enum Kind {
        case line
        case plus
        case reverseL
        case i
        case block
    }
    
    let name: String
    let particles: [[Particle]]
    var settled: Bool = false {
        didSet {
            guard settled else {
                return
            }
            for row in particles {
                for particle in row {
                    if particle.kind == .rock {
                        particle.settled = settled
                    }
                }
            }
        }
    }
    var towerPosition = (x: 0, y: 0)
    
    var height: Int {
        return particles.count
    }
    
    var width: Int {
        return particles[0].count
    }
    
    var description: String {
        return name
    }
    
    init(name: String, particles: [[Particle]]) {
        self.name = name
        self.particles = particles
    }
    
    static func of(kind: Kind) -> Shape {
        switch kind {
        case .line:
            return .makeLine()
        case .plus:
            return .makePlus()
        case .reverseL:
            return .makeReverseL()
        case .i:
            return .makeI()
        case .block:
            return .makeBlock()
        }
    }
    
    static func makeLine() -> Shape {
        return Shape(name: "Line", particles: [
            [
                Particle(kind: .rock),
                Particle(kind: .rock),
                Particle(kind: .rock),
                Particle(kind: .rock)
            ]
        ])
    }
    
    static func makePlus() -> Shape {
        return Shape(name: "Plus", particles: [
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
        return Shape(name: "Reverse L", particles: [
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
        return Shape(name: "I", particles: [
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
        return Shape(name: "Block", particles: [
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

struct Chamber: CustomStringConvertible {
    var tower = [[Particle]](repeating:
                                [Particle](repeating:
                                            Particle(kind: .air),
                                           count: 7),
                             count: 7)
    
    var tallestY: Int = -1
    var currentlyFallingShape: Shape?
    
    var description: String {
        var string = ""
        var maxI = 0
        for (i, row) in tower.enumerated() {
            var rowString = "\(i)\t|"
            for particle in row {
                rowString.append(String(describing: particle))
            }
            rowString.append("|\n")
            string = rowString + string
            maxI = i
        }
        let tabs = (maxI / 1000) > 1 ? "\t\t" : "\t"
        return "\n" + tabs + "|0123456|\n" + string + "\t+-------+"
    }
    
    var heightMap: [Int] {
        var map = [0, 0, 0, 0, 0, 0, 0]
        if tallestY == -1 {
            return map
        }
        
        let relativeY = tallestY
        for x in 0..<7 {
            var index = relativeY
            while true {
                let offset = relativeY - index
                if index < 0 {
                    map[x] = offset
                    break
                }
                
                let currentParticle = tower[index][x]
                if currentParticle.kind == .rock {
                    map[x] = offset
                    break
                }
                
                index -= 1
            }
        }
        
        return map
    }
    
    mutating func insert(shape: Shape) {
        if log {
            print("Inserting shape=\(shape)")
        }
        let newHeight = tallestY + 3 + shape.height
        if log {
            print("  Current tallestY=\(tallestY), newHeight=\(newHeight)")
        }
        if newHeight >= tower.count {
            if log {
                print("    increasing tower height")
            }
            tower.append(contentsOf:
                            [[Particle]](repeating:
                                            [Particle](repeating:
                                                        Particle(kind: .air),
                                                       count: 7),
                                         count: newHeight - tower.count + 1))
        }
        
        let towerYMin = tallestY + 3 + 1
        let towerYMax = newHeight + 1
        let towerXMin = 2
        let towerXMax = towerXMin + shape.width
        
        if log {
            print("  Inserting from (\(towerXMin), \(towerYMin)) to (\(towerXMax), \(towerYMax))")
        }
        
        for y in zip(towerYMin..<towerYMax, (0..<shape.height).reversed()) {
            for x in zip(towerXMin..<towerXMax, 0..<shape.width) {
                tower[y.0][x.0] = shape.particles[y.1][x.1]
            }
        }
        
        shape.towerPosition = (x: towerXMin, y: newHeight) // top-left of shape
        currentlyFallingShape = shape
        if log {
            print("  Setting new towerPosition=\(shape.towerPosition)")
        }
    }
    
    mutating func process(wind: AirMovement) {
        guard currentlyFallingShape != nil else {
            if log {
                print("nothing falling")
            }
            fatalError()
        }
        
        if log {
            print("Trying to move=\(currentlyFallingShape!)")
        }
        
        switch wind {
        case .left:
            if log {
                print("  moving left")
            }
            // check for wall or rock, don't move if find any in way of rock on left side
            
            // these points are aligned to the shape
            let top = currentlyFallingShape!.towerPosition.y
            let bottom = top - currentlyFallingShape!.height + 1
            let leftX = currentlyFallingShape!.towerPosition.x
            
            if leftX - 1 < 0 {
                if log {
                    print("    cannot move: hit wall")
                }
                return
            }
            
            // to see if we can move, go row by row checking for overlap between tower and shape
            // from the new x coord of the tower up to the x coord one less than shape width, compare the pairs
            
            let newXMin = leftX - 1
            let newXMax = newXMin + currentlyFallingShape!.width
            
            for y in zip(bottom..<(top + 1), (0..<currentlyFallingShape!.height).reversed()) {
                for x in zip(newXMin..<newXMax, 0..<currentlyFallingShape!.width) {
                    let towerMaterial = tower[y.0][x.0].kind
                    let shapeMaterial = currentlyFallingShape!.particles[y.1][x.1].kind
                    
                    if towerMaterial == .rock && shapeMaterial == .rock {
                        if log {
                            print("    cannot move: touching rock")
                        }
                        return
                    }
                    
                    if shapeMaterial == .rock {
                        if log {
                            print("    found shape start, no need to continue in this row")
                        }
                        break
                    }
                }
            }
            
            
            // we can move the shape!
            for y in zip(bottom..<(top + 1), (0..<currentlyFallingShape!.height).reversed()) {
                for x in zip(newXMin..<newXMax, 0..<currentlyFallingShape!.width) {
                    let currentTowerParticle = tower[y.0][x.0]
                    let shapeParticle = currentlyFallingShape!.particles[y.1][x.1]
                    
                    // only move the rocks
                    if shapeParticle.kind == .rock {
                        guard tower[y.0][x.0 + 1] == shapeParticle else {
                            fatalError()
                        }
                        
                        tower[y.0][x.0] = shapeParticle
                        tower[y.0][x.0 + 1] = currentTowerParticle
                    }
                }
            }
            
            currentlyFallingShape!.towerPosition.x -= 1
            
        case .right:
            if log {
                print("  moving right")
            }
            // check for wall or rock, don't move if find any in way of rock on right side
            let top = currentlyFallingShape!.towerPosition.y
            let bottom = top - currentlyFallingShape!.height + 1
            let rightX = currentlyFallingShape!.towerPosition.x + currentlyFallingShape!.width - 1
            
            if rightX + 1 >= tower[0].count {
                if log {
                    print("    cannot move: hit wall")
                }
                return
            }
                        
            let newXMax = rightX + 1
            let newXMin = newXMax - currentlyFallingShape!.width + 1
            
            for y in zip(bottom..<(top + 1), (0..<currentlyFallingShape!.height).reversed()) {
                for x in zip(newXMin..<(newXMax + 1), 0..<currentlyFallingShape!.width).reversed() {
                    let towerMaterial = tower[y.0][x.0].kind
                    let shapeMaterial = currentlyFallingShape!.particles[y.1][x.1].kind
                    
                    if towerMaterial == .rock && shapeMaterial == .rock {
                        if log {
                            print("    cannot move: touching rock")
                        }
                        return
                    }
                    
                    if shapeMaterial == .rock {
                        if log {
                            print("    found shape start, no need to continue in this row")
                        }
                        break
                    }
                }
            }
            
            
            // we can move the shape!
            for y in zip(bottom..<(top + 1), (0..<currentlyFallingShape!.height).reversed()) {
                for x in zip(newXMin..<(newXMax + 1), 0..<currentlyFallingShape!.width).reversed() {
                    let currentTowerParticle = tower[y.0][x.0]
                    let shapeParticle = currentlyFallingShape!.particles[y.1][x.1]
                    
                    // only move the rocks
                    if shapeParticle.kind == .rock {
                        guard tower[y.0][x.0 - 1] == shapeParticle else {
                            fatalError()
                        }
                        
                        tower[y.0][x.0] = shapeParticle
                        tower[y.0][x.0 - 1] = currentTowerParticle
                    }
                }
            }
            
            currentlyFallingShape!.towerPosition.x += 1
        }
    }
    
    mutating func processGravity() {
        guard currentlyFallingShape != nil else {
            if log {
                print("nothing falling")
            }
            fatalError()
        }
        
        if log {
            print("Trying to move=\(currentlyFallingShape!) down")
        }
        
        // check for wall or rock, don't move if find any in way of rock on bottom side
        let left = currentlyFallingShape!.towerPosition.x
        let right = left + currentlyFallingShape!.width - 1
        let bottom = currentlyFallingShape!.towerPosition.y - currentlyFallingShape!.height + 1
        
        if bottom - 1 < 0 {
            if log {
                print("    coming to a rest! hit wall")
            }
            currentlyFallingShape!.settled = true
            tallestY = max(tallestY, currentlyFallingShape!.towerPosition.y)
            currentlyFallingShape = nil
            return
        }
                
        let newYMin = bottom - 1
        let newYMax = newYMin + currentlyFallingShape!.height
        
        for x in zip(left..<(right + 1), 0..<currentlyFallingShape!.width) {
            for y in zip(newYMin..<newYMax, (0..<currentlyFallingShape!.height).reversed()) {
                let towerMaterial = tower[y.0][x.0].kind
                let shapeMaterial = currentlyFallingShape!.particles[y.1][x.1].kind
                
                if towerMaterial == .rock && shapeMaterial == .rock {
                    if log {
                        print("    coming to a rest: touching rock")
                    }
                    currentlyFallingShape!.settled = true
                    tallestY = max(tallestY, currentlyFallingShape!.towerPosition.y)
                    currentlyFallingShape = nil
                    return
                }
                
                if shapeMaterial == .rock {
                    if log {
                        print("    found shape start, no need to continue in this col")
                    }
                    break
                }
            }
        }
        
        
        // we can move the shape!
        for x in zip(left..<(right + 1), 0..<currentlyFallingShape!.width) {
            for y in zip(newYMin..<newYMax, (0..<currentlyFallingShape!.height).reversed()) {
                let currentTowerParticle = tower[y.0][x.0]
                let shapeParticle = currentlyFallingShape!.particles[y.1][x.1]
                
                // only move the rocks
                if shapeParticle.kind == .rock {
                    tower[y.0][x.0] = shapeParticle
                    tower[y.0 + 1][x.0] = currentTowerParticle
                }
            }
        }
        
        currentlyFallingShape!.towerPosition.y -= 1
    }
}

struct Key: Hashable {
    let heightMap: [Int]
    let movementIndex: Int
    let shapeIndex: Int
}

var chamber = Chamber()

let shapeOrder: [Shape.Kind] = [.line, .plus, .reverseL, .i, .block]

var cache = [Key: [(shapesDropped: Int, currentHeight: Int)]]()

var shapesFallen = 0
var index = 0

var heights = [Int]()
heights.append(0)

let TOTAL_SHAPES = 1000000000000

// create a cache with key: heightmap, wind index, current shape
// and store the number of shapes dropped so far

// once find a cycle, basically want to repeat it up to the number of shapes
// we care about the final height

while shapesFallen <= 5000 {
    let shapeIndex = shapesFallen % shapeOrder.count
    let movementIndex = index % movements.count
    if chamber.currentlyFallingShape == nil {
        let newShape = Shape.of(kind: shapeOrder[shapeIndex])
        chamber.insert(shape: newShape)
        
        // new cache entry for new shape
        let key = Key(heightMap: chamber.heightMap, movementIndex: movementIndex, shapeIndex: shapeIndex)
        let value = (shapesDropped: shapesFallen, currentHeight: chamber.tallestY - 1)
        if cache[key] != nil {
            cache[key]!.append(value)
        } else {
            cache[key] = [value]
        }
        heights.append(chamber.tallestY - 1)
    }
    
    let movement = movements[movementIndex]
    chamber.process(wind: movement)
    index += 1
    
    chamber.processGravity()

    if chamber.currentlyFallingShape == nil {
        shapesFallen += 1
    }

//    print(chamber)
}

//print(chamber)
print(movements.count)
//print(index)
print(chamber.tallestY - 1) // index 0 to 1

print(cache.keys.count)

var loop: [(shapesDropped: Int, currentHeight: Int)]?
for elem in cache {
    if elem.value.count > 1 {
        print("found loop!")
//        print(elem)
        loop = elem.value
        break
    }
}

guard let loop else {
    fatalError()
}

print(loop)
let loopShapeCountDelta = loop[1].shapesDropped - loop[0].shapesDropped
let loopHeightDelta = loop[1].currentHeight - loop[0].currentHeight
print("loopShapeCountDelta=\(loopShapeCountDelta), loopHeightDelta=\(loopHeightDelta)")

let shapesToFillWithLoop = TOTAL_SHAPES - loop[0].shapesDropped
let loopsThatFit = shapesToFillWithLoop / loopShapeCountDelta
let overflowShapes = shapesToFillWithLoop % loopShapeCountDelta
print("shapesToFillWithLoop=\(shapesToFillWithLoop), loopsThatFit=\(loopsThatFit), overflowShapes=\(overflowShapes)")

print(heights[loop[0].shapesDropped + 1])
let overflowHeight = heights[loop[1].shapesDropped + overflowShapes + 1] - heights[loop[1].shapesDropped + 1]
print("overflowHeight=\(overflowHeight)")

let totalHeight = loop[0].currentHeight + (loopsThatFit * loopHeightDelta) + overflowHeight
print("totalHeight=\(totalHeight)")
