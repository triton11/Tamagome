//
//  HealthKitSetupAssistant.swift
//  TamagoMe
//
//  Created by Tristrum Comet Tuttle on 11/24/18.
//  Copyright © 2018 Tristrum Comet Tuttle. All rights reserved.
//

import HealthKit

class HealthKitSetupAssistant {
    
    private enum HealthkitSetupError: Error {
        case notAvailableOnDevice
        case dataTypeNotAvailable
    }
    
    class func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthkitSetupError.notAvailableOnDevice)
            return
        }
        guard   let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
            let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
            let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
            let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            let height = HKObjectType.quantityType(forIdentifier: .height),
            let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            let activeTime = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            let sleepTime = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            let meditateTime = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
                
                completion(false, HealthkitSetupError.dataTypeNotAvailable)
                return
        }
        let healthKitTypesToWrite: Set<HKSampleType> = [bodyMassIndex,
                                                        activeEnergy,
                                                        HKObjectType.workoutType(),
                                                        dietaryEnergy, activeTime, sleepTime, meditateTime]
        
        let healthKitTypesToRead: Set<HKObjectType> = [dateOfBirth,
                                                       bloodType,
                                                       biologicalSex,
                                                       bodyMassIndex,
                                                       height,
                                                       bodyMass,
                                                       HKObjectType.workoutType(),
                                                       dietaryEnergy, activeTime, sleepTime, meditateTime]
        
        HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite,
                                             read: healthKitTypesToRead) { (success, error) in
                                                completion(success, error)
        }
    }
}
