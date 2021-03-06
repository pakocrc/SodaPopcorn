//
//  MovieApiEndpoint.swift
//  SodaPopcorn
//
//  Created by Francisco Cordoba on 3/9/21.
//

import Foundation

public enum MovieApiEndpoint {
    // MARK: Movies
    case moviesNowPlaying(page: Int)
    case moviesPopular(page: Int)
    case moviesTopRated(page: Int)
    case moviesUpcoming(page: Int)

	case movieVideos(movieId: String)
    case movieDetails(movieId: String)
    case movieImages(movieId: String)
    case movieExternalIds(movieId: String)
    case movieCredits(movieId: String)
    case movieSimilarMovies(movieId: String, page: Int)
    case genreList
    case discover(genre: Int, page: Int)
    case searchMovie(query: String, page: Int)

    // MARK: Persons
    case person(personId: String)
    case personMovieCredits(personId: String)
    case personExternalIds(personId: String)
    case personImages(personId: String)
}

extension MovieApiEndpoint: EndPointType {
	private var environmentBaseURL: String {
		do {
			let environment = try PlistReaderManager.shared.read(fromOptionName: "Environment") as? String

            var base = try PlistReaderManager.shared.read(fromContainer: ConfigKeys.baseUrl.rawValue, with: environment ?? "staging") as? String ?? ""

            switch self {
            case .person, .personMovieCredits, .personExternalIds, .personImages:
                base.append(contentsOf: "person")
                break
            case .genreList:
                base.append(contentsOf: "genre")
            case .discover:
                base.append(contentsOf: "discover")
            case .searchMovie:
                base.append(contentsOf: "search")
            default:
                base.append(contentsOf: "movie")
                break
            }

			return base

		} catch let error {
			print("❌ [Networking] [MovieApiEndpoint] Error reading base url from configuration file. Error description: \(error)")
			return ""
		}
	}

	var baseURL: URL {
		guard let url = URL(string: environmentBaseURL) else { fatalError("baseURL could not be configured.")}
		return url
	}

	var locale: String {
		return NSLocale.current.languageCode ?? "en"
	}

	var cachePolicy: URLRequest.CachePolicy {
		return .reloadIgnoringLocalAndRemoteCacheData
	}

    var path: String {
        switch self {
        case .moviesNowPlaying:
            return "now_playing"
        case .moviesPopular:
            return "popular"
        case .moviesTopRated:
            return "top_rated"
        case .moviesUpcoming:
            return "upcoming"
        case .movieVideos(let movieId):
            return "\(movieId)/videos"
        case .movieDetails(let movieId):
            return "\(movieId)"
        case .movieImages(let movieId):
            return "\(movieId)/images"
        case .movieExternalIds(let movieId):
            return "\(movieId)/external_ids"
        case .movieCredits(let movieId):
            return "\(movieId)/credits"
        case .movieSimilarMovies(let movieId, _):
            return "\(movieId)/similar"
        case .genreList:
            return "movie/list"
        case .discover:
            return "movie"
        case .searchMovie:
            return "movie"
        case .person(let personId):
            return "\(personId)"
        case .personMovieCredits(let personId):
            return "\(personId)/movie_credits"
        case .personExternalIds(let personId):
            return "\(personId)/external_ids"
        case .personImages(let personId):
            return "\(personId)/images"
        }
    }

    var httpMethod: HTTPMethod {
        return .get
    }
    
    var task: HTTPTask {
        switch self {
        case .moviesNowPlaying(let page), .moviesPopular(let page), .moviesTopRated(let page), .moviesUpcoming(let page), .movieSimilarMovies(_, let page):
            return .requestParameters(bodyParameters: nil,
                                      bodyEncoding: .urlEncoding,
                                      urlParameters: ["page": page,
                                                      "api_key": publicApiKey,
                                                      "include_adult": false,
                                                      "language": locale])
        case .movieDetails, .movieExternalIds, .movieCredits, .genreList, .person, .personMovieCredits, .personExternalIds:
            return .requestParameters(bodyParameters: nil,
                                      bodyEncoding: .urlEncoding,
                                      urlParameters: ["api_key": publicApiKey,
                                                      "include_adult": false,
                                                      "language": locale])
        case .movieImages, .personImages, .movieVideos:
            return .requestParameters(bodyParameters: nil,
                                      bodyEncoding: .urlEncoding,
                                      urlParameters: ["api_key": publicApiKey,
                                                      "include_adult": false])

        case .discover(let genre, let page):
            return .requestParameters(bodyParameters: nil,
                                      bodyEncoding: .urlEncoding,
                                      urlParameters: ["page": page,
                                                      "with_genres": genre,
                                                      "sort_by": "popularity.desc",
                                                      "api_key": publicApiKey,
                                                      "include_adult": false,
                                                      "language": locale])
        case .searchMovie(let query, let page):
            return .requestParameters(bodyParameters: nil,
                                      bodyEncoding: .urlEncoding,
                                      urlParameters: ["page": page,
                                                      "query": query,
                                                      "api_key": publicApiKey,
                                                      "include_adult": false,
                                                      "language": locale])
        }
    }

	var headers: HTTPHeaders? {
		return nil
	}
}
