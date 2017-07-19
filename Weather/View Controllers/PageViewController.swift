//
//  PageViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 19/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import CoreData

class PageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource
{
    var dataController: DataController!
    fileprivate var savedLocations: NSFetchedResultsController<SavedLocation>!
    
    fileprivate lazy var pages: [MainViewController] = {
        return self.createViewControllers()
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        savedLocations = dataController.savedLocations()
        savedLocations.delegate = self
        delegate = self
        dataSource = self
        
        setViewControllers(pages, direction: .forward, animated: false, completion: nil)
        // Do any additional setup after loading the view.
    }

    func pageViewController(_ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        guard let vc = viewController as? MainViewController else { return nil }
        if let index = pages.index(of: vc) {
            if index > 0 && index < pages.count { return pages[index - 1] }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        guard let vc = viewController as? MainViewController else { return nil }
        if let index = pages.index(of: vc) {
            if index < (pages.count - 1) { return pages[index + 1] }
        }
        return nil
    }
    
}

private extension PageViewController
{
    func createViewControllers() -> [MainViewController]
    {
        var vcs = [MainViewController]()
        if let storyboard = storyboard {
            if let savedLocations = savedLocations.fetchedObjects {
                for location in savedLocations {
                    let vc = storyboard.instantiateViewController(withIdentifier: "Forecast") as! MainViewController
                    vc.dataController = dataController
                    vc.location = location
                    vcs.append(vc)
                }
            }
            let vc = storyboard.instantiateViewController(withIdentifier: "Forecast") as! MainViewController
            vc.dataController = dataController
            vcs.insert(vc, at: 0)
        }
        
        return vcs
    }
}

extension PageViewController: NSFetchedResultsControllerDelegate
{
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any,
        at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type {
        case .delete, .insert:
            
            break
        case .move, .update:
            break
        }
    }
}
