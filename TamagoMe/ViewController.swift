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
    
    @IBOutlet weak var currentLvel: UILabel!
    
    @IBOutlet weak var prof: UIImageView!
    
    @IBOutlet weak var fitness: UISlider!
    @IBOutlet weak var nutrition: UISlider!
    @IBOutlet weak var mind: UISlider!
    @IBOutlet weak var sleep: UISlider!
    
    var nameHash = 0
    
    var buttonPressed = 0
    
    var predicate : NSPredicate? = nil
    
    let eyes = ["eyes1","eyes10","eyes2","eyes3","eyes4","eyes5","eyes6","eyes7","eyes9"]
    let nose = ["nose2","nose3","nose4","nose5","nose6","nose7","nose8","nose9"]
    let mouth = ["mouth7","mouth3","mouth1","mouth5","mouth6","mouth11","mouth9"]
    
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
        var level = 0;
        if (UserDefaults.standard.integer(forKey: "level") != 0) {
            level = UserDefaults.standard.integer(forKey: "level")
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let now = NSDate()
        let components = NSCalendar.current.dateComponents([.year, .month, .day], from: now as Date)
        
        guard let startDate = NSCalendar.current.date(from: components) else {
            fatalError("*** Unable to create the start date ***")
        }
        let today = formatter.string(from: startDate)
        if (Int(today)! > UserDefaults.standard.integer(forKey: "date")) {
            UserDefaults.standard.removeObject(forKey: "date")
            UserDefaults.standard.set(Int(today), forKey: "date")
            
            let oldLevel = UserDefaults.standard.integer(forKey: "level")
            UserDefaults.standard.removeObject(forKey: "level")
            UserDefaults.standard.set(oldLevel + 1, forKey: "level")
            level = oldLevel + 1
        }
        currentLvel.text = "Level: " + String(level)
    }
    
    func callMoa(mouthId: Int) {
        nameHash = 0
        print(UIDevice.current.name)
        let name = UIDevice.current.name.prefix(8).utf8
        var mult = 1
        for k in name {
            nameHash += Int(k) * mult
            mult = mult*10
        }
        print(nameHash)
        let eyesId = nameHash % eyes.count
        let noseId = (nameHash/100) % nose.count
        let hexColor = String.init(format: "%06X", (0xFFFFFF & (nameHash)%16777215));
        let url = "https://api.adorable.io/avatars/face/"+eyes[eyesId]+"/"+nose[noseId]+"/"+mouth[mouthId]+"/"+hexColor+"/300"
        print(url)
        Moa.logger = MoaConsoleLogger
        prof.moa.url = url
        
        prof.moa.onSuccess = { image in
            self.prof.layer.cornerRadius = 25.0
            self.prof.clipsToBounds = true
            
            // get the documents directory url
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            // choose a name for your image
            let fileName = "image.jpg"
            // create the destination file url to save your image
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            // get your UIImage jpeg data representation and check if the destination file url already exists
            if let data = UIImageJPEGRepresentation(image, 1.0) {
                do {
                    // writes the image data to disk
                    try data.write(to: fileURL)
                    print("file saved")
                } catch {
                    print("error saving file:", error)
                }
            }
            return image
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
        let updatedStart = calendar.date(byAdding: .day, value: -1, to: startDate)
        
        let endDate = calendar.date(byAdding: .day, value: 1, to: updatedStart!)
        
        predicate = HKQuery.predicateForSamples(withStart: updatedStart, end: endDate, options: [])
        
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
                self.checkLife()
                
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
                self.checkLife()
                
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
                }
                var score = 0.0
                for (_, v) in self.sleepTime {
                    score += v
                }
                DispatchQueue.main.async() {
                    self.sleepScore = Double.minimum(score/8.0, 1.0)
                    self.sleep.setValue(Float(self.sleepScore), animated: false)
                    self.checkLife()
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
                }
                var score = 0.0
                for (_, v) in self.mindfulTime {
                    score += v
                }
                DispatchQueue.main.async() {
                    self.mindScore = Double.minimum(score/2.0, 1.0)
                    self.mind.setValue(Float(self.mindScore), animated: false)
                    self.checkLife()
                }
            }
            
            // finally, we execute our query
            healthStore.execute(query)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "fitness") {
            let secondViewController = segue.destination as! LogViewController
            var arr: [LogItem] = []
            for (key, value) in workoutMiles {
                let l = LogItem()
                l.date = key
                l.value = value
                l.type = "Fitness"
                arr.append(l)
            }
            secondViewController.cellType = "Fitness"
            secondViewController.cells = arr
        } else if (segue.identifier == "sleep") {
            let secondViewController = segue.destination as! LogViewController
            var arr: [LogItem] = []
            for (key, value) in sleepTime {
                let l = LogItem()
                l.date = key
                l.value = value
                l.type = "Sleep"
                arr.append(l)
            }
            secondViewController.cellType = "Sleep"
            secondViewController.cells = arr
        } else if (segue.identifier == "nutrition") {
            let secondViewController = segue.destination as! LogViewController
            var arr: [LogItem] = []
            for (key, value) in nutritionCalories {
                let l = LogItem()
                l.date = key
                l.value = value
                l.type = "Nutrition"
                arr.append(l)
            }
            secondViewController.cellType = "Nutrition"
            secondViewController.cells = arr
        } else if (segue.identifier == "mind") {
            let secondViewController = segue.destination as! LogViewController
            var arr: [LogItem] = []
            for (key, value) in mindfulTime {
                let l = LogItem()
                l.date = key
                l.value = value
                l.type = "Mind"
                arr.append(l)
            }
            secondViewController.cellType = "Mind"
            secondViewController.cells = arr
        }
    }
    
    func checkLife() {
        if (mindScore + workoutScore + nutritionScore + mindScore < 1.0) {
            currentLvel.text = "DEAD :("
            UserDefaults.standard.removeObject(forKey: "level")
            UserDefaults.standard.set(0, forKey: "level")
        } else if (mindScore + workoutScore + nutritionScore + mindScore < 1.3) {
            callMoa(mouthId: 0)
        } else if (mindScore + workoutScore + nutritionScore + mindScore < 1.7) {
            callMoa(mouthId: 1)
        } else if (mindScore + workoutScore + nutritionScore + mindScore < 2) {
            print(mindScore, workoutScore, nutritionScore, mindScore)
            callMoa(mouthId: 2)
        } else if (mindScore + workoutScore + nutritionScore + mindScore < 2.5) {
            print(mindScore, workoutScore, nutritionScore, mindScore)
            callMoa(mouthId: 3)
        } else if (mindScore + workoutScore + nutritionScore + mindScore < 3.0) {
            callMoa(mouthId: 4)
        } else if (mindScore + workoutScore + nutritionScore + mindScore < 3.5) {
            callMoa(mouthId: 5)
        } else if (mindScore + workoutScore + nutritionScore + mindScore < 4.0) {
            callMoa(mouthId: 6)
        }
    }
    
    

}

