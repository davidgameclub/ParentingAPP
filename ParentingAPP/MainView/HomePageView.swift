//
//  HomePageView.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//

import SwiftUI
import CoreData

// 全域顏色常數
let appDeepGray = Color(red: 0.12, green: 0.12, blue: 0.14)

// 全域狀態管理類別 (Global State Class)
@Observable
class AppState {
    var currentDate: Date
    
    init() {
        // 初始化為今天的 00:00
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        self.currentDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: today)!
    }
}

// 用於計算位置的輔助結構
struct PositionedActivityItem: Identifiable {
    let id: NSManagedObjectID
    let item: ActivityItem
    let y: CGFloat
    var elapsedString: String? = nil // 存儲過往時間字串
}

// 用於包裝不同活動的 Identifiable 類型
enum ActivityItem: Identifiable {
    case wakeup(WakeupActivity)
    case sleep(SleepActivity)
    case custom(CustomActivity)
    case feeding(FeedingBottleActivity)
    case diaper(DiaperActivity)
    case breastFeeding(BreastFeedingActivity) // 新增：親餵
    
    var id: NSManagedObjectID {
        switch self {
        case .wakeup(let a): return a.objectID
        case .sleep(let a): return a.objectID
        case .custom(let a): return a.objectID
        case .feeding(let a): return a.objectID
        case .diaper(let a): return a.objectID
        case .breastFeeding(let a): return a.objectID
        }
    }
    
    var timestamp: Date {
        switch self {
        case .wakeup(let a): return a.timestamp ?? Date()
        case .sleep(let a): return a.timestamp ?? Date()
        case .custom(let a): return a.timestamp ?? Date()
        case .feeding(let a): return a.timestamp ?? Date()
        case .diaper(let a): return a.timestamp ?? Date()
        case .breastFeeding(let a): return a.timestamp ?? Date()
        }
    }
    
    var note: String {
        switch self {
        case .wakeup(let a): return a.note ?? ""
        case .sleep(let a): return a.note ?? ""
        case .custom(let a): return a.note ?? ""
        case .feeding(let a): return a.note ?? ""
        case .diaper(let a): return a.note ?? ""
        case .breastFeeding(let a): return a.note ?? ""
        }
    }
    
    var typeTitle: String {
        switch self {
        case .wakeup: return "起床"
        case .sleep: return "睡覺"
        case .custom(let a): return a.isStart ? "開始" : "結束"
        case .feeding: return "瓶餵"
        case .diaper: return "尿布"
        case .breastFeeding: return "親餵"
        }
    }

    var buttonCase: HomePageButtonCase {
        switch self {
        case .wakeup: return .wakeup
        case .sleep: return .sleep
        case .custom: return .customActivity
        case .feeding: return .feeding
        case .diaper: return .diaper
        case .breastFeeding: return .breastFeeding
        }
    }

    var attributeValue: String? {
        switch self {
        case .feeding(let a): return "\(a.volume)ml"
        case .breastFeeding(let a): return "\(a.volume)ml" // 親餵顯示奶量
        case .diaper(let a): return a.type ?? ""
        default: return nil
        }
    }

    var isDetailInstruction: Bool {
        switch self {
        case .feeding, .diaper, .breastFeeding: return true
        default: return false
        }
    }
    
    // 定義該項目在時間軸上的高度，用於計算碰撞
    var height: CGFloat {
        return isDetailInstruction ? 24 : 16
    }
    
    // 輔助屬性，用於 View 中判斷類型
    var isCustom: Bool { if case .custom = self { return true }; return false }
    var isFeeding: Bool { if case .feeding = self { return true }; return false }
    var isBreastFeeding: Bool { if case .breastFeeding = self { return true }; return false }
    var isDiaper: Bool { if case .diaper = self { return true }; return false }
    
    // 新增：格式化時間字串
    var formattedTimeString: String {
        timestamp.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
                .locale(Locale(identifier: "en_GB"))
        )
    }
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let hour: Int
    let date: Date
    var description: String
}

struct TimelineRowView: View {
    let event: TimelineEvent
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("\(event.hour):00")
                .font(.caption2)
                .frame(width: 45, alignment: .trailing)
                .foregroundColor(.gray)
                .padding(.trailing, 5)
                .offset(y: -7)
            VStack(alignment: .leading, spacing: 0) {
                Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
                Spacer()
            }
        }
        .frame(height: 50)
    }
}

struct ActivityDetailCard: View {
    // 改為接收具體的數值，而不是 ActivityItem
    // 這樣當上層重新計算這些值傳入時，SwiftUI 會偵測到變更並重繪
    let title: String
    let subtitle: String?
    let timeString: String
    let color: Color
    let iconName: String
    
    var body: some View {
        HStack(spacing: 0) {
            // 圖示區
            ZStack {
                Rectangle().fill(color)
                Image(systemName: iconName).font(.system(size: 10)).foregroundColor(.white)
            }
            .frame(width: 24, height: 24)
            
            // 內容區
            HStack(spacing: 8) {
                Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                if let attr = subtitle {
                    Text(attr).font(.system(size: 10)).foregroundColor(.gray)
                }
                Spacer()
                
                Text(timeString)
                    .font(.system(size: 9))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(Color.white.opacity(0.1))
        }
        .cornerRadius(4)
        .frame(width: 150, alignment: .leading)
    }
}

struct TimelineDatePickerSheet: View {
    @Environment(AppState.self) private var appState
    @Binding var isPresented: Bool
    @State private var tempDate: Date = Date()
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("取消") { isPresented = false }.foregroundColor(.red)
                Spacer()
                Button("今天") { tempDate = Date() }.foregroundColor(.blue)
                Spacer()
                Button("確認") { appState.currentDate = tempDate; isPresented = false }.fontWeight(.bold).foregroundColor(.blue)
            }
            .padding()
            DatePicker("Select Date", selection: $tempDate, displayedComponents: .date)
                .datePickerStyle(.wheel).labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_Hant_TW")).padding().layoutPriority(1)
        }
        .background(appDeepGray.ignoresSafeArea()).preferredColorScheme(.dark)
        .onAppear { tempDate = appState.currentDate }
    }
}

/// 核心容器視圖：負責日期導航與傳遞過濾後的日期範圍
struct DailyTimelineView: View {
    @Environment(AppState.self) private var appState
    @State private var showDatePicker = false
    @State private var slideEdge: Edge = .trailing
    
    private func updateDate(offset: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .day, value: offset, to: appState.currentDate) {
            slideEdge = offset < 0 ? .leading : .trailing
            withAnimation(.easeInOut(duration: 0.3)) { appState.currentDate = calendar.startOfDay(for: newDate) }
        }
    }
    
    private var formattedDateString: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: appState.currentDate), month = calendar.component(.month, from: appState.currentDate), day = calendar.component(.day, from: appState.currentDate), weekday = calendar.component(.weekday, from: appState.currentDate)
        let weekdays = ["週日", "週一", "週二", "週三", "週四", "週五", "週六"]
        return "\(year)年\(month)月\(day)日 \(weekdays[(weekday - 1) % 7])"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { updateDate(offset: -1) }) { Image(systemName: "chevron.left").font(.title2) }.padding(.leading)
                Button(action: { showDatePicker = true }) { Text(formattedDateString).font(.title2).bold().foregroundColor(.blue).frame(maxWidth: .infinity) }
                .sheet(isPresented: $showDatePicker) { TimelineDatePickerSheet(isPresented: $showDatePicker).presentationDetents([.height(350), .medium]) }
                Button(action: { updateDate(offset: 1) }) { Image(systemName: "chevron.right").font(.title2) }.padding(.trailing)
            }
            .padding(.vertical, 10)
            
            // 計算當天的範圍傳給子視圖進行 @FetchRequest
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: appState.currentDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            
            DailyTimelineContentView(startDate: start, endDate: end)
                .id(appState.currentDate) // 確保日期切換時視圖重置
                .transition(.asymmetric(insertion: .move(edge: slideEdge), removal: .move(edge: slideEdge == .leading ? .trailing : .leading)))
                .gesture(DragGesture().onEnded { value in
                    if value.translation.width > 50 { updateDate(offset: -1) }
                    else if value.translation.width < -50 { updateDate(offset: 1) }
                })
        }
    }
}

/// 內容視圖：直接在 @FetchRequest 階段進行資料庫層級篩選
struct DailyTimelineContentView: View {
    @Environment(AppState.self) private var appState
    let startDate: Date
    let endDate: Date
    
    @FetchRequest var wakeups: FetchedResults<WakeupActivity>
    @FetchRequest var sleeps: FetchedResults<SleepActivity>
    @FetchRequest var customActivities: FetchedResults<CustomActivity>
    @FetchRequest var feedings: FetchedResults<FeedingBottleActivity>
    @FetchRequest var breastFeedings: FetchedResults<BreastFeedingActivity> // 新增
    @FetchRequest var diapers: FetchedResults<DiaperActivity>
    
    @State private var editingActivity: ActivityItem?
    
    private let hourHeight: CGFloat = 50.0
    private let timeLabelWidth: CGFloat = 50.0

    // 初始化時動態建立 Predicate
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        
        let predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startDate as NSDate, endDate as NSDate)
        
        _wakeups = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \WakeupActivity.timestamp, ascending: true)],
            predicate: predicate
        )
        _sleeps = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \SleepActivity.timestamp, ascending: true)],
            predicate: predicate
        )
        _customActivities = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \CustomActivity.timestamp, ascending: true)],
            predicate: predicate
        )
        _feedings = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \FeedingBottleActivity.timestamp, ascending: true)],
            predicate: predicate
        )
        _breastFeedings = FetchRequest( // 新增
            sortDescriptors: [NSSortDescriptor(keyPath: \BreastFeedingActivity.timestamp, ascending: true)],
            predicate: predicate
        )
        _diapers = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \DiaperActivity.timestamp, ascending: true)],
            predicate: predicate
        )
    }

    private func yOffset(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = CGFloat(calendar.component(.hour, from: date))
        let minute = CGFloat(calendar.component(.minute, from: date))
        return (hour * hourHeight) + (minute / 60.0 * hourHeight)
    }

    private func getElapsedTimeString(since date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 0 { return "" }
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        return hours == 0 ? "\(max(1, minutes))分鐘前" : "\(hours)h\(minutes)m前"
    }

    private var todayActivityItems: [ActivityItem] {
        // 因為 @FetchRequest 已經篩選過了，這裡直接組合即可
        let w = wakeups.map { ActivityItem.wakeup($0) }
        let s = sleeps.map { ActivityItem.sleep($0) }
        let c = customActivities.map { ActivityItem.custom($0) }
        let f = feedings.map { ActivityItem.feeding($0) }
        let bf = breastFeedings.map { ActivityItem.breastFeeding($0) } // 新增
        let d = diapers.map { ActivityItem.diaper($0) }
        return (w + s + c + f + bf + d).sorted { $0.timestamp < $1.timestamp }
    }

    private var positionedActivityItems: [PositionedActivityItem] {
        let sortedItems = todayActivityItems
        var positioned: [PositionedActivityItem] = []
        let isToday = Calendar.current.isDate(appState.currentDate, inSameDayAs: Date())
        
        var latestIDsByType: [HomePageButtonCase: NSManagedObjectID] = [:]
        for item in sortedItems { latestIDsByType[item.buttonCase] = item.id }
        
        var lastStatusBottom: CGFloat = -100
        var lastCustomBottom: CGFloat = -100
        var lastInstructionBottom: CGFloat = -100
        
        for item in sortedItems {
            let idealY = yOffset(for: item.timestamp)
            let h = item.height
            var finalY = idealY - (h / 2)
            
            if case .custom = item {
                if finalY < lastCustomBottom + 2 { finalY = lastCustomBottom + 2 }
                lastCustomBottom = finalY + h
            } else if item.isDetailInstruction {
                if finalY < lastInstructionBottom + 2 { finalY = lastInstructionBottom + 2 }
                lastInstructionBottom = finalY + h
            } else {
                if finalY < lastStatusBottom + 2 { finalY = lastStatusBottom + 2 }
                lastStatusBottom = finalY + h
            }
            
            var posItem = PositionedActivityItem(id: item.id, item: item, y: finalY)
            if isToday && latestIDsByType[item.buttonCase] == item.id && item.isDetailInstruction {
                posItem.elapsedString = getElapsedTimeString(since: item.timestamp)
            }
            positioned.append(posItem)
        }
        return positioned
    }
    
    private var eventsForCurrentDate: [TimelineEvent] {
        let calendar = Calendar.current
        return (0..<24).map { hour in
            let specificDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startDate)!
            return TimelineEvent(hour: hour, date: specificDate, description: "")
        }
    }

    private var statusBlocks: [(start: CGFloat, end: CGFloat, color: Color)] {
        let isToday = Calendar.current.isDate(appState.currentDate, inSameDayAs: Date())
        let nowY = yOffset(for: Date())
        
        let wItems = wakeups.map { (t: $0.timestamp ?? Date(), s: "wakeup") }
        let sItems = sleeps.map { (t: $0.timestamp ?? Date(), s: "sleep") }
        
        let sorted = (wItems + sItems).sorted { $0.t < $1.t }
        
        if sorted.isEmpty { return [] }
        var blocks: [(start: CGFloat, end: CGFloat, color: Color)] = []
        if let first = sorted.first {
            let startY = 0.0
            var endY = yOffset(for: first.t)
            if isToday { endY = min(endY, nowY) }
            let color = (first.s == "wakeup") ? Color.white : Color.yellow
            if startY < endY { blocks.append((startY, endY, color)) }
        }
        for i in 0..<sorted.count {
            let current = sorted[i]
            let startY = yOffset(for: current.t)
            if isToday && startY >= nowY { break }
            var endY: CGFloat = (i < sorted.count - 1) ? yOffset(for: sorted[i+1].t) : 24 * hourHeight
            if isToday { endY = min(endY, nowY) }
            let color = (current.s == "wakeup") ? Color.yellow : Color.white
            if startY < endY { blocks.append((startY, endY, color)) }
        }
        return blocks
    }
    
    private var customActivityBlocks: [(start: CGFloat, end: CGFloat, color: Color)] {
        let isToday = Calendar.current.isDate(appState.currentDate, inSameDayAs: Date())
        let nowY = yOffset(for: Date())
        let sortedCustom = customActivities.sorted { ($0.timestamp ?? Date()) < ($1.timestamp ?? Date()) }
        if sortedCustom.isEmpty { return [] }
        var blocks: [(start: CGFloat, end: CGFloat, color: Color)] = []
        var activeStart: CGFloat? = nil
        for activity in sortedCustom {
            let currentY = yOffset(for: activity.timestamp ?? Date())
            if activity.isStart { activeStart = currentY }
            else if let start = activeStart {
                var endY = currentY
                if isToday { endY = min(endY, nowY) }
                if start < endY { blocks.append((start, endY, Color.blue.opacity(0.3))) }
                activeStart = nil
            }
            if isToday && currentY >= nowY { break }
        }
        if let start = activeStart {
            var endY = 24 * hourHeight
            if isToday { endY = min(endY, nowY) }
            if start < endY { blocks.append((start, endY, Color.blue.opacity(0.3))) }
        }
        return blocks
    }

    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        let initialTime = calendar.component(.hour, from: Date())
        if let targetDate = calendar.date(bySettingHour: max(0, initialTime - 2), minute: 0, second: 0, of: startDate) {
            proxy.scrollTo(targetDate, anchor: .top)
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    let columnWidth = UIScreen.main.bounds.width / 4 - 10
                    let customBlockWidth = columnWidth * 0.6
                    
                    ForEach(0..<statusBlocks.count, id: \.self) { index in
                        let block = statusBlocks[index]
                        Rectangle().fill(block.color.opacity(0.25)).frame(width: columnWidth, height: block.end - block.start).offset(x: timeLabelWidth, y: block.start)
                    }
                    ForEach(0..<customActivityBlocks.count, id: \.self) { index in
                        let block = customActivityBlocks[index]
                        Rectangle().fill(block.color).frame(width: customBlockWidth, height: block.end - block.start).offset(x: timeLabelWidth + columnWidth, y: block.start)
                    }

                    ForEach(positionedActivityItems) { pos in
                        let item = pos.item
                        let isInstruction = item.isDetailInstruction
                        let labelX: CGFloat = {
                            if case .custom = item { return timeLabelWidth + columnWidth + (customBlockWidth / 2) - 15 }
                            if isInstruction { return timeLabelWidth + columnWidth + customBlockWidth + 10 }
                            return timeLabelWidth + (columnWidth / 2) - 15
                        }()
                        
                        Button(action: { editingActivity = item }) {
                            if isInstruction {
                                HStack(alignment: .bottom, spacing: 4) {
                                    // 顯式傳遞屬性，強迫視圖刷新
                                    ActivityDetailCard(
                                        title: item.typeTitle,
                                        subtitle: item.attributeValue,
                                        timeString: item.formattedTimeString,
                                        color: item.buttonCase.color,
                                        iconName: item.buttonCase.iconName
                                    )
                                    if let elapsed = pos.elapsedString {
                                        Text(elapsed).font(.system(size: 8)).foregroundColor(.gray).padding(.bottom, 2)
                                    }
                                }
                            } else {
                                Text(item.typeTitle).font(.system(size: 10, weight: .bold)).foregroundColor(.white).padding(.horizontal, 6).padding(.vertical, 2).background(item.buttonCase.color).classCornerRadius(4)
                            }
                        }
                        .offset(x: labelX, y: pos.y)
                    }

                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(eventsForCurrentDate) { event in
                            TimelineRowView(event: event).id(event.date)
                        }
                    }
                    
                    if Calendar.current.isDate(startDate, inSameDayAs: Date()) {
                        HStack(spacing: 0) {
                            Color.clear.frame(width: timeLabelWidth)
                            Rectangle().fill(Color.red.opacity(0.6))
                        }
                        .frame(height: 2)
                        .overlay(alignment: .leading) {
                            HStack(spacing: 2) {
                                Text("NOW").font(.system(size: 8, weight: .bold)).foregroundColor(.red)
                                Circle().fill(.red).frame(width: 6, height: 6)
                            }
                            .padding(.trailing, 2)
                            .frame(width: timeLabelWidth, alignment: .trailing)
                        }
                        .offset(y: yOffset(for: Date()) - 1)
                    }
                }
            }
            .onAppear { scrollToCurrentTime(proxy: proxy) }
        }
        .sheet(item: $editingActivity) { item in
            ActivityEditView(item: item) { editingActivity = nil }
                .presentationDetents([.medium])
        }
    }
}

// 指令編輯與刪除畫面
struct ActivityEditView: View {
    let item: ActivityItem
    let onDismiss: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) private var appState
    @State private var selectedTime: Date
    @State private var note: String
    @State private var isStart: Bool = true
    @State private var volume: Int = 50
    @State private var diaperType: String = "濕"
    
    init(item: ActivityItem, onDismiss: @escaping () -> Void) {
        self.item = item
        self.onDismiss = onDismiss
        _selectedTime = State(initialValue: item.timestamp)
        _note = State(initialValue: item.note)
        
        // 使用預設值
        var initialIsStart = true
        var initialVolume = 50
        var initialDiaperType = "濕"
        
        // 根據類型提取值
        switch item {
        case .custom(let activity): initialIsStart = activity.isStart
        case .feeding(let activity): initialVolume = Int(activity.volume)
        case .breastFeeding(let activity): initialVolume = Int(activity.volume) // 新增：提取親餵量
        case .diaper(let activity): initialDiaperType = activity.type ?? "濕"
        default: break
        }
        
        _isStart = State(initialValue: initialIsStart)
        _volume = State(initialValue: initialVolume)
        _diaperType = State(initialValue: initialDiaperType)
    }
    
    private func saveChanges() {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: appState.currentDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        var combined = DateComponents()
        combined.year = dateComponents.year; combined.month = dateComponents.month; combined.day = dateComponents.day; combined.hour = timeComponents.hour; combined.minute = timeComponents.minute
        let finalDate = calendar.date(from: combined) ?? selectedTime
        
        switch item {
        case .wakeup(let activity): activity.timestamp = finalDate; activity.note = note
        case .sleep(let activity): activity.timestamp = finalDate; activity.note = note
        case .custom(let activity): activity.timestamp = finalDate; activity.note = note; activity.isStart = isStart
        case .feeding(let activity): activity.timestamp = finalDate; activity.note = note; activity.volume = Int32(volume)
        case .breastFeeding(let activity): activity.timestamp = finalDate; activity.note = note; activity.volume = Int32(volume) // 新增
        case .diaper(let activity): activity.timestamp = finalDate; activity.note = note; activity.type = diaperType
        }
        try? viewContext.save(); onDismiss()
    }
    
    private func deleteActivity() {
        switch item {
        case .wakeup(let activity): viewContext.delete(activity)
        case .sleep(let activity): viewContext.delete(activity)
        case .custom(let activity): viewContext.delete(activity)
        case .feeding(let activity): viewContext.delete(activity)
        case .breastFeeding(let activity): viewContext.delete(activity) // 新增
        case .diaper(let activity): viewContext.delete(activity)
        }
        try? viewContext.save(); onDismiss()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Text("編輯紀錄").font(.headline).padding(.top)
                DatePicker("時間", selection: $selectedTime, displayedComponents: .hourAndMinute).datePickerStyle(.wheel).labelsHidden().frame(height: 120).clipped()
                
                // 改用屬性檢查，避免 ViewBuilder 中的複雜 pattern matching 問題
                if item.isCustom {
                    Toggle(isOn: $isStart) { Text(isStart ? "標記為：開始" : "標記為：結束").fontWeight(.bold) }.toggleStyle(.button).tint(isStart ? .green : .red).padding(.bottom, 5)
                }
                // 共用介面：瓶餵與親餵
                if item.isFeeding || item.isBreastFeeding {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("餵奶量：\(volume) ml").font(.subheadline).bold()
                        Slider(value: Binding(get: { Double(volume) }, set: { volume = Int($0) }), in: 0...400, step: 5)
                    }.padding(.horizontal)
                }
                if item.isDiaper {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("尿布類型").font(.subheadline).bold().padding(.leading)
                        Picker("Diaper Type", selection: $diaperType) { Text("濕").tag("濕"); Text("髒").tag("髒"); Text("混合").tag("混合") }.pickerStyle(.segmented).padding(.horizontal)
                    }
                }
                VStack(spacing: 8) {
                    TextField("輸入備註...", text: $note).textFieldStyle(.roundedBorder)
                    Button(role: .destructive, action: deleteActivity) {
                        HStack { Image(systemName: "trash"); Text("刪除此紀錄") }.frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.red.opacity(0.1)).cornerRadius(10)
                    }
                }.padding(.horizontal)
                Color.clear.frame(height: 10)
            }
            .background(appDeepGray.ignoresSafeArea()).preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { onDismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("儲存") { saveChanges() }.fontWeight(.bold) }
            }
        }
    }
}

// 按鈕功能輸入頁面 (新增用)
@MainActor
struct ButtonDestinationView: View {
    let buttonCase: HomePageButtonCase
    let onDismiss: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppState.self) private var appState
    @State private var selectedTime = Date()
    @State private var note: String = ""
    @State private var isStart: Bool = true
    @State private var volume: Int = 50
    @State private var diaperType: String = "濕"

    private func _ToAppDate(time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: appState.currentDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var combined = DateComponents()
        combined.year = dateComponents.year; combined.month = dateComponents.month; combined.day = dateComponents.day; combined.hour = timeComponents.hour; combined.minute = timeComponents.minute
        return calendar.date(from: combined) ?? Date()
    }

    var body: some View {
        VStack(spacing: 15) {
            Text("新增\(buttonCase.title)").font(.headline).padding(.top)
            DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute).datePickerStyle(.wheel).labelsHidden().frame(height: 120).clipped()
            
            if buttonCase == .customActivity {
                Toggle(isOn: $isStart) { Text(isStart ? "標記為：開始" : "標記為：結束").fontWeight(.bold) }.toggleStyle(.button).tint(isStart ? .green : .red)
            }
            // 共用介面：瓶餵與親餵
            if buttonCase == .feeding || buttonCase == .breastFeeding {
                VStack(alignment: .leading, spacing: 5) {
                    Text("奶量：\(volume) ml").font(.headline).foregroundColor(.white)
                    Slider(value: Binding(get: { Double(volume) }, set: { volume = Int($0) }), in: 0...400, step: 5).accentColor(.pink)
                }.padding(.horizontal)
            }
            if buttonCase == .diaper {
                VStack(alignment: .leading, spacing: 5) {
                    Text("類型").font(.headline).foregroundColor(.white).padding(.leading)
                    Picker("Diaper Type", selection: $diaperType) { Text("濕").tag("濕"); Text("髒").tag("髒"); Text("混合").tag("混合") }.pickerStyle(.segmented).padding(.horizontal)
                }
            }
            TextField("輸入備註...", text: $note).textFieldStyle(.roundedBorder).padding(.horizontal)
            HStack(spacing: 15) {
                Button("Cancel") { onDismiss() }.buttonStyle(.bordered).tint(.gray).frame(maxWidth: .infinity)
                Button("Confirm") {
                    let finalDate = _ToAppDate(time: selectedTime)
                    switch buttonCase {
                    case .wakeup:
                        let a = WakeupActivity(context: viewContext)
                        a.timestamp = finalDate
                        a.note = note
                    case .sleep:
                        let a = SleepActivity(context: viewContext)
                        a.timestamp = finalDate
                        a.note = note
                    case .customActivity:
                        let a = CustomActivity(context: viewContext)
                        a.timestamp = finalDate
                        a.note = note
                        a.isStart = isStart
                    case .feeding:
                        let a = FeedingBottleActivity(context: viewContext)
                        a.timestamp = finalDate
                        a.note = note
                        a.volume = Int32(volume)
                    case .breastFeeding: // 新增：儲存親餵
                        let a = BreastFeedingActivity(context: viewContext)
                        a.timestamp = finalDate
                        a.note = note
                        a.volume = Int32(volume)
                    case .diaper:
                        let a = DiaperActivity(context: viewContext)
                        a.timestamp = finalDate
                        a.note = note
                        a.type = diaperType
                    }
                    try? viewContext.save(); onDismiss()
                }.buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
            }.padding(.horizontal).padding(.bottom, 20)
        }
        .background(appDeepGray.ignoresSafeArea()).preferredColorScheme(.dark)
    }
}

enum HomePageButtonCase: Int, Identifiable, CaseIterable{
    case wakeup = 1, sleep = 2, customActivity = 3, feeding = 5, diaper = 6, breastFeeding = 7 // 新增：親餵 ID
    var id: Int { self.rawValue }
    var title: String {
        switch self {
        case .wakeup: return "起床"; case .sleep: return "睡覺"; case .customActivity: return "活動"; case .feeding: return "瓶餵"; case .diaper: return "尿布"; case .breastFeeding: return "親餵"
        }
    }
    var iconName: String {
        switch self {
        case .wakeup: return "sun.max.fill"; case .sleep: return "moon.zzz.fill"; case .customActivity: return "figure.run"; case .feeding: return "drop.fill"; case .diaper: return "water.waves"; case .breastFeeding: return "heart.fill"
        }
    }
    var color: Color {
        switch self {
        case .wakeup: return .orange; case .sleep: return .indigo; case .customActivity: return .green; case .feeding: return .pink; case .diaper: return .green; case .breastFeeding: return .purple
        }
    }
}

// 用於記錄按鈕位置的 PreferenceKey
struct ItemFrameKey: PreferenceKey {
    static var defaultValue: [HomePageButtonCase: CGRect] = [:]
    static func reduce(value: inout [HomePageButtonCase: CGRect], nextValue: () -> [HomePageButtonCase: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}


// 全域常數設定
private let kButtonWidth: CGFloat = 80.0
private let kPadding: CGFloat = 20.0
private let kContainerHeight: CGFloat = 140.0

// MARK: - 純 UI 元件：按鈕外觀
struct HomePageButtonView: View {
    let caseItem: HomePageButtonCase
    let isDragging: Bool
    let isPressed: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Ellipse()
                    .fill(caseItem.color)
                    .frame(width: 40, height: 12)
                    .blur(radius: 8)
                    .opacity(0.4)
                    .offset(y: 25)
                
                Circle()
                    .fill(caseItem.color)
                    .frame(width: 60, height: 60)
                    .scaleEffect(isDragging ? 1.2 : (isPressed ? 1.1 : 1.0))
                    .shadow(color: isDragging ? .black.opacity(0.3) : .clear, radius: 10, x: 0, y: 10)
                
                Image(systemName: caseItem.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .scaleEffect(isDragging ? 1.2 : (isPressed ? 1.1 : 1.0))
            }
            .frame(width: 60, height: 60)
            
            Text(caseItem.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 2)
        }
        .frame(width: kButtonWidth) // 固定寬度
        .contentShape(Rectangle())
        .opacity(isDragging ? 0 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - 主視圖
struct HomePageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var appState = AppState()
    
    @State private var buttons: [HomePageButtonCase] = []
    @State private var activeSheet: HomePageButtonCase? = nil
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ButtonSortOrder.sortIndex, ascending: true)],
        animation: .default)
    private var savedSortOrders: FetchedResults<ButtonSortOrder>
    
    // --- 狀態變數 ---
    @State private var scrollOffset: CGFloat = 0
    @State private var currentDragOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    @State private var reorderingItem: HomePageButtonCase? = nil
    @State private var ghostPosition: CGPoint = .zero
    @State private var pressingItem: HomePageButtonCase? = nil
    
    @State private var isScrollMode: Bool = false
    @State private var isReorderMode: Bool = false
    @State private var touchStartTime: Date? = nil
    @State private var startTouchLocation: CGPoint = .zero
    
    // 🆕 新增：自動捲動計時器
    @State private var autoScrollTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            DailyTimelineView().frame(height: 600)
            Spacer()
            
            customScrollView
                .frame(height: kContainerHeight)
                .zIndex(1)
        }
        .navigationTitle("Home")
        .background(appDeepGray.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .environment(appState)
        .overlay(reorderingOverlay, alignment: .topLeading)
        .sheet(item: $activeSheet) { caseItem in
            ButtonDestinationView(buttonCase: caseItem, onDismiss: { activeSheet = nil })
                .environment(appState)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadButtonOrder()
        }
    }
    
    // MARK: - 自定義滑動視圖
    
    private var customScrollView: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .global)
            
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(buttons) { item in
                        HomePageButtonView(
                            caseItem: item,
                            isDragging: reorderingItem == item,
                            isPressed: pressingItem == item
                        )
                    }
                }
                .padding(.horizontal, kPadding)
                .background(GeometryReader { contentGeo in
                    Color.clear.onAppear {
                        self.contentWidth = contentGeo.size.width
                        self.containerWidth = frame.width
                    }
                    .onChange(of: buttons.count) { _, _ in
                        self.contentWidth = contentGeo.size.width
                    }
                })
                .offset(x: scrollOffset + (isReorderMode ? 0 : currentDragOffset))
            }
            .frame(height: kContainerHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        handleTouchMove(value: value, containerFrame: frame)
                    }
                    .onEnded { value in
                        handleTouchEnd(value: value)
                    }
            )
            .onAppear {
                self.containerWidth = frame.width
            }
        }
        .clipped()
    }
    
    @ViewBuilder
    private var reorderingOverlay: some View {
        if let reorderingItem = reorderingItem {
            HomePageButtonView(caseItem: reorderingItem, isDragging: false, isPressed: true)
                .scaleEffect(1.2)
                .position(ghostPosition)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
    
    // MARK: - 邏輯核心
    
    private func calculateHitIndex(at globalX: CGFloat) -> Int? {
        let relativeX = globalX - (scrollOffset + kPadding)
        let index = Int(floor(relativeX / kButtonWidth))
        if index >= 0 && index < buttons.count {
            return index
        }
        return nil
    }

    private func handleTouchMove(value: DragGesture.Value, containerFrame: CGRect) {
        let location = value.location
        let translation = value.translation
        
        if touchStartTime == nil {
            touchStartTime = Date()
            startTouchLocation = location
            if let index = calculateHitIndex(at: location.x) {
                let hitItem = buttons[index]
                withAnimation(.easeOut(duration: 0.1)) { pressingItem = hitItem }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { // 設為 0.25s
                    if pressingItem == hitItem && !isScrollMode && !isReorderMode {
                        // ✅ 加入這裡：觸發震動回饋
                        let generator = UIImpactFeedbackGenerator(style: .medium) // .medium 是標準的長按震動感
                        generator.impactOccurred()
                        startReordering(item: hitItem, index: index, containerY: containerFrame.midY)
                    }
                }
            }
        }
        
        if isReorderMode {
            // --- 重排模式 ---
            withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.7)) {
                ghostPosition = location
            }
            
            // 🆕 新增：邊緣自動捲動檢測
            // 定義熱區：距離螢幕邊緣 50 點
            let edgeThreshold: CGFloat = 50
            let maxScrollSpeed: CGFloat = 8 // 捲動速度
            
            // 判斷手指是否在熱區
            if location.x < edgeThreshold {
                // 手指在左邊緣 -> 列表向右滑 (Offset 增加)
                startAutoScroll(speed: maxScrollSpeed)
            } else if location.x > containerWidth - edgeThreshold {
                // 手指在右邊緣 -> 列表向左滑 (Offset 減少)
                startAutoScroll(speed: -maxScrollSpeed)
            } else {
                // 手指在中間 -> 停止自動捲動
                stopAutoScroll()
            }
            
            // 碰撞交換 (如果不在自動捲動中，手動觸發一次；如果在自動捲動中，Timer 會處理)
            if autoScrollTimer == nil {
                checkForReorderCollision(at: location.x)
            }
            
        } else {
            // --- 滑動判定 ---
            let dragDistance = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
            
            if dragDistance > 6 {
                if !isScrollMode {
                    isScrollMode = true
                    withAnimation { pressingItem = nil }
                }
            }
            
            if isScrollMode {
                let proposedOffset = scrollOffset + translation.width
                let minOffset = min(0, containerWidth - contentWidth - (kPadding * 2))
                if proposedOffset > 0 {
                    currentDragOffset = translation.width - (proposedOffset * 0.5)
                } else if proposedOffset < minOffset {
                    let overshoot = minOffset - proposedOffset
                    currentDragOffset = translation.width + (overshoot * 0.5)
                } else {
                    currentDragOffset = translation.width
                }
            }
        }
    }
    
    private func handleTouchEnd(value: DragGesture.Value) {
        // 🆕 確保手指放開時停止計時器
        stopAutoScroll()
        
        if isScrollMode {
            let currentVisualOffset = scrollOffset + currentDragOffset
            scrollOffset = currentVisualOffset
            currentDragOffset = 0
            
            let velocity = value.predictedEndTranslation.width - value.translation.width
            let inertia = velocity * 0.6
            let targetOffset = scrollOffset + inertia
            
            let minOffset = min(0, containerWidth - contentWidth - (kPadding * 2))
            let maxOffset: CGFloat = 0
            
            var finalDestination = targetOffset
            if finalDestination > maxOffset { finalDestination = maxOffset }
            else if finalDestination < minOffset { finalDestination = minOffset }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                scrollOffset = finalDestination
            }
            isScrollMode = false
            touchStartTime = nil
            startTouchLocation = .zero
            withAnimation { pressingItem = nil }
            return
        }
        
        if reorderingItem != nil {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                reorderingItem = nil
            }
            saveButtonOrder()
            isReorderMode = false
            touchStartTime = nil
            startTouchLocation = .zero
            withAnimation { pressingItem = nil }
            return
        }
        
        let dist = sqrt(pow(value.location.x - startTouchLocation.x, 2) + pow(value.location.y - startTouchLocation.y, 2))
        if dist < 20, let index = calculateHitIndex(at: value.startLocation.x) {
            let hitItem = buttons[index]
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            activeSheet = hitItem
        }
        
        touchStartTime = nil
        isReorderMode = false
        startTouchLocation = .zero
        withAnimation { pressingItem = nil }
    }
    
    private func startReordering(item: HomePageButtonCase, index: Int, containerY: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        withAnimation {
            isReorderMode = true
            reorderingItem = item
            let centerX = kPadding + (CGFloat(index) * kButtonWidth) + (kButtonWidth / 2) + scrollOffset
            ghostPosition = CGPoint(x: centerX, y: containerY)
        }
    }
    
    // MARK: - 自動捲動邏輯 (New)
    
    private func startAutoScroll(speed: CGFloat) {
        // 如果計時器已經在跑，就不重複建立
        guard autoScrollTimer == nil else { return }
        
        // 建立計時器 (每 0.016秒 = 60fps 更新一次)
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            performAutoScrollStep(speed: speed)
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    private func performAutoScrollStep(speed: CGFloat) {
        // 1. 計算新的 Offset
        var newOffset = scrollOffset + speed
        
        // 2. 邊界檢查 (不要滑過頭)
        let minOffset = min(0, containerWidth - contentWidth - (kPadding * 2))
        let maxOffset: CGFloat = 0
        
        if newOffset > maxOffset { newOffset = maxOffset }
        else if newOffset < minOffset { newOffset = minOffset }
        
        // 如果已經到底了，就不用更新
        if newOffset == scrollOffset { return }
        
        // 3. 更新畫面位置
        // 這裡不需要 withAnimation，因為 Timer 更新頻率夠高，自動形成動畫
        scrollOffset = newOffset
        
        // 4. ⚠️ 關鍵：因為列表在動，手指下的按鈕可能變了，所以要在這裡檢查碰撞
        checkForReorderCollision(at: ghostPosition.x)
    }
    
    // 抽取出碰撞檢查邏輯 (因為 HandleMove 和 Timer 都要用)
    private func checkForReorderCollision(at xLocation: CGFloat) {
        if let targetIndex = calculateHitIndex(at: xLocation) {
            let targetItem = buttons[targetIndex]
            if targetItem != reorderingItem {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    moveItem(from: reorderingItem!, to: targetItem)
                }
            }
        }
    }
    
    private func moveItem(from source: HomePageButtonCase, to destination: HomePageButtonCase) {
        guard let fromIndex = buttons.firstIndex(of: source),
              let toIndex = buttons.firstIndex(of: destination) else { return }
        if fromIndex != toIndex {
            buttons.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
    
    // MARK: - Core Data (不變)
    private func loadButtonOrder() {
        if savedSortOrders.isEmpty {
            self.buttons = HomePageButtonCase.allCases
            saveButtonOrder()
        } else {
            let sortedIDs = savedSortOrders.sorted { $0.sortIndex < $1.sortIndex }.map { Int($0.typeID) }
            var loadedButtons: [HomePageButtonCase] = []
            for id in sortedIDs {
                if let btn = HomePageButtonCase(rawValue: id) { loadedButtons.append(btn) }
            }
            let existingSet = Set(loadedButtons)
            let missingButtons = HomePageButtonCase.allCases.filter { !existingSet.contains($0) }
            if !missingButtons.isEmpty {
                loadedButtons.append(contentsOf: missingButtons)
                self.buttons = loadedButtons
                saveButtonOrder()
            } else { self.buttons = loadedButtons }
        }
    }
    
    private func saveButtonOrder() {
        let existingRecords = Dictionary(grouping: savedSortOrders, by: { Int($0.typeID) })
            .compactMapValues { $0.first }
        for (index, button) in buttons.enumerated() {
            let sortIndex = Int16(index)
            if let existingEntity = existingRecords[button.rawValue] {
                if existingEntity.sortIndex != sortIndex { existingEntity.sortIndex = sortIndex }
            } else {
                let newEntity = ButtonSortOrder(context: viewContext)
                newEntity.typeID = Int16(button.rawValue)
                newEntity.sortIndex = sortIndex
            }
        }
        try? viewContext.save()
    }
}
extension View {
    func classCornerRadius(_ radius: CGFloat) -> some View { self.cornerRadius(radius) }
}
