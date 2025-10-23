import Foundation
import Playgrounds

/// A Swift Package maze solver using the A* algorithm.
///
/// ## Example usage
///
/// ### Maze Square Type
///
/// Define an `enum` to describe each square type, which implements `MazeSquareType`.
///
/// e.g.

enum MyMazeSquareType: Character, MazeSquareType {
    case empty = "."
    case wall = "#"
    case start = "S" // Optional
    case end = "E" // Optional

    var isEmpty: Bool {
        self == .empty || self == .start || self == .end
    }

    var isWall: Bool {
        self == .wall
    }

    // Optional
    var isStart: Bool {
        self == .start
    }

    // Optional
    var isEnd: Bool {
        self == .end
    }
}


/// ### Initialise
///
/// A maze can be initialised in several ways.
///
/// #### Input string

#Playground("Example1") {
    let input = """
    ########
    #....#.#
    #.##E#.#
    #S.#...#
    ########
    """

    print("Solving maze:")
    print(input)
    print("Solution:")
    let maze = try Maze<MyMazeSquareType>(input: input)
    if let result = maze.findShortestPath() {
        let path = result.path
        let r = path.asciiGrid(width: 8, height: 5, emptyChar: ".")
        print(r)
    } else {
        print("No path")
    }
}

#Playground("Solve Maze") {
    print("Enter maze with '#' for walls, '.' for floor', 'S' for start and 'E' for end. Hit ^D to solve it.")
    // Read multi-line input from stdin until EOF
    var inputLines: [String] = []
    while let line = readLine() {
        inputLines.append(line)
    }
    let input = inputLines.joined(separator: "\n")

    guard !input.isEmpty else {
        print("No input provided")
        return
    }

    let mazeWidth = inputLines[0].count
    let mazeHeight = inputLines.count
    let mazeStr = inputLines.joined(separator: "\n")

    print("Solution:")
    let maze = try Maze<MyMazeSquareType>(input: mazeStr)
    if let result = maze.findShortestPath() {
        let path = result.path
        let r = path.asciiGrid(width: mazeWidth, height: mazeHeight, emptyChar: ".")
        print(r)
    } else {
        print("No path")
    }
}






extension Array where Element == Position {
    /// Returns an ASCII representation of a grid showing the positions in the array marked with their indices
    /// - Parameters:
    ///   - width: The width of the grid
    ///   - height: The height of the grid
    ///   - emptyChar: Character to use for empty spaces (default: ".")
    /// - Returns: String representing the grid with position indices
    func asciiGrid(width: Int, height: Int, emptyChar: Character = ".") -> String {
        // Create a 2D grid filled with the empty character
        var grid = Array<Array<Character>>(repeating: Array<Character>(repeating: emptyChar, count: width), count: height)

        // Place each index at its corresponding position
        for (index, position) in self.enumerated() {
            // Make sure the position is within the grid bounds
            guard position.x >= 0, position.x < width, position.y >= 0, position.y < height else { continue }
            
            // Convert the index to a string and place it in the grid
            let indexString = String(index)
            
            // If the index has multiple digits, we'll use just the last one
            // to keep the grid clean, though this may cause ambiguity
            // for indices >= 10
            if let lastChar = indexString.last {
                grid[position.y][position.x] = lastChar
            }
        }
        
        // Convert the grid to a string
        return grid.map { String($0) }.joined(separator: "\n")
    }
    
    /// Returns an ASCII representation of a grid with numbered indices that handles multi-digit numbers
    /// - Parameters:
    ///   - width: The width of the grid
    ///   - height: The height of the grid
    ///   - emptyChar: String to use for empty spaces (default: ".")
    /// - Returns: String representing the grid with position indices
    func detailedAsciiGrid(width: Int, height: Int, emptyChar: String = ".") -> String {
        // Find the largest index to determine spacing needs
        let maxIndex = self.count - 1
        let digitCount = String(maxIndex).count
        let cellWidth = Swift.max(digitCount, emptyChar.count)
        
        // Create a 2D grid filled with empty spaces
        var grid = Array<Array<String>>(repeating: Array<String>(repeating: emptyChar, count: width), count: height)

        // Place each index at its corresponding position
        for (index, position) in self.enumerated() {
            // Make sure the position is within the grid bounds
            guard position.x >= 0, position.x < width, position.y >= 0, position.y < height else { continue }
            
            // Convert the index to a string
            grid[position.y][position.x] = String(index)
        }
        
        // Convert the grid to a string with proper spacing
        var result = ""
        
        for row in grid {
            for (i, cell) in row.enumerated() {
                let paddedCell = cell.padding(toLength: cellWidth, withPad: " ", startingAt: 0)
                result += paddedCell
                if i < row.count - 1 {
                    result += " "
                }
            }
            result += "\n"
        }
        
        return result
    }
}
