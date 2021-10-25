//
//  HomeCoordinator.swift
//  SodaPopcorn
//
//  Created by Francisco Cordoba on 19/9/21.
//

import Combine
import Foundation
import UIKit

final class HomeCoordinator: Coordinator {
	// MARK: - Const
	private let parentViewController: UIViewController
	private let movieService = MovieService.shared()
	private let imageService = PosterImageService.shared()

	// MARK: - Vars
	var childCoordinators = [Coordinator]()
	private var homeVC: HomeVC?
	private var window: UIWindow

	private var cancellable = Set<AnyCancellable>()

	init(window: UIWindow) {
		self.parentViewController = RootViewController()

		self.window = window
		self.window.rootViewController = parentViewController
		self.window.makeKeyAndVisible()

		_ = Reachability.signalProducer.sink { reachability in
			switch reachability {
				case .none:
					if let rootViewController = self.window.rootViewController {
						Alert.showAlert(on: rootViewController, title: NSLocalizedString("alert", comment: "Alert"), message: NSLocalizedString("no_internet_connection", comment: "No internet connection"))
					}
				default:
					break
			}
		}
	}

	func start() {
		self.homeVC = HomeVC()

		let newMoviesListVM = NewMoviesListVM(movieService: movieService)
		let newMoviesListViewController = NavigationController(rootViewController: NewMoviesListVC(viewModel: newMoviesListVM))
		newMoviesListViewController.tabBarItem = UITabBarItem(title: "New Movies", image: UIImage(systemName: "film.fill"), tag: 0)

		homeVC?.viewControllers = [newMoviesListViewController]
		homeVC?.selectedIndex = 0

		parentViewController.addChild(homeVC!)
		parentViewController.view.addSubview(homeVC!.view)
		homeVC!.didMove(toParent: parentViewController)

		newMoviesListVM.outputs.movieSelectedAction()
			.sink { [weak self] movie in
				guard let `self` = self else { return }
				self.showMovieDetails(movie: movie)
			}.store(in: &cancellable)
	}

	private func showMovieDetails(movie: Movie) {
		print(movie.title ?? "")

		let viewModel = MovieDetailsVM(movie: movie)
		let viewController = MovieDetailsVC(viewModel: viewModel)

		homeVC?.present(viewController, animated: true, completion: nil)

		viewModel.outputs.closeButtonAction()
			.sink { [weak self] _ in
				guard let `self` = self else { return }
				self.homeVC?.dismiss(animated: true, completion: nil)
			}.store(in: &cancellable)
	}
}
