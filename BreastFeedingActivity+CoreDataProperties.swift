//
//  BreastFeedingActivity+CoreDataProperties.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//
//

public import Foundation
public import CoreData


public typealias BreastFeedingActivityCoreDataPropertiesSet = NSSet

extension BreastFeedingActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BreastFeedingActivity> {
        return NSFetchRequest<BreastFeedingActivity>(entityName: "BreastFeedingActivity")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var note: String?
    @NSManaged public var volume: Int32
    @NSManaged public var id: UUID?

}

extension BreastFeedingActivity : Identifiable {

}
