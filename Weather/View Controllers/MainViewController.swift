//
//  MainViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 19/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class MainViewController: UIViewController
{
    
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    var dataController: DataController!
    var user: User!

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        if user.isDeleted || user.managedObjectContext == nil {
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier ?? "" {
        case "embed":
            let nextVC = segue.destination as! PageViewController
            nextVC.shareButton = shareButton
            nextVC.deleteButton = deleteButton
            nextVC.dataController = dataController
            nextVC.user = user
        case "search":
            let nextVC = segue.destination as! SearchViewController
            nextVC.dataController = dataController
            nextVC.user = user
        case "settings":
            let nextVC = segue.destination as! SettingsContainerViewController
            nextVC.dataController = dataController
            nextVC.user = user
        default:
            break
        }
    }

    @IBAction func logout(_ sender: UIBarButtonItem)
    {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UINavigationBarDelegate Implementation
extension MainViewController: UINavigationBarDelegate
{
    func position(for bar: UIBarPositioning) -> UIBarPosition
    {
        return .topAttached
    }
}
