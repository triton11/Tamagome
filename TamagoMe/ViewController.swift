//
//  ViewController.swift
//  TamagoMe
//
//  Created by Tristrum Comet Tuttle on 11/21/18.
//  Copyright © 2018 Tristrum Comet Tuttle. All rights reserved.
//

import UIKit
import HealthKit
import moa

class ViewController: UIViewController {

    @IBOutlet weak var prof: UIImageView!
    
    @IBOutlet weak var fitness: UISlider!
    @IBOutlet weak var nutrition: UISlider!
    @IBOutlet weak var mind: UISlider!
    @IBOutlet weak var sleep: UISlider!
    
    var nameHash = 0
    
    var predicate : NSPredicate? = nil
    
    let eyes = ["eyes1","eyes10","eyes2","eyes3","eyes4","eyes5","eyes6","eyes7","eyes9"]
    let nose = ["nose2","nose3","nose4","nose5","nose6","nose7","nose8","nose9"]
    let mouth = ["mouth1","mouth10","mouth11","mouth3","mouth5","mouth6","mouth7","mouth9"]
    
    var mindfulTime = [Date: Double]()
    var sleepTime = [Date: Double]()
    var nutritionCalories = [Date: Double]()
    var workoutMiles = [Date: Double]()
    
    var mindScore = 1.0
    var sleepScore = 1.0
    var nutritionScore = 1.0
    var workoutScore = 1.0
    
    let healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        nameHash = UIDevice.current.name.hashValue
        print(nameHash)
        let eyesId = nameHash % eyes.count
        let noseId = (nameHash/100) % nose.count
        let mouthId = 0
        let hexColor = String.init(format: "%06X", (0xFFFFFF & (nameHash)%16777215));
        let url = "https://api.adorable.io/avatars/face/"+eyes[eyesId]+"/"+nose[noseId]+"/"+mouth[mouthId]+"/"+hexColor+"/300"
        print(url)
        Moa.logger = MoaConsoleLogger
        prof.moa.url = url
        
        prof.moa.onSuccess = { image in
            self.prof.layer.cornerRadius = 25.0
            self.prof.clipsToBounds = true
            return image
        }
        
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
            self.setPredicate()
            self.setNutritionValues()
            self.setWorkoutValues()
            self.setMindfulnessValues()
            self.setSleepValues()
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setPredicate() {
        let calendar = NSCalendar.current
        let now = NSDate()
        let components = calendar.dateComponents([.year, .month, .day], from: now as Date)
        
        guard let startDate = calendar.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
        
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)
        
        predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
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
                    self.nutritionCalories[sample.startDate] = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                }
                var score = 0.0
                for (_, v) in self.nutritionCalories {
                    score += v
                }
                self.nutritionScore = Double.minimum(score/2000.0, 1.0)
                self.nutrition.setValue(Float(self.nutritionScore), animated: false)
                
            }
        }
        healthStore.execute(query)
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
                    self.workoutMiles[sample.startDate] = sample.quantity.doubleValue(for: HKUnit.mile())
                }
                var score = 0.0
                for (_, v) in self.workoutMiles {
                    score += v
                }
                self.workoutScore = Double.minimum(score/8.0, 1.0)
                self.fitness.setValue(Float(self.workoutScore), animated: false)
                
            }
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
                            self.sleepTime[sample.startDate] = Double(dif!)
                        }
                    }
                    var score = 0.0
                    for (_, v) in self.sleepTime {
                        score += v
                    }
                    self.sleepScore = Double.minimum(score/8.0, 1.0)
                    self.sleep.setValue(Float(self.sleepScore), animated: false)
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
                            self.mindfulTime[sample.startDate] = Double(dif!)
                        }
                    }
                    var score = 0.0
                    for (_, v) in self.mindfulTime {
                        score += v
                    }
                    self.mindScore = Double.minimum(score/2.0, 1.0)
                    self.mind.setValue(Float(self.mindScore), animated: false)
                }
            }
            
            // finally, we execute our query
            healthStore.execute(query)
        }
    }
    
    

}

