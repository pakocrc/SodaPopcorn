//
//  ProfileImageVM.swift
//  SodaPopcorn
//
//  Created by Francisco Cordoba on 16/11/21.
//

import Foundation
import Combine

public protocol ProfileImageVMInputs: AnyObject {
    /// Call when the view did load.
    func viewDidLoad()

    /// Call when the close button is pressed.
    func closeButtonPressed()

    /// Call when the collection view was updated.
    func collectionViewUpdated()
}

public protocol ProfileImageVMOutputs: AnyObject {
    /// Emits to close the screen.
    func closeButtonAction() -> PassthroughSubject<Void, Never>

    /// Emits to get return the image information.
    func imagesAction() -> PassthroughSubject<[String], Never>

    /// Emits to get return the selected image information.
    func selectedImageAction() -> PassthroughSubject<String, Never>

    /// Emits when loading.
    func loading() -> CurrentValueSubject<Bool, Never>

    /// Emits when an error occurred.
    func showError() -> PassthroughSubject<String, Never>
}

public protocol ProfileImageVMTypes: AnyObject {
    var inputs: ProfileImageVMInputs { get }
    var outputs: ProfileImageVMOutputs { get }
}

public final class ProfileImageVM: ObservableObject, Identifiable, ProfileImageVMInputs, ProfileImageVMOutputs, ProfileImageVMTypes {
    // MARK: Constants
    private let selectedImage: String
    private let images: [String]

    // MARK: Variables
    public var inputs: ProfileImageVMInputs { return self }
    public var outputs: ProfileImageVMOutputs { return self }

    // MARK: Variables
    private var cancellable = Set<AnyCancellable>()

    init(selectedImage: String, images: [String]) {
        self.selectedImage = selectedImage
        self.images = images

        viewDidLoadProperty.sink { [weak self] _ in
            guard let `self` = self else { return }
            self.imagesActionProperty.send(self.images)
        }.store(in: &cancellable)

        collectionViewUpdatedProperty
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                self.selectedImageActionProperty.send(self.selectedImage)
            }.store(in: &cancellable)

        closeButtonPressedProperty.sink { [weak self] _ in
            self?.closeButtonActionProperty.send(())
        }.store(in: &cancellable)
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

    private let collectionViewUpdatedProperty = PassthroughSubject<Void, Never>()
    public func collectionViewUpdated() {
        collectionViewUpdatedProperty.send(())
    }

    // MARK: - ⬆️ OUTPUTS Definition
    private let closeButtonActionProperty = PassthroughSubject<Void, Never>()
    public func closeButtonAction() -> PassthroughSubject<Void, Never> {
        return closeButtonActionProperty
    }

    private let imagesActionProperty = PassthroughSubject<[String], Never>()
    public func imagesAction() -> PassthroughSubject<[String], Never> {
        return imagesActionProperty
    }

    private let loadingProperty = CurrentValueSubject<Bool, Never>(false)
    public func loading() -> CurrentValueSubject<Bool, Never> {
        return loadingProperty
    }

    private let showErrorProperty = PassthroughSubject<String, Never>()
    public func showError() -> PassthroughSubject<String, Never> {
        return showErrorProperty
    }

    private let selectedImageActionProperty = PassthroughSubject<String, Never>()
    public func selectedImageAction() -> PassthroughSubject<String, Never> {
        return selectedImageActionProperty
    }

    // MARK: - ⚙️ Helpers

    // MARK: - 🗑 Deinit
    deinit {
        print("🗑", "ProfileImageVM deinit.")
    }
}
