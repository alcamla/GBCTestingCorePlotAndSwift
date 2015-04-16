//
//  realTimeStaticPlot.swift
//  GBCTestingCorePlotAndSwift
//
//  Created by camacholaverde on 4/13/15.
//  Copyright (c) 2015 gibicgroup. All rights reserved.
//

import UIKit

class realTimeStaticPlot: NSObject, RealTimeSubPlotContainer {
    
    // MARK: - Properties
    
    //Stores the objects that contain the subplots
    var subPlotsContainers:[realTimeStaticSubPlot] = [realTimeStaticSubPlot]()
    
    //The graphContainer
    var graphContainer:CPTGraphContainer?
    
    //The plotIdentifier
    let identifier:String!
    
    //Current active subplot
    var activeSubPlotContainerIndex = 0;
    
    //Max value of the plot
    var maxValue:Double = 0
    
    // Min value of the plot
    var minValue:Double = 0
    
    // Location of the plot in the graph
    var locationIndex:Int = 0
    
    //
    var plotDataSize:Int{
        return graphContainer?.plotDataSize ?? 0
    }
    
    var samplesPerFrame:Int{
        return graphContainer!.samplesPerFrame
    }
    
    // Stores the last value added to the plot
    var lastValue:Double?
    
    // MARK:  - Initializers
    
    init(identifier:String) {
        for count in 0..<2{
            let subPlotContainer = realTimeStaticSubPlot(identifier: identifier + "\(count)")
            subPlotContainer.subPlotIndex = count
            subPlotsContainers.append(subPlotContainer)
        }
        self.identifier = identifier
        super.init()
        for subPlotsContainer in subPlotsContainers{
            subPlotsContainer.plotContainer = self
        }
        
        // Configure the active subplot to receive data points
        subPlotsContainers[activeSubPlotContainerIndex].isArrayBlockedForAppendings = false
    }
    
    convenience init(identifier:String, lineStyle:CPTLineStyle){
        self.init(identifier:identifier)
        for count in 0..<subPlotsContainers.count{
            var subPlotContainer = subPlotsContainers[count]
            subPlotContainer.plot.dataLineStyle = lineStyle
        }
    }
    
    // MARK: - Methods
    
    /** Adds new Data to plot. The new value to add  is calculated by the method itself */
    func addDataToPlot(){
        
        // Identify the roles of each subplotContainer
        let inactiveSubPlotIndex = activeSubPlotContainerIndex == 0 ? 1 : 0
        let inactiveSubPlot = subPlotsContainers[inactiveSubPlotIndex]
        let subPlotContainer = subPlotsContainers[activeSubPlotContainerIndex]
        
        if let dataPointsAmount = graphContainer?.samplesPerFrame{
            
            // Remove the given number of dataPoints
            inactiveSubPlot.removeDataPointsFromPlot(dataPointsAmount)
            
            // Insert the given number of dataPoints in the active subplot
            var array:[Double] = [Double]()
            var newValue:Double!
            for index in 0 ..< dataPointsAmount {
                if lastValue != nil {
                    newValue = ((1.0-kAlpha) * lastValue!) + (kAlpha * Double(arc4random()))/Double(UInt32.max)
                } else {
                    newValue = (kAlpha * Double(arc4random()))/Double(UInt32.max)
                }
                lastValue = newValue
                array.append(newValue)
            }
            subPlotContainer.addDataPointsToPlot(array)
        }
    }
    
    //MARK: - RealTimeSubPlotContainer protocol conformance
    
    func updateMaxValueForPlotSegmentWithIdentifier(identifier:String, newValue:Double){
        if newValue > maxValue{
            maxValue = newValue
            // Inform the graph container
            if let graphCont = graphContainer{
                graphCont.updateMaxValueForPlotWithIdentifier(identifier, newValue: maxValue)
            }
        }
    }
    
    func updateMinValueForPlotSegmentWithIdentifier(identifier:String, newValue:Double){
        if newValue < minValue{
            minValue = newValue
            // Inform the graph container
            if let graphCont = graphContainer{
                graphCont.updateMinValueForPlotWithIdentifier(identifier, newValue: minValue)
            }
        }
    }
    
    func plotStackIsFull(subPlot: realTimeStaticSubPlot) {
        //Can not add more dataPoints to this plot. 
        if let index = find(subPlotsContainers, subPlot){
            activeSubPlotContainerIndex = index == 0 ? 1 : 0
            // Check if the array is ready to be set as the active plot
            assert(subPlotsContainers[activeSubPlotContainerIndex].plotData.count == 0, "The array is not empty yet")
            subPlotsContainers[activeSubPlotContainerIndex].isArrayBlockedForAppendings = false
        }
    }
}

// MARK: - Protocols
protocol CPTGraphContainer{
    
    func updateMaxValueForPlotWithIdentifier(identifier:String, newValue:Double)
    func updateMinValueForPlotWithIdentifier(identifier:String, newValue:Double)
    //var samplingFrequency:Double {get}
    //var visualizingTime:Double {get}
    var plotDataSize:Int {get}
    var samplesPerFrame:Int {get}
}
