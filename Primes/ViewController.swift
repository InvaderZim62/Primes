//
//  ViewController.swift
//  Primes
//
//  Created by Phil Stern on 9/30/23.
//
//  Prime Number API: https://prime-number-api-docs.onrender.com
//
//  Order is the placement of the prime number in the list of all prime numbers.  For example,
//  number 5's order is 3, since it is the third prime number (2, 3, 5).  Note: 1 is not a prime.
//
//  The "Upper Range" input field applies to either prime numbers or prime orders, depending on
//  the selected "Range Type" (number or order).  Similarly, the max allowable value for "Upper
//  Range" is either maxPrimeNumber or maxPrimeOrder, depending on range type.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var lowerRange = 2 { // must be >= 2
        didSet {
            lowerRange = max(lowerRange, 2)
            lowerRangeTextField.text = "\(lowerRange)"
        }
    }
    
    var upperRange = 100 {
        didSet {
            // limit upperRange to max value in API's database
            switch rangeType {
            case .number:
                upperRange = min(upperRange, currentMax.primeNumber)
            case .order:
                upperRange = min(upperRange, currentMax.primeOrder)
            }
            upperRangeTextField.text = "\(upperRange)"
        }
    }
    
    var rangeType = RangeType.number {
        didSet {
            upperRange += 0  // cause upperRange.didSet to run
        }
    }
    
    var returnCount = 20
    var sortOrder = SortOrder.ascending
    var currentMax = CurrentMax()
    var primeNumbers = PrimeNumbers()

    @IBOutlet weak var lowerRangeTextField: UITextField!
    @IBOutlet weak var upperRangeTextField: UITextField!
    @IBOutlet weak var returnCountTextField: UITextField!
    @IBOutlet weak var rangeTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var sortOrderSegmentedControl: UISegmentedControl!

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.rowHeight = 30
            tableView.allowsSelection = false
        }
    }
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lowerRangeTextField.text = "\(lowerRange)"
        upperRangeTextField.text = "\(upperRange)"
        returnCountTextField.text = "\(returnCount)"
        
        lowerRangeTextField.keyboardType = .asciiCapableNumberPad
        upperRangeTextField.keyboardType = .asciiCapableNumberPad
        returnCountTextField.keyboardType = .asciiCapableNumberPad
        
        Task {
            // fetch max prime number and max prime order
            currentMax = await CurrentMax().fetch()
            upperRange += 0  // cause upperRange.didSet to run
        }
    }
    
    // get text field values and dismiss keyboard when tapping anywhere on screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lowerRange = Int(lowerRangeTextField.text!)!
        upperRange = Int(upperRangeTextField.text!)!
        returnCount = Int(returnCountTextField.text!)!

        lowerRangeTextField.resignFirstResponder()
        upperRangeTextField.resignFirstResponder()
        returnCountTextField.resignFirstResponder()
    }
    
    // MARK: - Actions
    
    @IBAction func typeSelected(_ sender: UISegmentedControl) {
        rangeType = RangeType(rawValue: rangeTypeSegmentedControl.selectedSegmentIndex)!
    }
    
    @IBAction func orderSelected(_ sender: UISegmentedControl) {
        sortOrder = SortOrder(rawValue: sortOrderSegmentedControl.selectedSegmentIndex - 1)!
    }
    
    @IBAction func lookUpSelected(_ sender: UIButton) {
        guard currentMax.primeNumber > 0 else { return }  // ensure CurrentMax().fetch completed
        
        Task {
            primeNumbers = await PrimeNumbers().fetch(lower: lowerRange, upper: upperRange, count: returnCount, type: rangeType, order: sortOrder)
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
