//
//  LoginViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 23/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

// MARK: - CellIdentifier Enum
private enum CellIdentifier: String
{
    case username = "username"
    case password = "password"
    case login = "login"
    case add = "add"
    case confirm = "confirm"
    case create = "create"
    case cancel = "cancel"
    
    func cellHeight() -> CGFloat
    {
        switch self {
        case .cancel, .add:
            return 100
        default:
            return 44
        }
    }
}

// MARK: - TableViewState Enum
private enum TableViewState
{
    case login
    case create
    
    func identifiers() -> [CellIdentifier]
    {
        switch self {
        case .login:
            return [
                .username,
                .password,
                .login,
                .add
            ]
        case .create:
            return [
                .username,
                .password,
                .confirm,
                .create,
                .cancel
            ]
        }
    }
}

class LoginViewController: UIViewController
{
    @IBOutlet weak var tableView: UITableView!
    fileprivate var tableviewState = TableViewState.login {
        didSet {
            tableView.beginUpdates()
            let removeIndexPaths = (2 ..< oldValue.identifiers().count).map( { IndexPath(row: $0, section: 0) } )
            let addIndexPaths = (2 ..< tableviewState.identifiers().count).map( { IndexPath(row: $0, section: 0) } )
            tableView.deleteRows(at: removeIndexPaths, with: .fade)
            tableView.insertRows(at: addIndexPaths, with: .fade)
            tableView.endUpdates()
        }
    }
    
    var dataController: DataController!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier ?? "" {
        case "main":
            let dest = segue.destination as! MainViewController
            dest.dataController = dataController
            dest.user = sender as? User
            dest.transitioningDelegate = self
            dest.modalPresentationStyle = .custom
            tableviewState = .login
            let indexPaths = (0 ..< tableviewState.identifiers().count).map( { IndexPath(row: $0, section: 0) })
            let textFields = indexPaths.flatMap( { tableView.cellForRow(at: $0)?.viewWithTag(1) as? UITextField } )
            for textField in textFields {
                textField.text = nil
                textField.resignFirstResponder()
            }
        default:
            break
        }
    }
    
    @IBAction func tapped(_ sender: UITapGestureRecognizer)
    {
        let indexPaths = (0 ..< tableviewState.identifiers().count).map( { IndexPath(row: $0, section: 0) })
        let textFields = indexPaths.flatMap( { tableView.cellForRow(at: $0)?.viewWithTag(1) as? UITextField } )
        for textField in textFields { textField.resignFirstResponder() }
    }
}

// MARK: - UITableViewDelegate Implementation
extension LoginViewController: UITableViewDelegate
{
}

// MARK: - UITableViewDataSource Implementation
extension LoginViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tableviewState.identifiers().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellId = tableviewState.identifiers()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId.rawValue)!
        switch cellId {
        case .add:
            (cell.viewWithTag(1) as? UIButton)?.addTarget(self, action: #selector(addUser(_:)), for: .touchUpInside)
        case .login:
            (cell.viewWithTag(1) as? UIButton)?.addTarget(self, action: #selector(login(_:)), for: .touchUpInside)
        case .cancel:
            (cell.viewWithTag(1) as? UIButton)?.addTarget(self, action: #selector(cancel(_:)), for: .touchUpInside)
        case .create:
            (cell.viewWithTag(1) as? UIButton)?.addTarget(self, action: #selector(create(_:)), for: .touchUpInside)
        case .username, .password, .confirm:
            (cell.viewWithTag(1) as? UITextField)?.delegate = self
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if indexPath.row == 0 {
            let midY = tableView.frame.height / 2.0
            switch tableviewState {
            case .login: return midY - 44
            case .create: return midY - 66
            }
        }
        return tableviewState.identifiers()[indexPath.row].cellHeight()
    }
}

// MARK: - UINavigationBarDelegate Implementation
extension LoginViewController: UINavigationBarDelegate
{
    func position(for bar: UIBarPositioning) -> UIBarPosition
    {
        return .topAttached
    }
}

// MARK: - Private Functions
private extension LoginViewController
{
    dynamic func login(_ sender: UIButton?)
    {
        guard let userRow = tableviewState.identifiers().index(of: .username),
            let passwordRow = tableviewState.identifiers().index(of: .password) else {
            return
        }
        let users = dataController.allUsers()
        let userIndexPath = IndexPath(row: userRow, section: 0)
        let passwordIndexPath = IndexPath(row: passwordRow, section: 0)
        let user = (tableView.cellForRow(at: userIndexPath)?.viewWithTag(1) as? UITextField)?.text
        let password = (tableView.cellForRow(at: passwordIndexPath)?.viewWithTag(1) as? UITextField)?.text
        let savedUser = users.first(where: { $0.name == user } )
        if user == nil || password == nil || savedUser == nil || savedUser?.password != password {
            presentAlertVC(withTitle: "Incorrect Credentials",
                message: "An invalid username or password was entered. Please try again.")
            return
        }
        performSegue(withIdentifier: "main", sender: savedUser)
        
    }
    
    dynamic func addUser(_ sender: UIButton)
    {
        tableviewState = .create
    }
    
    dynamic func cancel(_ sender: UIButton)
    {
        tableviewState = .login
    }
    
    dynamic func create(_ sender: UIButton?)
    {
        guard let userRow = tableviewState.identifiers().index(of: .username),
            let passwordRow = tableviewState.identifiers().index(of: .password),
            let confirmRow = tableviewState.identifiers().index(of: .confirm) else {
            return
        }
        let users = dataController.allUsers()
        let userIndexPath = IndexPath(row: userRow, section: 0)
        let passwordIndexPath = IndexPath(row: passwordRow, section: 0)
        let confirmIndexPath = IndexPath(row: confirmRow, section: 0)
        let user = (tableView.cellForRow(at: userIndexPath)?.viewWithTag(1) as? UITextField)?.text
        let password = (tableView.cellForRow(at: passwordIndexPath)?.viewWithTag(1) as? UITextField)?.text
        let confirmation = (tableView.cellForRow(at: confirmIndexPath)?.viewWithTag(1) as? UITextField)?.text
        if user?.isEmpty ?? true {
            presentAlertVC(withTitle: "Invalid Username", message: "No username entered")
        }
        else if password?.isEmpty ?? true {
            presentAlertVC(withTitle: "Invalid Password", message: "No password entered")
        }
        else if password != confirmation {
            presentAlertVC(withTitle: "Password Error", message: "The passwords don't match.")
        }
        else if users.contains(where: { $0.name == user }) {
            presentAlertVC(withTitle: "User Already Exists",
                message: "The user already exists. Please select a different username")
            
        }
        else {
            dataController.mainThreadContext.perform {
                self.dataController.mainThreadContext.insert(
                    User(userName: user!, password: password!, context: self.dataController.mainThreadContext)
                )
                self.dataController.save()
            }
            performSegue(withIdentifier: "main", sender: self)
        }
    }
    
    func presentAlertVC(withTitle: String, message: String)
    {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
            alertVC.dismiss(animated: true, completion: nil)
        }))
        present(alertVC, animated: true, completion: nil)
    }
}

// MAPK: - UITextFieldDelegate Implementation
extension LoginViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField.text == nil { return false }
        let textFieldIPs: [IndexPath]
        switch tableviewState {
        case .login:
            if let userRow = tableviewState.identifiers().index(of: .username),
                let passwordRow = tableviewState.identifiers().index(of: .password) {
                textFieldIPs = [userRow, passwordRow].map( { IndexPath(row: $0, section: 0) } )
            }
            else {
                textFieldIPs = []
            }
        case .create:
            if let userRow = tableviewState.identifiers().index(of: .username),
                let passwordRow = tableviewState.identifiers().index(of: .password),
                let confirmRow = tableviewState.identifiers().index(of: .confirm) {
                textFieldIPs = [userRow, passwordRow, confirmRow].map( { IndexPath(row: $0, section: 0) } )
            }
            else {
                textFieldIPs = []
            }
        }
        let textFields = textFieldIPs.flatMap( { tableView.cellForRow(at: $0)?.viewWithTag(1) as? UITextField } )
        if let index = textFields.index(of: textField) {
            switch index {
            case (textFields.count - 1):
                switch tableviewState {
                case .login: login(nil)
                case .create: create(nil)
                }
            default: textFields[index + 1].becomeFirstResponder()
            }
        }
        return true
    }
}

// MARK: - UIViewControllerTransitioningDelegate Implementation
extension LoginViewController: UIViewControllerTransitioningDelegate
{
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return SlideAnimationController(transitionType: .dismissing)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController,
        source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return SlideAnimationController(transitionType: .presenting)
    }
}

// MARK: - SlideAnimationController
private class SlideAnimationController: NSObject, UIViewControllerAnimatedTransitioning
    {
        enum TransitionType
        {
            case presenting
            case dismissing
        }
        
        private let transitionType: TransitionType
        
        init(transitionType: TransitionType)
        {
            self.transitionType = transitionType
        }
        
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
        {
            return 0.25
        }
        
        private func dismissTranisition(using transitionContext: UIViewControllerContextTransitioning)
        {
            guard let fromVC = transitionContext.viewController(forKey: .from),
                let toVC = transitionContext.viewController(forKey: .to) else { return }
            
            let finalFrame = transitionContext.finalFrame(for: toVC)
            let initialFrame = CGRect(origin: CGPoint(x: finalFrame.origin.x - finalFrame.width,
                                                      y: finalFrame.origin.y), size: finalFrame.size)
            toVC.view.frame = initialFrame
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                toVC.view.frame = finalFrame
                fromVC.view.frame.origin.x += toVC.view.frame.width
                
            }, completion: { finished in
                if transitionContext.transitionWasCancelled {
                    transitionContext.cancelInteractiveTransition()
                    transitionContext.completeTransition(false)
                }
                else {
                    transitionContext.finishInteractiveTransition()
                    transitionContext.completeTransition(true)
                }
            })
        }
        
        private func presentTransition(using transitionContext: UIViewControllerContextTransitioning)
        {
            guard let fromVC = transitionContext.viewController(forKey: .from),
                let toVC = transitionContext.viewController(forKey: .to) else {
                    return
            }
            let finalFrame = transitionContext.finalFrame(for: toVC)
            let initialFrame = CGRect(origin: CGPoint(x: fromVC.view.frame.origin.x + fromVC.view.frame.width,
                                                      y: fromVC.view.frame.origin.y),
                                      size: finalFrame.size)
            transitionContext.containerView.addSubview(toVC.view)
            toVC.view.frame = initialFrame
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                fromVC.view.frame.origin.x -= toVC.view.frame.width
                toVC.view.frame = finalFrame
            }, completion: { finished in
                if transitionContext.transitionWasCancelled {
                    transitionContext.cancelInteractiveTransition()
                    transitionContext.completeTransition(false)
                }
                else {
                    transitionContext.finishInteractiveTransition()
                    transitionContext.completeTransition(true)
                }
            })
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
        {
            switch transitionType {
            case .dismissing: dismissTranisition(using: transitionContext)
            case .presenting: presentTransition(using: transitionContext)
            }
        }
    }
