//
//  SleepActivity+CoreDataProperties.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//
//

public import Foundation
public import CoreData


public typealias SleepActivityCoreDataPropertiesSet = NSSet

extension SleepActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepActivity> {
        return NSFetchRequest<SleepActivity>(entityName: "SleepActivity")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var note: String?
    @NSManaged public var id: UUID?

}

extension SleepActivity : Identifiable {

}
