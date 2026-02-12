// Persistence.swift

import CoreData
import CloudKit // 加入 CloudKit 框架引用

struct PersistenceController {
    static let shared = PersistenceController()

    // 1. 改用 NSPersistentCloudKitContainer 以支援 CloudKit 同步
    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        // 這裡的名字 "Model" 必須對應 .xcdatamodeld 檔名
        container = NSPersistentCloudKitContainer(name: "Model")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // 2. CloudKit 同步與未來共享功能的關鍵設定
        if let description = container.persistentStoreDescriptions.first {
            // 開啟 Persistent History Tracking (CloudKit 同步必備，用於追蹤變更)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            
            // 開啟遠端變更通知 (讓 App 能收到 iCloud 來的變更)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // 未來若要實作「共享資料庫」(Shared Database)，您將需要在這裡設定 cloudKitContainerOptions
            // 例如：
            // let options = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.yourname.ParentingAPP")
            // description.cloudKitContainerOptions = options
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // 建議在正式版中優化這裡的錯誤處理，不要使用 fatalError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // 讓 ViewContext 自動合併來自 Parent Store (iCloud 背景同步) 的變更
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // 3. 設定合併策略：當衝突發生時，優先使用記憶體中(或最新)的物件屬性，避免 App 崩潰
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
