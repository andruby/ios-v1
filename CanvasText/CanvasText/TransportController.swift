//
//  TransportController.swift
//  Canvas
//
//  Created by Sam Soffes on 11/10/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import WebKit

class TransportController: NSObject {
	
	// MARK: - Properties

	let serverURL: NSURL
	private let accessToken: String
	let collectionID: String
	let canvasID: String
	weak var delegate: TransportControllerDelegate?
	var webView: WKWebView!
	
	
	// MARK: - Initializers
	
	init(serverURL: NSURL, accessToken: String, collectionID: String, canvasID: String) {
		self.serverURL = serverURL
		self.accessToken = accessToken
		self.collectionID = collectionID
		self.canvasID = canvasID
		
		super.init()
		
		let configuration = WKWebViewConfiguration()
		configuration.allowsAirPlayForMediaPlayback = false

		#if !os(OSX)
			configuration.allowsInlineMediaPlayback = false
			configuration.allowsPictureInPictureMediaPlayback = false
		#endif

		// Setup script handler
		let userContentController = WKUserContentController()
		userContentController.addScriptMessageHandler(self, name: "share")
		
		// Connect
		let js = "Canvas.connect('\(serverURL.absoluteString)', '\(accessToken)', '\(collectionID)', '\(canvasID)');"
		userContentController.addUserScript(WKUserScript(source: js, injectionTime: .AtDocumentEnd, forMainFrameOnly: true))
		configuration.userContentController = userContentController
		
		// Load file
		webView = WKWebView(frame: .zero, configuration: configuration)
	}


	// MARK: - Connecting

	func reload() {
		let fileURL = NSBundle(forClass: TransportController.self).URLForResource("editor", withExtension: "html")!
		webView.loadFileURL(fileURL, allowingReadAccessToURL: fileURL)
	}
	
	
	// MARK: - Operations
	
	func submitOperation(operation: Operation) {
		switch operation {
		case .Insert(let location, let string): insert(location: location, string: string)
		case .Remove(let location, let length): remove(location: location, length: length)
		}
	}

	
	// MARK: - Private
	
	private func insert(location location: UInt, string: String) {
		guard let data = try? NSJSONSerialization.dataWithJSONObject([string], options: []),
			json = String(data: data, encoding: NSUTF8StringEncoding)
			else { return }
		
		webView.evaluateJavaScript("Canvas.insert(\(location), \(json)[0]);", completionHandler: nil)
	}
	
	private func remove(location location: UInt, length: UInt) {
		webView.evaluateJavaScript("Canvas.remove(\(location), \(length));", completionHandler: nil)
	}
}


protocol TransportControllerDelegate: class {
	func transportController(controller: TransportController, didReceiveSnapshot text: String)
	func transportController(controller: TransportController, didReceiveOperation operation: Operation)
}


extension TransportController: WKScriptMessageHandler {
	func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
		guard let dictionary = message.body as? [String: AnyObject] else { return }
		
		if let dict = dictionary["op"] as? [String: AnyObject], operation = Operation(dictionary: dict) {
			delegate?.transportController(self, didReceiveOperation: operation)
		} else if let snapshot = dictionary["snapshot"] as? String {
			delegate?.transportController(self, didReceiveSnapshot: snapshot)
		}
	}
}