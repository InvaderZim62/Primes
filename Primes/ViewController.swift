//
//  ViewController.swift
//  Primes
//
//  Created by Phil Stern on 9/30/23.
//
//  Prime Number API: https://prime-number-api-docs.onrender.com
//
//  The "Upper" input field applies to either prime numbers or prime orders,
//  depending on the selected "Type" (number or order).  Similarly, the max
//  allowable value for "Upper" is either maxPrimeNumber or maxPrimeOrder.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var lowerRange = 2 { // must be >= 2
        didSet {
            lowerRange = max(lowerRange, 2)
            lowerTextField.text = "\(lowerRange)"
        }
    }
    
    var upperRange = 100 {
        didSet {
            upperTextField.text = "\(upperRange)"  // note: calling limitUpperRange() from here causes an infinite loop
        }
    }
    
    var returnType = ReturnType.number
    var count = 10
    var returnOrder = ReturnOrder.ascending
    var currentMax = CurrentMax()
    var primeNumbers = PrimeNumbers()

    @IBOutlet weak var lowerTextField: UITextField!
    @IBOutlet weak var upperTextField: UITextField!
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
        lowerTextField.text = "2"
        upperTextField.text = "100"
        countTextField.text = "10"
        
        lowerTextField.keyboardType = .asciiCapableNumberPad
        upperTextField.keyboardType = .asciiCapableNumberPad
        countTextField.keyboardType = .asciiCapableNumberPad
        
        Task {
            // fetch max prime number and max prime order
            currentMax = await CurrentMax().fetch()
            limitUpperRange()
        }
    }
    
    private func limitUpperRange() {
        switch returnType {
        case .number:
            upperRange = min(upperRange, currentMax.primeNumber)
        case .order:
            upperRange = min(upperRange, currentMax.primeOrder)
        }
    }
    
    @IBAction func typeSelected(_ sender: UISegmentedControl) {
        returnType = ReturnType(rawValue: typeSegmentedControl.selectedSegmentIndex)!
        limitUpperRange()
    }
    
    @IBAction func orderSelected(_ sender: UISegmentedControl) {
        returnOrder = ReturnOrder(rawValue: orderSegmentedControl.selectedSegmentIndex - 1)!
    }
    
    // get text field values and dismiss keyboard when tapping anywhere on screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lowerRange = Int(lowerTextField.text!)!
        upperRange = Int(upperTextField.text!)!
        limitUpperRange()
        count = Int(countTextField.text!)!

        lowerTextField.resignFirstResponder()
        upperTextField.resignFirstResponder()
        countTextField.resignFirstResponder()
    }
    
    @IBAction func LookUpSelected(_ sender: UIButton) {
        guard currentMax.primeNumber > 0 else { return }  // ensure CurrentMax().fetch completed
        
        Task {
            primeNumbers = await PrimeNumbers().fetch(lower: lowerRange, upper: upperRange, count: count, type: returnType, order: returnOrder)
            tableView.reloadData()
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
