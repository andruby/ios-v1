//
//  Analytics.swift
//  Canvas
//
//  Created by Sam Soffes on 11/25/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import Mixpanel
import CanvasKit

struct Analytics {

	// MARK: - Types

	enum Event {
		case LoggedOut
		case LoggedIn
		case LaunchedApp
		case ChangedCollection(collection: Collection)
		case OpenedCanvas

		var name: String {
			switch self {
			case .LoggedOut: return "Logged Out"
			case .LoggedIn: return "Logged In"
			case .LaunchedApp: return "Launched App"
			case .ChangedCollection(_): return "Changed Collection"
			case .OpenedCanvas: return "Opened Canvas"
			}
		}

		var parameters: [String: AnyObject]? {
			switch self {
			case .ChangedCollection(let collection): return ["collection_name": collection.name]
			default: return nil
			}
		}
	}


	// MARK: - Properties

	private static let mixpanel: Mixpanel = {
		var mp = Mixpanel(token: "447ae99e6cff699db67f168818c1dbf9")

		let uniqueIdentifier: String
		let key = "Identifier"
		if let identifier = NSUserDefaults.standardUserDefaults().stringForKey(key) {
			uniqueIdentifier = identifier
		} else {
			let identifier = NSUUID().UUIDString
			NSUserDefaults.standardUserDefaults().setObject(identifier, forKey: key)
			uniqueIdentifier = identifier
		}

		mp.identify(uniqueIdentifier)

		#if DEBUG
			mp.enabled = false
		#endif

		return mp
	}()


	// MARK: - Tracking

	static func track(event: Event) {
		var params = event.parameters ?? [:]
		if let account = AccountController.sharedController.currentAccount {
			params["id"] = account.user.ID
			params["$username"] = account.user.username
		}
		mixpanel.track(event.name, parameters: params)
	}
}

