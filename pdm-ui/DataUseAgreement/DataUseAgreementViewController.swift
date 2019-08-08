//
//  DataUseAgreementViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

// Master controller for the data use agreement view.
class DataUseAgreementViewController: UINavigationController, UINavigationControllerDelegate {
    var dataUseAgreement: DataUseAgreement? {
        didSet {
            createPages()
        }
    }
    var pages = [UIViewController]()
    var currentPage = 0
    var fakeRootController: UIViewController!
    var previousPageCommand: UIKeyCommand!
    var nextPageCommand: UIKeyCommand!
    // If you mash the keys, you can trigger navigations faster than the system can handle.
    var isIgnoringKeyNavigation = false
    var legalDetailsViewController: LegalDetailsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        fakeRootController = FakeRootViewController()
        previousPageCommand = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(DataUseAgreementViewController.moveToPreviousPage), discoverabilityTitle: "Previous Page")
        nextPageCommand = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(DataUseAgreementViewController.moveToNextPage), discoverabilityTitle: "Next Page")
        setNavigationKeyControls(enabled: true)
        if pages.count == 0 && dataUseAgreement != nil {
            // Pages may not have been created because the DUA may have been set before we were loaded
            createPages()
        }
        // The initial view we have showing is simply a loading indicator.
        if pages.count > 0 {
            // Replace the first page with the first page
            setViewControllers([ fakeRootController, pages[0] ], animated: false)
        } else {
            print("Not going to first page (no pages loaded)")
        }
        // Also create the legal details view so we don't create it on-demand and so that parts are loaded immediately
        let detailsView = storyboard?.instantiateViewController(withIdentifier: "LegalDetails")
        if let legalDetailsView = detailsView as? LegalDetailsViewController {
            legalDetailsView.dataUseAgreement = dataUseAgreement
            self.legalDetailsViewController = legalDetailsView
            // Force it to load
            legalDetailsView.loadViewIfNeeded()
        }
    }

    func setNavigationKeyControls(enabled: Bool) {
        if (enabled) {
            addKeyCommand(previousPageCommand)
            addKeyCommand(nextPageCommand)
        } else {
            removeKeyCommand(previousPageCommand)
            removeKeyCommand(nextPageCommand)
        }
    }

    // Creates (or recreates) the pages from the DUA.
    func createPages() {
        pages.removeAll()
        guard let dua = dataUseAgreement, let storyboard = storyboard else {
            // Just quit if we're missing anything
            print("Cannot create pages (not fully loaded)")
            return
        }
        for page in dua.pages {
            let viewController = storyboard.instantiateViewController(withIdentifier: "ComicPage")
            if let comicPageViewController = viewController as? ComicPageViewController {
                comicPageViewController.page = page
                comicPageViewController.pageNumber = pages.count
                pages.append(comicPageViewController)
            }
        }
        // Then create a few static pages (sort of)
        pages.append(storyboard.instantiateViewController(withIdentifier: "DigitalSignature"))
    }

    @objc func moveToPreviousPage() {
        if (!isIgnoringKeyNavigation) {
            goToPreviousPage(animated: true)
        }
    }

    func goToPreviousPage(animated: Bool = true) {
        // For this, if we're not at page 0, just pop off the current page
        if currentPage > 0 {
            popViewController(animated: animated)
        }
    }

    @objc func moveToNextPage() {
        if (!isIgnoringKeyNavigation) {
            goToNextPage(animated: true)
        }
    }

    func goToNextPage(animated: Bool = true) {
        guard let comicPageController = topViewController as? ComicPageViewController,
            let pageNumber = comicPageController.pageNumber else {
                // Currently this means we're onto the digital signature, so "next page" can no longer be handled by this controller and is dealt with by the pages themselves.
                return
        }
        currentPage = pageNumber + 1
        if currentPage < 0 {
            currentPage = 0
        }
        if currentPage >= pages.count {
            // This means there is no next page so do nothing
            return
        }
        pushViewController(pages[currentPage], animated: animated)
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController == fakeRootController {
            // In this (special) case, dismiss ourself
            dismiss(animated: true)
            return
        }
        // Will show is called as the view is showing, so disable keyboard navigation at this point
        isIgnoringKeyNavigation = true
    }

    // Used to ensure we know what page we're currently at so things work correctly
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // At this point the view controller is visible and we can use it
        isIgnoringKeyNavigation = false
    }

    func showLegalDetails(for page: DataUseAgreementPage) {
        if let legalDetailsViewController = legalDetailsViewController {
            legalDetailsViewController.page = page
            show(legalDetailsViewController, sender: self)
        }
    }

    // MARK: - Navigation

    //override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //}
}

class FakeRootViewController: UIViewController {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        // Do (almost) nothing
        view = UIView()
        view.backgroundColor = UIColor.white
    }
}
