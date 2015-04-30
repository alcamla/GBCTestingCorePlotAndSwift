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
     var whiteNoiseCoefficient: NSNumber? = nil
     var coefficients: String? =  nil
    
    
    class func whiteNoise() -> Float{
        //srand48(arc4random())
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
        let y1 = x1 * w;
        let y2 = x2 * w;
        println("\(y2)")
        return Float(y1)
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
