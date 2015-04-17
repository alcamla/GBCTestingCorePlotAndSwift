//
//  PlotsViewController.swift
//  GBCTestingCorePlotAndSwift
//
//  Created by camacholaverde on 4/13/15.
//  Copyright (c) 2015 gibicgroup. All rights reserved.
//

import UIKit
import QuartzCore

class PlotsViewController: UIViewController, CPTGraphContainer {
    
    // A Timer to update the plot's data
    private var dataTimer:NSTimer? = nil
    
    // The Graph
    private var realTimeScatterGraph: CPTXYGraph? = nil
    
    // The range on the Y axis
    var yRange  = CPTPlotRange(location: 0.0, length: 16.0)
    
    var yAx:CPTXYAxis! = nil
    
    // The plots
    private var plotsArray:[realTimeStaticPlot] = [realTimeStaticPlot]() {
        willSet{
            if let newPlot = newValue.last as realTimeStaticPlot!{
                // Add the subplots contained in the new  realTimeStaticPlot
                for subPlotContainer in newPlot.subPlotsContainers{
                    realTimeScatterGraph!.addPlot(subPlotContainer.plot)
                }
                // Asign the location property
                newPlot.locationIndex = newValue.count-1
                // Assign the maxValue to MaxValues
                SimulationProperties.maxValues[newPlot.identifier] = newPlot.maxValue
                SimulationProperties.minValues[newPlot.identifier] = newPlot.minValue
                newPlot.graphContainer = self
                // Insert the new yLabel
                let newLabel = CPTAxisLabel(text: newPlot.identifier, textStyle: yAx.labelTextStyle)
                newLabel.tickLocation = newPlot.locationIndex + 1
                newLabel.offset       = yAx.labelOffset + yAx.majorTickLength
                yLabels.insert(newLabel)
                let axisSet = realTimeScatterGraph?.axisSet as! CPTXYAxisSet
                axisSet.yAxis.axisLabels = yLabels
                // Insert a new tick horizontal mark to split the plots a bit visually
                let location = CGFloat(Double(newValue.count) * offset)
                yTickLinesLocations.insert(location)
                axisSet.yAxis.majorTickLocations = yTickLinesLocations
            }
        }
    }
    
    // The index of the simulation
    struct SimulationProperties
    {
        static var index: Int = 0
        // The max value among all the plots included
        static var maxValue: Double = 0
        // The min value among all the plots included
        static var minValue: Double = 0
        // The max values of all the plots included
        static var maxValues:Dictionary = [String:Double]()
        // The min values of all the plots included
        static var minValues:Dictionary = [String:Double]()
        // The simulation sampling frequency
        static var samplingFrequency:Double = 100.0
        // The window time to visualize, in seconds
        static var visualizingTime:Double = 10.0
        // Factor used to downscale the Fs to facilitate data refresh
        static var frequencyDownscaleFactor:Int = 10
        // Offset between plots included in the graph
        static var standardOffsetBetweenPlots = 1.0
    }
    
    // Frequency at wich the signals are sampled
    var samplingFrequency:Double{
        return SimulationProperties.samplingFrequency
    }
    
    // Time interval being visualized
    var visualizingTime:Double{
        return SimulationProperties.visualizingTime
    }
    
    // The number of samples of a plot that can be visualized in the graph for the visualizing time set
    var plotDataSize:Int{
        //return Int((samplingFrequency * visualizingTime) + 1)
        return Int(samplingFrequency * visualizingTime)
    }
    
    // The number of samples inserted on each call to the newData method.
    var samplesPerFrame:Int{
        return SimulationProperties.frequencyDownscaleFactor
    }
    
    // The number of interruptions per second to insert new data.
    var frameRate:Double{
        // Checking if the relation can be hold. The sampling frequency must be a multiple of the frame rate
        assert(Int(samplingFrequency)%SimulationProperties.frequencyDownscaleFactor == 0, "Not a valid downscale factor")
        return samplingFrequency/Double(SimulationProperties.frequencyDownscaleFactor)
    }
    
    var offset:Double{
        return SimulationProperties.standardOffsetBetweenPlots
    }
    
    // Stores the labels for all the plots
    var yLabels = Set<CPTAxisLabel>()
    
    // Stores the location of the horizontal lines in the graph
    var yTickLinesLocations = Set<CGFloat>()
    
    // MARK:- Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        // Graph
        let newGraph = CPTXYGraph(frame: CGRectZero)
        newGraph.applyTheme(CPTTheme(named: kCPTPlainWhiteTheme))
        newGraph.title = kPlotTitle
        let titleTextStyle = CPTMutableTextStyle()
        titleTextStyle.color = CPTColor.grayColor()
        titleTextStyle.fontName = "Helveltica-Neue"
        titleTextStyle.fontSize = self.titleSize()
        
        // Graph's hosting view
        let hostingView = view as! CPTGraphHostingView
        hostingView.hostedGraph = newGraph
        
        // Border
        newGraph.plotAreaFrame.borderLineStyle = nil
        newGraph.plotAreaFrame.cornerRadius    = 0.0
        newGraph.plotAreaFrame.masksToBorder   = false
        
        // Paddings
        newGraph.paddingLeft   = 0.0
        newGraph.paddingRight  = 0.0
        newGraph.paddingTop    = 0.0
        newGraph.paddingBottom = 0.0
    
        newGraph.plotAreaFrame.paddingTop    = 15.0
        newGraph.plotAreaFrame.paddingRight  = 15.0
        newGraph.plotAreaFrame.paddingLeft   = 55.0
        newGraph.plotAreaFrame.paddingBottom = 55.0
        newGraph.plotAreaFrame.masksToBorder = false
        
        //Asign to property
        realTimeScatterGraph = newGraph

        // Axis
        
        // X
        // Grid line styles. For the X axis
        var majorGridLineStyle = CPTMutableLineStyle()
        majorGridLineStyle.lineWidth = 0.75
        majorGridLineStyle.lineColor = CPTColor(genericGray: CGFloat()).colorWithAlphaComponent(CGFloat(0.75))
        majorGridLineStyle.dashPattern = [CGFloat(3), CGFloat(3)]
        var minorGridLineStyle = CPTMutableLineStyle()
        minorGridLineStyle.lineWidth = 0.25
        minorGridLineStyle.lineColor = CPTColor.blackColor().colorWithAlphaComponent(CGFloat(0.1))
        minorGridLineStyle.dashPattern = [CGFloat(3), CGFloat(3)]
        
        let axisSet = newGraph.axisSet as! CPTXYAxisSet
        let xAxis = axisSet.xAxis
        xAxis.labelingPolicy = CPTAxisLabelingPolicy.Automatic
        xAxis.orthogonalPosition = 0.0
        xAxis.majorGridLineStyle = majorGridLineStyle
        xAxis.minorGridLineStyle = minorGridLineStyle
        // Do not present the Ticks that appear over the X axis line
        xAxis.majorTickLineStyle = nil
        xAxis.minorTickLineStyle = nil
        xAxis.minorTicksPerInterval = 1
        xAxis.labelOffset = titleSize() * CGFloat(0.25)
        xAxis.title = "X Axis"
        xAxis.titleOffset = titleSize() * CGFloat(1.5)
        xAxis.axisConstraints = CPTConstraints(lowerOffset: 0.0) // Fixes the axis to low left corner of the graph
        xAxis.labelFormatter = nil
        xAxis.labelExclusionRanges = [CPTPlotRange(location: 0.0, length: 0.1)] // Do not show the vertical dashed line over the yAxis
        let labelFormatter = NSNumberFormatter()
        labelFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        xAxis.labelFormatter = labelFormatter
        
        // Y
        // Grid line styles. For the Y axis
        majorGridLineStyle = CPTMutableLineStyle()
        majorGridLineStyle.lineWidth = 0.25
        majorGridLineStyle.lineColor = CPTColor(genericGray: CGFloat()).colorWithAlphaComponent(CGFloat(0.1))
        majorGridLineStyle.dashPattern = [CGFloat(3), CGFloat(3)]
        minorGridLineStyle = CPTMutableLineStyle()
        minorGridLineStyle.lineWidth = 0.25
        minorGridLineStyle.lineColor = CPTColor.blackColor().colorWithAlphaComponent(CGFloat(0.1))
        
        let yAxis = axisSet.yAxis
        yAxis.labelingPolicy = .Automatic
        yAxis.orthogonalPosition = 0.0
        yAxis.majorGridLineStyle = majorGridLineStyle
        yAxis.minorGridLineStyle = minorGridLineStyle
        // Do not present the Ticks that appear over the axis
        yAxis.majorTickLineStyle = nil
        yAxis.minorTickLineStyle = nil
        yAxis.minorTicksPerInterval = 0
        yAxis.labelOffset = titleSize() * CGFloat(0.25)
        //yAxis.title = "Y Axis"
        xAxis.titleOffset = titleSize() * CGFloat(1.25)
        yAxis.axisConstraints = CPTConstraints(lowerOffset: 0.0) // Fixes the axis to low left corner of the graph
        //yAxis.labelFormatter = nil
        yAxis.labelingPolicy = .None
        //Store the label style
        yAx = yAxis
        
        
        // Set the plots to the graph
        
        // First plot
        var plotLineStyle = CPTMutableLineStyle()
        plotLineStyle.lineWidth = 0.5
        plotLineStyle.lineColor = CPTColor.greenColor()
        var  plot = realTimeStaticPlot(identifier: "Fp1", lineStyle: plotLineStyle)
        plotsArray.append(plot)
        
        // Second plot
        plotLineStyle.lineWidth = 0.5
        plotLineStyle.lineColor = CPTColor.redColor()
        plot = realTimeStaticPlot(identifier: "Fp2", lineStyle: plotLineStyle)
        plotsArray.append(plot)
        
        // Third plot
        plotLineStyle.lineWidth = 0.5
        plotLineStyle.lineColor = CPTColor.grayColor()
        plot = realTimeStaticPlot(identifier: "Cz", lineStyle: plotLineStyle)
        plotsArray.append(plot)
        
        // Fourth plot
        plotLineStyle.lineWidth = 0.5
        plotLineStyle.lineColor = CPTColor.blackColor()
        plot = realTimeStaticPlot(identifier: "Fz", lineStyle: plotLineStyle)
        plotsArray.append(plot)
        
        // Fifth plot
        plotLineStyle.lineWidth = 0.5
        plotLineStyle.lineColor = CPTColor.brownColor()
        plot = realTimeStaticPlot(identifier: "C3", lineStyle: plotLineStyle)
        plotsArray.append(plot)
        
        // Sixth plot
        plotLineStyle.lineWidth = 0.5
        plotLineStyle.lineColor = CPTColor.magentaColor()
        plot = realTimeStaticPlot(identifier: "T4", lineStyle: plotLineStyle)
        plotsArray.append(plot)
        
        // Plot Space
        let plotSpace = realTimeScatterGraph!.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = CPTPlotRange(location: 0.0, length: visualizingTime)
        plotSpace.yRange = yRange
        
        // Set up the refreshing Timer interruption
        dataTimer = NSTimer(timeInterval: 1.0/frameRate, target: self, selector: Selector("newData:"), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(self.dataTimer!, forMode: NSRunLoopCommonModes)
        generateData()
    }
    
    // MARK: - Plot Methods
    
    func generateData(){
        SimulationProperties.index = 0
    }
    
    func newData(theTimer:NSTimer){
        
        let theGraph = realTimeScatterGraph!
        let plotSpace = theGraph.defaultPlotSpace as CPTPlotSpace
        
        // Update Ranges
        // In this version, the x range does not need to be updated
        // Y
        // Find the max and min between all plots
        let mins = Array(SimulationProperties.minValues.values)
        var globalMin = mins.reduce(mins[0], combine: {min($0, $1)})
        globalMin = globalMin - 0.3
        let maxs = Array(SimulationProperties.maxValues.values)
        var globalMax = maxs.reduce(maxs[0], combine: {max($0, $1)})
        
        // Increment a bit the max value
        globalMax  = globalMax + 0.3
        let realRangeLength = globalMax - globalMin
        if  (yRange.location as Double > globalMin) || realRangeLength != yRange.location{
            let oldRange = yRange
            yRange = CPTPlotRange(location: globalMin, length: realRangeLength)
            //CPTAnimation.animate(plotSpace, property: "yRange", fromPlotRange: oldRange, toPlotRange: yRange, duration: CGFloat(1.0/kFrameRate))
        }
        
        SimulationProperties.index++
        
        //Add data to all plots
        for aPlot in plotsArray{
            aPlot.addDataToPlot()
        }
    }
    
    func titleSize()->CGFloat{
        
        let titleSize:CGFloat
        switch UI_USER_INTERFACE_IDIOM(){
        case .Pad:
            titleSize = 24.0
        case .Phone:
            titleSize = 16.0
        default:
            titleSize = 0.0
        }
        return titleSize
    }
    
    // MARK: - CPTGraphContainer protocol conformance
    
    func updateMaxValueForPlotWithIdentifier(identifier:String, newValue:Double){
        SimulationProperties.maxValues.updateValue(newValue, forKey: identifier)
    }
    
    func updateMinValueForPlotWithIdentifier(identifier:String, newValue:Double){
        SimulationProperties.minValues.updateValue(newValue, forKey: identifier)
    }
}
