//
//  ContainerViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 19/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController
{
    
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    var dataController: DataController!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier ?? "" {
        case "embed":
            let nextVC = segue.destination as! PageViewController
            nextVC.shareButton = shareButton
            nextVC.deleteButton = deleteButton
            nextVC.dataController = dataController
        case "search":
            let nextVC = segue.destination as! SearchViewController
            nextVC.dataController = dataController
        default:
            break
        }
    }

}

// MARK: - UINavigationBarDelegate Implementation
extension ContainerViewController: UINavigationBarDelegate
{
    func position(for bar: UIBarPositioning) -> UIBarPosition
    {
        return .topAttached
    }
}
