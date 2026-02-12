//
//  ContentView.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // 用來讀取已存在的 UserProfile (如果有的話)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.birthDate, ascending: true)],
        animation: .default)
    private var profiles: FetchedResults<UserProfile>
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
