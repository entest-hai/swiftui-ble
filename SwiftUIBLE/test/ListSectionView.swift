//
//  ListSectionView.swift
//  SwiftUIBLE
//
//  Created by hai on 28/1/21.
//  Copyright © 2021 biorithm. All rights reserved.
//  28 JAN 2021 test dynamic list with section
//  - Full screen sheet model 

import SwiftUI
import CoreBluetooth

struct ListSectionView: View {
    @Binding var isPresented: Bool
    var services = [Service(id: CBUUID(string: "ABC1"), characteristics: [CBUUID(string: "123A")]),
                    Service(id: CBUUID(string: "ABC2"), characteristics: [CBUUID(string: "123B")]),
                    Service(id: CBUUID(string: "ABC3"), characteristics: [CBUUID(string: "123C")])]
    var body: some View {
        NavigationView{
            List{
                ForEach(self.services){service in
                    Section(header: Text("Service-\(service.id)")) {
                        ForEach(service.characteristics, id: \.self){characteristic in
                            Text("Characteristic-\(characteristic)")
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Services"))
            .navigationBarItems(trailing: Button(action: {self.isPresented.toggle()}){
                Text("Done")
                    .bold()
            })
        }
    }
}

struct TestHomeView : View {
    @State var isPresented: Bool = false
    var body: some View {
        Button(action: {self.didTapButton()}){
            Text("Scan")
                .frame(width: 300, height: 50)
                .background(Color.green.opacity(0.8))
                .foregroundColor(Color.white)
                .cornerRadius(12)
        }
        .sheet(isPresented: self.$isPresented){
            ListSectionView(isPresented: self.$isPresented)
        }
    }
    
    func didTapButton(){
        self.isPresented.toggle()
    }
}

struct TestFullSceenView : View {
    @State var isPresented: Bool = false
    var body: some View {
        ZStack {
            NavigationView {
                Button(action: {
                    withAnimation {
                        self.didTapButton()
                    }
                    
                }){
                    Text("Scan")
                        .frame(width: 300, height: 50)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(Color.white)
                        .cornerRadius(12)
                }
                .navigationBarTitle(Text("Title"))
                .navigationBarItems(leading: Button(action: {}){
                    Text("Scan")
                })
            }
            
            ZStack {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        HStack {
                            ListSectionView(isPresented: self.$isPresented)
                        }
                    }
                    .padding(.top,
                             UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.safeAreaInsets.top)
                    
                    Spacer()
                }
            }.background(Color.white)
                .edgesIgnoringSafeArea(.all)
                .offset(x: 0,
                        y: self.isPresented ? 0 : UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.frame.height ?? 0)
        }
    }
    
    func didTapButton(){
        self.isPresented.toggle()
    }
}
