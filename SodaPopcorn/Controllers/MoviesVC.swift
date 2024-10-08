//
//  MoviesVC.swift
//  SodaPopcorn
//
//  Created by Francisco Cordoba on 5/9/21.
//

import Combine
import UIKit

final class MoviesVC: MoviesBaseCollectionView {
    // MARK: - Consts
    private let viewModel: MoviesVM

    // MARK: Subscriptions
    private var finishedFetchingSubscription: Cancellable?
    private var fetchMoviesSubscription: Cancellable?
    private var searchCriteriaSubscription: Cancellable?
    private var loadingSubscription: Cancellable?
    private var showErrorSubscription: Cancellable?
    private var viewtitleSubscription: Cancellable?

    // MARK: - UI Elements
    private lazy var sizeMenu: UIMenu = { [unowned self] in
        let menu = UIMenu(title: NSLocalizedString("collection_view_set_size_menu_title", comment: "Select items size"), image: nil, identifier: nil, options: [.displayInline], children: [
            UIAction(title: NSLocalizedString("columns", comment: "Columns"), image: UIImage(systemName: "rectangle.split.3x1"), handler: { (_) in
                self.collectionLayout = .columns
            }),
            UIAction(title: NSLocalizedString("list", comment: "List"), image: UIImage(systemName: "square.fill.text.grid.1x2"), handler: { (_) in
                self.collectionLayout = .list
            })
        ])

        return menu
    }()

    private lazy var moviesFilterMenu: UIMenu = { [unowned self] in
        let menu = UIMenu(title: NSLocalizedString("movie_lists", comment: "Filter movies by list"), image: nil, identifier: nil, options: [.displayInline], children: [
            UIAction(title: NSLocalizedString("now_playing_movies", comment: "Now playing movies filter"), image: UIImage(systemName: "clock"), handler: { (_) in
                self.viewModel.inputs.setSearchCriteria(searchCriteria: .nowPlaying)
                self.title = NSLocalizedString("now_playing_movies", comment: "Now playing movies filter")
            }),
            UIAction(title: NSLocalizedString("popular_movies", comment: "Popular movies filter"), image: UIImage(systemName: "person.2.wave.2"), handler: { (_) in
                self.viewModel.inputs.setSearchCriteria(searchCriteria: .popular)
                self.title = NSLocalizedString("popular_movies", comment: "Popular movies filter")
            }),
            UIAction(title: NSLocalizedString("top_rated_movies", comment: "Top rated movies filter"), image: UIImage(systemName: "10.square.fill"), handler: { (_) in
                self.viewModel.inputs.setSearchCriteria(searchCriteria: .topRated)
                self.title = NSLocalizedString("top_rated_movies", comment: "Top rated movies filter")
            }),
            UIAction(title: NSLocalizedString("upcoming_movies", comment: "Upcoming movies filter"), image: UIImage(systemName: "sparkles.tv"), handler: { (_) in
                self.viewModel.inputs.setSearchCriteria(searchCriteria: .upcomming)
                self.title = NSLocalizedString("upcoming_movies", comment: "Upcoming movies filter")
            })
        ])

        return menu
    }()

    init(viewModel: MoviesVM) {
        self.viewModel = viewModel
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        collectionView.delegate = self
        viewModel.inputs.fetchMovies()
    }

    override func setupNavigationBar() {
        navigationItem.title = NSLocalizedString("app_name_with_icon", comment: "App name")

        if viewModel.presentedViewController {
            let leftBarButtonItemImage = UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate)
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftBarButtonItemImage, style: .done, target: self, action: #selector(closeButtonPressed))

        } else {
            let leftBarButtonImage = UIImage(systemName: "square.fill.text.grid.1x2")
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("collection_view_set_layout_button_title", comment: "Set collection layout"), image: leftBarButtonImage, primaryAction: nil, menu: sizeMenu)

            let rightBarButtonImage = UIImage(systemName: "line.3.horizontal.decrease.circle")
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("collection_view_set_layout_button_title", comment: "Filter movies"), image: rightBarButtonImage, primaryAction: nil, menu: moviesFilterMenu)
        }
    }

    override func bindViewModel() {
        fetchMoviesSubscription = viewModel.outputs.fetchMoviesAction()
            .filter({ !($0?.isEmpty ?? true) })
            .sink(receiveValue: { [weak self] (movies) in
                guard let movies = movies, !movies.isEmpty else { return }

                DispatchQueue.main.async { [weak self] in
                    self?.navigationController?.navigationItem.rightBarButtonItem?.isEnabled = true
                    self?.updateDataSource(movies: movies)
                }
            })

        loadingSubscription = viewModel.outputs.loading()
            .sink(receiveValue: { [weak self] (loading) in
                guard let `self` = self else { return }
                self.loading = loading
            })

        finishedFetchingSubscription = viewModel.outputs.finishedFetchingAction()
            .sink(receiveValue: { [weak self] (finishedFetching) in
                guard let `self` = self else { return }
                self.finishedFetching = finishedFetching
            })

        showErrorSubscription = viewModel.outputs.showError()
            .sink(receiveValue: { [weak self] errorMessage in
                guard let `self` = self else { return }
                self.handleEmptyView()
                Alert.showAlert(on: self, title: NSLocalizedString("alert", comment: "Alert title"), message: errorMessage)
            })

        searchCriteriaSubscription = viewModel.outputs.searchCriteriaAction()
            .dropFirst()
            .sink(receiveValue: { [weak self] searchCriteria in
                self?.finishedFetching = false
                self?.reloadDataSource()
                self?.handleEmptyView()

                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }

                    switch searchCriteria {
                    case .nowPlaying:
                        self.title = NSLocalizedString("now_playing_movies", comment: "Now playing movies filter")
                    case .popular:
                        self.title = NSLocalizedString("popular_movies", comment: "Popular movies filter")
                    case .topRated:
                        self.title = NSLocalizedString("top_rated_movies", comment: "Top rated movies filter")
                    case .upcomming:
                        self.title = NSLocalizedString("upcoming_movies", comment: "Upcoming movies filter")
                    default:
                        break
                    }
                }
            })

        viewtitleSubscription = viewModel.outputs.setViewTitle()
            .sink(receiveValue: { [weak self] genreName in
                self?.title = genreName
            })
    }

    // MARK: - Collection View
    override func updateDataSource(movies: [Movie], animatingDifferences: Bool = true) {
            var snapshot = self.dataSource.snapshot()

            snapshot.appendItems(movies, toSection: .movies)
            self.loadedCount = snapshot.numberOfItems

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let `self` = self else { return }

            self.collectionView.removeEmptyView()
            self.setActivityIndicator(active: false)
            self.dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard loadedCount != 0 else { return }

        self.footerContentView.isHidden = indexPath.row <= loadedCount - 6

        if indexPath.row == loadedCount - 1 {
            if !finishedFetching {
                self.setActivityIndicator(active: true)
                self.viewModel.inputs.fetchMovies()
            }
        }
    }

    override func handleEmptyView() {
        let dataSourceItems = dataSource.snapshot().numberOfItems

        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            if self.loading && dataSourceItems < 1 {
                self.collectionView.setEmptyView(title: NSLocalizedString("loading_movies_title_label", comment: "Loading title"),
                                                 message: NSLocalizedString("loading_movies_description_label", comment: "Loading Message"),
                                                 centeredY: true)

            } else if !self.loading && dataSourceItems < 1 {
                self.collectionView.setEmptyView(title: NSLocalizedString("empty_movies_title_label", comment: "Empty list title"),
                                                 message: NSLocalizedString("empty_movies_description_label", comment: "Empty list message"),
                                                 centeredY: true)

                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.reloadCollectionView))
                tapGestureRecognizer.numberOfTapsRequired = 1

                self.collectionView.backgroundView?.isUserInteractionEnabled = true

                self.collectionView.backgroundView?.addGestureRecognizer(tapGestureRecognizer)

            } else {
                self.collectionView.removeEmptyView()
            }
        }
    }

    // MARK: - ⚙️ Helpers
    @objc
    private func closeButtonPressed() {
        viewModel.inputs.closeButtonPressed()
    }

    @objc
    private func reloadCollectionView() {
        viewModel.inputs.fetchMovies()
        handleEmptyView()
    }

    // MARK: - 🗑 Deinit
    deinit {
        print("🗑 MoviesVC deinit.")
    }
}

extension MoviesVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let movie = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.inputs.movieSelected(movie: movie)
    }
}
