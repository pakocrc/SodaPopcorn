//
//  GalleryVM.swift
//  SodaPopcorn
//
//  Created by Francisco Cordoba on 9/11/21.
//

import Foundation
import Combine

public protocol GalleryVMInputs: AnyObject {
    /// Call when the view did load.
    func viewDidLoad()

    /// Call when the close button is pressed.
    func closeButtonPressed()

    /// Call when an backdrop image is selected.
    func backdropImageSelected(imageURL: String)

    /// Call when a poster image is selected.
    func posterImageSelected(imageURL: String)

    /// Call when a video is selected.
    func videoSelected(videoURL: String)
}

public protocol GalleryVMOutputs: AnyObject {
    /// Emits to close the screen.
    func closeButtonAction() -> PassthroughSubject<Void, Never>

    /// Emits to return the gallery information.
    func galleryAction() -> PassthroughSubject<Gallery, Never>

    /// Emits when loading.
    func loading() -> CurrentValueSubject<Bool, Never>

    /// Emits when an error occurred.
    func showError() -> PassthroughSubject<String, Never>

    /// Emits when an backdrop image is selected.
    func backdropImageAction() -> PassthroughSubject<String, Never>

    /// Emits when an poster image is selected.
    func posterImageAction() -> PassthroughSubject<String, Never>

    /// Emits when an video image is selected.
    func videoAction() -> PassthroughSubject<String, Never>
}

public protocol GalleryVMTypes: AnyObject {
    var inputs: GalleryVMInputs { get }
    var outputs: GalleryVMOutputs { get }
}

public final class GalleryVM: ObservableObject, Identifiable, GalleryVMInputs, GalleryVMOutputs, GalleryVMTypes {
    // MARK: Constants
    private let movieService: MovieService
    private let movie: Movie

    // MARK: Variables
    public var inputs: GalleryVMInputs { return self }
    public var outputs: GalleryVMOutputs { return self }

    // MARK: Variables
    private var cancellable = Set<AnyCancellable>()
    private var gallery = Gallery()

    public init(movieService: MovieService, movie: Movie) {
        self.movieService = movieService
        self.movie = movie

        closeButtonPressedProperty.sink { [weak self] _ in
            self?.closeButtonActionProperty.send(())
        }.store(in: &cancellable)

        backdropImageSelectedProperty.sink { [weak self] imageUrl in
            self?.backdropImageActionProperty.send(imageUrl)
        }.store(in: &cancellable)

        posterImageSelectedProperty.sink { [weak self] imageUrl in
            self?.posterImageActionProperty.send(imageUrl)
        }.store(in: &cancellable)

        videoSelectedProperty.sink { [weak self] imageUrl in
            self?.videoActionProperty.send(imageUrl)
        }.store(in: &cancellable)

        let imagesEvent = viewDidLoadProperty
            .flatMap { [weak self] _ -> AnyPublisher<MovieImages, Never> in
                guard let `self` = self else { return Empty(completeImmediately: true).eraseToAnyPublisher() }

                return movieService.getImages(movieId: self.movie.id ?? "")
                    .mapError({ [weak self] networkResponse -> NetworkResponse in
                        print("🔴 [GalleryVM] [init] Received completion error. Error: \(networkResponse.localizedDescription)")

                        self?.handleNetworkResponseError(networkResponse)
                        return networkResponse
                    })
                    .replaceError(with: MovieImages())
                    .eraseToAnyPublisher()
            }.share()

        let videosEvent = viewDidLoadProperty
            .flatMap { [weak self] _ -> AnyPublisher<Videos, Never> in
                guard let `self` = self else { return Empty(completeImmediately: true).eraseToAnyPublisher() }

                return movieService.getVideos(movieId: self.movie.id ?? "")
                    .mapError({ [weak self] networkResponse -> NetworkResponse in
                        print("🔴 [GalleryVM] [init] Received completion error. Error: \(networkResponse.localizedDescription)")

                        self?.handleNetworkResponseError(networkResponse)
                        return networkResponse
                    })
                    .replaceError(with: Videos())
                    .eraseToAnyPublisher()
            }.share()

        Publishers.CombineLatest(imagesEvent, videosEvent)
            .sink(receiveCompletion: { [weak self] completionReceived in
                guard let `self` = self else { return }

                switch completionReceived {
                case .failure(let error):
                    print("🔴 [GalleryVM] [init] Received completion error. Error: \(error.localizedDescription)")
                    self.showErrorProperty.send(NSLocalizedString("network_connection_error", comment: "Network error message"))
                default: break
                }
            }, receiveValue: { [weak self] (movieImages, videos) in
                guard let `self` = self else { return }

                if let backdrops = movieImages.backdrops, !backdrops.isEmpty {
                    self.gallery.backdrops = backdrops
                }

                if let posters = movieImages.posters, !posters.isEmpty {
                    self.gallery.posters = posters
                }

                if let videos = videos.results {
                    self.gallery.videos = videos
                }

                self.galleryActionProperty.send(self.gallery)
            }).store(in: &cancellable)
    }

    // MARK: - ⬇️ INPUTS Definition
    private let viewDidLoadProperty = PassthroughSubject<Void, Never>()
    public func viewDidLoad() {
        viewDidLoadProperty.send(())
    }

    private let closeButtonPressedProperty = PassthroughSubject<Void, Never>()
    public func closeButtonPressed() {
        closeButtonPressedProperty.send(())
    }

    private let backdropImageSelectedProperty = PassthroughSubject<String, Never>()
    public func backdropImageSelected(imageURL: String) {
        backdropImageSelectedProperty.send(imageURL)
    }

    private let posterImageSelectedProperty = PassthroughSubject<String, Never>()
    public func posterImageSelected(imageURL: String) {
        posterImageSelectedProperty.send(imageURL)
    }

    private let videoSelectedProperty = PassthroughSubject<String, Never>()
    public func videoSelected(videoURL: String) {
        videoSelectedProperty.send(videoURL)
    }

    // MARK: - ⬆️ OUTPUTS Definition
    private let closeButtonActionProperty = PassthroughSubject<Void, Never>()
    public func closeButtonAction() -> PassthroughSubject<Void, Never> {
        return closeButtonActionProperty
    }

    private let galleryActionProperty = PassthroughSubject<Gallery, Never>()
    public func galleryAction() -> PassthroughSubject<Gallery, Never> {
        return galleryActionProperty
    }

    private let loadingProperty = CurrentValueSubject<Bool, Never>(false)
    public func loading() -> CurrentValueSubject<Bool, Never> {
        return loadingProperty
    }

    private let showErrorProperty = PassthroughSubject<String, Never>()
    public func showError() -> PassthroughSubject<String, Never> {
        return showErrorProperty
    }

    private let backdropImageActionProperty = PassthroughSubject<String, Never>()
    public func backdropImageAction() -> PassthroughSubject<String, Never> {
        return backdropImageActionProperty
    }

    private let posterImageActionProperty = PassthroughSubject<String, Never>()
    public func posterImageAction() -> PassthroughSubject<String, Never> {
        return posterImageActionProperty
    }

    private let videoActionProperty = PassthroughSubject<String, Never>()
    public func videoAction() -> PassthroughSubject<String, Never> {
        return videoActionProperty
    }

    // MARK: - ⚙️ Helpers
    private func handleNetworkResponseError(_ networkResponse: NetworkResponse) {
        var localizedErrorString: String

        switch networkResponse {

        case .authenticationError: localizedErrorString = "network_response_error_authentication_error"
        case .badRequest: localizedErrorString = "network_response_error_bad_request"
        case .outdated: localizedErrorString = "network_response_error_outdated"
        case .failed: localizedErrorString = "network_response_error_failed"
        case .noData: localizedErrorString = "network_response_error_no_data"
        case .unableToDecode: localizedErrorString = "network_response_error_unable_to_decode"
        default: localizedErrorString = "network_response_error_failed"
        }

        self.showErrorProperty.send(NSLocalizedString(localizedErrorString, comment: "Network response error"))
    }

    // MARK: - 🗑 Deinit
    deinit {
        print("🗑", "GalleryVM deinit.")
    }
}