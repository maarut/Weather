//
//  SettingsViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 24/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

class SettingsContainerViewController: UIViewController
{
    var user: User!
    var dataController: DataController!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier ?? "" {
        case "embed":
            let nextVC = segue.destination as! SettingsViewController
            nextVC.user = user
        default: break
        }
        
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem)
    {
        user.managedObjectContext?.rollback()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: UIBarButtonItem)
    {
        if user.managedObjectContext?.hasChanges ?? false {
            do { try user.managedObjectContext?.save(); dataController.save() }
            catch let error as NSError { NSLog("\(error)\n\(error.localizedDescription)")}
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteAccount(_ sender: UIButton)
    {
        let alertVC = UIAlertController(title: "Confirm Account Deletion",
            message: "Are you sure you would like to delete your account?", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.deleteUser()
        }))
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    private func deleteUser()
    {
        dataController.mainThreadContext.perform {
            if let moc = self.user.managedObjectContext {
                moc.delete(self.user)
                do { try moc.save() }
                catch let error as NSError { NSLog("\(error)\n\(error.localizedDescription)") }
                self.dataController.save()
            }
        }
        dismiss(animated: true, completion: nil)
    }
}

extension SettingsContainerViewController: UINavigationBarDelegate
{
    func position(for bar: UIBarPositioning) -> UIBarPosition
    {
        return .topAttached
    }
}

class SettingsViewController: UITableViewController
{
    var user: User!
    @IBOutlet weak var forecastCount: UILabel!
    @IBOutlet weak var units: UISegmentedControl!
    @IBOutlet weak var stepper: UIStepper!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        units.selectedSegmentIndex = Int(user.units)
        stepper.value = Double(user.forecastedCount)
        forecastCount.text = "\(user.forecastedCount)"
    }
    
    @IBAction func unitsChanged(_ sender: UISegmentedControl)
    {
        user.managedObjectContext?.perform {
            self.user.units = Int32(sender.selectedSegmentIndex)
        }
    }
    
    @IBAction func forecastCountChanged(_ sender: UIStepper)
    {
        user.managedObjectContext?.perform {
            let count = Int32(sender.value)
            self.forecastCount.text = "\(count)"
            self.user.forecastedCount = count
        }
    }
}

