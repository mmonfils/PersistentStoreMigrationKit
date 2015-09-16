//
//  MigrationStep.swift
//  PersistentStoreMigrationKit
//
//  Created by Georg C. Brückmann on 26.08.15.
//  Copyright (c) 2015 Georg C. Brückmann. All rights reserved.
//

import Foundation
import CoreData

final class MigrationStep: NSObject {
	let mappingModel: NSMappingModel
	let sourceModel: NSManagedObjectModel
	let destinationModel: NSManagedObjectModel
	
	private var keyValueObservingContext = NSUUID().UUIDString
	
	init(sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel, mappingModel: NSMappingModel) {
		self.sourceModel = sourceModel
		self.destinationModel = destinationModel
		self.mappingModel = mappingModel
	}
	
	private var progress: NSProgress?
	
	func executeForStoreAtURL(sourceURL: NSURL, type sourceStoreType: String, destinationURL: NSURL, storeType destinationStoreType: String) throws {
		progress = NSProgress(totalUnitCount: 100)
		defer { progress = nil }
		let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
		migrationManager.addObserver(self, forKeyPath: "migrationProgress", options: .New, context: &keyValueObservingContext)
		defer { migrationManager.removeObserver(self, forKeyPath: "migrationProgress", context: &keyValueObservingContext) }
		try migrationManager.migrateStoreFromURL(sourceURL, type: sourceStoreType, options: nil, withMappingModel: mappingModel, toDestinationURL: destinationURL, destinationType: destinationStoreType, destinationOptions: nil)
	}
	
	// MARK: NSKeyValueObserving
	override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [String : AnyObject]!, context: UnsafeMutablePointer<Void>) {
		if context != &keyValueObservingContext {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			return
		}
		if let _ = object as? NSMigrationManager {
			switch keyPath {
			case "migrationProgress":
				let newMigrationProgress = (change[NSKeyValueChangeNewKey] as! NSNumber).floatValue
				progress?.completedUnitCount = Int64(newMigrationProgress * 100)
			default:
				break
			}
		}
	}
}
