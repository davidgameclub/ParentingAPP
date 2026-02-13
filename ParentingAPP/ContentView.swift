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
    
    // MARK: - State Properties
    @State private var name: String = ""
    @State private var navigateToNameEntry: Bool = false
    @State private var navigateToGender: Bool = false
    @State private var showCelebration: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var didAttemptAutoNavigation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6).ignoresSafeArea()
                
                Group {
                    if let profile = profiles.first {
                        List {
                            Section("寶寶資料") {
                                LabeledContent("暱稱", value: profile.name ?? "未設定")
                                LabeledContent("性別", value: profile.gender ?? "未設定")
                                // 使用指定的 Locale 確保日期顯示為「年月日」中文格式
                                if let birthDate = profile.birthDate {
                                    LabeledContent("生日", value: birthDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "zh_Hant_TW"))))
                                } else {
                                    LabeledContent("生日", value: "未設定")
                                }
                            }
                            
                            Section {
                                Button {
                                    navigateToHome = true
                                } label: {
                                    Text("進入主選單")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                }
                                .foregroundColor(.accentColor)
                            }
                            
                            Section {
                                Button(role: .destructive) {
                                    deleteProfile(profile)
                                } label: {
                                    Text("刪除並重新建立")
                                        .frame(maxWidth: .infinity)
                                }
                            } footer: {
                                Text("若要修改資料，您必須先刪除目前的檔案。")
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .onAppear {
                            if !didAttemptAutoNavigation {
                                didAttemptAutoNavigation = true
                                // 使用 async 確保在 View 更新週期結束後才修改狀態
                                DispatchQueue.main.async {
                                    navigateToHome = true
                                }
                            }
                        }
                    } else {
                        RegistrationView {
                            navigateToNameEntry = true
                        }
                    }
                }
                
                // 慶祝特效層
                if showCelebration {
                    FireworksView()
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $navigateToHome) {
                MainFenuView()
            }
            .navigationDestination(isPresented: $navigateToNameEntry) {
                BabyNameView { enteredName in
                    self.name = enteredName
                    self.navigateToGender = true
                }
            }
            .navigationDestination(isPresented: $navigateToGender) {
                GenderView(name: name) {
                    name = ""
                    navigateToGender = false
                    
                    // 觸發煙火邏輯
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            showCelebration = true
                        }
                        // 持續時間改為 1.0 秒
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showCelebration = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func deleteProfile(_ profile: UserProfile) {
        withAnimation {
            viewContext.delete(profile)
            do {
                try viewContext.save()
                // 重置導航狀態，確保刪除後回到註冊流程
                didAttemptAutoNavigation = false
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - RegistrationView
struct RegistrationView: View {
    var onRegister: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("歡迎")
                    .font(.title)
                    .foregroundStyle(.black)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemGray5))
            
            Spacer()
            
            VStack(spacing: 24) {
                Button(action: {
                    onRegister()
                }) {
                    Text("註冊帳號")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }
                
                Button(action: {
                    // 未來實作共享代碼邏輯
                }) {
                    Text("使用共享代碼")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }
            }
            .padding(.horizontal, 60)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - BabyNameView
struct BabyNameView: View {
    @State private var name: String = ""
    var onNext: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("設定寶寶資料")
                    .font(.title)
                    .foregroundStyle(.black)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemGray5))
            
            Spacer()
            
            VStack(spacing: 36) {
                Text("寶寶暱稱")
                    .font(.title2)
                    .bold()
                
                VStack(spacing: 12) {
                    TextField("輸入", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .padding(.horizontal, 60)
                    
                    Text("請輸入寶寶暱稱或乳名")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Button(action: {
                    if !name.isEmpty {
                        onNext(name)
                    }
                }) {
                    Text("下一步")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(name.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }
                .disabled(name.isEmpty)
                .padding(.horizontal, 120)
            }
            
            Spacer()
            Spacer()
        }
        .navigationTitle("暱稱設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - GenderView
struct GenderView: View {
    let name: String
    var onComplete: () -> Void
    
    @State private var selectedGender: String = "男生"
    @State private var navigateToBirth = false
    let genders = ["男生", "女生"]
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Text("歡迎，\(name)")
                    .font(.title2)
                    .bold()
                
                Text("請選擇寶寶性別")
                    .foregroundColor(.secondary)
                
                Picker("Gender", selection: $selectedGender) {
                    ForEach(genders, id: \.self) { gender in
                        Text(gender).tag(gender)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                
                Button(action: { navigateToBirth = true }) {
                    Text("下一步")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .navigationTitle("性別設定")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToBirth) {
            BirthView(name: name, gender: selectedGender, onComplete: onComplete)
        }
    }
}

// MARK: - BirthView
struct BirthView: View {
    let name: String
    let gender: String
    var onComplete: () -> Void
    
    @State private var birthDate = Date()
    @State private var navigateToSummary = false
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Text("寶寶什麼時候出生的？")
                    .font(.title2)
                    .bold()
                
                DatePicker(
                    "Birthday",
                    selection: $birthDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_Hant_TW"))
                .frame(height: 200)
                
                Button(action: { navigateToSummary = true }) {
                    Text("下一步：確認總覽")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .navigationTitle("出生日期")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSummary) {
            SummaryView(name: name, gender: gender, birthDate: birthDate, onComplete: onComplete)
        }
    }
}

// MARK: - SummaryView
struct SummaryView: View {
    let name: String
    let gender: String
    let birthDate: Date
    var onComplete: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("寶寶資料總覽")
                    .font(.title)
                    .foregroundStyle(.black)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemGray5))
            
            List {
                Section {
                    LabeledContent("暱稱", value: name)
                    LabeledContent("性別", value: gender)
                    LabeledContent("生日", value: birthDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "zh_Hant_TW"))))
                } header: {
                    Text("請確認以下資料是否正確")
                }
            }
            .scrollContentBackground(.hidden)
            
            VStack(spacing: 16) {
                Button(action: saveProfile) {
                    Text("確認並儲存")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 60)
                
                Text("儲存後，若要修改需刪除後重新建立。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .navigationTitle("總覽")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveProfile() {
        let newProfile = UserProfile(context: viewContext)
        newProfile.name = name
        newProfile.gender = gender
        newProfile.birthDate = birthDate
        newProfile.createdAt = Date()
        
        do {
            try viewContext.save()
            onComplete()
        } catch {
            print("無法儲存設定: \(error)")
        }
    }
}

// MARK: - FireworksView
struct FireworksView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height + 10)
        emitter.emitterShape = .point
        emitter.emitterSize = CGSize(width: 1, height: 1)
        
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemYellow, .systemGreen, .systemPink, .systemPurple, .systemOrange]
        
        let cells = colors.map { color -> CAEmitterCell in
            let cell = CAEmitterCell()
            cell.birthRate = 60
            cell.lifetime = 1.5
            cell.velocity = CGFloat.random(in: 400...600)
            cell.velocityRange = 50
            cell.emissionLongitude = -.pi / 2
            cell.emissionRange = 2.0
            cell.spin = 1
            cell.spinRange = 5
            cell.scale = 0.05
            cell.scaleRange = 0.1
            cell.alphaSpeed = -0.3
            cell.color = color.cgColor
            cell.contents = createConfettiImage()?.cgImage
            return cell
        }
        
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    private func createConfettiImage() -> UIImage? {
        let size = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(CGRect(x: 2, y: 2, width: size.width - 4, height: size.height - 4))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
