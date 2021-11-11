//
//  MovieApiResponse.swift
//  SodaPopcorn
//
//  Created by Francisco Cordoba on 3/9/21.
//

public final class MovieApiResponse: Codable {
    public let id: String?
    public let title: String?
    public let overview: String?
    public let rating: Double?
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String?
    public let genres: [GenreApiResponse]?
    public let homepage: String?
    public let runtime: Int?
    public let voteCount: Int?
    public let budget: Int?
    public let revenue: Int?
    public let tagline: String?
    public let productionCompanies: [ProductionCompanyApiResponse]?

    private enum MovieApiResponseCodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case genres
        case homepage
        case runtime
        case budget
        case revenue
        case tagline
        case rating               = "vote_average"
        case posterPath           = "poster_path"
        case backdropPath         = "backdrop_path"
        case releaseDate          = "release_date"
        case voteCount            = "vote_count"
        case productionCompanies  = "production_companies"
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MovieApiResponseCodingKeys.self)

        id = try String(container.decode(Int.self, forKey: .id))
        title = try container.decodeIfPresent(String.self, forKey: .title)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        genres = try container.decodeIfPresent([GenreApiResponse].self, forKey: .genres)
        homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount)
        budget = try container.decodeIfPresent(Int.self, forKey: .budget)
        revenue = try container.decodeIfPresent(Int.self, forKey: .revenue)
        tagline = try container.decodeIfPresent(String.self, forKey: .tagline)
        productionCompanies = try container.decodeIfPresent([ProductionCompanyApiResponse].self, forKey: .productionCompanies)
    }
}
