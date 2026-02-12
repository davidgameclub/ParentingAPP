//
//  WakeupActivity+CoreDataProperties.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//
//

public import Foundation
public import CoreData


public typealias WakeupActivityCoreDataPropertiesSet = NSSet

extension WakeupActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WakeupActivity> {
        return NSFetchRequest<WakeupActivity>(entityName: "WakeupActivity")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var note: String?
    @NSManaged public var id: UUID?

}

extension WakeupActivity : Identifiable {

}
