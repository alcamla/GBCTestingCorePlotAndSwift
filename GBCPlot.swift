//
//  GBCPlot.swift
//  GBCTestingCorePlotAndSwift
//
//  Created by camacholaverde on 4/7/15.
//  Copyright (c) 2015 gibicgroup. All rights reserved.
//

import UIKit

class GBCPlot: NSObject, CPTPlotDataSource{
    var plot:CPTScatterPlot
    var plotData = [Double](){
        didSet{
            println("The oldValue is \(oldValue)")
            if oldValue.count == 1 {
                minValue = oldValue.last!
            }
            //Check if the modification was an insertion or a deletion
                let deltaInDataPoints = plotData.count - oldValue.count
                if deltaInDataPoints > 0{
                    //Insertion
                    plot.insertDataAtIndex(UInt(plotData.count - 1 ), numberOfRecords: UInt(deltaInDataPoints))
                    // check if the number of points is greater than the permited
                    if plotData.count >= kMaxDataPoints{
                        let overflow:Int = plotData.count - (kMaxDataPoints - 1)
                        //deleteValuesFromBeginngTondex(overflow)
                        
                        //Store removed Values
                        let values = Array(plotData[0..<overflow])
                        
                        //Removal
                        plotData.removeRange(Range(start: 0, end: overflow))
                        plot.deleteDataInIndexRange(NSMakeRange(0, overflow))
                        
                        //Check if the value deleted was the current max or min.
                        requiresMinMaxUpdate(values)
                    } else{
                        //Check if the value deleted was the current max or min.
                        requiresMinMaxUpdate([plotData.last!])
                    }
                    
                } else{
                    //Deletion
                    let overflow = plotData.count - (kMaxDataPoints - 1)
                    deleteValuesFromBeginngTondex(overflow)
                }
            // Check if the new value updates the max or min
            if let dataValue = plotData.last{
                if dataValue > ViewController.SimulationProperties.maxValue{
                    ViewController.SimulationProperties.maxValue = dataValue
                }
                if dataValue < ViewController.SimulationProperties.minValue{
                    ViewController.SimulationProperties.minValue = dataValue
                }
            }
            
        }        
        willSet{
            // Check if the new value updates the max or min 
            if let dataValue = newValue.last{
                if dataValue > ViewController.SimulationProperties.maxValue{
                    ViewController.SimulationProperties.maxValue = dataValue
                }
                if dataValue < ViewController.SimulationProperties.minValue{
                    ViewController.SimulationProperties.minValue = dataValue
                }
            }
        }
    }
    
    var locationIndex:Int?
    var minValue: Double = 0 {
        didSet{
            if let location = locationIndex{
                minValue = minValue + (Double(location)*0.2)
            }
            ViewController.updateMinValueForPlotWithIdentifier(plot.identifier as! String, newValue: minValue)
        }

    }
    var maxValue: Double = 0{
        didSet{
            if let location = locationIndex{
                maxValue = maxValue + (Double(location)*0.2)
            }
            ViewController.updateMaxValueForPlotWithIdentifier(plot.identifier as! String, newValue: maxValue)            
        }
    }
    
    func deleteValuesFromBeginngTondex(index:Int){
        //Store removed Values
        let values = Array(plotData[0..<index])
        
        //Removal
        plotData.removeRange(Range(start: 0, end: index))
        plot.deleteDataInIndexRange(NSMakeRange(0, index))
        
        //Check if the value deleted was the current max or min.
        requiresMinMaxUpdate(values)
        
    }
    
    func requiresMinMaxUpdate(valuesToDelete:[Double]) -> (updateMin:Bool, updateMax:Bool){
        var mustUpdate = (updateMin:false, updateMax:false)
        for value in valuesToDelete{
            if value >= maxValue {
                mustUpdate.updateMax = true
            }
            if value <= minValue{
                mustUpdate.updateMin = true
            }
        }
        if mustUpdate.updateMax{
            maxValue = plotData.reduce(plotData[0], combine:{max($0, $1)})
        }
        if mustUpdate.updateMin{
            minValue = plotData.reduce(plotData[0], combine: {min($0, $1)})
        }
        return mustUpdate
    }
    
    override init(){
        // Create the Plot
        plot = CPTScatterPlot(frame: CGRectZero)
        //plot.identifier = kPlotIdentifier
        plot.cachePrecision = .Double
        
        //Set the lineStyle for the plot
        let plotLineStyle = plot.dataLineStyle.mutableCopy() as! CPTMutableLineStyle
        plotLineStyle.lineWidth = 3.0
        plotLineStyle.lineColor = CPTColor.greenColor()
        plot.dataLineStyle = plotLineStyle
        
        super.init()
        plot.dataSource = self
    }
    
    convenience init(identifier:String) {
        self.init()
        plot.identifier = identifier
    }
    
    // Create another convinience initializer to set the line properties of the plot
    convenience init(identifier:String, lineStyle:CPTLineStyle){
        self.init(identifier: identifier)
        plot.dataLineStyle = lineStyle
    }
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
         return UInt(plotData.count)
    }
    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject! {
        
        switch CPTScatterPlotField(rawValue: Int(fieldEnum))! {
        case .X:
            let num = idx + UInt(ViewController.SimulationProperties.index) - UInt(plotData.count)
            return num as NSNumber
            
        case .Y:
            
            var num = plotData[Int(idx)]
            //Consider the possible offset to correctly visualize the plots in the graph
            if let location = locationIndex{
                num = num + (Double(location)*0.2)
            }
            return num as NSNumber
            
        default:
            return nil
        }
    }
    
    func addDataToPlot(){
        let newValue:Double!
        if let lastValue = plotData.last as Double?{
            newValue = ((1.0-kAlpha) * lastValue) + (kAlpha * Double(arc4random()))/Double(UInt32.max)
            println("The new value is \(newValue)")
        } else{
            newValue = (kAlpha * Double(arc4random()))/Double(UInt32.max)
            println("Version without last value is being used")
        }
        plotData.append(newValue)
        
    }
}
