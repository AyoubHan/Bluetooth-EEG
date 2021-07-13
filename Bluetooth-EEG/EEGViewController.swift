//
//  ViewController.swift
//  Bluetooth-EEG
//
//  Created by AyoubHan on 13/07/2021.
//

import UIKit
import CoreBluetooth

class EEGViewController: UIViewController {

    var centralManager: CBCentralManager!
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

