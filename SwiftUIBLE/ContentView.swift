//
//  ContentView.swift
//  SwiftUIBLE
//
//  Created by hai on 26/1/21.
//  Copyright © 2021 biorithm. All rights reserved.
//  26 JAN 2021 scan BLE with swiftui
//  - need override init() to create CBCentralManager()
//  - implement CBCentralManagerDelegate with

import SwiftUI
import CoreBluetooth

struct Peripheral: Identifiable {
    let id: Int
    let name: String
    let rssi: Int
    let uuid: String
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var peripherals = [Peripheral]()
    @Published var isSwitchedOn = false
    @Published var isScanning = false
    
    var myCentral: CBCentralManager!
    override init() {
        super.init()
        myCentral = CBCentralManager(delegate: self, queue: nil)
        myCentral.delegate = self
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isSwitchedOn = true
            print("BLE power on")
        }
        else {
            isSwitchedOn = false
            print("BLE power off")
        }
    }
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var peripheralName: String!
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            peripheralName = name
        }
        else {
            peripheralName = "Unknown"
        }
        
        let newPeripheral = Peripheral(id: peripherals.count,
                                       name: peripheralName,
                                       rssi: RSSI.intValue,
                                       uuid: peripheral.identifier.uuidString)
        print(newPeripheral)
        peripherals.append(newPeripheral)
    }
    func scan(){
        print("start scanning ")
        self.isScanning = true
                myCentral.scanForPeripherals(withServices: nil, options: nil)
//        self.peripherals.append(Peripheral(id: 1, name: "HeartRate", rssi: 100, uuid: "ABCD"))
    }
    func stopScanning() {
        print("stopScanning")
        self.isScanning = false
        self.myCentral.stopScan()
    }
}

struct BLEPeripheralTableView : View {
    @ObservedObject var sot = BLEManager()
    var body: some View {
        NavigationView{
            List(self.sot.peripherals){device in
                HStack{
                    Text("uuid:\(String(device.uuid.prefix(4)))-name:\(device.name)-rssi:\(device.rssi)")
                        .lineLimit(1)
                    Spacer()
                    Button(action: {self.didTapConnectButton()}){
                        Text("Connect")
                            .frame(width: 80, height: 30)
                            .background(Color.green)
                            .foregroundColor(Color.white)
                            .cornerRadius(5)
                    }
                }
            }
            .navigationBarTitle(Text("BLE"))
            .navigationBarItems(trailing: Button(action: {self.scanBLEDevices()}){
                Text(self.sot.isScanning ? "stop" : "scan" )
            })
        }
    }
    
    func scanBLEDevices(){
        self.sot.isScanning ? self.sot.stopScanning() : self.sot.scan()
    }
    
    func didTapConnectButton(){
        print("connect to device")
    }
}

struct ContentView: View {
    var body: some View {
        BLEPeripheralTableView()
    }
}
