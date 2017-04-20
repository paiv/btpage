//
//  ViewController.swift
//  btpage
//
//  Created by Pavel Ivashkov on 2017-04-20.
//

import CoreBluetooth
import UIKit


class ViewController: UIViewController {
    
    let testDeviceIdentifier = "FE2B48EF-828E-41DF-B38E-41C5AA75CD3C"

    @IBOutlet weak var textView: UITextView!
    
    var centralManager: CBCentralManager!
    var device: CBPeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.text = ""
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func doScan() {
        log("start scanning")
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false, block: { [weak self] _ in
            self?.centralManager.stopScan()
            self?.log("stop scanning")
        })
    }
    
    func doQuery(peripheral identifier: UUID) {
        guard let peripheral = centralManager.retrievePeripherals(withIdentifiers: [identifier]).first else {
            log("no peripheral found for \(identifier)")
            return
        }
        
        peripheral.delegate = self
        device = peripheral
        
        log("connecting to \(peripheral.identifier)")
        centralManager.connect(peripheral, options: nil)
    }
    
    func log(_ text: String) {
        let now = ViewController.formatter.string(from: Date())
        let line = "\(now) \(text)"
        textView?.text = [textView?.text, line] .flatMap {$0} .joined(separator: "\n")
    }
    
    class var formatter: DateFormatter {
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        return fmt
    }
}


extension ViewController : CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            
        case .poweredOn:
            #if true
                doQuery(peripheral: UUID(uuidString: testDeviceIdentifier)!)
            #else
                doScan()
            #endif
            
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        log("discovered \"\(peripheral.name ?? "(noname)")\" \(peripheral.identifier.uuidString)")
        print("discovered \(peripheral.identifier.uuidString)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("connected to \(peripheral.identifier)")
        
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("failed connecting to \(peripheral.identifier): \(error?.localizedDescription ?? "(no error)")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log("disconnected from \(peripheral.identifier)")
        
        device = nil
    }

}


extension ViewController : CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            log("failed to discover services on \(peripheral.identifier): \(error)")
            return
        }
        
        log("discovered services on \(peripheral.identifier): \(peripheral.services ?? [])")
        
        log("disconnecting from \(peripheral.identifier)")
        centralManager.cancelPeripheralConnection(peripheral)
    }
}
