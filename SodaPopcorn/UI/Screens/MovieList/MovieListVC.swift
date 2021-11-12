//
//  MovieListVC.swift
//  SodaPopcorn
//
//  Created by Francisco Cordoba on 11/11/21.
//

import Combine
import UIKit

final class MoviesListVC: BaseViewController {
    enum Section: CaseIterable {
        case movies
    }

    // MARK: - Types
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Movie>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Movie>

    // MARK: - Consts
    private let viewModel: MoviesListVM

    // MARK: - Variables
    private var moviesSubscription: Cancellable!
    private var dataSource: DataSource!

    // MARK: - UI Elements
    private var movieCollectionView: UICollectionView!

    private lazy var closeButton: UIButton = {
        let image = UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate)
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.contentMode = .scaleAspectFit
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("close", comment: "Close button")
        button.tintColor = UIColor(named: "PrimaryColor")
        return button
    }()

    init(viewModel: MoviesListVM) {
        self.viewModel = viewModel
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        configureCollectionView()
        configureDataSource()
        setInitialData()
        super.viewDidLoad()
        viewModel.inputs.viewDidLoad()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.backgroundColor = traitCollection.userInterfaceStyle == .light ? .white : .black
        movieCollectionView.backgroundColor = traitCollection.userInterfaceStyle == .light ? .white : .black
    }

    override func setupUI() {
        view.addSubview(closeButton)
        view.addSubview(movieCollectionView)

        closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true

        movieCollectionView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 10).isActive = true
        movieCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        movieCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        movieCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    override func bindViewModel() {
        moviesSubscription = viewModel.outputs.moviesAction()
            .sink(receiveValue: { [weak self] (movies) in
                guard let `self` = self else { return }
                self.updateDataSource(movies: movies)
            })
    }

    // MARK: - Collection
    private func configureCollectionView() {
        movieCollectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        movieCollectionView.register(MovieListCollectionViewCell.self, forCellWithReuseIdentifier: MovieListCollectionViewCell.reuseIdentifier)
        movieCollectionView.register(SectionFooterReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: SectionFooterReusableView.reuseIdentifier)
        movieCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "blankCellId")
        movieCollectionView.translatesAutoresizingMaskIntoConstraints = false
        movieCollectionView.isScrollEnabled = true
        movieCollectionView.showsVerticalScrollIndicator = false
        movieCollectionView.allowsSelection = true
        movieCollectionView.isPrefetchingEnabled = true
        movieCollectionView.delegate = self
        movieCollectionView.alwaysBounceVertical = true
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { (_, _) -> NSCollectionLayoutSection? in

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3333),
                                                  heightDimension: .fractionalHeight(1.0))

            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .uniform(size: 5.0)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(UIScreen.main.bounds.height / (UIWindow.isLandscape ? 2 : 3.5)))

            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)

            // Supplementary footer view setup
            let headerFooterSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(20))

            let sectionFooter = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerFooterSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom)

            section.boundarySupplementaryItems = [sectionFooter]

            return section
        })
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<MovieListCollectionViewCell, Movie> { cell, _, movie in
            cell.configure(with: movie)
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, Movie>(collectionView: movieCollectionView) { (collectionView, indexPath, movie) in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: movie)
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionFooter else { return nil }

            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionFooterReusableView.reuseIdentifier, for: indexPath) as? SectionFooterReusableView
        }

        self.dataSource = dataSource
    }

    private func setInitialData() {
        var snapshot = dataSource.snapshot()
        snapshot.appendSections(Section.allCases)
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func updateDataSource(movies: [Movie], animatingDifferences: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }

            var snapshot = self.dataSource.snapshot()

            snapshot.appendItems(movies, toSection: .movies)

            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }

    // MARK: - ⚙️ Helpers
    @objc
    private func closeButtonPressed() {
        viewModel.inputs.closeButtonPressed()
    }

    // MARK: - 🗑 Deinit
    deinit {
        print("🗑 MoviesListVC deinit.")
    }
}

extension MoviesListVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let movie = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.inputs.movieSelected(movie: movie)
    }
}