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
	private let parentViewController: BaseViewController
	private let movieService = MovieService.shared()
    private let storageService = StorageService.shared()

	// MARK: - Vars
	var childCoordinators = [Coordinator]()
	private var homeVC: HomeVC?
	private var window: UIWindow

	private var cancellable = Set<AnyCancellable>()

	init(window: UIWindow) {
		self.parentViewController = BaseViewController()

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

        // Home
        let moviesVM = MoviesVM(movieService: movieService, searchCriteria: .nowPlaying, presentedViewController: false)
		let moviesVC = MoviesVC(viewModel: moviesVM)
        let moviesNavigationController = NavigationController(rootViewController: moviesVC)

        moviesNavigationController.tabBarItem = UITabBarItem(title: NSLocalizedString("home", comment: "Home"), image: UIImage(systemName: "film.fill"), tag: 0)

        // Search
        let searchVM = SearchVM(movieService: movieService)
        let searchVC = SearchVC(viewModel: searchVM)
        let searchNavigationController = NavigationController(rootViewController: searchVC)

        searchVC.tabBarItem = UITabBarItem(title: NSLocalizedString("search", comment: "Search"), image: UIImage(systemName: "magnifyingglass"), tag: 1)

        // Favorites
        let favoritesVM = FavoritesVM(movieService: movieService, storageService: storageService)
        let favoritesVC = FavoritesVC(viewModel: favoritesVM)
        let favoritesNavigationController = NavigationController(rootViewController: favoritesVC)

        favoritesVC.tabBarItem = UITabBarItem(title: NSLocalizedString("favorites", comment: "Favorites"), image: UIImage(systemName: "star.fill"), tag: 2)

		homeVC?.viewControllers = [moviesNavigationController, searchNavigationController, favoritesNavigationController]
		homeVC?.selectedIndex = 0
        homeVC?.tabBar.tintColor = UIColor(named: "PrimaryColor")

		parentViewController.addChild(homeVC!)
		parentViewController.view.addSubview(homeVC!.view)
		homeVC!.didMove(toParent: parentViewController)

        moviesVM.outputs.movieSelectedAction()
			.sink { [weak self] movie in
                self?.showMovieDetails(movie: movie, on: moviesNavigationController)
			}.store(in: &cancellable)

        searchVM.outputs.genreSelectedAction()
            .sink { [weak self] genre in
                self?.showMovieList(searchCriteria: .discover(genre: genre), on: searchNavigationController)
            }.store(in: &cancellable)

        searchVM.outputs.movieSelectedAction()
            .sink { [weak self] movie in
                self?.showMovieDetails(movie: movie, on: searchNavigationController)
            }.store(in: &cancellable)

        favoritesVM.outputs.movieSelectedAction()
            .sink { [weak self] movie in
                self?.showMovieDetails(movie: movie, on: favoritesNavigationController)
            }.store(in: &cancellable)
	}

	private func showMovieDetails(movie: Movie, on baseViewController: UINavigationController) {
        let viewModel = MovieDetailsVM(movieService: movieService, storageService: storageService, movie: movie)
		let viewController = MovieDetailsVC(viewModel: viewModel)

        let navigationController = NavigationController(rootViewController: viewController)
        baseViewController.present(navigationController, animated: true, completion: nil)

		viewModel.outputs.closeButtonAction()
			.sink { _ in
                baseViewController.dismiss(animated: true, completion: nil)
			}.store(in: &cancellable)

        viewModel.outputs.galleryButtonAction()
            .sink { [weak self] _ in
                self?.showGalleryView(with: movie, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.overviewTextAction()
            .sink { [weak self] overview in
                self?.showCustomLongTextView(with: overview, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.creditsButtonAction()
            .sink { [weak self] (movie, credits) in
                self?.showCreditsView(with: credits, of: movie, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.castMemberAction()
            .sink { [weak self] person in
                self?.showPersonDetailsView(with: person, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.movieSelectedAction()
            .sink { [weak self] movie in
                self?.showMovieDetails(movie: movie, with: navigationController)
            }.store(in: &cancellable)
	}

    private func showBackdropImagesView(with selectedImage: String, and images: [String], on navigationController: NavigationController) {
        let viewModel = BackdropImagesVM(selectedImage: selectedImage, images: images)
        let viewController = BackdropImagesVC(viewModel: viewModel)

        navigationController.present(viewController, animated: true, completion: nil)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                navigationController.dismiss(animated: true, completion: nil)
            }.store(in: &cancellable)
    }

    private func showPosterImageView(with selectedImage: String, and images: [String], on navigationController: UIViewController) {
        let viewModel = PosterImagesVM(selectedImage: selectedImage, images: images)
        let viewController = PosterImagesVC(viewModel: viewModel)

        navigationController.present(viewController, animated: true, completion: nil)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                navigationController.dismiss(animated: true, completion: nil)
            }.store(in: &cancellable)
    }

    private func showProfileImageView(with selectedImage: String, and images: [String], on navigationController: UIViewController) {
        let viewModel = ProfileImageVM(selectedImage: selectedImage, images: images)
        let viewController = ProfileImageVC(viewModel: viewModel)

        navigationController.present(viewController, animated: true, completion: nil)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                navigationController.dismiss(animated: true, completion: nil)
            }.store(in: &cancellable)
    }

    private func showGalleryView(with movie: Movie, on navigationController: NavigationController) {
        let viewModel = GalleryVM(movieService: movieService, movie: movie)
        let viewController = GalleryVC(viewModel: viewModel)

        navigationController.pushViewController(viewController, animated: true)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                navigationController.popViewController(animated: true)
            }.store(in: &cancellable)

        viewModel.outputs.backdropImagesAction()
            .sink { [weak self] (selectedImage, images) in
                self?.showBackdropImagesView(with: selectedImage, and: images, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.posterImagesAction()
            .sink { [weak self] (selectedImage, images) in
                self?.showPosterImageView(with: selectedImage, and: images, on: navigationController)
            }.store(in: &cancellable)
    }

    private func showCreditsView(with credits: Credits, of movie: Movie, on navigationController: NavigationController) {
        let viewModel = CreditsVM(movie: movie, credits: credits)
        let viewController = CreditsVC(viewModel: viewModel)

        navigationController.pushViewController(viewController, animated: true)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                navigationController.popViewController(animated: true)
            }.store(in: &cancellable)

        viewModel.outputs.castMemberAction()
            .sink { [weak self] person in
                self?.showPersonDetailsView(with: person, on: navigationController)
            }.store(in: &cancellable)
    }

    private func showCustomLongTextView(with text: String, on navigationController: UIViewController) {
        let viewModel = CustomLongTextVM(text: text)
        let viewController = CustomLongTextVC(viewModel: viewModel)

        navigationController.present(viewController, animated: true, completion: nil)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                navigationController.dismiss(animated: true, completion: nil)
            }.store(in: &cancellable)
    }

    private func showPersonDetailsView(with person: Person, on navigationController: NavigationController) {
        let viewModel = PersonDetailsVM(movieService: movieService, person: person)
        let viewController = PersonDetailsVC(viewModel: viewModel)

        navigationController.pushViewController(viewController, animated: true)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                navigationController.popViewController(animated: true)
            }.store(in: &cancellable)

        viewModel.outputs.biographyTextAction()
            .sink { [weak self] biography in
                self?.showCustomLongTextView(with: biography, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.movieSelectedAction()
            .sink { [weak self] movie in
                self?.showMovieDetails(movie: movie, with: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.personMoviesButtonAction()
            .sink { [weak self] (movies, person) in
                self?.showPersonMovieList(with: movies, and: person, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.personImageAction()
            .sink { [weak self] (selectedImage, images) in
                self?.showProfileImageView(with: selectedImage, and: images, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.personGallerySelectedAction()
            .sink { [weak self] (person, images) in
                self?.showPersonGallery(person: person, images: images, with: navigationController)
            }.store(in: &cancellable)
    }

    private func showPersonMovieList(with movies: [Movie], and person: Person, on navigationController: NavigationController) {
        guard !movies.isEmpty else { return }

        let viewModel = PersonMovieListVM(movies: movies, person: person)
        let viewController = PersonMovieListVC(viewModel: viewModel)

        navigationController.pushViewController(viewController, animated: true)

        viewModel.outputs.movieSelectedAction()
            .sink { [weak self] movie in
                self?.showMovieDetails(movie: movie, with: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                navigationController.popViewController(animated: true)
            }.store(in: &cancellable)
    }

    private func showMovieDetails(movie: Movie, with navigationController: NavigationController) {
        let viewModel = MovieDetailsVM(movieService: movieService, storageService: storageService, movie: movie)
        let viewController = MovieDetailsVC(viewModel: viewModel, pushedViewController: true)

        navigationController.pushViewController(viewController, animated: true)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                navigationController.popViewController(animated: true)
            }.store(in: &cancellable)

        viewModel.outputs.galleryButtonAction()
            .sink { [weak self] _ in
                self?.showGalleryView(with: movie, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.overviewTextAction()
            .sink { [weak self] overview in
                self?.showCustomLongTextView(with: overview, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.creditsButtonAction()
            .sink { [weak self] (movie, credits) in
                self?.showCreditsView(with: credits, of: movie, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.castMemberAction()
            .sink { [weak self] person in
                self?.showPersonDetailsView(with: person, on: navigationController)
            }.store(in: &cancellable)

        viewModel.outputs.movieSelectedAction()
            .sink { [weak self] movie in
                self?.showMovieDetails(movie: movie, with: navigationController)
            }.store(in: &cancellable)
    }

    private func showPersonGallery(person: Person, images: [PersonImage], with navigationController: NavigationController) {
        let viewModel = PersonGalleryVM(person: person, personImages: images)
        let viewController = PersonGalleryVC(viewModel: viewModel)

        navigationController.pushViewController(viewController, animated: true)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                navigationController.popViewController(animated: true)
            }.store(in: &cancellable)

        viewModel.outputs.imageAction()
            .sink { [weak self] (selectedImage, images) in
                self?.showProfileImageView(with: selectedImage, and: images, on: navigationController)
            }.store(in: &cancellable)
    }

    private func showMovieList(searchCriteria: SearchCriteria, on baseViewController: UIViewController) {
        let viewModel = MoviesVM(movieService: movieService, searchCriteria: searchCriteria, presentedViewController: true)
        let viewController = MoviesVC(viewModel: viewModel)
        let navigationController = NavigationController(rootViewController: viewController)

        baseViewController.present(navigationController, animated: false, completion: nil)

        viewModel.outputs.closeButtonAction()
            .sink { _ in
                baseViewController.dismiss(animated: false, completion: nil)
            }.store(in: &cancellable)

        viewModel.outputs.movieSelectedAction()
            .sink { [weak self] movie in
                self?.showMovieDetails(movie: movie, on: navigationController)
            }.store(in: &cancellable)
    }
}
