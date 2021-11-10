//
//  PosterImageVC.swift
//  SodaPopcorn
//
//  Created by Francisco Cordoba on 9/11/21.
//

import Combine
import UIKit

final class PosterImageVC: BaseViewController, UIScrollViewDelegate {
    // MARK: Consts
    private let viewModel: PosterImageVM

    // MARK: - Variables
    private var imageURLSubscription: Cancellable!
    private var imageURL: String? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self, let imageURL = self.imageURL else { return }
                self.posterImage.posterSize = .original
                self.posterImage.setUrlString(urlString: imageURL)
            }
        }
    }

    // MARK: UI Elements
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        return scrollView
    }()

    private let contentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()

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

    private lazy var posterImage: CustomPosterImage = {
        let customImage = CustomPosterImage(frame: .zero)

        if let cacheImage = cache.value(forKey: "\(PosterSize.w342.rawValue)\(self.viewModel.imageURL)") {
            customImage.image = cacheImage
        }
        customImage.contentMode = .scaleAspectFit

        return customImage
    }()

    init(viewModel: PosterImageVM) {
        self.viewModel = viewModel
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.inputs.viewDidLoad()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.backgroundColor = traitCollection.userInterfaceStyle == .light ? .white : .black
    }

    override func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.delegate = self

        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        contentView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

        contentView.addSubview(posterImage)
        contentView.addSubview(closeButton)

        closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true

        posterImage.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        posterImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        posterImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        posterImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        posterImage.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.0).isActive = true

        handleGestureRecongnizers()
    }

    override func bindViewModel() {
        imageURLSubscription = viewModel.outputs.imageURLAction()
            .sink(receiveValue: { [weak self] (imageURL) in
                guard let `self` = self else { return }
                self.imageURL = imageURL
            })
    }

    // MARK: - Helpers ⚙️
    private func handleGestureRecongnizers() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(presentImageOptionsActionSheet))
        longPressRecognizer.minimumPressDuration = 1.0

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureZoomOutAction))
        doubleTapRecognizer.numberOfTapsRequired = 2

        posterImage.isUserInteractionEnabled = true
        posterImage.addGestureRecognizer(longPressRecognizer)
        posterImage.addGestureRecognizer(doubleTapRecognizer)

        scrollView.addGestureRecognizer(doubleTapRecognizer)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.posterImage
    }

    @objc
    private func tapGestureZoomOutAction(recognizer: UITapGestureRecognizer) {
        scrollView.setZoomScale(1.0, animated: true)
    }

    @objc
    private func closeButtonPressed() {
        viewModel.inputs.closeButtonPressed()
    }

    @objc
    private func presentImageOptionsActionSheet() {
        let saveAction = UIAlertAction(title: NSLocalizedString("alert_save_button", comment: "Save button"), style: .default) { [weak self] _ in
            self?.downloadImageToPhotosAlbum()
        }

        Alert.showActionSheet(on: self, actions: [saveAction])
    }

    @objc
    private func downloadImageToPhotosAlbum() {
        guard let image = posterImage.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    // MARK: - 🗑 Deinit
    deinit {
        print("🗑 PosterImageVC deinit.")
    }
}