//
//  CustomActivity+CoreDataProperties.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//
//

public import Foundation
public import CoreData


public typealias CustomActivityCoreDataPropertiesSet = NSSet

extension CustomActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomActivity> {
        return NSFetchRequest<CustomActivity>(entityName: "CustomActivity")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var note: String?
    @NSManaged public var isStart: Bool
    @NSManaged public var id: UUID?

}

extension CustomActivity : Identifiable {

}

