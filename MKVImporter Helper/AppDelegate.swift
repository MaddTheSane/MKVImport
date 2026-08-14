//
//  AppDelegate.swift
//  MKVImporter Helper
//
//  Created by C.W. Betts on 7/14/26.
//  Copyright © 2026 C.W. Betts. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet var window: NSWindow!
	@IBOutlet weak var statusImage: NSImageView!
	@IBOutlet weak var infoTextView: NSTextField!
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		let urls: [URL]
		if #available(macOS 12.0, *) {
			urls = NSWorkspace.shared.urlsForApplications(withBundleIdentifier: "uk.org.marginal.qlvideo")
		} else {
			// Fallback on earlier versions
			urls = (LSCopyApplicationURLsForBundleIdentifier("uk.org.marginal.qlvideo" as CFString, nil)?.takeRetainedValue() as? [URL]) ?? []
		}
		if urls.isEmpty {
			infoTextView.stringValue = "Everything should be okay!"
			statusImage.image = NSImage(named: NSImage.statusAvailableName)
		} else {
			infoTextView.stringValue = "QuickLook Video may prevent the importer from working!"
			statusImage.image = NSImage(named: NSImage.statusPartiallyAvailableName)
		}
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}
}

