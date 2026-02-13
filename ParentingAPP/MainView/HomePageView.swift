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
    
    var id: NSManagedObjectID {
        switch self {
        case .wakeup(let a): return a.objectID
        case .sleep(let a): return a.objectID
        case .custom(let a): return a.objectID
        case .feeding(let a): return a.objectID
        case .diaper(let a): return a.objectID
        }
    }
    
    var timestamp: Date {
        switch self {
        case .wakeup(let a): return a.timestamp ?? Date()
        case .sleep(let a): return a.timestamp ?? Date()
        case .custom(let a): return a.timestamp ?? Date()
        case .feeding(let a): return a.timestamp ?? Date()
        case .diaper(let a): return a.timestamp ?? Date()
        }
    }
    
    var note: String {
        switch self {
        case .wakeup(let a): return a.note ?? ""
        case .sleep(let a): return a.note ?? ""
        case .custom(let a): return a.note ?? ""
        case .feeding(let a): return a.note ?? ""
        case .diaper(let a): return a.note ?? ""
        }
    }
    
    var typeTitle: String {
        switch self {
        case .wakeup: return "起床"
        case .sleep: return "睡覺"
        case .custom(let a): return a.isStart ? "開始" : "結束"
        case .feeding: return "瓶餵"
        case .diaper: return "尿布"
        }
    }

    var buttonCase: HomePageButtonCase {
        switch self {
        case .wakeup: return .wakeup
        case .sleep: return .sleep
        case .custom: return .customActivity
        case .feeding: return .feeding
        case .diaper: return .diaper
        }
    }

    var attributeValue: String? {
        switch self {
        case .feeding(let a): return "\(a.volume)ml"
        case .diaper(let a): return a.type ?? ""
        default: return nil
        }
    }

    var isDetailInstruction: Bool {
        switch self {
        case .feeding, .diaper: return true
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
        let d = diapers.map { ActivityItem.diaper($0) }
        return (w + s + c + f + d).sorted { $0.timestamp < $1.timestamp }
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
                if item.isFeeding {
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
            if buttonCase == .feeding {
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
    case wakeup = 1, sleep = 2, customActivity = 3, feeding = 5, diaper = 6
    var id: Int { self.rawValue }
    var title: String {
        switch self {
        case .wakeup: return "起床"; case .sleep: return "睡覺"; case .customActivity: return "活動"; case .feeding: return "瓶餵"; case .diaper: return "尿布"
        }
    }
    var iconName: String {
        switch self {
        case .wakeup: return "sun.max.fill"; case .sleep: return "moon.zzz.fill"; case .customActivity: return "figure.run"; case .feeding: return "drop.fill"; case .diaper: return "water.waves"
        }
    }
    var color: Color {
        switch self {
        case .wakeup: return .orange; case .sleep: return .indigo; case .customActivity: return .green; case .feeding: return .pink; case .diaper: return .green
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

// 提取單獨的按鈕視圖以保持清晰
struct HomePageButtonView: View {
    let caseItem: HomePageButtonCase
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // 使用 onTapGesture 代替 Button 以避免手勢衝突
            ZStack {
                Ellipse().fill(caseItem.color).frame(width: 40, height: 12).blur(radius: 8).opacity(0.4).offset(y: 25)
                Circle().fill(caseItem.color).frame(width: 60, height: 60)
                Image(systemName: caseItem.iconName).font(.title2).foregroundColor(.white)
            }
            .contentShape(Circle()) // 確保點擊區域正確
            .onTapGesture(perform: action)
            
            Text(caseItem.title).font(.caption).foregroundColor(.gray)
        }
    }
}

struct HomePageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var appState = AppState()
    @State private var activeSheet: HomePageButtonCase? = nil
    
    // Core Data Fetch Request: 取得按鈕順序
    // 假設您已經在 .xcdatamodeld 建立了一個名為 ButtonSortOrder 的 Entity
    // 屬性：typeID (Int16), sortIndex (Int16)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ButtonSortOrder.sortIndex, ascending: true)],
        animation: .default)
    private var savedSortOrders: FetchedResults<ButtonSortOrder>
    
    // 拖曳重排相關狀態
    @State private var buttons: [HomePageButtonCase] = [] // 初始為空，等 onAppear 再載入
    @State private var draggingItem: HomePageButtonCase? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var initialDragLocation: CGPoint = .zero
    @State private var itemFrames: [HomePageButtonCase: CGRect] = [:]
    
    var body: some View {
        VStack(spacing: 0) {
            DailyTimelineView().frame(height: 600)
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(buttons) { caseItem in
                        HomePageButtonView(caseItem: caseItem) {
                            // 點擊動作：只有在非拖曳模式下才觸發
                            if draggingItem == nil {
                                activeSheet = caseItem
                            }
                        }
                        // 讀取位置
                        .overlay(GeometryReader { geo in
                            Color.clear.preference(key: ItemFrameKey.self, value: [caseItem: geo.frame(in: .global)])
                        })
                        // 拖曳時隱藏原項目（佔位符）
                        .opacity(draggingItem == caseItem ? 0 : 1)
                        // 手勢邏輯
                        .gesture(
                            LongPressGesture(minimumDuration: 0.3)
                                .sequenced(before: DragGesture(coordinateSpace: .global))
                                .onChanged { value in
                                    switch value {
                                    case .second(true, let drag):
                                        // 進入拖曳模式
                                        if draggingItem == nil {
                                            draggingItem = caseItem
                                            // 觸覺回饋
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                            
                                            // 設置初始位置為該項目的中心
                                            if let frame = itemFrames[caseItem] {
                                                initialDragLocation = CGPoint(x: frame.midX, y: frame.midY)
                                                dragLocation = initialDragLocation
                                            }
                                        }
                                        
                                        // 更新位置
                                        if let drag = drag {
                                            // 使用初始中心點 + 拖曳位移
                                            dragLocation = CGPoint(
                                                x: initialDragLocation.x + drag.translation.width,
                                                y: initialDragLocation.y + drag.translation.height
                                            )
                                            
                                            // 檢查碰撞與重排
                                            if let hoveredItem = findHoveredItem(at: dragLocation), hoveredItem != caseItem {
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                                    if let fromIndex = buttons.firstIndex(of: caseItem),
                                                       let toIndex = buttons.firstIndex(of: hoveredItem) {
                                                        buttons.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                                                    }
                                                }
                                            }
                                        }
                                    default: break
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        draggingItem = nil
                                    }
                                    // 拖曳結束：儲存順序
                                    saveButtonOrder()
                                }
                        )
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 20)
            }
            .frame(height: 140)
            .onPreferenceChange(ItemFrameKey.self) { itemFrames = $0 }
        }
        .navigationTitle("Home").background(appDeepGray.ignoresSafeArea()).preferredColorScheme(.dark).environment(appState)
        // 浮動層：顯示正在被拖曳的項目
        .overlay(alignment: .topLeading) {
            if let draggingItem, let _ = itemFrames[draggingItem] {
                HomePageButtonView(caseItem: draggingItem, action: {})
                    .scaleEffect(1.2) // 放大效果
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 10) // 陰影
                    .position(dragLocation) // 跟隨手指
                    .ignoresSafeArea()
                    .allowsHitTesting(false) // 確保不阻擋下層交互
            }
        }
        .sheet(item: $activeSheet) { caseItem in
            ButtonDestinationView(buttonCase: caseItem, onDismiss: { activeSheet = nil }).environment(appState).presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        }
        .onAppear {
            loadButtonOrder()
        }
    }
    
    // 輔助函數：從 Core Data 載入順序或初始化
    private func loadButtonOrder() {
        if savedSortOrders.isEmpty {
            // 第一次執行：初始化資料庫
            self.buttons = HomePageButtonCase.allCases
            saveButtonOrder() // 建立初始資料
        } else {
            // 從資料庫讀取並轉換回 Enum
            let sortedIDs = savedSortOrders.sorted { $0.sortIndex < $1.sortIndex }.map { Int($0.typeID) }
            var loadedButtons: [HomePageButtonCase] = []
            
            for id in sortedIDs {
                if let btn = HomePageButtonCase(rawValue: id) {
                    loadedButtons.append(btn)
                }
            }
            
            // 檢查是否有新功能按鈕不在資料庫中 (防呆)
            let existingSet = Set(loadedButtons)
            let missingButtons = HomePageButtonCase.allCases.filter { !existingSet.contains($0) }
            
            if !missingButtons.isEmpty {
                loadedButtons.append(contentsOf: missingButtons)
                self.buttons = loadedButtons
                saveButtonOrder() // 更新缺少的項目
            } else {
                self.buttons = loadedButtons
            }
        }
    }
    
    // 輔助函數：將當前順序儲存至 Core Data
    private func saveButtonOrder() {
        // 先建立一個 ID -> Entity 的查表，避免重複建立或 O(N^2) 搜尋
        let existingRecords = Dictionary(grouping: savedSortOrders, by: { Int($0.typeID) })
            .compactMapValues { $0.first }
        
        for (index, button) in buttons.enumerated() {
            let sortIndex = Int16(index)
            
            if let existingEntity = existingRecords[button.rawValue] {
                // 更新現有紀錄
                if existingEntity.sortIndex != sortIndex {
                    existingEntity.sortIndex = sortIndex
                }
            } else {
                // 找不到紀錄，建立新的
                let newEntity = ButtonSortOrder(context: viewContext)
                newEntity.typeID = Int16(button.rawValue)
                newEntity.sortIndex = sortIndex
            }
        }
        
        // 儲存 Context
        do {
            try viewContext.save()
        } catch {
            print("Error saving button order: \(error)")
        }
    }
    
    // 輔助函數：找出當前手指下方的項目
    private func findHoveredItem(at point: CGPoint) -> HomePageButtonCase? {
        for (item, frame) in itemFrames {
            if frame.contains(point) {
                return item
            }
        }
        return nil
    }
}

extension View {
    func classCornerRadius(_ radius: CGFloat) -> some View { self.cornerRadius(radius) }
}
