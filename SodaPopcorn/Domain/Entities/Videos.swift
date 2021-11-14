//
//  Videos.swift
//  SodaPopcorn
//
//  Created by Francisco Cordoba on 9/11/21.
//

public struct Videos: Hashable {
    public var id: String?
    public var results: [Video]?

    init(id: String? = nil, results: [Video]? = nil) {
        self.id = id
        self.results = results
    }

    init(apiResponse: VideosApiResponse) {
        self.init(id: apiResponse.id,
                  results: apiResponse.results?.map({ Video(apiResponse: $0) }) ?? [])
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }

    public static func == (lhs: Videos, rhs: Videos) -> Bool {
        return lhs.id == rhs.id
    }
}
