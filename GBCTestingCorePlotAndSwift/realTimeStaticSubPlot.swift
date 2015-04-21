//
//  realTimeStaticSubPlot.swift
//  GBCTestingCorePlotAndSwift
//
//  Created by camacholaverde on 4/13/15.
//  Copyright (c) 2015 gibicgroup. All rights reserved.
//

import UIKit

let kRealTimeMaxDataPoints = 51

class realTimeStaticSubPlot: NSObject, CPTPlotDataSource {
    
    //MARK: -  Properties
    
    /// The CPTPlot
    var plot:CPTScatterPlot
    
    /// Integer to identify the subplot by the plotContainer
    var subPlotIndex :Int?
    
    /// The plotContainer
    var plotContainer:RealTimeSubPlotContainer?
    
    /// The insertion flag
    var isArrayBlockedForAppendings = true
    
    /// The data
    var plotData = [DataPoint](){
        didSet{
            
            if oldValue.count == 1 {
                let oldValueDataPoint = oldValue.last!
                minValue = oldValueDataPoint.value
                //minValue = oldValue.last?.values.array[0]!
            }
            // Check if the modification was an insertion or a deletion
            let deltaInDataPoints = plotData.count - oldValue.count
            if deltaInDataPoints > 0{
                // Insertion
                plot.insertDataAtIndex(UInt(plotData.count - 1 ), numberOfRecords: UInt(deltaInDataPoints))
                currentIndex++
                
                // Check if the number of points is greater than the permited
                if plotData.count == plotContainer!.plotDataSize{
                    
                    isArrayBlockedForAppendings = true
                    if let plotCont = plotContainer{
                        plotCont.plotStackIsFull(self)
                        //Reset index
                        currentIndex = 0
                    }
                    
                    // Remove the first samples of the plot
                    // At first, remove 2 times the number of samples inserted per frame
                    // Store the values to be removed.
                    let numberOfSamplesToRemove = plotContainer!.samplesPerFrame * 2
                    let dataPoints = Array(plotData[0..<numberOfSamplesToRemove])
                    var dataValues = [Double]()
                    for dataPoint in dataPoints{
                        let dataValue = dataPoint.value
                        dataValues.append(dataValue)
                    }
                    
                    // Removal
                    plotData.removeRange(Range(start: 0, end: numberOfSamplesToRemove))
                    plot.deleteDataInIndexRange(NSMakeRange(0, numberOfSamplesToRemove))
                    
                    // Check if the value deleted was the current max or min.
                    requiresMinMaxUpdate(dataValues)
                    
                } else{
                    // Check if the value inserted was the current max or min.
                    let dataValue = plotData.last!.value
                    requiresMinMaxUpdate([dataValue])
                }
                
            } else{
                
                // Deletion
                let dataPointsRemoved = -deltaInDataPoints
                // Store the values to be removed
                let dataPoints = Array(oldValue[0..<dataPointsRemoved])
                var dataValues = [Double]()
                for dataPoint in dataPoints{
                    let dataValue = dataPoint.value
                    dataValues.append(dataValue)
                }
                // Check if the value deleted was the current max or min.
                requiresMinMaxUpdate(dataValues)
                plot.deleteDataInIndexRange(NSMakeRange(0, dataPointsRemoved))
            }
            
            // Check if the new value updates the max or min
            
            if !plotData.isEmpty{
                let lastDataValue = plotData.last!.value
                
                if lastDataValue > maxValue{
                    maxValue = lastDataValue
                }
                if lastDataValue < minValue{
                    minValue = lastDataValue
                }
            }
        }
        willSet{
            
            // Check if the new value updates the max or min
            if let lastPoint = newValue.last{
                let dataValue = lastPoint.value
                if dataValue > ViewController.SimulationProperties.maxValue{
                    ViewController.SimulationProperties.maxValue = dataValue
                }
                if dataValue < ViewController.SimulationProperties.minValue{
                    ViewController.SimulationProperties.minValue = dataValue
                }
            }
        }
    }
    
    /// Structure that represents a dataPoint for the plot
    struct DataPoint {
        var index=0
        var value=0.0
    }
    
    /// Index of the next dataPoint, in relation to the graph
    var currentIndex = 0

    /// Stores the minimum value being plotted
    var minValue: Double = 0 {
        didSet{
            if let location = plotContainer?.locationIndex{
                minValue = minValue + (Double(location)*0.2)
            }
            if let plotCont = plotContainer{
                plotCont.updateMinValueForPlotSegmentWithIdentifier(plot.identifier as! String, newValue: minValue)
            }
        }
    }
    
    /// Stores the max value being plotted
    var maxValue: Double = 0{
        didSet{
            if let location = plotContainer?.locationIndex{
                maxValue = maxValue + (Double(location)*0.2)
            }
            if let plotCont = plotContainer{
                plotCont.updateMaxValueForPlotSegmentWithIdentifier(plot.identifier as! String, newValue: maxValue)
            }            
        }
    }
    
    // MARK: - Initializers
    
    override init(){
        // Create the Plot
        plot = CPTScatterPlot(frame: CGRectZero)
        plot.cachePrecision = .Double
        plot.interpolation = .Curved
        
        // Set the lineStyle for the plot
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
    
    convenience init(identifier:String, lineStyle:CPTLineStyle){
        self.init(identifier: identifier)
        plot.dataLineStyle = lineStyle
    }
    
    convenience init(identifier:String, lineStyle:CPTLineStyle, index:Int) {
        self.init(identifier:identifier, lineStyle:lineStyle)
        subPlotIndex = index
    }
    
    // MARK: - Methods
    
    /**
    
        Indicates if a new min o new max must be calculated after deleting a range of data from the plot
    
    */
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
        var dataPointValues = [Double]()
        for plotDataPoint in plotData{
            dataPointValues.append(plotDataPoint.value)
        }
        if !dataPointValues.isEmpty{
            if mustUpdate.updateMax{
                maxValue = dataPointValues.reduce(dataPointValues[0], combine:{max($0, $1)})
            }
            if mustUpdate.updateMin {
                minValue = dataPointValues.reduce(dataPointValues[0], combine: {min($0, $1)})
            }
        }

        return mustUpdate
    }
    
    /**
    
        Adds the received  data values to plot
    
    */
    func addDataPointsToPlot(values:[Double])-> Int?{
        //Check if the value can be added
        var newDataPoint:DataPoint
        for var index = 0; index < values.count; ++index{
            if !isArrayBlockedForAppendings && plotData.count < plotContainer!.plotDataSize{
                newDataPoint = DataPoint(index: currentIndex, value: values[index])
                plotData.append(newDataPoint)
            } else{
                return index
            }
        }
        
        return nil
    }
    
    /** 
    
        Removes the indicated number of dataPoints from the plots. FIFO 
    
    */
    func removeDataPointsFromPlot(numberOfDataPoints:Int) -> Bool{
        if  numberOfDataPoints <= plotData.count{
            plotData.removeRange(Range(start: 0, end: numberOfDataPoints))
            return true
        }
        return false
    }
    
    /**
    
        Clears all data from the plotData array
    
    */
    func clearPlot(){
        
        plotData.removeAll(keepCapacity: true)
        isArrayBlockedForAppendings = true
        currentIndex = 0
        
    }
    
    // MARK: - PlotDataSource protocol conformance
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        return UInt(plotData.count)
    }
    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject! {
        
        switch CPTScatterPlotField(rawValue: Int(fieldEnum))! {
        case .X:
            let num = Double(plotData[Int(idx)].index)/Double(plotContainer!.samplingFrequency)
            return num as NSNumber
            
        case .Y:
            var dataPoint = plotData[Int(idx)]
            var dataValue = dataPoint.value
            // Consider the possible offset to correctly visualize the plots in the graph
            if let location = plotContainer?.locationIndex{
                if let offset = plotContainer?.offset{
                    dataValue = dataValue + (Double(location + 1)*offset)
                    
                } else{
                    dataValue = dataValue + (Double(location)*0.2)
                }
               
            }
            return dataValue as NSNumber
            
        default:
            return nil
        }
    }
}

// MARK: - Protocols
protocol RealTimeSubPlotContainer{
    // Informs the plotContainer that the max value of this segment changed
    func updateMaxValueForPlotSegmentWithIdentifier(identifier:String, newValue:Double)
    // Informs the plotContainer that the min value of this segment changed
    func updateMinValueForPlotSegmentWithIdentifier(identifier:String, newValue:Double)
    // Informns the plotContainer that no more data can be added to the plot
    func plotStackIsFull(subPlot:realTimeStaticSubPlot)
    // Get the location of the plot for drawing purposes
    var locationIndex:Int {get}
    // Geth the number of data points
    var plotDataSize:Int {get}
    // Get the number of samples inserted on each iterruption
    var samplesPerFrame:Int {get}
    // Get the sampling frequency for drawing
    var samplingFrequency:Int {get}
    // Get the plot offset, for drawing
    var offset:Double {get}
    
}
