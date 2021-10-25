//
//  ReachabilityHandler.swift
//  SodaPopcorn
//
//  Created by Wilson Desimini on 10/17/21.
//

import Foundation

@objc protocol ReachabilityHandler {
    func didReceiveReachabilityNotification(_ notification: Notification)
}
