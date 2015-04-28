//
//  EEGModel.swift
//  GBCTestingCorePlotAndSwift
//
//  Created by camacholaverde on 4/27/15.
//  Copyright (c) 2015 gibicgroup. All rights reserved.
//

import Foundation
import CoreData

class EEGModel: NSManagedObject {

    @NSManaged var condition: String
    @NSManaged var channel: String
    @NSManaged var whiteNoiseCoefficient: NSNumber
    @NSManaged var coefficients: String

}
