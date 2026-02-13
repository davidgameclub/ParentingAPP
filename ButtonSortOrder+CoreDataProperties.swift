//
//  ButtonSortOrder+CoreDataProperties.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//
//

public import Foundation
public import CoreData


public typealias ButtonSortOrderCoreDataPropertiesSet = NSSet

extension ButtonSortOrder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ButtonSortOrder> {
        return NSFetchRequest<ButtonSortOrder>(entityName: "ButtonSortOrder")
    }

    @NSManaged public var typeID: Int16
    @NSManaged public var sortIndex: Int16

}

extension ButtonSortOrder : Identifiable {

}
