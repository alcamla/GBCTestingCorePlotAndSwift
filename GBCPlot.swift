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
            //Check if the modification was an insertion or a deletion
                let deltaInDataPoints = plotData.count - oldValue.count
                if deltaInDataPoints > 0{
                    //Insertion
                    plot.insertDataAtIndex(UInt(plotData.count - 1 ), numberOfRecords: UInt(deltaInDataPoints))
                    //ViewController.SimulationProperties.index++
                    // check if the number of points is greater than the permited
                    if plotData.count >= kMaxDataPoints{
                        let overflow = plotData.count - (kMaxDataPoints - 1)
                        plotData.removeRange(Range(start: 0, end: overflow))
                        plot.deleteDataInIndexRange(NSMakeRange(0, overflow))
                    }
                } else{
                    let overflow = plotData.count - (kMaxDataPoints - 1)
                    plotData.removeRange(Range(start: 0, end: overflow))
                    plot.deleteDataInIndexRange(NSMakeRange(0, overflow))
                }
        }
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
    
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
         return UInt(plotData.count)
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
