//
//  UserProfile+CoreDataProperties.swift
//  ParentingAPP
//
//  Created by Michael on 2026/2/12.
//
//

public import Foundation
public import CoreData


public typealias UserProfileCoreDataPropertiesSet = NSSet

extension UserProfile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        return NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }

    @NSManaged public var birthDate: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var gender: String?
    @NSManaged public var name: String?

}

extension UserProfile : Identifiable {

}
