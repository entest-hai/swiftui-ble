//
//  ContentView.swift
//  SwiftUIBLE
//
//  Created by hai on 26/1/21.
//  Copyright © 2021 biorithm. All rights reserved.
//  26 JAN 2021 scan BLE with swiftui
//  - need override init() to create CBCentralManager()
//  - implement CBCentralManagerDelegate with
// 27 JAN 2021 select a peripheral then connect
//  - select a peripheral
//  - connect a peripheral
//  - discover services
//  - list show services 
// 28 JAN 2021 list section
//  - service session
//  - characteristics within a session
//  - TODO: isConnectable?
// 31 JAN 2021 BLEPeripheral delegate
//  - self.blePeripheral = device
//  - self.blePeripheral.delegate = self
//  - didDiscoverServices
//  - didDiscoverCharacteristics
//  - didReadRSSI
// 02 FEB 2021 how BLE read value for a characteristic
//  - check permission characteristic.properties.contains(.read)
//  - update didUpdateValue For Characteristic
//  - append characteristic to sot.readingCharacteristicBuffer[CBCharacteristic]
//  - list to show reading characteristic buffer 

import Foundation
import SwiftUI
import CoreBluetooth

extension CBPeripheral : Identifiable {
    
}

extension CBService: Identifiable {
    
}

struct Service {
    let id: CBUUID
    var characteristics: [CBUUID]
}

extension Service: Identifiable {
    
}

extension CBCharacteristic: Identifiable {
    
}

struct ConnectedCharacteristicView: View {
    @Binding var isPresented: Bool
    @ObservedObject var sot: BLEManager
    var body: some View {
        NavigationView{
            VStack{
                List{
                    Section(header: Text("\(self.sot.interestedCharacteristic.uuid)-\(String(self.sot.interestedCharacteristic.uuid.uuidString.prefix(6)))").lineLimit(1)){
                        ForEach(self.sot.readingCharacteristicBuffer){char in
                            Text("\(char)")
                        }
                    }
                }
                Button(action: {
                    self.sot.readCharacteristic(characteristic: self.sot.interestedCharacteristic)
                }){
                    Text("Read")
                        .frame(width: 200, height: 50)
                        .background(Color.green)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                }
            }
            .navigationBarItems(trailing: Button(action: {
                self.isPresented.toggle()
            }){
                Text("Done")
            })
        }
    }
}

// TODO refactor to use sot directly without services=[Service]
struct ConnectedDeviceView: View {
    @ObservedObject var sot: BLEManager
    @Binding var isPresented: Bool
    @State var isPresentedCharacteristicView: Bool = false
    var body: some View {
        NavigationView{
            List{
                ForEach(self.sot.gatProfile){ service in
                    Section(header: Text("\(String(service.uuid.uuidString.prefix(6)))-\(service.uuid)").lineLimit(1)){
                        ForEach(service.characteristics ?? [], id: \.self){characteristic in
                            Text("\(characteristic.uuid.uuidString)-\(characteristic.uuid)")
                                .lineLimit(1)
                                .onTapGesture {
                                    self.sot.interestedCharacteristic = characteristic
                                    self.sot.readingCharacteristicBuffer.removeAll()
                                    self.isPresentedCharacteristicView.toggle()
                            }
                            .sheet(isPresented: self.$isPresentedCharacteristicView){
                                ConnectedCharacteristicView(isPresented: self.$isPresentedCharacteristicView,
                                                            sot: self.sot)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text("\(self.sot.connectedPeripheral != nil ? "\(String(self.sot.connectedPeripheral.identifier.uuidString.prefix(4))) - \(self.sot.connectedPeripheral.name ?? "")" : "Unknown")"))
            .navigationBarItems(trailing: Button(action: {
                // TODO cancel connection and clean GAT
                self.isPresented.toggle()
            }){
                Text("Done")
            })
        }
    }
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let sampleServiceUUID = CBUUID(string: "180F")
    let sampledPeripheralUUID = CBUUID(string: "69BDBEDB-0998-48F5-9456-3EB055408B9E")
    @Published var peripherals = [CBPeripheral]()
    @Published var isSwitchedOn = false
    @Published var isScanning = false
    @Published var isConnectedDevice = false
    @Published var gatProfile = [CBService]()
    @Published var readingCharacteristicBuffer = [CBCharacteristic]()
    var readCharacteristicValue: String = ""
    var readCharacteristicHex: String = ""
    var interestedCharacteristic: CBCharacteristic!
    var characteristicDescription = [String]()
    var permissions = [String]()
    var myCentral: CBCentralManager!
    var connectedPeripheral: CBPeripheral!
    
    override init() {
        super.init()
        myCentral = CBCentralManager(delegate: self, queue: nil)
        myCentral.delegate = self
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isSwitchedOn = true
            print("BLE power on")
            // Classic Bluetooth 2019
            //            let matchingOptions = [CBConnectionEventMatchingOption.serviceUUIDs: [sampleServiceUUID]]
            //            self.myCentral?.registerForConnectionEvents(options: matchingOptions)
        }
        else {
            isSwitchedOn = false
            print("BLE power off")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        connectionEventDidOccur event: CBConnectionEvent,
                        for peripheral: CBPeripheral) {
        switch event {
        case .peerConnected:
            print("connected to \(peripheral)")
            self.connectDevice(device: peripheral)
            
        default:
            print("No interested")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        var peripheralFound = false
        for blePeripheral in peripherals {
            if blePeripheral.identifier == peripheral.identifier {
                peripheralFound = true
                break
            }
        }
        
        if !peripheralFound {
            print(peripheral)
            peripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to \(peripheral.name ?? "unknown")")
        peripheral.readRSSI()
        peripheral.discoverServices(nil)
        //
        self.isConnectedDevice = true
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("RSSI \(RSSI)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Discover service")
        
        if  error != nil  {
            print("Discover service error")
        } else {
            for service in peripheral.services! {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("service \(service)")
        gatProfile.append(service)
        
        if let characteristics  = service.characteristics {
            print("Discover \(characteristics.count) characteristic")
            for characteristic in characteristics {
                print("--> \(characteristic.uuid.uuidString)")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("Read value from BLE Characteristic \(characteristic)")
        self.readingCharacteristicBuffer.append(characteristic)
        
        if let value = characteristic.value {
            if let stringValue = String(data: value, encoding: .ascii) {
                self.readCharacteristicValue = stringValue
            }
            
            if characteristic.uuid == CBUUID(string: "0x2A19") {
                self.readCharacteristicValue = "\(characteristic.value![0])"
            }

            let charSet = CharacterSet(charactersIn: "<>")
            let nsdataStr = NSData.init(data: value)
            let valueHex = nsdataStr.description.trimmingCharacters(in:charSet).replacingOccurrences(of: " ", with: "")
            self.readCharacteristicHex = "0x\(valueHex)"
        }
    }
    
    func scan(){
        print("start scanning ")
        self.isScanning = true
        myCentral.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScanning() {
        print("stopScanning")
        self.isScanning = false
        self.myCentral.stopScan()
    }
    
    func connectDevice(device: CBPeripheral) {
        self.myCentral?.stopScan()
        self.connectedPeripheral =  device
        self.connectedPeripheral.delegate = self
        self.gatProfile.removeAll()
        self.myCentral?.connect(device, options: nil)
    }
    
    func readCharacteristic(characteristic: CBCharacteristic){
        if characteristic.properties.contains(.read) {
            print("read charac \(characteristic.uuid): properities contains .read")
            self.connectedPeripheral?.readValue(for: characteristic)
        }
        if characteristic.properties.contains(.notify) {
            print("read charac \(characteristic.uuid): properties contain .notify")
            self.connectedPeripheral?.setNotifyValue(true, for: characteristic)
        }
    }
}

struct BLEPeripheralTableView : View {
    @ObservedObject var sot = BLEManager()
    @State var isConnectedDevice = false
    @State var connectedDevice: CBPeripheral!
    var body: some View {
        NavigationView{
            ZStack{
                NavigationLink(destination: ConnectedDeviceView(sot: self.sot, isPresented: self.$isConnectedDevice),
                               isActive: self.$isConnectedDevice){
                                EmptyView()}
                List(self.sot.peripherals){device in
                    HStack{
                        Text("uuid: \(String(device.identifier.uuidString.prefix(4))) -name:\(String(device.name?.prefix(6) ?? "Unknow")) -rssi:")
                            .lineLimit(1)
                        Spacer()
                        Button(action: {}){
                            Text("Connect")
                                .frame(width: 80, height: 30)
                                .background(Color.green)
                                .foregroundColor(Color.white)
                                .cornerRadius(5)
                                .gesture(TapGesture().onEnded({self.didTapConnectButton(device: device)}))
                        }
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
    
    func didTapConnectButton(device: CBPeripheral){
        self.isConnectedDevice = true
        self.connectedDevice = device
        self.sot.connectDevice(device: device)
    }
}

struct BLEPeripheralTableViewTest : View {
    @ObservedObject var sot = BLEManager()
    @State var isConnectedDevice = false
    @State var connectedDevice: CBPeripheral!
    var body: some View {
        ZStack {
            NavigationView{
                ZStack{
                    List(self.sot.peripherals){device in
                        HStack{
                            Text("uuid: \(String(device.identifier.uuidString.prefix(4))) -name:\(String(device.name?.prefix(6) ?? "Unknow")) -rssi:")
                                .lineLimit(1)
                            Spacer()
                            Button(action: {}){
                                Text("Connect")
                                    .frame(width: 80, height: 30)
                                    .background(Color.green)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(5)
                                    .gesture(TapGesture().onEnded({self.didTapConnectButton(device: device)}))
                            }
                        }
                    }
                }
                .navigationBarTitle(Text("BLE"))
                .navigationBarItems(trailing: Button(action: {
                    //                    self.isConnectedDevice.toggle()
                    self.scanBLEDevices()
                    
                }){
                    Text(self.sot.isScanning ? "stop" : "scan" )
                })
            }
            ZStack {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        HStack {
                            //                            ListSectionView(isPresented: self.$isConnectedDevice)
                            ConnectedDeviceView(sot: self.sot, isPresented: self.$isConnectedDevice)
                        }
                    }
                    .padding(.top,
                             UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.safeAreaInsets.top)
                    
                    Spacer()
                }
            }.background(Color.white)
                .edgesIgnoringSafeArea(.all)
                .offset(x: 0,
                        y: self.isConnectedDevice ? 0 : UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.frame.height ?? 0)
        }
        
    }
    
    func scanBLEDevices(){
        self.sot.isScanning ? self.sot.stopScanning() : self.sot.scan()
    }
    
    func didTapConnectButton(device: CBPeripheral){
        self.isConnectedDevice = true
        self.connectedDevice = device
        self.sot.connectDevice(device: device)
    }
}

struct ContentView: View {
    var body: some View {
        BLEPeripheralTableViewTest()
        //        ListSectionView()
        //        TestHomeView()
        //        TestFullSceenView()
    }
}
