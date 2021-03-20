//
//  ContentView.swift
//  Shared
//
//  Created by TAKURO FUKAMIZU on 2021/03/20.
//

import SwiftUI

struct ContentView: View {
    let service = BluetoothService()
    
    @State var textStatus = "Hello"
    
    var body: some View {
        VStack {
            Text(textStatus)
                .padding()
            
            Button(action: {
                // Peripheralをスキャンして接続する
                textStatus = "Scan..."
                service.scanStart {
                    textStatus = "Connected!"
                }
            }){
                Text("Scan")
                   .font(.largeTitle)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 1)
            )
            
            Button(action: {
                // Peripheral にメッセージ送信
                service.sendMessage(message: "hogehoge")
            }){
                Text("Send")
                   .font(.largeTitle)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 1)
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
