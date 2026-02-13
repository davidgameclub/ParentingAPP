// Persistence.swift

import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()

    // 1. 使用 NSPersistentCloudKitContainer 以支援 CloudKit 同步
    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        // 這裡的名字 "Model" 必須對應 .xcdatamodeld 檔名
        container = NSPersistentCloudKitContainer(name: "Model")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // MARK: - CloudKit 多人共享設定
            
            // TODO: 請將此字串替換為您在 Apple Developer Portal > CloudKit Console 建立的 Container ID
            // 格式通常為 "iCloud.com.yourcompany.appname"
            let iCloudContainerIdentifier = "iCloud.ParentingAPP"
            
            // 取得預設的儲存路徑 (Application Support)
            let defaultDirectoryURL = NSPersistentContainer.defaultDirectoryURL()
            
            // --- 設定 1: Private Database (私有資料庫) ---
            // 這是預設的主要儲存區，存放使用者自己的資料
            let privateStoreURL = defaultDirectoryURL.appendingPathComponent("Model.sqlite")
            let privateDescription = NSPersistentStoreDescription(url: privateStoreURL)
            
            // [FIX] 若您在 Core Data Model Editor 中沒有特別新增名為 "Default" 的 Configuration，請勿指定此行，否則會導致 Crash
            // privateDescription.configuration = "Default"
            
            let privateOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: iCloudContainerIdentifier)
            privateOptions.databaseScope = .private
            privateDescription.cloudKitContainerOptions = privateOptions
            
            // 開啟同步必備選項
            privateDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            privateDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // --- 設定 2: Shared Database (共享資料庫) ---
            // 這是用來存放與他人共享之 records 的儲存區
            let sharedStoreURL = defaultDirectoryURL.appendingPathComponent("Model_Shared.sqlite")
            let sharedDescription = NSPersistentStoreDescription(url: sharedStoreURL)
            
            // [FIX] 同上，若無 "Default" Configuration，請勿指定
            // sharedDescription.configuration = "Default"
            
            let sharedOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: iCloudContainerIdentifier)
            sharedOptions.databaseScope = .shared // 關鍵：設定 Scope 為 .shared
            sharedDescription.cloudKitContainerOptions = sharedOptions
            
            // 開啟同步必備選項
            sharedDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            sharedDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // 將兩個 Description 載入 Container
            // 注意：Private Store 放在第一個，這樣新增物件時預設會寫入 Private Store
            container.persistentStoreDescriptions = [privateDescription, sharedDescription]
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // 建議在正式版中優化這裡的錯誤處理
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // 讓 ViewContext 自動合併來自 Parent Store (iCloud 背景同步) 的變更
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // 3. 設定合併策略：當衝突發生時，優先使用記憶體中(或最新)的物件屬性，避免 App 崩潰
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
