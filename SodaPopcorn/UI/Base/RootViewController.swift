//
//  RootViewController.swift
//  SodaPopcorn
//
//  Created by Wilson Desimini on 10/17/21.
//

import Reachability
import UIKit

final class RootViewController: BaseViewController, ReachabilityObserver {
    var reachability = try? Reachability()
    
    override init() {
        super.init()
        observeReachability()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        try? reachability?.startNotifier()
    }
    
    @objc func didReceiveReachabilityNotification(_ notification: Notification) {
        let reachability = notification.object as! Reachability
        // handle reachability updates with child controllers, etc
    }
}
