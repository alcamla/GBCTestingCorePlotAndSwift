//
//  EEGModelsManager.swift
//  GBCTestingCorePlotAndSwift
//
//  Created by camacholaverde on 4/28/15.
//  Copyright (c) 2015 gibicgroup. All rights reserved.
//

import UIKit
import Foundation

/**
    Holds the different conditions that can be simulated.
*/
enum EEGModelConditions : String {
    case EyesOpened = "EyesOpenedCleaned"
    case EyesClosed = "EyesClosedCleaned"
}

/**
    Holds the different Keys includeded in the EEG models imported from the JSON file.
*/
enum EEGModelKeys : String {
    case Channel = "Channel"
    case Condition = "Condition"
    case WhiteNoiseCoefficient = "WhiteNoiseCoefficient"
    case Coefficients = "Coefficients"
    
    static let allValues =  [Channel, Condition, WhiteNoiseCoefficient, Coefficients]
}

/**
    Holds the different channels that can be included in a simulation.
*/
enum EEGModelChannels : String {
    case Fp2 = "Fp2"
    case Fz  = "Fz"
    case Fpz = "Fpz"
    case Fp1 = "Fp1"
    case F3  = "F3"
    case F7  = "F7"
    case C3  = "C3"
    case T3  = "T3"
    case P3  = "P3"
    case T5  = "T5"
    case Pz  = "Pz"
    case O1  = "O1"
    case Oz  = "Oz"
    case O2  = "O2"
    case P4  = "P4"
    case T6  = "T6"
    case C4  = "C4"
    case T4  = "T4"
    case F8  = "F8"
    case F4  = "F4"
    case Cz  = "Cz"
    static let allValues =  [Fp2, Fz, Fpz, Fp1, F3, F7]
    
    // Returns the number of the given channel in the original register system.
    func channelNumber()->Int{
        switch self{
        case .Fp2:
            return 9
        case .Fz:
            return 11
        case .Fpz:
            return 15
        case Fp1:
            return 22
        case .F3:
            return 24
        case .F7:
            return 33
        case .C3:
            return 36
        case .T3:
            return 45
        case .P3:
            return 52
        case .T5:
            return 58
        case .Pz:
            return 62
        case .O1:
            return 70
        case .Oz:
            return 75
        case .O2:
            return 83
        case .P4:
            return 92
        case .T6:
            return 96
        case .C4:
            return 104
        case .T4:
            return 108
        case .F8:
            return 122
        case .F4:
            return 124
        case .Cz:
            return 129
        }
    }
    
}



class EEGModelsManager: NSObject {
    
    /// Stores the EEG models as data that can be parsed to JSON string
    class var jsonData:NSData? {
        let path = NSBundle.mainBundle().pathForResource("eegModels", ofType: "json")
        let jsonString = NSString(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: nil)
        return  jsonString!.dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    /**
    */
    class func loadModels() {
        if let jsonDataResult = jsonData{
            var jsonError:NSError? = nil
            if let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonData!, options: nil, error: &jsonError){
                if let jsonAsArray = jsonObject as? NSArray{
                    let arrayWithModels = jsonAsArray as? [[String:String]]
                    println("\(arrayWithModels)")
                } else {
                    println("not an array")
                }
            } else {
                println("Could not parse JSON: \(jsonError!)")
            }
        }

    }
    
    /**
        Returns the array of models(dictionaries) of all channels for the given condition, if the condition exists,
    
        :param: condition String representing the condition of the EEG models to load
    */
    class func loadAllEEGModelForCondition(condition:EEGModelConditions) -> [[String:String]]? {
        var result:[[String:String]]? = nil
        if let jsonDataResult = jsonData{
            var jsonError:NSError? = nil
            if let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonData!, options: nil, error: &jsonError){
                if let jsonAsArray = jsonObject as? NSArray{
                    println(jsonAsArray)
                    
                    let selectedModelsIndexSet: NSIndexSet = jsonAsArray.indexesOfObjectsPassingTest{(dict, idx, stop) in
                        let thedict = dict as! NSDictionary
                        return  thedict.objectForKey(EEGModelKeys.Condition.rawValue) as! String == condition.rawValue
                    }
                    var index = selectedModelsIndexSet.firstIndex
                    var selectedModelsArray:NSMutableArray! = NSMutableArray(capacity: selectedModelsIndexSet.count)
                    while (index != NSNotFound){
                        selectedModelsArray.addObject(jsonAsArray.objectAtIndex(index))
                        index = selectedModelsIndexSet.indexGreaterThanIndex(index)
                    }
                    result = selectedModelsArray as NSArray as? [[String:String]]
                    
                } else {
                    println("not an array")
                }
            } else {
                println("Could not parse JSON: \(jsonError!)")
            }
        }
        return result
    }
    
    /**
    Returns the array of models (dictionaries) for the given channel, all conditions.
    
    :param: condition String representing the condition of the EEG models to load
    */
    class func loadAllEEGModelForChannel(channel:EEGModelChannels) ->[[String:String]]?{
        var result:[[String:String]]? = nil
        if let jsonDataResult = jsonData{
            var jsonError:NSError? = nil
            if let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonData!, options: nil, error: &jsonError){
                if let jsonAsArray = jsonObject as? NSArray{
                    println(jsonAsArray)
                    
                    let selectedModelsIndexSet: NSIndexSet = jsonAsArray.indexesOfObjectsPassingTest{(dict, idx, stop) in
                        let thedict = dict as! NSDictionary
                        return  thedict.objectForKey(EEGModelKeys.Channel.rawValue) as! String == channel.rawValue
                    }
                    var index = selectedModelsIndexSet.firstIndex
                    var selectedModelsArray:NSMutableArray! = NSMutableArray(capacity: selectedModelsIndexSet.count)
                    while (index != NSNotFound){
                        selectedModelsArray.addObject(jsonAsArray.objectAtIndex(index))
                        index = selectedModelsIndexSet.indexGreaterThanIndex(index)
                    }
                    result = selectedModelsArray as NSArray as? [[String:String]]
                    
                } else {
                    println("not an array")
                }
            } else {
                println("Could not parse JSON: \(jsonError!)")
            }
        }
        return result
    }
    
    /**
    Loads a dictionary representing the model for the EEG channel under the given condition
    
    :param: condition String representing the condition of the EEG model to load
    :param: channel String representing the channel of interest
    */
    class func loadEEGModelForCondition(condition:EEGModelConditions, channel:EEGModelChannels) ->[String:String]?{
        var result:[String:String]? = nil
        if let jsonDataResult = jsonData{
            var jsonError:NSError? = nil
            if let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonData!, options: nil, error: &jsonError){
                if let jsonAsArray = jsonObject as? NSArray{
                    println(jsonAsArray)
                    
                    let selectedModelsIndexSet: NSIndexSet = jsonAsArray.indexesOfObjectsPassingTest{(dict, idx, stop) in
                        let thedict = dict as! NSDictionary
                        return  thedict.objectForKey(EEGModelKeys.Condition.rawValue) as! String == condition.rawValue
                    }
                    var index = selectedModelsIndexSet.firstIndex
                    var selectedModelsArray:NSMutableArray! = NSMutableArray(capacity: selectedModelsIndexSet.count)
                    while (index != NSNotFound){
                        selectedModelsArray.addObject(jsonAsArray.objectAtIndex(index))
                        index = selectedModelsIndexSet.indexGreaterThanIndex(index)
                    }
                    // Find from this models the one that corresponds to the parameter
                    for dict in selectedModelsArray {
                        if let model = dict as? NSDictionary{
                            if model.valueForKey(EEGModelKeys.Channel.rawValue) as! String == channel.rawValue {
                                result = model as? [String:String]
                                break
                            }
                        }
                    }
                    
                } else {
                    println("not an array")
                }
            } else {
                println("Could not parse JSON: \(jsonError!)")
            }
        }
        return result
    }
}
