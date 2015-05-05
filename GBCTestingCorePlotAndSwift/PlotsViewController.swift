//
//  PlotsViewController.swift
//  GBCTestingCorePlotAndSwift
//
//  Created by camacholaverde on 4/13/15.
//  Copyright (c) 2015 gibicgroup. All rights reserved.
//

import UIKit

class PlotsViewController: UIViewController, CPTGraphContainer {
    
    /// A Timer to update the plot's data
    private var dataTimer:NSTimer? = nil
    
    /// The Graph
    private var realTimeScatterGraph: CPTXYGraph? = nil
    
    /// The range on the Y axis
    var yRange  = CPTPlotRange(location: 0.0, length: 16.0)
    
    var yAx:CPTXYAxis! = nil
    
    /// The plots
    private var plotsArray:[realTimeStaticPlot] = [realTimeStaticPlot]() {
        willSet{
            // Check if the number of plots has incremented.
            let deltaPlots = newValue.count - plotsArray.count
            if deltaPlots > 0{
                // A new plot has been added
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
                    insertLabelWithText(newPlot.identifier, atLocation: newPlot.locationIndex)
                }
            }
        }
        didSet{
            // Update the vertical range of the plot
            refreshYAxis()
        }
    }
    
    /// The index of the simulation
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
        // Space separating the last line from the top of the graph
        static var graphVerticalPadding = 0.2
        // Vertical offset for the labels
        static var yLabelsVerticalOffset = 0.5
    }
    
    /// Frequency at wich the signals are sampled
    var samplingFrequency:Double{
        return SimulationProperties.samplingFrequency
    }
    
    /// Time interval being visualized
    var visualizingTime:Double{
        return SimulationProperties.visualizingTime
    }
    
    /// The number of samples of a plot that can be visualized in the graph for the visualizing time set
    var plotDataSize:Int{
        //return Int((samplingFrequency * visualizingTime) + 1)
        return Int(samplingFrequency * visualizingTime)
    }
    
    /// The number of samples inserted on each call to the newData method.
    var samplesPerFrame:Int{
        return SimulationProperties.frequencyDownscaleFactor
    }
    
    /// The number of interruptions per second to insert new data.
    var frameRate:Double{
        // Checking if the relation can be hold. The sampling frequency must be a multiple of the frame rate
        assert(Int(samplingFrequency)%SimulationProperties.frequencyDownscaleFactor == 0, "Not a valid downscale factor")
        return samplingFrequency/Double(SimulationProperties.frequencyDownscaleFactor)
    }
    
    /// The offset that exists between plots
    var offset:Double{
        return SimulationProperties.standardOffsetBetweenPlots
    }
    
    /// The index of the current simulation
    var simulationIndex:Int{
        return SimulationProperties.index
    }
    
    /// Stores the labels for all the plots
    var yLabels = Set<CPTAxisLabel>()
    
    /// Stores the location of the horizontal lines in the graph
    var yTickLinesLocations = Set<CGFloat>()
    
    /// Stores the current device orientation
    var orientation = AppUtilities.getDeviceOrientation(){
        didSet{
            // Clear the plots
            clearPlots()
        }
        willSet{
            let xRange:CPTPlotRange!
            let plotSpace = realTimeScatterGraph!.defaultPlotSpace as! CPTXYPlotSpace
            if (newValue == .Portrait) || (newValue == .PortraitUpsideDown){
                SimulationProperties.visualizingTime = 5.0
            } else {
                SimulationProperties.visualizingTime = 10.0
            }
            xRange = CPTPlotRange(location: 0.0, length: visualizingTime)
            plotSpace.xRange = xRange
        }
    }
    
    // MARK:- Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        graphConfiguration()
    }
    
    func graphConfiguration(){
        
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
        
        // Asign to property
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
        
        // Plot Space
        let plotSpace = realTimeScatterGraph!.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = CPTPlotRange(location: 0.0, length: visualizingTime)
        plotSpace.yRange = yRange
        
        // Set up the refreshing Timer interruption
        dataTimer = NSTimer(timeInterval: 1.0/frameRate, target: self, selector: Selector("insertDataToPlotsWithTimer:"), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(self.dataTimer!, forMode: NSRunLoopCommonModes)

        /* //Some functions to test functionality and performance
        
         //Set up a timer to delete plots
        let removalTimer = NSTimer(timeInterval: 5.2, target: self, selector: Selector("deletePlotTimer:"), userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(removalTimer, forMode: NSRunLoopCommonModes)
        
        // Set up a timer to add new plots
        let insertionTimer = NSTimer(timeInterval: 7.0, target: self, selector: Selector("insertPlotsTimer:"), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(insertionTimer, forMode: NSRunLoopCommonModes)
        */
    }
    
    override func viewDidAppear(animated: Bool) {
        // Set the plots to the graph
        
        var plotLineStyle = CPTMutableLineStyle()
        plotLineStyle.lineWidth = 0.5
        var colorFuncts =  [CPTColor.grayColor, CPTColor.redColor, CPTColor.blackColor, CPTColor.brownColor, CPTColor.magentaColor, CPTColor.greenColor]
        var identifiers = ["Fp1", "Fp2", "Cz", "Fz", "C3", "T4"]
        for counter in 0...2{
            let channel = EEGModelChannels.allValues[counter]
            let condition = EEGModelConditions.EyesClosed
            plotLineStyle.lineColor = colorFuncts[counter]()
            addPlotWithIdentifier(identifiers[counter], channel: channel, condition: condition, andLineStyle: plotLineStyle)
        }        
    }
    
    override func viewWillLayoutSubviews() {
        // Check if the orientation changed
        if AppUtilities.getDeviceOrientation() != orientation {
            orientation = AppUtilities.getDeviceOrientation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        println("Do something about this warning")
    }
    
    
    // MARK: - Plot Methods

    /**
        Adds new data to the visible plots of the graph
        
        :param: theTimer NSTimer that triggers the interruption
    
    */
    func insertDataToPlotsWithTimer(theTimer:NSTimer){
        
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
            CPTAnimation.animate(plotSpace, property: "yRange", fromPlotRange: oldRange, toPlotRange: yRange, duration: CGFloat(1.0/kFrameRate))
        }
        
        //Add data to all plots
        for aPlot in plotsArray{
            aPlot.addDataToPlot2()
        }
        // Increment the simulation index. Keep in mind that we are adding several samples in  a single call to plot.addDataToPlot.
        SimulationProperties.index++
    }
    
    /**
        Adds a new plotContainer and its corresponding plot to the active graph.
    
        :param: identifier String to identify the plot, also corresponds to the label set on the Y axis
        :param: lineStyle CPTMutableLineStyle with which the plot will be visualized
    */
    func addPlotWithIdentifier(identifier:String, channel:EEGModelChannels, condition:EEGModelConditions, andLineStyle lineStyle:CPTMutableLineStyle){
        let plot = realTimeStaticPlot(identifier: identifier, eegChannel:channel, eegCondition:condition, lineStyle:lineStyle)
        plotsArray.append(plot)
    }
    
    /**
        Calculates the proper size for the graph's title
    */
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
    

    
    /**
        Removes a plot with the given identifier, if its part of the plotsArray
    
        :param: identifier: String that identifies the plot
    
    */
    func removePlotWithIdentifier(identifier:String){
        var index = 0
        var indexToRemove:Int!
        for plot in plotsArray{
            if plot.identifier == identifier{
                // Remove the plot from the array
                removePlotAtIndex(index)
                break
            }
            index++
        }
    }
    
    /**
        Removes the plot at the given index.
    
        :param: identifier: String that identifies the plot
    
    */
    func removePlotAtIndex(indexToRemove:Int){
        // Get the current number of plots
        var lastIndex = plotsArray.count - 1
        for index in indexToRemove ... lastIndex {
            plotsArray[index].locationIndex = --plotsArray[index].locationIndex
        }
        let plotContainer = plotsArray.removeAtIndex(indexToRemove)
        // Remove the plots from the graph
        for subPlotContainer in plotContainer.subPlotsContainers {
            realTimeScatterGraph!.removePlot(subPlotContainer.plot)
        }
        // Given that the number of plots has changed, clear the plots
        clearPlots()
        // The plots labels need to be updated
        refreshLabels()
    }
    
    /**
        Clears  all the dataPoints of the plots  in the graph. call this method
        when a plot has been deleted, or when the device orientation has changed.
    
    */
    func clearPlots(){
        
        for plotContainer in plotsArray{
            plotContainer.clearPlotData()
        }
        
    }
    
    /**
        Refreshes the ylabels. This method should be called after a plot has been deleted
    */
    func refreshLabels(){
        // Clear current labels and horizontal tick lines
        let axisSet = realTimeScatterGraph?.axisSet as! CPTXYAxisSet
        yLabels.removeAll(keepCapacity: true)
        yTickLinesLocations.removeAll(keepCapacity: true)
        
        // Refresh the labels
        for plotContainer in plotsArray{
            let newLabel = CPTAxisLabel(text: plotContainer.identifier, textStyle: yAx.labelTextStyle)
            newLabel.tickLocation = Double(plotContainer.locationIndex) + SimulationProperties.yLabelsVerticalOffset
            newLabel.offset       = yAx.labelOffset + yAx.majorTickLength
            yLabels.insert(newLabel)
        }
        axisSet.yAxis.axisLabels = yLabels
        
        // Refresh the tick lines locations
        for lineCount in 1 ... yLabels.count{
            let axisSet = realTimeScatterGraph?.axisSet as! CPTXYAxisSet
            // Insert a new tick horizontal mark to split the plots a bit visually
            let location = CGFloat(Double(lineCount) * offset)
            yTickLinesLocations.insert(location)
        }
        axisSet.yAxis.majorTickLocations = yTickLinesLocations
   
    }
    
    /**
        Updates the range in the vertical axis after the number of plots has changed.
    */
    func refreshYAxis(){
        let plotSpace = realTimeScatterGraph!.defaultPlotSpace as! CPTXYPlotSpace
        // Refreshing the vertical axis
        let newRange = CPTPlotRange(location: 0.0, length: Double(plotsArray.count) * offset + SimulationProperties.graphVerticalPadding)
         plotSpace.yRange = newRange

    }
    
    /**
        Generates a new label and tick horizontal line at the given location and with the given text
    
        :param: text The text for the label
        :param: location the vertical coordinate where the label will be located
    */
    func insertLabelWithText(text:String, atLocation location:Int){
        let newLabel = CPTAxisLabel(text: text, textStyle: yAx.labelTextStyle)
        newLabel.tickLocation =  Double(location) + SimulationProperties.yLabelsVerticalOffset
        newLabel.offset       = yAx.labelOffset + yAx.majorTickLength
        yLabels.insert(newLabel)
        //Set the updated labels
        let axisSet = realTimeScatterGraph?.axisSet as! CPTXYAxisSet
        axisSet.yAxis.axisLabels = yLabels
        
        // Update the tick horizontal lines
        yTickLinesLocations.insert(CGFloat(Double(location+1) * offset))
        axisSet.yAxis.majorTickLocations = yTickLinesLocations
    }
    
    
    // MARK: - Testing methods
    
    func deletePlotTimer(theTimer: NSTimer){
        if theTimer.timeInterval < 10.0 {
            //Remove the plot with identifier T4
            removePlotWithIdentifier("Fz")
        }
    }
    
    func insertPlotsTimer(theTimer: NSTimer){
        var plotLineStyle = CPTMutableLineStyle()
        plotLineStyle.lineWidth = 0.5
        //addPlotWithIdentifier("A1", andLineStyle: plotLineStyle)
        // Given that the number of plots has changed, clear the plots
        clearPlots()
        // The plots labels need to be updated
        refreshLabels()
    }
    
    
    // MARK: - CPTGraphContainer protocol conformance
    
    func updateMaxValueForPlotWithIdentifier(identifier:String, newValue:Double){
        SimulationProperties.maxValues.updateValue(newValue, forKey: identifier)
    }
    
    func updateMinValueForPlotWithIdentifier(identifier:String, newValue:Double){
        SimulationProperties.minValues.updateValue(newValue, forKey: identifier)
    }
}
