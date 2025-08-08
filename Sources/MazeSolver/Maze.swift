//
//  Maze.swift
//  MazeSolver
//
//  Created by Adam Young on 18/12/2024.
//

import Foundation

///
/// A maze.
///
public final class Maze<ElementType: MazeSquareType>: CustomStringConvertible {

    ///
    /// A type representing the grid of squares in the maze.
    ///
    public typealias Grid = [[MazeSquare<ElementType>]]

    ///
    /// The 2D array of squares in the maze.
    ///
    public let grid: Grid

    ///
    /// Start square.
    ///
    public let start: MazeSquare<ElementType>

    ///
    /// End square.
    ///
    public let end: MazeSquare<ElementType>

    ///
    /// Maze settings.
    ///
    public let settings: MazeSettings

    ///
    /// Creates a new maze with a grid, start, end and settings.
    ///
    /// - Parameters:
    ///   - grid: The 2D array of squares in the maze.
    ///   - start: Start square.
    ///   - end: End square.
    ///   - settings: Maze settings.
    ///
    /// - Throws: `MazeError`.
    ///
    public init(
        grid: Grid = [],
        start: Position? = nil,
        end: Position? = nil,
        settings: MazeSettings = .default
    ) throws(MazeError) {
        self.grid = grid

        if let startPosition = start {
            guard let startSquare = Self.square(at: startPosition, in: grid) else {
                throw .invalidPosition(startPosition)
            }
            self.start = startSquare
        } else if let startSquare = (Self.filterSquares(in: grid) { $0.type.isStart }).first {
            self.start = startSquare
        } else {
            throw .noStart
        }

        if let endPosition = end {
            guard let endSquare = Self.square(at: endPosition, in: grid) else {
                throw .invalidPosition(endPosition)
            }
            self.end = endSquare
        } else if let endSquare = (Self.filterSquares(in: grid) { $0.type.isEnd }).first {
            self.end = endSquare
        } else {
            throw .noEnd
        }

        self.settings = settings
    }

    ///
    /// Creates a new maze from a text value.
    ///
    /// - Parameters:
    ///   - input: A textual representation of the maze.
    ///   - settings: Maze settings.
    ///
    /// - Throws: `MazeError`.
    ///
    public convenience init(input: String, settings: MazeSettings = .default) throws(MazeError) {
        let rows =
            input
            .split(separator: "\n")
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        try self.init(rows: rows, settings: settings)
    }

    ///
    /// Creates a new maze from a file.
    ///
    /// - Parameters:
    ///   - fileURL: The URL to a text file containing a textual presentation of the maze.
    ///   - settings: Maze settings.
    ///
    /// - Throws: `MazeError`.
    ///
    public convenience init(
        fileURL: URL,
        settings: MazeSettings = .default
    ) async throws(MazeError) {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
            fatalError("cannot open input file")
        }

        defer {
            try? handle.close()
        }

        var rows: [String] = []
        do {
#if os(Linux)
let lines = handle.asyncLines()
#else
let lines = handle.bytes.lines
#endif
            //for try await line in handle.bytes.lines {
            for try await line in lines {
                rows.append(line)
            }
        } catch {
            throw .cannotReadFile(fileURL)
        }

        try self.init(rows: rows, settings: settings)
    }

    convenience init(rows: [String], settings: MazeSettings = .default) throws(MazeError) {
        var grid: Grid = []

        for (y, row) in rows.enumerated() {
            var squaresInRow: [MazeSquare<ElementType>] = []
            for (x, character) in row.enumerated() {
                guard let squareType = ElementType(rawValue: character) else {
                    print("Unknown square type: '\(character)'")
                    throw MazeError.unknownSquareType
                }

                let position = Position(x: x, y: y)
                let square = MazeSquare(type: squareType, position: position)
                squaresInRow.append(square)
            }

            grid.append(squaresInRow)
        }

        try self.init(grid: grid, settings: settings)
    }

    ///
    /// Finds the shortest path from the start to the end of the maze.
    ///
    /// - Returns: A result containing the path (a list of positions).
    ///
    public func findShortestPath() -> PathResult? {
        Self.findShortestPath(start: start, end: end, in: grid, settings: settings)
    }

    ///
    /// Find the lowest scoring paths from the start to the end of the maze.
    ///
    /// The 'cost' for a move or direction change can specified using `MazeSettings`.
    ///
    /// - Returns: A result containing the lowest score and all paths with this score.
    ///
    public func findLowestScoringPaths() -> LowestScoringPathsResult? {
        Self.findLowestScoringPaths(start: start, end: end, in: grid, settings: settings)
    }

    ///
    /// Returns a textual representing of the maze.
    ///
    /// - Parameters:
    ///   - path: An optional path to include in the representation.
    ///   - symbol: The character to use when displaying the path.
    ///
    /// - Returns: A textual representation of the maze.
    ///
    public func text(path: [Position]? = nil, symbol: Character = "O") -> String {
        let path = path ?? []

        var rowResults: [String] = []
        for (rowIndex, row) in grid.enumerated() {
            var rowResult = ""
            for (columnIndex, square) in row.enumerated() {
                let position = Position(x: columnIndex, y: rowIndex)
                if path.contains(position) {
                    rowResult += String(symbol)
                    continue
                }

                if square.isEmpty {
                    rowResult += " "
                    continue
                }

                rowResult += "\(square.type.rawValue)"
            }

            rowResults.append(rowResult)
        }

        return rowResults.joined(separator: "\n")
    }

    ///
    /// A textual representation of the maze.
    ///
    public var description: String {
        text()
    }

}

extension Maze {

    ///
    /// Returns the square at the given position in the maze.
    ///
    /// - Parameter position: The position in the maze.
    ///
    /// - Returns: The square a the given position, if the position is value.
    ///
    public func square(at position: Position) -> MazeSquare<ElementType>? {
        Self.square(at: position, in: grid)
    }

    ///
    /// Returns a filtered list of squares from the maze.
    ///
    /// - Parameter isIncluded: Closure to filter with.
    ///
    /// - Returns: Squares matching the filter.
    ///
    public func filterSquares(
        _ isIncluded: (MazeSquare<ElementType>) -> Bool
    ) -> [MazeSquare<ElementType>] {
        Self.filterSquares(in: grid, isIncluded)
    }

}

extension Maze {

    private static func findShortestPath(
        start startSquare: MazeSquare<ElementType>,
        end endSquare: MazeSquare<ElementType>,
        in grid: Grid,
        settings: MazeSettings
    ) -> PathResult? {
        guard
            let result = Self.findLowestScoringPaths(
                start: startSquare,
                end: endSquare,
                in: grid,
                settings: settings
            )
        else {
            return nil
        }

        guard let pathResult = result.pathResults.first else {
            return nil
        }

        return pathResult
    }

    private static func findLowestScoringPaths(
        start startSquare: MazeSquare<ElementType>,
        end endSquare: MazeSquare<ElementType>,
        in grid: Grid,
        settings: MazeSettings
    ) -> LowestScoringPathsResult? {
        var priorityQueue = PriorityQueue<(path: [Position], state: State)> {
            $0 < $1
        }

        let initialQueueItem = (
            path: [startSquare.position],
            state: State(position: startSquare.position, direction: settings.initialDirection)
        )
        priorityQueue.enqueue(initialQueueItem, score: 0)

        var visited: [State: Int] = [:]
        let initialState = State(
            position: startSquare.position,
            direction: settings.initialDirection
        )
        visited[initialState] = 0

        var lowestScore = Int.max
        var lowestScoringPaths: [[Position]] = []

        while let current = priorityQueue.dequeue() {
            let currentScore = current.score
            let currentPath = current.element.path
            let currentState = current.element.state

            if currentScore > lowestScore {
                continue
            }

            if currentState.position == endSquare.position {
                if currentScore < lowestScore {
                    lowestScore = currentScore
                    lowestScoringPaths = [currentPath]
                } else if currentScore == lowestScore {
                    lowestScoringPaths.append(currentPath)
                }

                continue
            }

            for nextDirection in Direction.allCases {
                let offset = nextDirection.offset
                let nextPosition = Position(
                    x: currentState.position.x + offset.column,
                    y: currentState.position.y + offset.row
                )

                guard
                    let nextSquare = Self.square(at: nextPosition, in: grid),
                    !nextSquare.type.isWall
                else {
                    continue
                }

                let rotationCost =
                    (nextDirection == currentState.direction) ? 0 : settings.rotationCost
                let newScore = currentScore + settings.moveCost + rotationCost
                let nextState = State(position: nextPosition, direction: nextDirection)

                if newScore <= (visited[nextState] ?? Int.max) {
                    visited[nextState] = newScore
                    let queueItem = (path: currentPath + [nextPosition], state: nextState)
                    priorityQueue.enqueue(queueItem, score: newScore)
                }
            }
        }

        guard !lowestScoringPaths.isEmpty else {
            return nil
        }

        let pathResults = lowestScoringPaths.map(PathResult.init)

        return LowestScoringPathsResult(score: lowestScore, pathResults: pathResults)
    }

}

extension Maze {

    private static func square(at position: Position, in grid: Grid) -> MazeSquare<ElementType>? {
        guard position.isValid(in: grid) else {
            return nil
        }

        return grid[position.y][position.x]
    }

    private static func filterSquares(
        in grid: Grid,
        _ isIncluded: (MazeSquare<ElementType>) -> Bool
    ) -> [MazeSquare<ElementType>] {
        var matchingSquares: [MazeSquare<ElementType>] = []

        for row in grid {
            matchingSquares.append(contentsOf: row.filter(isIncluded))
        }

        return matchingSquares
    }

}

#if os(Linux)
// Workaround for Linux
extension FileHandle {
    func asyncLines() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let data = self.readDataToEndOfFile()
                let string = String(data: data, encoding: .utf8) ?? ""
                let lines = string.components(separatedBy: .newlines)
                
                for line in lines {
                    continuation.yield(line)
                }
                continuation.finish()
            }
        }
    }
}
#endif

