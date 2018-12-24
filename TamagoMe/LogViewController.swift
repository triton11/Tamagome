//
//  LogViewController.swift
//  TamagoMe
//
//  Created by Tristrum Comet Tuttle on 12/6/18.
//  Copyright © 2018 Tristrum Comet Tuttle. All rights reserved.
//
import HealthKit
import UIKit

class LogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var datepicker: UIDatePicker!
    
    let formatter = DateFormatter()
    
    var cells: [LogItem]?
    
    var cellType = ""
    
    var predicate : NSPredicate? = nil
    
    let healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        formatter.dateFormat = "HH:mm:ss"
        datepicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        HealthKitSetupAssistant.authorizeHealthKit { (authorized, error) in
            
            guard authorized else {
                
                let baseMessage = "HealthKit Authorization Failed"
                
                if let error = error {
                    print("\(baseMessage). Reason: \(error.localizedDescription)")
                } else {
                    print(baseMessage)
                }
                
                return
            }
            
            print("HealthKit Successfully Authorized.")
        }
        
    }
    
    @objc func datePickerChanged(picker: UIDatePicker) {
        setPredicate()
    }
    
    func setNutritionValues() {
        
        guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed) else {
            fatalError("*** This method should never fail ***")
        }
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
            query, results, error in
            
            guard let samples = results as? [HKQuantitySample] else {
                fatalError("An error occured fetching the user's tracked food. In your app, try to handle this error gracefully. The error was: \(String(describing: error?.localizedDescription))");
            }
            
            DispatchQueue.main.async() {
                
                for sample in samples {
                    let p = LogItem()
                    p.date = sample.startDate
                    p.value = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                    p.type = "nutrition"
                    self.cells?.append(p)
                }
                self.tableView.reloadData()
            }
        }
        healthStore.execute(query)
        tableView.reloadData()
    }
    
    func setWorkoutValues() {
        guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning) else {
            fatalError("*** This method should never fail ***")
        }
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
            query, results, error in
            
            guard let samples = results as? [HKQuantitySample] else {
                fatalError("An error occured fetching the user's tracked food. In your app, try to handle this error gracefully. The error was: \(String(describing: error?.localizedDescription))");
            }
            
            DispatchQueue.main.async() {
                for sample in samples {
                    let p = LogItem()
                    p.date = sample.startDate
                    p.value = sample.quantity.doubleValue(for: HKUnit.mile())
                    p.type = "fitness"
                    self.cells?.append(p)
                }
            }
            self.tableView.reloadData()

        }
        healthStore.execute(query)
    }

    func setSleepValues() {
        // first, we define the object type we want
        if let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis) {
            
            // Use a sortDescriptor to get the recent data first
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            // we create our query with a block completion to execute
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 30, sortDescriptors: [sortDescriptor]) { (query, tmpResult, error) -> Void in
                
                if error != nil {
                    
                    // something happened
                    return
                    
                }
                
                if let result = tmpResult {
                    
                    // do something with my data
                    for item in result {
                        if let sample = item as? HKCategorySample {
                            let dif = Calendar.current.dateComponents([.hour], from: sample.startDate, to: sample.endDate).hour
                            let p = LogItem()
                            p.date = sample.startDate
                            p.value = Double(dif!)
                            p.type = "sleep"
                            self.cells?.append(p)
                        }
                    }
                    self.tableView.reloadData()
                    
                }
            }
            
            // finally, we execute our query
            healthStore.execute(query)
        }
    }
    
    func setMindfulnessValues() {
        if let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession) {
            
            // Use a sortDescriptor to get the recent data first
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            
            // we create our query with a block completion to execute
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 30, sortDescriptors: [sortDescriptor]) { (query, tmpResult, error) -> Void in
                
                if error != nil {
                    
                    // something happened
                    return
                    
                }
                
                if let result = tmpResult {
                    
                    // do something with my data
                    for item in result {
                        if let sample = item as? HKCategorySample {
                            let dif = Calendar.current.dateComponents([.hour], from: sample.startDate, to: sample.endDate).hour
                            let p = LogItem()
                            p.date = sample.startDate
                            p.value = Double(dif!)
                            p.type = "sleep"
                            self.cells?.append(p)
                        }
                        self.tableView.reloadData()
                    }
                }
            }
            
            // finally, we execute our query
            healthStore.execute(query)
            tableView.reloadData()
        }
    }
    
    func setPredicate() {
        print("MADE IT")
        let calendar = NSCalendar.current
        let now = datepicker.date
        print(now)
        let components = calendar.dateComponents([.year, .month, .day], from: now as Date)
        
        guard let startDate = calendar.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
        
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)
        
        predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        self.cells = []
        
        if (self.cellType == "Fitness") {
            setWorkoutValues()
        } else if (self.cellType == "Sleep") {
            setSleepValues()
        } else if (self.cellType == "Nutrition") {
            setNutritionValues()
        } else {
            setMindfulnessValues()
        }
        
    }
    

    // Table View Data Source and Delegate Methods
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell")
        if let cells = self.cells {
            if (indexPath.row < cells.count) {
                cell?.textLabel?.text = String(cells[indexPath.row].value)
                cell?.detailTextLabel?.text = formatter.string(for: cells[indexPath.row].date)
                if (cellType == "Fitness") {
                    cell?.backgroundColor = UIColor.red
                    cell?.textLabel?.text = String(cells[indexPath.row].value) + " miles"
                } else if (cellType == "Nutrition") {
                    cell?.backgroundColor = UIColor.cyan
                    cell?.textLabel?.text = String(cells[indexPath.row].value) + " calories"
                } else if (cellType == "Sleep") {
                    cell?.backgroundColor = UIColor.blue
                    cell?.textLabel?.text = String(cells[indexPath.row].value) + " hours"
                } else {
                    cell?.backgroundColor = UIColor.green
                    cell?.textLabel?.text = String(cells[indexPath.row].value) + " hours"
                }
            }
        }
        return cell!
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let c = cells {
            return c.count
        } else {
            return 0;
        }
    }
    
    
}
