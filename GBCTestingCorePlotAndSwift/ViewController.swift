//
//  ViewController.swift
//  GBCTestingCorePlotAndSwift
//
//  Created by camacholaverde on 4/1/15.
//  Copyright (c) 2015 gibicgroup. All rights reserved.
//

import UIKit
import QuartzCore


let kMaxDataPoints = 52
let kFrameRate = 5.0 //Frames per second
let kAlpha = 0.25 //Smoothing constant
let kPlotIdentifier = "RealTimePlot"
let kPlotTitle = "Real Time Plot"

class ViewController: UIViewController {
    
    // MARK: - Properties
    
    //A Timer to update the plot's data
    private var dataTimer:NSTimer? = nil
    
    // The Graph
    private var realTimeScatterGraph: CPTXYGraph? = nil
    
    // The range on the Y axis
    var yRange  = CPTPlotRange(location: 0.0, length: 1.0)
    
    // The plots
    private var plotsArray:[GBCPlot] = [GBCPlot]() {
        willSet{
            if let newPlot = newValue.last as GBCPlot!{
                realTimeScatterGraph!.addPlot(newPlot.plot)
                //Asign the location property
                newPlot.locationIndex = newValue.count-1
                //Assign the maxValue to MaxValues
                SimulationProperties.maxValues[newPlot.plot.identifier as! String] = newPlot.maxValue
                SimulationProperties.minValues[newPlot.plot.identifier as! String] = newPlot.minValue
            }
            
        }
    }
    
    // The index of the simulation
     struct SimulationProperties
    {
        static var index: Int = 0
        static var maxValue: Double = 0
        static var minValue: Double = 0
        static var maxValues:Dictionary = [String:Double]()
        static var minValues:Dictionary = [String:Double]()
    }
    
    class func updateMaxValueForPlotWithIdentifier(identifier:String, newValue:Double){
        SimulationProperties.maxValues.updateValue(newValue, forKey: identifier)
    }
    
    class func updateMinValueForPlotWithIdentifier(identifier:String, newValue:Double){
        SimulationProperties.minValues.updateValue(newValue, forKey: identifier)
    }
    
    
    // MARK:- Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
        
        
        realTimeScatterGraph = newGraph
        
        // Grid line styles. Set them to the axis
        let majorGridLineStyle = CPTMutableLineStyle()
        majorGridLineStyle.lineWidth = 0.75
        majorGridLineStyle.lineColor = CPTColor(genericGray: CGFloat()).colorWithAlphaComponent(CGFloat(0.75))
        let minorGridLineStyle = CPTMutableLineStyle()
        minorGridLineStyle.lineWidth = 0.25
        minorGridLineStyle.lineColor = CPTColor.blackColor().colorWithAlphaComponent(CGFloat(0.1))
        
        
        // Axis
        // X
        let axisSet = newGraph.axisSet as! CPTXYAxisSet
        let xAxis = axisSet.xAxis
        xAxis.labelingPolicy = CPTAxisLabelingPolicy.Automatic
        xAxis.orthogonalPosition = 0.0
        xAxis.majorGridLineStyle = majorGridLineStyle
        xAxis.minorGridLineStyle = minorGridLineStyle
        xAxis.minorTicksPerInterval = 9
        xAxis.labelOffset = titleSize() * CGFloat(0.25)
        xAxis.title = "X Axis"
        xAxis.titleOffset = titleSize() * CGFloat(1.5)
        xAxis.labelRotation = CGFloat(M_PI_4)
        xAxis.axisConstraints = CPTConstraints(lowerOffset: 0.0)
        
        let labelFormatter = NSNumberFormatter()
        labelFormatter.numberStyle = NSNumberFormatterStyle.NoStyle
        xAxis.labelFormatter = labelFormatter
        
        // Y
        let yAxis = axisSet.yAxis
        yAxis.labelingPolicy = .Automatic
        yAxis.orthogonalPosition = 0.0
    
        yAxis.majorGridLineStyle = majorGridLineStyle
        yAxis.minorGridLineStyle = minorGridLineStyle
        yAxis.minorTicksPerInterval = 3
        yAxis.labelOffset = titleSize() * CGFloat(0.25)
        yAxis.title = "Y Axis"
        xAxis.titleOffset = titleSize() * CGFloat(1.25)
        yAxis.axisConstraints = CPTConstraints(lowerOffset: 0.0) //Fixes the axis to given plot
        
        // Set the plots to the graph
        
        // First plot
        let plotLineStyle = CPTMutableLineStyle()
        plotLineStyle.lineWidth = 3.0
        plotLineStyle.lineColor = CPTColor.greenColor()
        let firstPlot = GBCPlot(identifier: kPlotIdentifier, lineStyle: plotLineStyle)
        plotsArray.append(firstPlot)
        
        // Second plot
        plotLineStyle.lineWidth = 3.0
        plotLineStyle.lineColor = CPTColor.redColor()
        let secondPlot = GBCPlot(identifier: "SecondIdentifier", lineStyle: plotLineStyle)
        plotsArray.append(secondPlot)
        
        // Third plot
        plotLineStyle.lineWidth = 3.0
        plotLineStyle.lineColor = CPTColor.blueColor()
        let thirdPlot = GBCPlot(identifier: "ThirdIdentifier", lineStyle: plotLineStyle)
        plotsArray.append(thirdPlot)

        // Plot Space
        let plotSpace = realTimeScatterGraph!.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = CPTPlotRange(location: 0.0, length: (200 - 2))
        plotSpace.yRange = yRange
        
        //Set up the animation
        dataTimer = NSTimer(timeInterval: 1.0/kFrameRate, target: self, selector: Selector("newData:"), userInfo: nil, repeats: true)
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
        // X
        let location = (SimulationProperties.index >= kMaxDataPoints ? (SimulationProperties.index - kMaxDataPoints + 2): 0)
        let oldRange = CPTPlotRange(location: (location > 0 ? (location - 1) : 0) , length: kMaxDataPoints-2)
        let newRange = CPTPlotRange(location: location, length: (kMaxDataPoints-2))
        
        CPTAnimation.animate(plotSpace, property: "xRange", fromPlotRange: oldRange, toPlotRange: newRange, duration: CGFloat(1.0/kFrameRate))
        // Y
        //Find the max and min between all plots
        let mins = Array(SimulationProperties.minValues.values)
        var globalMin = mins.reduce(mins[0], combine: {min($0, $1)})
        globalMin = globalMin - 0.3
        let maxs = Array(SimulationProperties.maxValues.values)
        var globalMax = maxs.reduce(maxs[0], combine: {max($0, $1)})
        //Increment a bit the max value
        globalMax  = globalMax + 0.3
        let realRangeLength = globalMax - globalMin
        if  (yRange.location as Double > globalMin) || realRangeLength != yRange.location{
            let oldRange = yRange
            yRange = CPTPlotRange(location: globalMin, length: realRangeLength)
            CPTAnimation.animate(plotSpace, property: "yRange", fromPlotRange: oldRange, toPlotRange: yRange, duration: CGFloat(1.0/kFrameRate))
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
    
}








