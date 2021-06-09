//
//  ViewController.swift
//  MMR-Swift-Tutorial
//
//  Created by Almina on 2021/02/17.
//  Copyright © 2021 Almina. All rights reserved.
//

import Cocoa
import MetaWear
import MetaWearCpp
import CorePlot

// MARK:
//   The following method may cause serious errors.
//   It is recommended to use another method.
var vc: ViewController!
var L_freqCounter = FrequencyCounter()
var R_freqCounter = FrequencyCounter()

var L_accTextBuff: String = "" {
  didSet { DispatchQueue.main.async { vc.charaLabel.stringValue = L_accTextBuff } }
}
var L_gyroTextBuff: String = "" {
  didSet { DispatchQueue.main.async { vc.charaLabel2.stringValue = L_gyroTextBuff } }
}
var R_accTextBuff: String = "" {
  didSet { DispatchQueue.main.async { vc.charaLabel3.stringValue = R_accTextBuff } }
}
var R_gyroTextBuff: String = "" {
  didSet { DispatchQueue.main.async { vc.charaLabel4.stringValue = R_gyroTextBuff } }
}

var L_raw_accRecordTextBuff: String = "" {
  didSet { DispatchQueue.main.async {
    if vc.L_raw_csvMng.isRecording { vc.L_raw_csvMng.addRecordText(addText: L_raw_accRecordTextBuff) }
  } }
}
var R_raw_accRecordTextBuff: String = "" {
  didSet { DispatchQueue.main.async {
    if vc.R_raw_csvMng.isRecording { vc.R_raw_csvMng.addRecordText(addText: R_raw_accRecordTextBuff) }
  } }
}
var L_accRecordTextBuff: String = "" {
  didSet { DispatchQueue.main.async{
    if vc.L_csvMng.isRecording { vc.L_csvMng.addRecordBuffer(addText: L_accRecordTextBuff) }
  } }
}
var R_accRecordTextBuff: String = "" {
  didSet { DispatchQueue.main.async {
    if vc.R_csvMng.isRecording { vc.R_csvMng.addRecordBuffer(addText: R_accRecordTextBuff) }
  } }
}

var L_freqTextBuff: String = "" {
  didSet {
    L_freqCounter.update()
    if L_freqCounter.isFreqValueUpdated {
      var freqTextBuff = "(L) BLE Frequency: "
      freqTextBuff += String(format: "%.2f", L_freqCounter.freq)
      freqTextBuff += "Hz"
      DispatchQueue.main.async { vc.L_FreqLabel.stringValue = freqTextBuff }
    }
    if vc.L_raw_csvMng.isRecording {
      DispatchQueue.main.async { vc.timerLabel.stringValue = "timer: " + String(format: "%.2f", NSDate().timeIntervalSince(vc.timestamp)) }
    }
  }
}
var R_freqTextBuff: String = "" {
  didSet {
    R_freqCounter.update()
    if R_freqCounter.isFreqValueUpdated {
      var freqTextBuff = "(R) BLE Frequency: "
      freqTextBuff += String(format: "%.2f", R_freqCounter.freq)
      freqTextBuff += "Hz"
      DispatchQueue.main.async { vc.R_FreqLabel.stringValue = freqTextBuff }
    }
    if vc.L_raw_csvMng.isRecording {
      DispatchQueue.main.async { vc.timerLabel.stringValue = "timer: " + String(format: "%.2f", NSDate().timeIntervalSince(vc.timestamp)) }
    }
  }
}

var L_accXPlotValueBuff: Float = 0.0 {
  didSet { DispatchQueue.main.async {
    vc.lxPlotData.append(L_accXPlotValueBuff)
  } }
}
var L_accYPlotValueBuff: Float = 0.0 {
  didSet { DispatchQueue.main.async {
    vc.lyPlotData.append(L_accYPlotValueBuff)
    } }
}
var L_accZPlotValueBuff: Float = 0.0 {
  didSet { DispatchQueue.main.async {
    vc.lzPlotData.append(L_accZPlotValueBuff)
    vc.L_plotAcc(point: L_accZPlotValueBuff)
    } }
}
var R_accXPlotValueBuff: Float = 0.0 {
  didSet { DispatchQueue.main.async {
    vc.rxPlotData.append(R_accXPlotValueBuff)
    } }
}
var R_accYPlotValueBuff: Float = 0.0 {
  didSet { DispatchQueue.main.async {
    vc.ryPlotData.append(R_accYPlotValueBuff)
    } }
}
var R_accZPlotValueBuff: Float = 0.0 {
  didSet { DispatchQueue.main.async {
    vc.rzPlotData.append(R_accZPlotValueBuff)
    vc.R_plotAcc(point: R_accZPlotValueBuff)
    } }
}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
  @IBOutlet weak var tableView: NSTableView!
  
  @IBOutlet weak var recordButton: NSButton!
  @IBOutlet weak var charaLabel: NSTextField!
  @IBOutlet weak var charaLabel2: NSTextField!
  @IBOutlet weak var charaLabel3: NSTextField!
  @IBOutlet weak var charaLabel4: NSTextField!
  @IBOutlet weak var L_FreqLabel: NSTextField!
  @IBOutlet weak var R_FreqLabel: NSTextField!
  
  @IBOutlet weak var L_StreamPopUpButton: NSPopUpButton!
  @IBOutlet weak var R_StreamPopUpButton: NSPopUpButton!
  @IBOutlet weak var L_StreamButton: NSButton!
  @IBOutlet weak var R_StreamButton: NSButton!
  @IBOutlet weak var L_StreamStopButton: NSButton!
  @IBOutlet weak var R_StreamStopButton: NSButton!
  
  @IBOutlet weak var filenameTextField: NSTextField!
  
  @IBOutlet weak var L_accYGraphLabel: NSTextField!
  @IBOutlet weak var R_accYGraphLabel: NSTextField!
  
  @IBOutlet weak var timerLabel: NSTextField!
  
  var scannerModel: ScannerModel!
  //  var L_freqCounter = FrequencyCounter()
  //  var R_freqCounter = FrequencyCounter()
  
  var debug: Bool!
  //  var format = DateFormatter()
  
  let L_raw_csvMng = CsvManager()
  let R_raw_csvMng = CsvManager()
  let L_csvMng = CsvManager()
  let R_csvMng = CsvManager()
  
  var timestamp = Date()
  
  var maxDataPoints = 300
  @IBOutlet weak var L_cptGraphHostingView: CPTGraphHostingView!
  @IBOutlet weak var R_cptGraphHostingView: CPTGraphHostingView!
  
  fileprivate struct PlotIdentifier {
    static let lx = "lxPlot"
    static let ly = "lyPlot"
    static let lz = "lzPlot"
    static let rx = "rxPlot"
    static let ry = "ryPlot"
    static let rz = "rzPlot"
  }
  
  fileprivate struct ZPosition {
    static let lxPlot: CGFloat = 3.0
    static let lyPlot: CGFloat = 2.0
    static let lzPlot: CGFloat = 1.0
    static let rxPlot: CGFloat = 3.0
    static let ryPlot: CGFloat = 2.0
    static let rzPlot: CGFloat = 1.0
  }
  
  var lxPlotData = [Float](repeating: 0.0, count: 300)
  var lyPlotData = [Float](repeating: 0.0, count: 300)
  var lzPlotData = [Float](repeating: 0.0, count: 300)
  var rxPlotData = [Float](repeating: 0.0, count: 300)
  var ryPlotData = [Float](repeating: 0.0, count: 300)
  var rzPlotData = [Float](repeating: 0.0, count: 300)
  
  // MARK: View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.debug = true
    //    self.format.dateFormat = "yyyy-MMdd-HHmmsss"
    
    tableView.target = self
    tableView.doubleAction = #selector(ViewController.tableViewDoubleClick(sender:))
    scannerModel = ScannerModel(delegate: self)
    
    vc = self
    
    L_StreamPopUpButton.removeAllItems()
    R_StreamPopUpButton.removeAllItems()
    
    //    self.L_raw_csvMng.setFileNameText(setText: "sample1-acc")
    //    self.R_raw_csvMng.setFileNameText(setText: "sample2-acc")
    self.L_raw_csvMng.setFileNameText(setText: "MMR-left-raw")
    self.R_raw_csvMng.setFileNameText(setText: "MMR-right-raw")
    self.L_csvMng.setFileNameText(setText: "MMR-left")
    self.R_csvMng.setFileNameText(setText: "MMR-right")
    
    timestamp = Date()
    
    initializeGraph()
  }
  
  func initializeGraph(){
    configureGraphView()
    configureGraphAxis()
    configurePlot()
  }
  
  func configureGraphView(){
    L_cptGraphHostingView.allowPinchScaling = false
    R_cptGraphHostingView.allowPinchScaling = false
  }
  
  func configureGraphAxis(){
    //Configure graph
    let graph = CPTXYGraph(frame: L_cptGraphHostingView.bounds)
    graph.plotAreaFrame?.masksToBorder = false
    L_cptGraphHostingView.hostedGraph = graph
    graph.backgroundColor = NSColor(red: 0.215, green: 0.215, blue: 0.215, alpha: 1.0).cgColor
    graph.paddingBottom = 40.0
    graph.paddingLeft = 40.0
    graph.paddingTop = 30.0
    graph.paddingRight = 15.0
    
    //Style for graph title
    let titleStyle = CPTMutableTextStyle()
    titleStyle.color = CPTColor.white()
    titleStyle.fontName = "HelveticaNeue-Bold"
    titleStyle.fontSize = 20.0
    titleStyle.textAlignment = .center
    graph.titleTextStyle = titleStyle
    
    //Set graph title
    let title = "Left Acc"
    graph.title = title
    graph.titlePlotAreaFrameAnchor = .top
    graph.titleDisplacement = CGPoint(x: 0.0, y: 0.0)
    
    let axisSet = graph.axisSet as! CPTXYAxisSet
    
    let axisTextStyle = CPTMutableTextStyle()
    axisTextStyle.color = CPTColor.white()
    axisTextStyle.fontName = "HelveticaNeue-Bold"
    axisTextStyle.fontSize = 10.0
    axisTextStyle.textAlignment = .center
    let lineStyle = CPTMutableLineStyle()
    lineStyle.lineColor = CPTColor.white()
    lineStyle.lineWidth = 5
    let gridLineStyle = CPTMutableLineStyle()
    gridLineStyle.lineColor = CPTColor.gray()
    gridLineStyle.lineWidth = 0.5
    
    if let x = axisSet.xAxis {
      x.majorIntervalLength   = 50
      x.minorTicksPerInterval = 5
      x.labelTextStyle = axisTextStyle
      x.minorGridLineStyle = gridLineStyle
      x.axisLineStyle = lineStyle
      x.axisConstraints = CPTConstraints(lowerOffset: 0.0)
      x.delegate = self
    }
    
    if let y = axisSet.yAxis {
      y.majorIntervalLength   = 2.0
      y.minorTicksPerInterval = 5
      y.minorGridLineStyle = gridLineStyle
      y.labelTextStyle = axisTextStyle
      y.alternatingBandFills = [CPTFill(color: CPTColor.init(componentRed: 255, green: 255, blue: 255, alpha: 0.03)),CPTFill(color: CPTColor.black())]
      y.axisLineStyle = lineStyle
      y.axisConstraints = CPTConstraints(lowerOffset: 0.0)
      y.delegate = self
    }
    
    // Set plot space
    let xMin = 0.0
    let xMax = 300.0
    let yMin = -8.0
    let yMax = 8.0
    guard let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return }
    plotSpace.xRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(xMin), lengthDecimal: CPTDecimalFromDouble(xMax - xMin))
    plotSpace.yRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(yMin), lengthDecimal: CPTDecimalFromDouble(yMax - yMin))


    //Configure graph
    let rGraph = CPTXYGraph(frame: R_cptGraphHostingView.bounds)
    rGraph.plotAreaFrame?.masksToBorder = false
    R_cptGraphHostingView.hostedGraph = rGraph
    rGraph.backgroundColor = NSColor(red: 0.215, green: 0.215, blue: 0.215, alpha: 1.0).cgColor
    rGraph.paddingBottom = 40.0
    rGraph.paddingLeft = 40.0
    rGraph.paddingTop = 30.0
    rGraph.paddingRight = 15.0

    //Style for graph title
    rGraph.titleTextStyle = titleStyle

    //Set graph title
    let rTitle = "Right Acc"
    rGraph.title = rTitle
    rGraph.titlePlotAreaFrameAnchor = .top
    rGraph.titleDisplacement = CGPoint(x: 0.0, y: 0.0)

    let rAxisSet = rGraph.axisSet as! CPTXYAxisSet

    if let x = rAxisSet.xAxis {
      x.majorIntervalLength   = 50
      x.minorTicksPerInterval = 5
      x.labelTextStyle = axisTextStyle
      x.minorGridLineStyle = gridLineStyle
      x.axisLineStyle = lineStyle
      x.axisConstraints = CPTConstraints(lowerOffset: 0.0)
      x.delegate = self
    }

    if let y = rAxisSet.yAxis {
      y.majorIntervalLength   = 2.0
      y.minorTicksPerInterval = 5
      y.minorGridLineStyle = gridLineStyle
      y.labelTextStyle = axisTextStyle
      y.alternatingBandFills = [CPTFill(color: CPTColor.init(componentRed: 255, green: 255, blue: 255, alpha: 0.03)),CPTFill(color: CPTColor.black())]
      y.axisLineStyle = lineStyle
      y.axisConstraints = CPTConstraints(lowerOffset: 0.0)
      y.delegate = self
    }

    // Set plot space
    guard let rPlotSpace = rGraph.defaultPlotSpace as? CPTXYPlotSpace else { return }
    rPlotSpace.xRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(xMin), lengthDecimal: CPTDecimalFromDouble(xMax - xMin))
    rPlotSpace.yRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(yMin), lengthDecimal: CPTDecimalFromDouble(yMax - yMin))
  }
  
  func configurePlot(){
    guard let graph = L_cptGraphHostingView.hostedGraph else { return }
    
    let lxPlot: CPTScatterPlot = CPTScatterPlot()
    let lxPlotLineStile = CPTMutableLineStyle()
    lxPlotLineStile.lineJoin = .round
    lxPlotLineStile.lineCap = .round
    lxPlotLineStile.lineWidth = 2
    lxPlotLineStile.lineColor = CPTColor.red()
    lxPlot.identifier = PlotIdentifier.lx as NSString
    lxPlot.zPosition = ZPosition.lxPlot
    lxPlot.dataSource = (self as CPTPlotDataSource)
    lxPlot.delegate = (self as CALayerDelegate)
    lxPlot.dataLineStyle = lxPlotLineStile
    graph.add(lxPlot, to: graph.defaultPlotSpace)
    
    let lyPlot: CPTScatterPlot = CPTScatterPlot()
    let lyPlotLineStile = CPTMutableLineStyle()
    lyPlotLineStile.lineJoin = .round
    lyPlotLineStile.lineCap = .round
    lyPlotLineStile.lineWidth = 2
    lyPlotLineStile.lineColor = CPTColor.blue()
    lyPlot.identifier = PlotIdentifier.ly as NSString
    lyPlot.zPosition = ZPosition.lyPlot
    lyPlot.dataSource = self
    lyPlot.dataLineStyle = lyPlotLineStile
    graph.add(lyPlot, to: graph.defaultPlotSpace)

    let lzPlot: CPTScatterPlot = CPTScatterPlot()
    let lzPlotLineStile = CPTMutableLineStyle()
    lzPlotLineStile.lineJoin = .round
    lzPlotLineStile.lineCap = .round
    lzPlotLineStile.lineWidth = 2
    lzPlotLineStile.lineColor = CPTColor.green()
    lzPlot.identifier = PlotIdentifier.lz as NSString
    lzPlot.zPosition = ZPosition.lzPlot
    lzPlot.dataSource = self
    lzPlot.dataLineStyle = lzPlotLineStile
    graph.add(lzPlot, to: graph.defaultPlotSpace)
    

    guard let rGraph = R_cptGraphHostingView.hostedGraph else { return }

    let rxPlot: CPTScatterPlot = CPTScatterPlot()
    let rxPlotLineStile = CPTMutableLineStyle()
    rxPlotLineStile.lineJoin = .round
    rxPlotLineStile.lineCap = .round
    rxPlotLineStile.lineWidth = 2
    rxPlotLineStile.lineColor = CPTColor.red()
    rxPlot.identifier = PlotIdentifier.rx as NSString
    rxPlot.zPosition = ZPosition.rxPlot
    rxPlot.dataSource = (self as CPTPlotDataSource)
    rxPlot.delegate = (self as CALayerDelegate)
    rxPlot.dataLineStyle = rxPlotLineStile
    rGraph.add(rxPlot, to: rGraph.defaultPlotSpace)

    let ryPlot: CPTScatterPlot = CPTScatterPlot()
    let ryPlotLineStile = CPTMutableLineStyle()
    ryPlotLineStile.lineJoin = .round
    ryPlotLineStile.lineCap = .round
    ryPlotLineStile.lineWidth = 2
    ryPlotLineStile.lineColor = CPTColor.blue()
    ryPlot.identifier = PlotIdentifier.ry as NSString
    ryPlot.zPosition = ZPosition.ryPlot
    ryPlot.dataSource = self
    ryPlot.dataLineStyle = ryPlotLineStile
    rGraph.add(ryPlot, to: rGraph.defaultPlotSpace)

    let rzPlot: CPTScatterPlot = CPTScatterPlot()
    let rzPlotLineStile = CPTMutableLineStyle()
    rzPlotLineStile.lineJoin = .round
    rzPlotLineStile.lineCap = .round
    rzPlotLineStile.lineWidth = 2
    rzPlotLineStile.lineColor = CPTColor.green()
    rzPlot.identifier = PlotIdentifier.rz as NSString
    rzPlot.zPosition = ZPosition.rzPlot
    rzPlot.dataSource = self
    rzPlot.dataLineStyle = rzPlotLineStile
    rGraph.add(rzPlot, to: rGraph.defaultPlotSpace)
  }
  
  func L_plotAcc(point: Float){
    if(self.lxPlotData.count >= maxDataPoints){
//      print("L_delete")
      configureGraphAxis()
      configurePlot()
      self.lxPlotData.removeFirst()
      self.lyPlotData.removeFirst()
      self.lzPlotData.removeFirst()
    }
    
    let lxGraph = self.L_cptGraphHostingView.hostedGraph
    let lxPlot = lxGraph?.plot(withIdentifier: PlotIdentifier.lx as NSCopying)
    lxPlot?.insertData(at: UInt(self.lxPlotData.count-1), numberOfRecords: 1)
    
    let lyGraph = self.L_cptGraphHostingView.hostedGraph
    let lyPlot = lyGraph?.plot(withIdentifier: PlotIdentifier.ly as NSCopying)
    lyPlot?.insertData(at: UInt(self.lyPlotData.count-1), numberOfRecords: 1)
    
    let lzGraph = self.L_cptGraphHostingView.hostedGraph
    let lzPlot = lzGraph?.plot(withIdentifier: PlotIdentifier.lz as NSCopying)
    lzPlot?.insertData(at: UInt(self.lzPlotData.count-1), numberOfRecords: 1)
  }
  
  func R_plotAcc(point: Float){
    if(self.rxPlotData.count >= maxDataPoints){
//      print("R_delete")
      configureGraphAxis()
      configurePlot()
      self.rxPlotData.removeFirst()
      self.ryPlotData.removeFirst()
      self.rzPlotData.removeFirst()
    }

    let rxGraph = self.R_cptGraphHostingView.hostedGraph
    let rxPlot = rxGraph?.plot(withIdentifier: PlotIdentifier.rx as NSCopying)
    rxPlot?.insertData(at: UInt(self.rxPlotData.count-1), numberOfRecords: 1)

    let ryGraph = self.R_cptGraphHostingView.hostedGraph
    let ryPlot = ryGraph?.plot(withIdentifier: PlotIdentifier.ry as NSCopying)
    ryPlot?.insertData(at: UInt(self.ryPlotData.count-1), numberOfRecords: 1)

    let rzGraph = self.R_cptGraphHostingView.hostedGraph
    let rzPlot = rzGraph?.plot(withIdentifier: PlotIdentifier.rz as NSCopying)
    rzPlot?.insertData(at: UInt(self.rzPlotData.count-1), numberOfRecords: 1)
  }
  
  override func viewWillAppear() {
    super.viewWillAppear()
    scannerModel.isScanning = true
  }
  
  override func viewWillDisappear() {
    super.viewWillDisappear()
    scannerModel.isScanning = false
  }
  
  
  // MARK: NSTableViewDelegate
  
  func numberOfRows(in tableView: NSTableView) -> Int {
    return scannerModel.items.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MetaWearCell"), owner: nil) as? NSTableCellView else {
      return nil
    }
    
    let device = scannerModel.items[row].device
    let uuid = cell.viewWithTag(1) as! NSTextField
    uuid.stringValue = device.peripheral.identifier.uuidString
    print(device.peripheral.identifier.uuidString)
    
    if let rssiNumber = device.averageRSSI() {
      let rssi = cell.viewWithTag(2) as! NSTextField
      rssi.stringValue = String(Int(rssiNumber.rounded()))
    }
    
    let connected = cell.viewWithTag(3) as! NSTextField
    if device.isConnectedAndSetup {
      connected.stringValue = "Connected!"
      connected.isHidden = false
      L_StreamPopUpButton.addItem(withTitle: device.peripheral.identifier.uuidString)
      R_StreamPopUpButton.addItem(withTitle: device.peripheral.identifier.uuidString)
    } else if scannerModel.items[row].isConnecting {
      connected.stringValue = "Connecting..."
      connected.isHidden = false
    } else {
      connected.isHidden = true
    }
    
    let name = cell.viewWithTag(4) as! NSTextField
    name.stringValue = device.name
    
    //        let signal = cell.viewWithTag(5) as! NSImageView
    //        if let movingAverage = device.averageRSSI() {
    //            if movingAverage < -80.0 {
    //                signal.image = #imageLiteral(resourceName: "wifi_d1")
    //            } else if movingAverage < -70.0 {
    //                signal.image = #imageLiteral(resourceName: "wifi_d2")
    //            } else if movingAverage < -60.0 {
    //                signal.image = #imageLiteral(resourceName: "wifi_d3")
    //            } else if movingAverage < -50.0 {
    //                signal.image = #imageLiteral(resourceName: "wifi_d4")
    //            } else if movingAverage < -40.0 {
    //                signal.image = #imageLiteral(resourceName: "wifi_d5")
    //            } else {
    //                signal.image = #imageLiteral(resourceName: "wifi_d6")
    //            }
    //        } else {
    //            signal.image = #imageLiteral(resourceName: "wifi_not_connected")
    //        }
    
    //    if debug { print("service: ") }
    //    if debug { print(device.peripheral.services) }
    //    if debug {
    //      if device.peripheral.services != nil {
    //        for service in device.peripheral.services! {
    //          print("/** service **/")
    //          print(service)
    //          for characteristic in service.characteristics! {
    //            print(characteristic)
    //          }
    //        }
    //      }
    //    }
    
    //    if debug {
    //      print("/** board **/")
    //      print(device.board!)
    //    }
    
    //    // MARK: (sample) Streaming Gyro
    //
    //    if debug {
    //      if device.peripheral.services != nil {
    //        mbl_mw_gyro_bmi160_set_range(device.board, MBL_MW_GYRO_BMI160_RANGE_125dps)
    //        mbl_mw_gyro_bmi160_set_odr(device.board, MBL_MW_GYRO_BMI160_ODR_100Hz)
    //        mbl_mw_gyro_bmi160_write_config(device.board)
    //
    //        let signal = mbl_mw_gyro_bmi160_get_rotation_data_signal(device.board)!
    ////        if device.peripheral.identifier.uuidString == "225B47EA-926D-428A-AAD9-6FF53F053578" {
    //        if device.peripheral.identifier.uuidString == "9193BC93-E1B9-4B6C-8A6F-5DC3EAD72845" {
    //          mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, obj) in
    //            let gyroscope: MblMwCartesianFloat = obj!.pointee.valueAs()
    //            L_gyroTextBuff = "(L) [gyro]: " + String(obj!.pointee.epoch)
    //              + " / x: " + String(gyroscope.x)
    //              + " / y: " + String(gyroscope.y)
    //              + " / z: " + String(gyroscope.z)
    //          }
    //        } else {
    //          mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, obj) in
    //            let gyroscope: MblMwCartesianFloat = obj!.pointee.valueAs()
    //            R_gyroTextBuff = "(R) [gyro]: " + String(obj!.pointee.epoch)
    //              + " / x: " + String(gyroscope.x)
    //              + " / y: " + String(gyroscope.y)
    //              + " / z: " + String(gyroscope.z)
    //          }
    //        }
    //        mbl_mw_gyro_bmi160_enable_rotation_sampling(device.board)
    //        mbl_mw_gyro_bmi160_start(device.board)
    //
    ////        streamingCleanup[signal] = {
    ////          mbl_mw_gyro_bmi160_stop(self.device.board)
    ////          mbl_mw_gyro_bmi160_disable_rotation_sampling(self.device.board)
    ////          mbl_mw_datasignal_unsubscribe(signal)
    ////        }
    //      }
    //    }
    //
    //    // MARK: (sample) Streaming Acceleration
    //    if debug {
    //      if device.peripheral.services != nil {
    //        print("/** debug **/")
    //        mbl_mw_acc_bosch_set_range(device.board, MBL_MW_ACC_BOSCH_RANGE_2G)
    //        mbl_mw_acc_set_odr(device.board, 100.0)
    //        mbl_mw_acc_bosch_write_acceleration_config(device.board)
    //
    //        let signal = mbl_mw_acc_bosch_get_acceleration_data_signal(device.board)!
    //
    ////        if device.peripheral.identifier.uuidString == "225B47EA-926D-428A-AAD9-6FF53F053578" {
    //        if device.peripheral.identifier.uuidString == "9193BC93-E1B9-4B6C-8A6F-5DC3EAD72845" {
    //          mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, obj) in
    //            let acceleration: MblMwCartesianFloat = obj!.pointee.valueAs()
    //            let format = DateFormatter()
    //            format.dateFormat = "MMddHHmmssSS"
    //            L_accTextBuff = "(L) " + "[acc]: " + String(obj!.pointee.epoch)
    //              + " / x: " + String(acceleration.x)
    //              + " / y: " + String(acceleration.y)
    //              + " / z: " + String(acceleration.z)
    //            let accRecordText: String = format.string(from: Date())
    //              + "," + String(acceleration.x)
    //              + "," + String(acceleration.y)
    //              + "," + String(acceleration.z)
    //            L_raw_accRecordTextBuff = accRecordText
    //            L_accRecordTextBuff = accRecordText
    //            L_freqTextBuff = "---"  // just trigger
    //          }
    //        } else {
    //          mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, obj) in
    //            let acceleration: MblMwCartesianFloat = obj!.pointee.valueAs()
    //            let format = DateFormatter()
    //            format.dateFormat = "MMddHHmmssSS"
    //            R_accTextBuff = "(R) " + "[acc]: " + String(obj!.pointee.epoch)
    //              + " / x: " + String(acceleration.x)
    //              + " / y: " + String(acceleration.y)
    //              + " / z: " + String(acceleration.z)
    //            let accRecordText: String = format.string(from: Date())
    //              + "," + String(acceleration.x)
    //              + "," + String(acceleration.y)
    //              + "," + String(acceleration.z)
    //            R_raw_accRecordTextBuff = accRecordText
    //            R_accRecordTextBuff = accRecordText
    //            R_freqTextBuff = "---"  // just trigger
    //          }
    //        }
    //        mbl_mw_acc_enable_acceleration_sampling(device.board)
    //        mbl_mw_acc_start(device.board)
    //
    ////        streamingCleanup[signal] = {
    ////          mbl_mw_acc_stop(self.device.board)
    ////          mbl_mw_acc_disable_acceleration_sampling(self.device.board)
    ////          mbl_mw_datasignal_unsubscribe(signal)
    ////        }
    //      }
    //    }
    
    //    // MARK: (sample) Read Temperature???
    //    if debug && device.isConnectedAndSetup {
    //      let source = mbl_mw_multi_chnl_temp_get_source(device.board, UInt8(MBL_MW_TEMPERATURE_SOURCE_PRESET_THERM.rawValue))
    //      let selected = mbl_mw_multi_chnl_temp_get_temperature_data_signal(device.board, UInt8(MBL_MW_TEMPERATURE_SOURCE_PRESET_THERM.rawValue))!
    //      selected.read().continueOnSuccessWith(.mainThread) { obj in
    //        print(String(format: "%.1f°C", (obj.valueAs() as Float)))
    //      }
    //    }
    
    //    // MARK: (sample) Control LED???
    //    device.connectAndSetup().continueWith { t in
    //      var pattern = MblMwLedPattern()
    //      mbl_mw_led_load_preset_pattern(&pattern, MBL_MW_LED_PRESET_PULSE)
    //      mbl_mw_led_stop_and_clear(device.board)
    //      mbl_mw_led_write_pattern(device.board, &pattern, MBL_MW_LED_COLOR_GREEN)
    //      mbl_mw_led_play(device.board)
    //    }
    
    return cell
  }
  
  @objc func tableViewDoubleClick(sender: AnyObject) {
    let device = scannerModel.items[tableView.clickedRow].device
    guard !device.isConnectedAndSetup else {
      device.flashLED(color: .red, intensity: 1.0, _repeat: 3)
      mbl_mw_debug_disconnect(device.board)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        self.tableView.reloadData()
      }
      L_StreamPopUpButton.removeItem(withTitle: device.peripheral.identifier.uuidString)
      R_StreamPopUpButton.removeItem(withTitle: device.peripheral.identifier.uuidString)
      return
    }
    scannerModel.items[tableView.clickedRow].toggleConnect()
    tableView.reloadData()
  }
  
  @IBAction func L_streamButtonPressed(_ sender: NSButton) {
    var device = scannerModel.items[0].device
    for i in 0...scannerModel.items.count {
      device = scannerModel.items[i].device
      if L_StreamPopUpButton.titleOfSelectedItem == device.peripheral.identifier.uuidString { break }
    }
    
    // MARK: (sample) Streaming Gyro
    DispatchQueue.global().async {
      if device.peripheral.services != nil {
        mbl_mw_gyro_bmi160_set_range(device.board, MBL_MW_GYRO_BOSCH_RANGE_125dps)
//        mbl_mw_gyro_bmi160_set_odr(device.board, MBL_MW_GYRO_BMI160_ODR_100Hz)
        mbl_mw_gyro_bmi160_write_config(device.board)
        
        let signal = mbl_mw_gyro_bmi160_get_rotation_data_signal(device.board)!
        mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, obj) in
          let gyroscope: MblMwCartesianFloat = obj!.pointee.valueAs()
          L_gyroTextBuff = "(L) [gyro]: " + String(obj!.pointee.epoch)
            + " / x: " + String(gyroscope.x)
            + " / y: " + String(gyroscope.y)
            + " / z: " + String(gyroscope.z)
        }
        mbl_mw_gyro_bmi160_enable_rotation_sampling(device.board)
        mbl_mw_gyro_bmi160_start(device.board)
      }
    }
    
    // MARK: (sample) Streaming Acceleration
    DispatchQueue.global().async {
      if device.peripheral.services != nil {
//        mbl_mw_acc_bosch_set_range(device.board, MBL_MW_ACC_BOSCH_RANGE_2G)
//        mbl_mw_acc_bosch_set_range(device.board, MBL_MW_ACC_BOSCH_RANGE_4G)
        mbl_mw_acc_bosch_set_range(device.board, MBL_MW_ACC_BOSCH_RANGE_8G)
//        mbl_mw_acc_bosch_set_range(device.board, MBL_MW_ACC_BOSCH_RANGE_16G)
      mbl_mw_acc_set_odr(device.board, 100.0)
      mbl_mw_acc_bosch_write_acceleration_config(device.board)
      
      let signal = mbl_mw_acc_bosch_get_acceleration_data_signal(device.board)!
      
      mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, obj) in
        let acceleration: MblMwCartesianFloat = obj!.pointee.valueAs()
        let format = DateFormatter()
        format.dateFormat = "MMddHHmmssSS"
        L_accTextBuff = "(L) " + "[acc]: " + String(obj!.pointee.epoch)
          + " / x: " + String(acceleration.x)
          + " / y: " + String(acceleration.y)
          + " / z: " + String(acceleration.z)
        let accRecordText: String = String(Int(NSDate().timeIntervalSince1970 * 1000.0))
          + "," + String(acceleration.x)
          + "," + String(acceleration.y)
          + "," + String(acceleration.z)
//        let accRecordText: String = format.string(from: Date())
//          + "," + String(acceleration.x)
//          + "," + String(acceleration.y)
//          + "," + String(acceleration.z)
        L_raw_accRecordTextBuff = accRecordText
        L_accRecordTextBuff = accRecordText
        L_freqTextBuff = "---"  // just trigger
        L_accXPlotValueBuff = acceleration.x
        L_accYPlotValueBuff = acceleration.y
        L_accZPlotValueBuff = acceleration.z
      }
      
      mbl_mw_acc_enable_acceleration_sampling(device.board)
      mbl_mw_acc_start(device.board)
    }
  }
}

@IBAction func R_streamButtonPressed(_ sender: NSButton) {
  var device = scannerModel.items[0].device
  for i in 0...scannerModel.items.count {
    device = scannerModel.items[i].device
    if R_StreamPopUpButton.titleOfSelectedItem == device.peripheral.identifier.uuidString { break }
  }
  
  // MARK: (sample) Streaming Gyro
  DispatchQueue.global().async {
    if device.peripheral.services != nil {
      mbl_mw_gyro_bmi160_set_range(device.board, MBL_MW_GYRO_BOSCH_RANGE_125dps)
//        mbl_mw_gyro_bmi160_set_odr(device.board, MBL_MW_GYRO_BMI160_ODR_100Hz)
      mbl_mw_gyro_bmi160_write_config(device.board)
      
      let signal = mbl_mw_gyro_bmi160_get_rotation_data_signal(device.board)!
      mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, obj) in
        let gyroscope: MblMwCartesianFloat = obj!.pointee.valueAs()
        R_gyroTextBuff = "(R) [gyro]: " + String(obj!.pointee.epoch)
          + " / x: " + String(gyroscope.x)
          + " / y: " + String(gyroscope.y)
          + " / z: " + String(gyroscope.z)
      }
      mbl_mw_gyro_bmi160_enable_rotation_sampling(device.board)
      mbl_mw_gyro_bmi160_start(device.board)
    }
  }
  
  // MARK: (sample) Streaming Acceleration
  DispatchQueue.global().async {
    if device.peripheral.services != nil {
//        mbl_mw_acc_bosch_set_range(device.board, MBL_MW_ACC_BOSCH_RANGE_2G)
//        mbl_mw_acc_bosch_set_range(device.board, MBL_MW_ACC_BOSCH_RANGE_4G)
        mbl_mw_acc_bosch_set_range(device.board, MBL_MW_ACC_BOSCH_RANGE_8G)
//        mbl_mw_acc_bosch_set_range(device.board, MBL_MW_ACC_BOSCH_RANGE_16G)
        mbl_mw_acc_set_odr(device.board, 100.0)
        mbl_mw_acc_bosch_write_acceleration_config(device.board)
        
        let signal = mbl_mw_acc_bosch_get_acceleration_data_signal(device.board)!
        
        mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, obj) in
          let acceleration: MblMwCartesianFloat = obj!.pointee.valueAs()
          let format = DateFormatter()
          format.dateFormat = "MMddHHmmssSS"
          R_accTextBuff = "(R) " + "[acc]: " + String(obj!.pointee.epoch)
            + " / x: " + String(acceleration.x)
            + " / y: " + String(acceleration.y)
            + " / z: " + String(acceleration.z)
          let accRecordText: String = String(Int(NSDate().timeIntervalSince1970 * 1000.0))
            + "," + String(acceleration.x)
            + "," + String(acceleration.y)
            + "," + String(acceleration.z)
//          let accRecordText: String = format.string(from: Date())
//            + "," + String(acceleration.x)
//            + "," + String(acceleration.y)
//            + "," + String(acceleration.z)
          R_raw_accRecordTextBuff = accRecordText
          R_accRecordTextBuff = accRecordText
          R_freqTextBuff = "---"  // just trigger
//          R_accYPlotValueBuff = acceleration.y
          R_accXPlotValueBuff = acceleration.x
          R_accYPlotValueBuff = acceleration.y
          R_accZPlotValueBuff = acceleration.z
        }
        
        mbl_mw_acc_enable_acceleration_sampling(device.board)
        mbl_mw_acc_start(device.board)
      }
    }
  }
  
  @IBAction func L_StreamStopButtonPressed(_ sender: NSButton) {
    var device = scannerModel.items[0].device
    for i in 0...scannerModel.items.count {
      device = scannerModel.items[i].device
      if L_StreamPopUpButton.titleOfSelectedItem == device.peripheral.identifier.uuidString { break }
    }
    mbl_mw_acc_stop(device.board)
    mbl_mw_acc_disable_acceleration_sampling(device.board)
    mbl_mw_gyro_bmi160_stop(device.board)
    mbl_mw_gyro_bmi160_disable_rotation_sampling(device.board)
  }
  
  @IBAction func R_StreamStopButtonPressed(_ sender: NSButton) {
    var device = scannerModel.items[0].device
    for i in 0...scannerModel.items.count {
      device = scannerModel.items[i].device
      if R_StreamPopUpButton.titleOfSelectedItem == device.peripheral.identifier.uuidString { break }
    }
    mbl_mw_acc_stop(device.board)
    mbl_mw_acc_disable_acceleration_sampling(device.board)
    mbl_mw_gyro_bmi160_stop(device.board)
    mbl_mw_gyro_bmi160_disable_rotation_sampling(device.board)
  }
  
  @IBAction func recordButtonPressed(_ sender: NSButton) {
    if L_raw_csvMng.isRecording {
      self.L_raw_csvMng.stopRecording()
      self.L_raw_csvMng.saveSensorDataToCsv()
      self.R_raw_csvMng.stopRecording()
      self.R_raw_csvMng.saveSensorDataToCsv()
      self.L_csvMng.stopRecording()
      self.L_csvMng.saveSensorDataToCsv()
      self.R_csvMng.stopRecording()
      self.R_csvMng.saveSensorDataToCsv()
      self.recordButton.title = "START"
    } else {
      self.L_raw_csvMng.setFileNameText(setText: "MMR-left-raw-" + filenameTextField.stringValue)
      self.R_raw_csvMng.setFileNameText(setText: "MMR-right-raw-" + filenameTextField.stringValue)
      self.L_csvMng.setFileNameText(setText: "MMR-left-" + filenameTextField.stringValue)
      self.R_csvMng.setFileNameText(setText: "MMR-right-" + filenameTextField.stringValue)
      self.L_raw_csvMng.startRecording()
      self.R_raw_csvMng.startRecording()
      self.L_csvMng.startRecording()
      self.R_csvMng.startRecording()
      self.recordButton.title = "STOP"
      timestamp = Date()
      self.timerLabel.stringValue = "timer: " + String(NSDate().timeIntervalSince(timestamp))
    }
  }
  
  //  @IBAction func accelerometerBMI160StartStreamPressed(_ sender: Any) {
  //    accelerometerBMI160StartStream.isEnabled = false
  //    accelerometerBMI160StopStream.isEnabled = true
  //    accelerometerBMI160StartLog.isEnabled = false
  //    accelerometerBMI160StopLog.isEnabled = false
  //    updateAccelerometerBMI160Settings()
  //    accelerometerBMI160Data.removeAll()
  //    let signal = mbl_mw_acc_bosch_get_acceleration_data_signal(device.board)!
  //    mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, obj) in
  //      let acceleration: MblMwCartesianFloat = obj!.pointee.valueAs()
  //      let _self: DeviceDetailViewController = bridge(ptr: context!)
  //      DispatchQueue.main.async {
  //        _self.accelerometerBMI160Graph.addX(Double(acceleration.x), y: Double(acceleration.y), z: Double(acceleration.z))
  //      }
  //      // Add data to data array for saving
  //      _self.accelerometerBMI160Data.append((obj!.pointee.epoch, acceleration))
  //    }
  //    mbl_mw_acc_enable_acceleration_sampling(device.board)
  //    mbl_mw_acc_start(device.board)
  //
  //    streamingCleanup[signal] = {
  //      mbl_mw_acc_stop(self.device.board)
  //      mbl_mw_acc_disable_acceleration_sampling(self.device.board)
  //      mbl_mw_datasignal_unsubscribe(signal)
  //    }
  //  }
  //
  //  @IBAction func accelerometerBMI160StopStreamPressed(_ sender: Any) {
  //    accelerometerBMI160StartStream.isEnabled = true
  //    accelerometerBMI160StopStream.isEnabled = false
  //    accelerometerBMI160StartLog.isEnabled = true
  //    let signal = mbl_mw_acc_bosch_get_acceleration_data_signal(device.board)!
  //    streamingCleanup.removeValue(forKey: signal)?()
  //  }
  //
  //  @IBAction func gyroBMI160StartStreamPressed(_ sender: Any) {
  //    gyroBMI160StartStream.isEnabled = false
  //    gyroBMI160StopStream.isEnabled = true
  //    gyroBMI160StartLog.isEnabled = false
  //    gyroBMI160StopLog.isEnabled = false
  //    updateGyroBMI160Settings()
  //    gyroBMI160Data.removeAll()
  //
  //    let signal = mbl_mw_gyro_bmi160_get_rotation_data_signal(device.board)!
  //    mbl_mw_datasignal_subscribe(signal, bridge(obj: self)) { (context, obj) in
  //      let acceleration: MblMwCartesianFloat = obj!.pointee.valueAs()
  //      let _self: DeviceDetailViewController = bridge(ptr: context!)
  //      DispatchQueue.main.async {
  //        // TODO: Come up with a better graph interface, we need to scale value
  //        // to show up right
  //        _self.gyroBMI160Graph.addX(Double(acceleration.x * 0.008), y: Double(acceleration.y * 0.008), z: Double(acceleration.z * 0.008))
  //      }
  //      // Add data to data array for saving
  //      _self.gyroBMI160Data.append((obj!.pointee.epoch, acceleration))
  //    }
  //    mbl_mw_gyro_bmi160_enable_rotation_sampling(device.board)
  //    mbl_mw_gyro_bmi160_start(device.board)
  //
  //    streamingCleanup[signal] = {
  //      mbl_mw_gyro_bmi160_stop(self.device.board)
  //      mbl_mw_gyro_bmi160_disable_rotation_sampling(self.device.board)
  //      mbl_mw_datasignal_unsubscribe(signal)
  //    }
  //  }
  //
  //  @IBAction func gyroBMI160StopStreamPressed(_ sender: Any) {
  //    gyroBMI160StartStream.isEnabled = true
  //    gyroBMI160StopStream.isEnabled = false
  //    gyroBMI160StartLog.isEnabled = true
  //    let signal = mbl_mw_gyro_bmi160_get_rotation_data_signal(device.board)!
  //    streamingCleanup.removeValue(forKey: signal)?()
  //  }
}

extension ViewController: ScannerModelDelegate {
  func scannerModel(_ scannerModel: ScannerModel, didAddItemAt idx: Int) {
    //    if debug { print("Found!! - index: " + String(idx)) }
    tableView.reloadData()
  }
  
  func scannerModel(_ scannerModel: ScannerModel, confirmBlinkingItem item: ScannerModelItem, callback: @escaping (Bool) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      callback(true)
      self.tableView.reloadData()
    }
  }
  
  func scannerModel(_ scannerModel: ScannerModel, errorDidOccur error: Error) {
  }
}

extension ViewController: CPTScatterPlotDataSource, CPTScatterPlotDelegate {
  func numberOfRecords(for plot: CPTPlot) -> UInt {
    return UInt(self.maxDataPoints)
  }
  
  func number(for plot: CPTPlot, field: UInt, record: UInt) -> Any? {
    switch CPTScatterPlotField(rawValue: Int(field))! {
    case .X:
      return NSNumber(value: Int(record))
    case .Y:
      if plot.identifier!.isEqual(PlotIdentifier.lx) { return self.lxPlotData[Int(record)] as NSNumber }
      if plot.identifier!.isEqual(PlotIdentifier.ly) { return self.lyPlotData[Int(record)] as NSNumber }
      if plot.identifier!.isEqual(PlotIdentifier.lz) { return self.lzPlotData[Int(record)] as NSNumber }
      if plot.identifier!.isEqual(PlotIdentifier.rx) { return self.rxPlotData[Int(record)] as NSNumber }
      if plot.identifier!.isEqual(PlotIdentifier.ry) { return self.ryPlotData[Int(record)] as NSNumber }
      if plot.identifier!.isEqual(PlotIdentifier.rz) { return self.rzPlotData[Int(record)] as NSNumber }
      return 0.0 as NSNumber
    default:
      return 0
    }
  }
}
