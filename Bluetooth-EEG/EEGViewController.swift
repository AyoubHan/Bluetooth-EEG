//
//  ViewController.swift
//  Bluetooth-EEG
//
//  Created by AyoubHan on 13/07/2021.
//

import UIKit
import CoreBluetooth
import os

class EEGViewController: UIViewController, CBPeripheralDelegate {

    
    // MARK: - Outlets
    
    
    // MARK: - Private Properties
    
    private var centralManager: CBCentralManager!
    private var savedPeripherals = [CBPeripheral]()
    private var channelsData = TransferService.EEGChannels.data
    private var magnetometerData = TransferService.magnetometer.data
    private var accelerometerData = TransferService.accelerometer.data
    private var gyroscopeData = TransferService.gyroscope.data
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Helpers
    
    func searchForElectroEncephalogram() {
        os_log("Scanning for Electro Encephalogram")
        centralManager.scanForPeripherals(withServices: [TransferService.ElectroEncephalogram], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
    }
    
    func stopScan() {
        centralManager.stopScan()
        os_log("Scanning did stop")
    }
}

// MARK: - Central Manager Delegate

extension EEGViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOn:
            os_log("System is active")
            searchForElectroEncephalogram()
        case .poweredOff:
            os_log("System is inactive")
            stopScan()
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
        case .unauthorized:
            if #available(iOS 13.1, *) {
                switch central.authorization {
                case .denied:
                    os_log("Authorization denied")
                case .restricted:
                    os_log("Bluetooth is restricted")
                default:
                    os_log("Unexpected authorization")
                }
            }
        case .resetting:
            os_log("Connection lost")
            os_log("Reconnection..")
        case .unknown:
            os_log("State is unknown")
        @unknown default:
            os_log("Unknown state occured")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //We first check if the RSSI value allow for data transfer
        //RSSI value should be between -50 & 0 to allow for transfer
        guard RSSI.intValue >= -50 else {
            return os_log("Signal is not strong enough to allow for data transfer, please get closer to the Electro Encephalogram")
        }
        
        os_log("Discovered %s", String(describing: peripheral.name))
        
        //Device is in range, do the system already know it ?
        if savedPeripherals.contains(peripheral) {
            os_log("Connecting to %d", peripheral)
            centralManager.connect(peripheral, options: nil)
        } else {
            os_log("%d is not registered", peripheral)
            os_log("Saving of %d", peripheral)
            //We store a local copy of the Electro Encephalogram
            savedPeripherals.append(peripheral)
            //Then connect to it
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("System is successfully connected to %d", peripheral)
        stopScan()
        
        //We're only want service that match our UUID
        peripheral.discoverServices([TransferService.ElectroEncephalogram])
        
        //We make sure we receive events from the Electro Encephalogram
        peripheral.delegate = self
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        //If we fail to connect we retry a scan for the Electro Encephalogram
        os_log("Failed to connect to %d", peripheral)
        os_log("Cause of failure: %d", String(describing: error))
        
        //We re-launch scanning
        searchForElectroEncephalogram()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        //If peripheral is disconected we launch a scan for peripherals
        os_log("%d have been disconnected. %s", peripheral, String(describing: error))
        searchForElectroEncephalogram()
    }
}

