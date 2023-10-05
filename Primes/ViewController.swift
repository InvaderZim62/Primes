//
//  ViewController.swift
//  Primes
//
//  Created by Phil Stern on 9/30/23.
//
//  Prime Number API: https://prime-number-api-docs.onrender.com
//
//  Order is the placement of the prime number in the list of all prime numbers.  For example,
//  number 5's order is 3, since it is the third prime number (2, 3, 5, 7,...).  Note: 1 is not
//  a prime.
//
//  The "Upper Range" input field applies to either prime numbers or prime orders, depending on
//  the selected "Range Type" (number or order).  Similarly, the max allowable value for "Upper
//  Range" is either maxPrimeNumber or maxPrimeOrder, depending on the selected range type.
//
//  In Interface Builder, for the max range button, I set Title blank and set Intrinsic Size:
//  Placeholder (Width = 40), since I couldn't figure out how to enter a default SF Symbol using
//  Interface Builder.
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
                upperRange = isMaxRange ? currentMax.primeNumber : min(upperRange, currentMax.primeNumber)
            case .order:
                upperRange = isMaxRange ? currentMax.primeOrder : min(upperRange, currentMax.primeOrder)
            }
            upperRangeTextField.text = "\(upperRange)"
        }
    }
    
    var isMaxRange = false {
        didSet {
            if isMaxRange {
                maxRangeButton.setImage(UIImage(systemName: "record.circle", withConfiguration: smallConfig), for: .normal)
                upperRange += 0  // cause upperRange.didSet to run
            } else {
                maxRangeButton.setImage(UIImage(systemName: "circle", withConfiguration: smallConfig), for: .normal)
            }
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
    let smallConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .small)

    @IBOutlet weak var lowerRangeTextField: UITextField!
    @IBOutlet weak var upperRangeTextField: UITextField!
    @IBOutlet weak var maxRangeButton: UIButton!
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
        isMaxRange = false

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
    
    private func lookUpPrimeNumbers() {
        Task {
            primeNumbers = await PrimeNumbers().fetch(lower: lowerRange, upper: upperRange, count: returnCount, type: rangeType, order: sortOrder)
            tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func upperRangeTextFieldSelected(_ sender: UITextField) {  // used Event: Touch Down, so it clears max range button right away
        isMaxRange = false
    }
    
    @IBAction func maxRangeSelected(_ sender: UIButton) {
        isMaxRange.toggle()
    }
    
    @IBAction func rangeTypeSelected(_ sender: UISegmentedControl) {
        rangeType = RangeType(rawValue: rangeTypeSegmentedControl.selectedSegmentIndex)!
        lookUpPrimeNumbers()
    }
    
    @IBAction func sortOrderSelected(_ sender: UISegmentedControl) {
        sortOrder = SortOrder(rawValue: sortOrderSegmentedControl.selectedSegmentIndex - 1)!
        lookUpPrimeNumbers()
    }
    
    @IBAction func lookUpSelected(_ sender: UIButton) {
        guard currentMax.primeNumber > 0 else { return }  // ensure CurrentMax().fetch completed
        lookUpPrimeNumbers()
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
