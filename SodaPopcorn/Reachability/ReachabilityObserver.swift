//
//  ReachabilityObserver.swift
//  SodaPopcorn
//
//  Created by Wilson Desimini on 10/17/21.
//

import Foundation
import Reachability

protocol ReachabilityObserver: ReachabilityHandler {
    var reachability: Reachability? { get }
    func observeReachability()
}

extension ReachabilityObserver {
    func observeReachability() {
        let center = NotificationCenter.default
        let selector = #selector(didReceiveReachabilityNotification(_:))
        let name = Notification.Name.reachabilityChanged
        center.addObserver(self, selector: selector, name: name, object: reachability)
    }
}
