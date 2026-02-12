//
//  DiaperActivity+CoreDataProperties.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//
//

public import Foundation
public import CoreData


public typealias DiaperActivityCoreDataPropertiesSet = NSSet

extension DiaperActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DiaperActivity> {
        return NSFetchRequest<DiaperActivity>(entityName: "DiaperActivity")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var note: String?
    @NSManaged public var type: String?
    @NSManaged public var id: UUID?

}

extension DiaperActivity : Identifiable {

}
