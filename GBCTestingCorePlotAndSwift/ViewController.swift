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

class ViewController: UIViewController , CPTPlotDataSource {
    
    // MARK: - Properties
    
    //A Timer to update the plot's data
    private var dataTimer:NSTimer? = nil
    
    //The plot
    private var realTimeScatterGraph: CPTXYGraph? = nil
    
    //The data of the plot
    private var plotData = [Double](){
        didSet{
            println("The oldValue is \(oldValue)")
            //Check if the modification was an insertion or a deletion
            let theGraph = realTimeScatterGraph!
            if let thePlot = theGraph.plotWithIdentifier(kPlotIdentifier){
                let deltaInDataPoints = plotData.count - oldValue.count
                if deltaInDataPoints > 0{
                    //Insertion
                    thePlot.insertDataAtIndex(UInt(plotData.count - 1 ), numberOfRecords: UInt(deltaInDataPoints))
                    SimulationProperties.index++
                    // check if the number of points is greater than the permited
                    if plotData.count >= kMaxDataPoints{
                        let overflow = plotData.count - (kMaxDataPoints - 1)
                        plotData.removeRange(Range(start: 0, end: overflow))
                        thePlot.deleteDataInIndexRange(NSMakeRange(0, overflow))
                    }
                } else{
                    let overflow = plotData.count - (kMaxDataPoints - 1)
                    plotData.removeRange(Range(start: 0, end: overflow))
                    thePlot.deleteDataInIndexRange(NSMakeRange(0, overflow))
                }
            }
        }
    }
    
    // The index of the simulation
    
    var simulationIndex = 0
    
    struct SimulationProperties
    {
        static var index: Int = 0
    }
    
    class var globalSimulationIndex:Int{
        return self.SimulationProperties.index
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
        
        newGraph.plotAreaFrame.paddingLeft   = 70.0
        newGraph.plotAreaFrame.paddingTop    = 20.0
        newGraph.plotAreaFrame.paddingRight  = 20.0
        newGraph.plotAreaFrame.paddingBottom = 80.0
        
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
        
        
        // Create the Plot
        let dataSourceLinePlot = CPTScatterPlot(frame: CGRectZero)
        dataSourceLinePlot.identifier = kPlotIdentifier
        dataSourceLinePlot.cachePrecision = .Double
        
        //Set the lineStyle for the plot
        let plotLineStyle = dataSourceLinePlot.dataLineStyle.mutableCopy() as! CPTMutableLineStyle
        plotLineStyle.lineWidth = 3.0
        plotLineStyle.lineColor = CPTColor.greenColor()
        dataSourceLinePlot.dataLineStyle = plotLineStyle
        dataSourceLinePlot.dataSource = self
        newGraph.addPlot(dataSourceLinePlot)
        
        // Plot Space
        let plotSpace = newGraph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.xRange = CPTPlotRange(location: 0.0, length: (200 - 2))
        plotSpace.yRange = CPTPlotRange(location: 0.0, length: 1.0)
        
        //Set up the animation
        dataTimer = NSTimer(timeInterval: 1.0/kFrameRate, target: self, selector: Selector("newData:"), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(self.dataTimer!, forMode: NSRunLoopCommonModes)
        
        realTimeScatterGraph = newGraph
        
        generateData()
        
    }
    
    // MARK: - Plot Methods
    
    func generateData(){
        simulationIndex = 0
    }
    
    func newData(theTimer:NSTimer){
        
        let theGraph = realTimeScatterGraph!
        if let thePlot = theGraph.plotWithIdentifier(kPlotIdentifier){
            let plotSpace = theGraph.defaultPlotSpace
            let location = (simulationIndex >= kMaxDataPoints ? (simulationIndex - kMaxDataPoints + 2): 0)
            let oldRange = CPTPlotRange(location: (location > 0 ? (location - 1) : 0) , length: kMaxDataPoints-2)
            let newRange = CPTPlotRange(location: location, length: (kMaxDataPoints-2))
            CPTAnimation.animate(plotSpace, property: "xRange", fromPlotRange: oldRange, toPlotRange: newRange, duration: CGFloat(1.0/kFrameRate))
            
            simulationIndex++
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
    
    // MARK: - Plot Data Source Methods
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        return UInt(plotData.count)
    }
    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject! {
        
        switch CPTScatterPlotField(rawValue: Int(fieldEnum))! {
        case .X:
            let num = idx + UInt(self.simulationIndex) - UInt(plotData.count)
            return num as NSNumber           
            
        case .Y:
            return plotData[Int(idx)] as NSNumber
            
        default:
            return nil
        }
    }
}








