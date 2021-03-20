//
//  ViewController.swift
//  ble-central-service
//
//  Created by TAKURO FUKAMIZU on 2021/03/20.
//

import Foundation
import CoreBluetooth




class BluetoothService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
//    let DEVICE_NAME = "BT_SPP_SLAVE"
    let DEVICE_NAME = "BT_SPP_SLAVE2"
    let UUID_VSP_SERVICE = CBUUID(string: "569a1101-b87f-490c-92cb-11ba5ea5167c") //VSP
    let UUID_RX = CBUUID(string: "569a2001-b87f-490c-92cb-11ba5ea5167c") //RX
    let UUID_TX = CBUUID(string: "569a2000-b87f-490c-92cb-11ba5ea5167c") //TX
    
    
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    private var cbPeripheral: CBPeripheral? = nil
    private var txCharacteristic: CBCharacteristic? = nil
    private var rxCharacteristic: CBCharacteristic? = nil
    
    private var connectedCallback: (() -> Void)? = nil

    override init () {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    func scanStart(connectedCallback: @escaping () -> Void) {
        self.connectedCallback = connectedCallback
        if centralManager!.isScanning == false {
            // サービスのUUIDを指定しない
            centralManager!.scanForPeripherals(withServices: nil, options: nil)
            
            // サービスのUUIDを指定する
            // let service: CBUUID = CBUUID(string: "サービスのUUID")
            // centralManager!.scanForPeripherals(withServices: service, options: nil)
        }
    }
    
    //MARK : - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
            case .poweredOff:
                // BLE PoweredOff
                print("BLE PoweredOff")
            case .poweredOn:
                // BLE PoweredOn
                print("BLE PoweredOn")
            case .resetting:
                // BLE Resetting
                print("BLE Resetting")
            case .unauthorized:
                // BLE Unauthorized
                print("BLE Unauthorized")
            case .unknown:
                // BLE Unknown
                print("BLE Unknown")
            case .unsupported:
                // BLE Unsupported
                print("BLE Unsupported")
//        @unknown default:
//            <#fatalError()#>
//            print
        }
    }
    
    /// STEP-1 ペリフェラルを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("find: \(String(describing: peripheral.name))")
        if peripheral.name != nil && peripheral.name == DEVICE_NAME {
//            peripherals.append(peripheral)
            cbPeripheral = peripheral
            centralManager?.stopScan()
            
            centralManager!.connect(cbPeripheral!, options: nil)
        }
    }
    
//    func connect() {
//        for peripheral in peripherals {
//            if peripheral.name != nil && peripheral.name == DEVICE_NAME {
//                cbPeripheral = peripheral
//                centralManager?.stopScan()
//                break;
//            }
//        }
//
//        if cbPeripheral != nil {
//            centralManager!.connect(cbPeripheral!, options: nil)
//        }
//    }
    
    /// STEP-2 接続されると呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        cbPeripheral?.delegate = self
        
        // 指定のサービスを探す
        cbPeripheral!.discoverServices([UUID_VSP_SERVICE])
       
        // すべてのサービスを探す
        // cbPeripheral!.discoverServices(nil)
    }
    
    // 接続が失敗すると呼ばれるデリゲートメソッド
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
       print("connection failed.")
    }
    
    
    //MARK : - CBPeripheralDelegate
    
    /// STEP-3 サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in cbPeripheral!.services! {
            if(service.uuid != UUID_VSP_SERVICE) {
                continue
            }
            
            // サービスが見つかったら、キャラクタリスティックを探す
            cbPeripheral?.discoverCharacteristics([UUID_RX, UUID_TX], for: service)
        }
    }
    
    /// STEP-4 キャリアクタリスティク発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor")
        for characreristic in service.characteristics!{
            print(characreristic.uuid.uuidString)
            // TX
            if characreristic.uuid == UUID_TX {
                print("find TX char: \(characreristic.uuid.uuidString)")
                txCharacteristic = characreristic
                //Notificationを受け取るハンドラ
                peripheral.setNotifyValue(true, for: characreristic)
            }
            // RX
            if characreristic.uuid == UUID_RX {
                print("find RX char: \(characreristic.uuid.uuidString)")
                rxCharacteristic = characreristic
            }
            // 全部揃ったか？
            if txCharacteristic != nil && rxCharacteristic != nil {
                self.connectedCallback!()
            }
        }
    }
    
    /// 接続したRXキャラクタリスティックにメッセージを送信する
    func sendMessage(message: String) {
        guard let chara = rxCharacteristic else {
            print("rxCharacteristic is not found")
            return
        }
        let command = message + "\n"
        let data = command.data(using: String.Encoding.utf8, allowLossyConversion:true)
        cbPeripheral!.writeValue(data! , for: chara, type: .withResponse)
//        cbPeripheral!.writeValue(data! , for: chara, type: .withoutResponse)
    }
    
    /// 接続したTXキャラクタリスティックからメッセージを受信する
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("error \(error)")
            return
        }
        print("received Notification, value = \(String(describing: characteristic.value))")
    }

 
}
