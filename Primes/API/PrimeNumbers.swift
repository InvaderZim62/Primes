//
//  PrimeNumbers.swift
//  Primes
//
//  Created by Phil Stern on 9/30/23.
//
//  API Documentation: https://prime-number-api-docs.onrender.com/primeNumbers
//

import Foundation

enum FetchError: Error {
    case badURL
    case badResponse
    case badStatusCode(Int)  // Int: status code
}

enum ReturnType: Int {
    case number  // prime number
    case order  // number's placement in prime number order
}

enum ReturnOrder: Int {
    case descending = -1
    case random
    case ascending
}

class PrimeNumbers: NSObject {
    
    var numbers = [Int]()
    var orders = [Int]()
    
    var minRange = 2  // must be >= 2
    var maxRange = 100

    func fetch(minRange: Int, maxRange: Int, len: Int, type: ReturnType = .number, order: ReturnOrder = .ascending) async -> PrimeNumbers {
        self.minRange = max(minRange, 2)
        self.maxRange = maxRange
        let urlString = "https://prime-number-api.onrender.com/primeNumbers?min=\(self.minRange)&max=\(self.maxRange)&len=\(len)&type=\(type)&order=\(order.rawValue)"
        do {
            guard let url = URL(string: urlString) else { throw FetchError.badURL }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else { throw FetchError.badResponse }
            guard (200...299) ~= response.statusCode else {
                print(String(bytes: data, encoding: .utf8)!.formatJson())
                throw FetchError.badStatusCode(response.statusCode)
            }
//            print(String(bytes: data, encoding: .utf8)!.formatJson())  // use to create JsonModel
//            print(String(bytes: data, encoding: .utf8)!.createJsonModel())  // use to create JsonModel
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let jsonModel = try decoder.decode([JsonModel].self, from: data)
            extractData(from: jsonModel)
//            printData()
        } catch {
            print("\n(PrimeNumbers.fetch) \(error.localizedDescription)")
        }
        return self
    }

    private func extractData(from jsonModel: [JsonModel]) {
        numbers = jsonModel.map { $0.number }
        orders = jsonModel.map { $0.order }
    }
    
    private func printData() {
        print()
        print("Requested range: \(minRange)-\(maxRange)")
        print()
        print("  Order  Number")
        print("  -----  ------")
        for index in 0..<numbers.count {
            print(String(format: "%6d  %6d", orders[index], numbers[index]))
        }
    }

    private struct JsonModel: Decodable {
        let number: Int
        let order: Int
    }
}
/*
 [
     {
         "number":2,
         "order":1
     },
     {
         "number":3,
         "order":2
     },
     {
         "number":5,
         "order":3
     },
     {
         "number":7,
         "order":4
     }
 ]
*/
