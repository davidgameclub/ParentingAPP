//
//  FeedingBottleActivity+CoreDataProperties.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//
//

public import Foundation
public import CoreData


public typealias FeedingBottleActivityCoreDataPropertiesSet = NSSet

extension FeedingBottleActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FeedingBottleActivity> {
        return NSFetchRequest<FeedingBottleActivity>(entityName: "FeedingBottleActivity")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var note: String?
    @NSManaged public var volume: Int32
    @NSManaged public var id: UUID?

}

extension FeedingBottleActivity : Identifiable {

}
