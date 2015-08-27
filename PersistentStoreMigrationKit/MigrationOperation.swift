//
//  MigrationOperation.swift
//  PersistentStoreMigrationKit
//
//  Created by Georg C. Brückmann on 26/08/15.
//  Copyright (c) 2015 Georg C. Brückmann. All rights reserved.
//

import Foundation
import CoreData

public final class MigrationOperation: NSOperation {
	public var sourceURL: NSURL!
	public var sourceStoreType: String!
	public var destinationURL: NSURL!
	public var destinationStoreType: String!
	public var destinationModel: NSManagedObjectModel!
	public var bundles: [NSBundle]!
	public let progress: NSProgress
	public private(set) var error: NSError?
	
	override public required init() {
		progress = NSProgress(totalUnitCount: 100)
		super.init()
	}
	
	@objc public enum State: Int {
		case Ready
		case Executing
		case Failed
		case Finished
		case Cancelled
	}
	private(set) public dynamic var state = State.Ready
	
	private func cancelWithError(error: NSError) {
		self.error = error
		state = .Cancelled
	}
	
	// MARK: NSOperation
	public override func start() {
		precondition(sourceURL != nil, "Missing source URL.")
		precondition(sourceStoreType != nil, "Missing source store type.")
		precondition(destinationURL != nil, "Missing destination URL.")
		precondition(destinationStoreType != nil, "Missing desetination store type.")
		precondition(destinationModel != nil, "Missing destination model.")
		precondition(bundles != nil, "Missing bundles.")
		state = .Executing
		
		var metadataError: NSError?
		let existingStoreMetadata: [NSObject: AnyObject]! = NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(sourceStoreType, URL: sourceURL, error: &metadataError)
		
		// Devise migration plan.
		var migrationPlanError: NSError?
		let migrationPlan: MigrationPlan! = MigrationPlan(storeMetadata: existingStoreMetadata, destinationModel: destinationModel, bundles: bundles, error: &migrationPlanError)
		if migrationPlan == nil {
			cancelWithError(migrationPlanError!)
			return
		}
		progress.completedUnitCount += 10
		
		// Execute migration plan.
		progress.becomeCurrentWithPendingUnitCount(90)
		var migrationPlanExecutionError: NSError?
		let migrationSucceeded = migrationPlan.executeForStoreAtURL(sourceURL, type: sourceStoreType, destinationURL: destinationURL, storeType: destinationStoreType, error: &migrationPlanExecutionError)
		if !migrationSucceeded {
			cancelWithError(migrationPlanExecutionError!)
			return
		}
		progress.resignCurrent()
		
		state = .Finished
	}
	
	class func keyPathsForValuesAffectingIsReady() -> Set<String> {
		return ["state"]
	}
	
	override public var ready: Bool {
		return state == .Ready
	}
	
	class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
		return ["state"]
	}
	
	override public var executing: Bool {
		return state == .Executing
	}
	
	class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
		return ["state"]
	}
	
	override public var finished: Bool {
		return state == .Finished
	}
	
	class func keyPathsForValuesAffectingIsCancelled() -> Set<String> {
		return ["state"]
	}
	
	override public var cancelled: Bool {
		return state == .Cancelled
	}
}