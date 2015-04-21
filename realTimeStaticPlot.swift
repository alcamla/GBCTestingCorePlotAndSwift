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
    
    /// Stores the objects that contain the subplots
    var subPlotsContainers:[realTimeStaticSubPlot] = [realTimeStaticSubPlot]()
    
    /// The graphContainer
    var graphContainer:CPTGraphContainer?
    
    /// The plotIdentifier
    let identifier:String!
    
    /// Current active subplot
    var activeSubPlotContainerIndex = 0;
    
    /// Max value of the plot
    var maxValue:Double = 0
    
    /// Min value of the plot
    var minValue:Double = 0
    
    /// Location of the plot in the graph
    var locationIndex:Int = 0
    
    /// The number of dataPoints for the plot and its subplots
    var plotDataSize:Int{
        return graphContainer?.plotDataSize ?? 0
    }
    
    /// Number of samples inserted on each timer interruption
    var samplesPerFrame:Int{
        return graphContainer!.samplesPerFrame
    }
    
    /// Required to supply the values for the X axis in the subplots
    var samplingFrequency:Int {
        return Int(graphContainer!.samplingFrequency)
    }
    
    /// Stores the last value added to the plot
    var lastValue:Double?
    
    /// Standard offset between plots of the containing graph
    var offset:Double{
        return graphContainer?.offset ?? 0.0
    }
    
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
    
    /**
    
    Adds new Data to plot. The new value to add  is calculated by the method itself 
    
    */
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
    
    /**
    
        This method removes all data points from plot. However, the simulation keeps going from the same point, 
        doing a clearing of the graph
    
    */
    func clearPlotData(){
        
        // Must reset all data of subPlots
        for subPlotContainer in subPlotsContainers{
            subPlotContainer.clearPlot()
        }
        subPlotsContainers[0].isArrayBlockedForAppendings = false        
        
    }
    
    // MARK: - RealTimeSubPlotContainer protocol conformance
    
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
    
    // Informs the delegate that the max value of this plot has changed
    func updateMaxValueForPlotWithIdentifier(identifier:String, newValue:Double)
    // Informs the delegate that the min value of this plot has changed
    func updateMinValueForPlotWithIdentifier(identifier:String, newValue:Double)
    // Get the Fs from the simulation
    var samplingFrequency:Double {get}
    // Get the number of data points that the plot should have
    var plotDataSize:Int {get}
    // Get the number of samples inserted on each call to the refreshing function
    var samplesPerFrame:Int {get}
    // Get the offset stablished by the container in order to draw the plot correctly
    var offset: Double {get}
}
