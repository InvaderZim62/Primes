//
//  ViewController.swift
//  Primes
//
//  Created by Phil Stern on 9/30/23.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var minRange = 2  // must be >= 2
    var maxRange = 100
    var count = 10
    var primeNumbers = PrimeNumbers()

    @IBOutlet weak var minTextField: UITextField!
    @IBOutlet weak var maxTextField: UITextField!
    @IBOutlet weak var countTextField: UITextField!
    @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var orderSegmentedControl: UISegmentedControl!

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = 30
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        minTextField.text = "2"
        maxTextField.text = "100"
        countTextField.text = "10"
        
        minTextField.keyboardType = .asciiCapableNumberPad
        maxTextField.keyboardType = .asciiCapableNumberPad
        countTextField.keyboardType = .asciiCapableNumberPad
    }
    
    // dismiss keyboard or segmented control when tapping anywhere on screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        minRange = Int(minTextField.text!)!
        maxRange = Int(maxTextField.text!)!
        count = Int(countTextField.text!)!

        minTextField.resignFirstResponder()
        maxTextField.resignFirstResponder()
        countTextField.resignFirstResponder()
    }
    
    @IBAction func LookUpSelected(_ sender: UIButton) {
        Task {
            if let type = ReturnType(rawValue: typeSegmentedControl.selectedSegmentIndex),
               let order = ReturnOrder(rawValue: orderSegmentedControl.selectedSegmentIndex - 1) {
                primeNumbers = await PrimeNumbers().fetch(minRange: minRange, maxRange: maxRange, len: count, type: type, order: order)
                tableView.reloadData()
            }
        }
    }

    // MARK: - TableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return primeNumbers.numbers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrimeCell", for: indexPath)
        let order = primeNumbers.orders[indexPath.row]
        let number = primeNumbers.numbers[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.text = String(format: "%d    %d", order, number)
        return cell
    }
}
