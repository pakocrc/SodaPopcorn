//
//  ProductionCompanyApiResponse.swift
//  Networking
//
//  Created by Francisco Cordoba on 6/11/21.
//

import Foundation

public final class ProductionCompanyApiResponse: Codable {
    public let id: Int?
    public let logoPath: String?
    public let name: String?
    public let originCountry: String?

    private enum ProductionCompanyApiResponseCodingKeys: String, CodingKey {
        case id
        case name
        case logoPath       = "logo_path"
        case originCountry  = "origin_country"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ProductionCompanyApiResponseCodingKeys.self)

        id = try container.decodeIfPresent(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        logoPath = try container.decodeIfPresent(String.self, forKey: .logoPath)
        originCountry = try container.decodeIfPresent(String.self, forKey: .originCountry)
    }
}
