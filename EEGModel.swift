//
//  EEGModel.swift
//  GBCTestingCorePlotAndSwift
//
//  Created by camacholaverde on 4/27/15.
//  Copyright (c) 2015 gibicgroup. All rights reserved.
//

import Foundation
import CoreData

class EEGModel: NSObject {
    
    var condition: String? = nil
    var channel: String? = nil
    var whiteNoiseCoefficient: Float? = nil
    var coefficients: [Float] = [Float]()
    var order:Int! = 0
    static var savedWhiteNoiseSamples = [Float]()
    

    
    init(coefficients coefficientsString:String, whiteNoise:String, channel:String, condition:String) {
        // Convert coefficient string to array of Float
        let coefficientsStringArray = coefficientsString.componentsSeparatedByString(",")
        let formatter = NSNumberFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US")
        formatter.decimalSeparator = "."
        formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        formatter.roundingMode = NSNumberFormatterRoundingMode.RoundUp
        for coefficientString in coefficientsStringArray{
            if let number = formatter.numberFromString(coefficientString){
                coefficients.append(Float(number))
            }
        }
        // Convert whiteNoiseCoefficient to Float
        if let whiteNoiseNumber = formatter.numberFromString(whiteNoise){
            whiteNoiseCoefficient = Float(whiteNoiseNumber)
        }
        // Store the channel name and the condition
        self.channel = channel
        self.condition = condition
        self.order = coefficients.count
        super.init()
    }
    
    convenience init(modelDictionary:[String:String]) {
        self.init(coefficients:modelDictionary[EEGModelKeys.Coefficients.rawValue]!, whiteNoise:modelDictionary[EEGModelKeys.WhiteNoiseCoefficient.rawValue]!,
            channel:modelDictionary[EEGModelKeys.Channel.rawValue]!, condition:modelDictionary[EEGModelKeys.Condition.rawValue]!)
    }
    
    
    class func whiteNoise() -> Float{
        if savedWhiteNoiseSamples.count<100{
            srand48(Int(arc4random()))
            var w:Double = 0.0
            var x1:Double = 0.0
            var x2:Double = 0.0
            do {
                x1 = 2.0 * drand48() - 1.0;
                x2 = 2.0 * drand48() - 1.0;
                w = x1 * x1 + x2 * x2;
            } while ( w >= 1.0 );
            
            w = sqrt( (-2.0 * log(w))/w);
            savedWhiteNoiseSamples.append(Float(x1 * w))
            savedWhiteNoiseSamples.append(Float(x2 * w))
        }
        return savedWhiteNoiseSamples.removeAtIndex(0)
    }
    
    class func randomNumber() ->Float{
        let r = Float(CGFloat(Float(arc4random()) / Float(UINT32_MAX)))
        println("\(r)")
        return r
    }
    
    class func generate(){
        for counter in 1 ... 100{
            self.whiteNoise()
        }
        
    }
}
