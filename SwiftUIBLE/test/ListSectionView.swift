//
//  ListSectionView.swift
//  SwiftUIBLE
//
//  Created by hai on 28/1/21.
//  Copyright © 2021 biorithm. All rights reserved.
//  28 JAN 2021 test dynamic list with section 

import SwiftUI
import CoreBluetooth

struct ListSectionView: View {
    var services = [Service(id: CBUUID(string: "ABC1"), characteristics: [CBUUID(string: "123A")]),
                    Service(id: CBUUID(string: "ABC2"), characteristics: [CBUUID(string: "123B")]),
                    Service(id: CBUUID(string: "ABC3"), characteristics: [CBUUID(string: "123C")])]
    var body: some View {
        List{
            ForEach(self.services){service in
                Section(header: Text("Service-\(service.id)")) {
                    ForEach(service.characteristics, id: \.self){characteristic in
                        Text("Characteristic-\(characteristic)")
                    }
                }
            }
        }
    }
}
