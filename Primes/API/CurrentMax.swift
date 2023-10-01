//
//  CurrentMax.swift
//  Primes
//
//  Created by Phil Stern on 9/30/23.
//

import Foundation

class CurrentMax: NSObject {
    
    var lastUpdated = "2023-02-18"
    var primeNumber = 0
    var primeOrder = 0

    func fetch() async -> CurrentMax {
        let urlString = "https://prime-number-api.onrender.com/"
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
            let jsonModel = try decoder.decode(JsonModel.self, from: data)
            extractData(from: jsonModel)
//            printData()
        } catch {
            print("\n(CurrentMax.fetch) \(error.localizedDescription)")
        }
        return self
    }

    private func extractData(from jsonModel: JsonModel) {
        lastUpdated = jsonModel.lastUpdated
        primeNumber = jsonModel.maxPrimeNumber
        primeOrder = jsonModel.maxPrimeOrder
    }
    
    private func printData() {
        print()
        print("As of: \(lastUpdated)")
        print("Max prime number: \(primeNumber)")
        print("Max prime order: \(primeOrder)")
    }

    private struct JsonModel: Decodable {
        let about: String
        let lastUpdated: String
        let maxPrimeNumber: Int
        let maxPrimeOrder: Int
    }
}
/*
 {
     "about":"Prime Number API: a self-updating API where you can get basic information about number's prime-ness.",
     "last_updated":"2023-02-18",
     "max_prime_number":4630447,
     "max_prime_order":324435
 }
*/
