//
//  StringExtension.swift
//  PRQuest
//
//  Created by Phil Stern on 12/8/19.
//  Copyright © 2019 Phil Stern. All rights reserved.
//

import Foundation

extension StringProtocol {

    // subscript definitions from https://stackoverflow.com/questions/24092884 (Leo Dabus)
    subscript(_ offset: Int)                     -> Element     { self[index(startIndex, offsetBy: offset)] }                 // str[4]
    subscript(_ range: Range<Int>)               -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }  // str[4..<10]
    subscript(_ range: ClosedRange<Int>)         -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }  // str[4...10]
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence { prefix(range.upperBound.advanced(by: 1)) }                  // str[...10]
    subscript(_ range: PartialRangeUpTo<Int>)    -> SubSequence { prefix(range.upperBound) }                                  // str[..<10]
    subscript(_ range: PartialRangeFrom<Int>)    -> SubSequence { suffix(Swift.max(0, count-range.lowerBound)) }              // str[4...]
    
    func formatJson() -> String {
        var output = ""
        var line = ""
        var indent = 0
        let indentString = "    "
        var readingString = false
        for char in self {
            if readingString {  // pass whole strings through (may contain brackets)
                line += String(char)
                if char == "\"" {
                    readingString = false
                }
            } else if char == "\"" {
                line += String(char)
                readingString = true
            } else if char == "," {
                output += line + ",\n"
                line = String(repeating: indentString, count: indent)
            } else if char == "{" || char == "[" {
                output += line + String(char) + "\n"
                indent += 1
                line = String(repeating: indentString, count: indent)
            } else if char == "}" || char == "]" {
                output += line + "\n"
                indent -= 1
                line = String(repeating: indentString, count: indent) + String(char)
            } else {
                line += String(char)
            }
        }
        output += line + "\n"
        return output
    }
    
    // Shortcomings of createJsonModel:
    // - creates empty structs for arrays of basic types (ex. [3, 4, 5])
    // - does not create CodingKeys for variables with invalid names (ex. 600, nearest-station, private...)
    // - only processes the first struct in an array, potentially missing different variables in the
    //   remaining structs (ex. API | Ride With GPS | RouteDetails | TrackPoints)
    // - does not handle structs where one element determines the type of another (ex. API | Strava | Streams)
    func createJsonModel(level: Int = 0) -> String {
        var output = ""
        if level == 0 {
            output = "\nprivate struct JsonModel: Decodable {\n"
            output += self.createJsonModel(level: 1)
            output += "}\n"
            return output
        }
        var line  = ""
        let leadingSpace = String(repeating: "    ", count: level)
        var creatingArray = false
        var readingString = false
        var skipToIndex = 0
        for (index, char) in self.enumerated() {
            if index > skipToIndex {
                if readingString {  // in middle of a string, just accept character
                    line += String(char)
                    if char == "\"" {
                        readingString = false
                    }
                } else if char == "\"" {  // beginning of a string
                    line += String(char)
                    readingString = true
                } else if char == "," || char == "}" || char == "]" {
                    var lineComponents = line.components(separatedBy: ":")
                    if lineComponents.count >= 2 {
                        // if there are more than two components, put 2..end back together
                        // ex. "created_at":"2013-11-30T20:36:04-08:00" (5 components)
                        for i in 2..<lineComponents.count {
                            lineComponents[1] += lineComponents[i]
                        }
                        let variableName = lineComponents[0].withoutQuotes().camelCased()
                        let variableType = lineComponents[1].type()
                        output += leadingSpace + "let \(variableName): \(variableType)\n"
                    } else {
                        if creatingArray { return output }
                    }
                    line = ""
                } else if char == "{" {
                    var lineComponents = line.components(separatedBy: ":")
                    if lineComponents.count >= 2 {
                        for i in 2..<lineComponents.count {
                            lineComponents[1] += lineComponents[i]
                        }
                        let variableName = lineComponents[0].withoutQuotes().camelCased()
                        let structName = variableName.leadingCapped()
                        output += leadingSpace + "let \(variableName): \(structName)\n"
                        output += leadingSpace + "struct \(structName): Decodable {\n"

                        skipToIndex = index + self[index...].findClosingBracket(for: char)
                        let recursiveOutput = self[index...skipToIndex].createJsonModel(level: level + 1)
                        output += recursiveOutput
                        output += leadingSpace + "}\n"
                    } else {
                        creatingArray = true
                        skipToIndex = index + self[index...].findClosingBracket(for: char)
                        let recursiveOutput = self[index...skipToIndex].createJsonModel(level: level)  // same indentation level
                        output += recursiveOutput
                    }
                    line = ""
                } else if char == "[" {
                    let lineComponents = line.components(separatedBy: ":")
                    if lineComponents.count == 2 {
                        let variableName = lineComponents[0].withoutQuotes().camelCased()
                        let structName = variableName.leadingCapped()
                        output += leadingSpace + "let \(variableName): [\(structName)]\n"  // []
                        output += leadingSpace + "struct \(structName): Decodable {\n"

                        skipToIndex = index + self[index...].findClosingBracket(for: char)
                        let recursiveOutput = self[index...skipToIndex].createJsonModel(level: level + 1)
                        output += recursiveOutput
                        output += leadingSpace + "}\n"
                    }
                    line = ""
                } else {
                    line += String(char)
                }
            }
        }
        return output
    }
    
    // pws: 9/10/22 after adding CoreDate, I got the following error, wherever I used "char", above:
    // "Cannot convert value of type 'Swift.Character' to expected argument type 'KevinBacon.Character'"
    // To fix, I changed Character to Swift.Character, below.
    
    func findClosingBracket(for openingBracket: Swift.Character) -> Int {
        var readingString = false
        let closingBracket = openingBracket == Swift.Character("{") ? Swift.Character("}") : Swift.Character("]")
        var nestingLevel = 0
        for (index, char) in self.enumerated() {
            if readingString {  // ignore characters in the middle of a string
                if char == "\"" {
                    readingString = false
                }
            } else if char == "\"" {  // beginning of a string
                readingString = true
            } else if char == openingBracket {
                nestingLevel += 1
            } else if char == closingBracket {
                nestingLevel -= 1
            }
            if nestingLevel == 0 {
                return index
            }
        }
        return self.count
    }
    
    // convert from "variable" to "Variable"
    func leadingCapped() -> String {
        return prefix(1).uppercased() + dropFirst()
    }

    // convert from snake case ("variable_name") to camel case ("variableName")
    // preserve leading underscore, if present
    // Note: $0.offset is the array position of the underscore-separated part
    func camelCased() -> String {
        return (self.first == "_" ? "_" : "") +
            self.split(separator: "_")
            .enumerated()
            .map { $0.offset > 0 ? $0.element.capitalized : String($0.element) }
            .joined()
    }
    
    // convert from ""hello"" to "hello"
    func withoutQuotes() -> String {
        return self.replacingOccurrences(of: "\"", with: "")
    }
    
    func type() -> String {
        if self == "null" {
            return "Any?"
        } else if self.contains("\"") {
            return "String"
        } else if self.contains(".") {
            return "Double"
        } else if self == "true" || self == "false" {
            return "Bool"
        } else {
            return "Int"
        }
    }
}
