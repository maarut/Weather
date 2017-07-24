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
    var user: User!
    weak var shareButton: UIBarButtonItem!
    weak var deleteButton: UIBarButtonItem!
    
    fileprivate var savedLocations: NSFetchedResultsController<SavedLocation>!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        savedLocations = dataController.savedLocations(forUser: user)
        savedLocations.delegate = self
        deleteButton.target = self
        deleteButton.action = #selector(deleteLocation)
        deleteButton.isEnabled = false
        do { try savedLocations.performFetch() }
        catch let error as NSError { NSLog("\(error)\n\(error.localizedDescription)") }
        delegate = self
        dataSource = self
        
        setViewControllers([createVC(withLocation: nil)], direction: .forward, animated: false, completion: nil)
        // Do any additional setup after loading the view.
    }

    func pageViewController(_ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController) -> UIViewController?
    {
        guard let vc = viewController as? ForecastViewController else { return nil }
        if let location = vc.location,
            let savedLocations = savedLocations.fetchedObjects,
            let index = savedLocations.index(of: location) {
            let vc = createVC(withLocation: nil)
            if index > 0 { vc.location = savedLocations[index - 1] }
            return vc
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        guard let vc = viewController as? ForecastViewController,
            let savedLocations = savedLocations.fetchedObjects else {
            return nil
        }
        guard savedLocations.count > 0 else { return nil }
        guard vc.location != savedLocations.last else { return nil }

        let nextLocation: SavedLocation
        if let location = vc.location, let index = savedLocations.index(of: location) {
            nextLocation = savedLocations[index + 1]
        }
        else {
            nextLocation = savedLocations[0]
        }
        return createVC(withLocation: nextLocation)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int
    {
        return (savedLocations.fetchedObjects?.count ?? 0) + 1
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int
    {
        if let vc = viewControllers?.first as? ForecastViewController,
            let location = vc.location,
            let savedLocations = self.savedLocations.fetchedObjects,
            let index = savedLocations.index(of: location) {
            return index + 1
        }
        return 0
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        if completed {
            if let vc = viewControllers?.first as? ForecastViewController {
                deleteButton.isEnabled = vc.location != nil
            }
        }
    }
}

// MARK: - Private Functions
private extension PageViewController
{
    dynamic func deleteLocation()
    {
        if let location = (viewControllers?.first as? ForecastViewController)?.location {
            dataController.delete(location)
            dataController.save()
        }
    }
    
    func createVC(withLocation location: SavedLocation?) -> ForecastViewController
    {
        guard let storyboard = storyboard else { fatalError("UI wasn't constructed from a storyboard.") }
        let vc = storyboard.instantiateViewController(withIdentifier: "Forecast") as! ForecastViewController
        vc.location = location
        vc.shareButton = shareButton
        vc.dataController = dataController
        vc.user = user
        return vc
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
            let oldIndex = indexPath!.row
            let location: SavedLocation? = oldIndex == 0 ? nil : savedLocations.fetchedObjects![oldIndex - 1]
            
            setViewControllers([createVC(withLocation: location)], direction: .reverse, animated: true, completion: nil)
            break
        case .insert:
            if let loc = anObject as? SavedLocation {
                setViewControllers([createVC(withLocation: loc)], direction: .forward, animated: false, completion: nil)
                deleteButton.isEnabled = true
            }
            break
        case .move, .update:
            break
        }
    }
}
