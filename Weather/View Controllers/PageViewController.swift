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
    weak var shareButton: UIBarButtonItem!
    weak var deleteButton: UIBarButtonItem!
    
    fileprivate var savedLocations: NSFetchedResultsController<SavedLocation>!
    fileprivate var currentIndex = 0 {
        didSet {
            deleteButton.isEnabled = currentIndex != 0
        }
    }
    
    fileprivate lazy var pages: [MainViewController] = {
        return self.createViewControllers()
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        savedLocations = dataController.savedLocations()
        savedLocations.delegate = self
        deleteButton.target = self
        deleteButton.action = #selector(deleteLocation)
        deleteButton.isEnabled = false
        do { try savedLocations.performFetch() }
        catch let error as NSError { NSLog("\(error)\n\(error.localizedDescription)") }
        delegate = self
        dataSource = self
        
        if let page = pages.first {
            setViewControllers([page], direction: .forward, animated: false, completion: nil)
        }
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
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int
    {
        return savedLocations.fetchedObjects?.count ?? 0
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int
    {
        return currentIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        if completed {
            if let vc = viewControllers?.first as? MainViewController, let index = pages.index(of: vc) {
                currentIndex = index
            }
        }
    }
}

// MARK: - Private Functions
private extension PageViewController
{
    dynamic func deleteLocation()
    {
        if let location = savedLocations.fetchedObjects?[currentIndex - 1] {
            dataController.delete(location)
            dataController.save()
        }
    }
    
    func createViewControllers() -> [MainViewController]
    {
        var vcs = [MainViewController]()
        if let storyboard = storyboard {
            if let savedLocations = savedLocations.fetchedObjects {
                for location in savedLocations {
                    let vc = storyboard.instantiateViewController(withIdentifier: "Forecast") as! MainViewController
                    vc.dataController = dataController
                    vc.location = location
                    vc.shareButton = shareButton
                    vcs.append(vc)
                }
            }
            let vc = storyboard.instantiateViewController(withIdentifier: "Forecast") as! MainViewController
            vc.dataController = dataController
            vc.shareButton = shareButton
            vcs.insert(vc, at: 0)
        }
        
        return vcs
    }
}

// MARK: - NSFetchedResultsControllerDelegate Implementation
extension PageViewController: NSFetchedResultsControllerDelegate
{
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any,
        at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type {
        case .delete:
            pages.remove(at: currentIndex)
            currentIndex -= 1
            let vc = pages[currentIndex]
            setViewControllers([vc], direction: .reverse, animated: true, completion: nil)
            break
        case .insert:
            if let loc = anObject as? SavedLocation, let storyboard = storyboard {
                let vc = storyboard.instantiateViewController(withIdentifier: "Forecast") as! MainViewController
                vc.dataController = dataController
                vc.location = loc
                vc.shareButton = shareButton
                pages.append(vc)
                currentIndex = pages.count
                setViewControllers([vc], direction: .forward, animated: true, completion: nil)
            }
            break
        case .move, .update:
            break
        }
    }
}
