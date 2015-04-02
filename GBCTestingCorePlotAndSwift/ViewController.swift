//
//  ViewController.swift
//  GBCTestingCorePlotAndSwift
//
//  Created by camacholaverde on 4/1/15.
//  Copyright (c) 2015 gibicgroup. All rights reserved.
//

import UIKit

class ViewController: UIViewController , CPTPlotDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        let newGraph = CPTXYGraph(frame: CGRectZero)
        newGraph.applyTheme(CPTTheme(named: kCPTPlainWhiteTheme))
        
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
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Plot Data Source Methods
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        return 16
    }
    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: UInt) -> AnyObject! {
        switch CPTScatterPlotField(rawValue: Int(fieldEnum))! {
        case .X:
            return idx as NSNumber
            
        case .Y:
            let plotID = plot.identifier as! String
            return (plotID == "Bar Plot 2" ? idx : ((idx + 1) * (idx + 1)) ) as NSNumber
            
        default:
            return nil
        }
    }
}

