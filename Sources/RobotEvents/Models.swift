// Models.swift
// RobotEvents Swift Library
// Models matching the RobotEvents API v2 schema.

import Foundation

// MARK: - Shared / Primitive Models

/// A lightweight reference to another resource (id + name + optional code).
public struct IdInfo: Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let code: String?
}

/// Geographic coordinates.
public struct Coordinates: Codable, Hashable, Sendable {
    public let lat: Double?
    public let lon: Double?
}

/// A physical location.
public struct Location: Codable, Hashable, Sendable {
    public let venue: String?
    public let address1: String?
    public let address2: String?
    public let city: String?
    public let region: String?
    public let postcode: String?
    public let country: String?
    public let coordinates: Coordinates?

    enum CodingKeys: String, CodingKey {
        case venue
        case address1 = "address_1"
        case address2 = "address_2"
        case city, region, postcode, country, coordinates
    }
}

/// A division within an event.
public struct Division: Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let order: Int?
}

// MARK: - Pagination

/// Metadata about a paginated response.
public struct PageMeta: Codable, Sendable {
    public let currentPage: Int
    public let lastPage: Int
    public let perPage: Int
    public let total: Int
    public let from: Int?
    public let to: Int?
    public let firstPageUrl: String?
    public let lastPageUrl: String?
    public let nextPageUrl: String?
    public let prevPageUrl: String?
    public let path: String?

    enum CodingKeys: String, CodingKey {
        case currentPage  = "current_page"
        case lastPage     = "last_page"
        case perPage      = "per_page"
        case total, from, to, path
        case firstPageUrl = "first_page_url"
        case lastPageUrl  = "last_page_url"
        case nextPageUrl  = "next_page_url"
        case prevPageUrl  = "prev_page_url"
    }
}

/// A generic paginated response wrapping any `Decodable` item type.
public struct PaginatedResult<T: Codable & Sendable>: Codable, Sendable {
    public let meta: PageMeta
    public let data: [T]
}

// MARK: - Enums

public enum EventLevel: String, Codable, Sendable {
    case world      = "World"
    case national   = "National"
    case regional   = "Regional"
    case state      = "State"
    case signature  = "Signature"
    case other      = "Other"
}

public enum EventType: String, Codable, Sendable {
    case tournament = "Tournament"
    case league     = "League"
    case workshop   = "Workshop"
    case virtual    = "Virtual"
}

public enum Grade: String, Codable, Sendable {
    case college          = "College"
    case highSchool       = "High School"
    case middleSchool     = "Middle School"
    case elementarySchool = "Elementary School"
}

public enum SkillType: String, Codable, Sendable {
    case driver              = "Driver"
    case programming         = "Programming"
    case packageDeliveryTime = "package_delivery_time"
}

public enum AllianceColor: String, Codable, Sendable {
    case red  = "Red"
    case blue = "Blue"
}

public enum AwardDesignation: String, Codable, Sendable {
    case tournament = "Tournament"
    case division   = "Division"
}

public enum AwardClassification: String, Codable, Sendable {
    case champion       = "Champion"
    case finalist       = "Ffinalist"
    case semifinalist   = "Semi-finalist"
    case quarterfinalist = "Quarter-finalist"
}

// MARK: - Event

public struct Event: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let sku: String
    public let name: String
    public let start: Date?
    public let end: Date?
    public let season: IdInfo
    public let program: IdInfo
    public let location: Location
    public let divisions: [Division]
    public let level: EventLevel?
    public let ongoing: Bool?
    public let awardsFinalized: Bool?
    public let eventType: EventType?

    enum CodingKeys: String, CodingKey {
        case id, sku, name, start, end, season, program, location, divisions, level, ongoing
        case awardsFinalized = "awards_finalized"
        case eventType       = "event_type"
    }
}

// MARK: - Team

public struct Team: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let number: String
    public let teamName: String?
    public let robotName: String?
    public let organization: String?
    public let location: Location?
    public let registered: Bool?
    public let program: IdInfo
    public let grade: Grade?

    enum CodingKeys: String, CodingKey {
        case id, number, organization, location, registered, program, grade
        case teamName  = "team_name"
        case robotName = "robot_name"
    }
}

// MARK: - Match

public struct AllianceTeam: Codable, Hashable, Sendable {
    public let team: IdInfo?
    public let sitting: Bool?
}

public struct Alliance: Codable, Hashable, Sendable {
    public let color: AllianceColor
    public let score: Int
    public let teams: [AllianceTeam]
}

public struct Match: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let event: IdInfo
    public let division: IdInfo
    public let round: Int
    public let instance: Int
    public let matchnum: Int
    public let scheduled: Date?
    public let started: Date?
    public let field: String?
    public let scored: Bool
    public let name: String
    public let alliances: [Alliance]
}

// MARK: - Ranking

public struct Ranking: Codable, Identifiable, Hashable, Sendable {
    public let id: Int?
    public let event: IdInfo?
    public let division: IdInfo?
    public let rank: Int?
    public let team: IdInfo?
    public let wins: Int?
    public let losses: Int?
    public let ties: Int?
    public let wp: Int?
    public let ap: Int?
    public let sp: Int?
    public let highScore: Int?
    public let averagePoints: Double?
    public let totalPoints: Int?

    enum CodingKeys: String, CodingKey {
        case id, event, division, rank, team, wins, losses, ties, wp, ap, sp
        case highScore     = "high_score"
        case averagePoints = "average_points"
        case totalPoints   = "total_points"
    }
}

// MARK: - Skill

public struct Skill: Codable, Identifiable, Hashable, Sendable {
    public let id: Int?
    public let event: IdInfo?
    public let team: IdInfo?
    public let type: SkillType?
    public let season: IdInfo?
    public let division: IdInfo?
    public let rank: Int?
    public let score: Int?
    public let attempts: Int?
}

// MARK: - Award

public struct TeamAwardWinner: Codable, Hashable, Sendable {
    public let division: IdInfo?
    public let team: IdInfo?
}

public struct Award: Codable, Identifiable, Hashable, Sendable {
    public let id: Int?
    public let event: IdInfo?
    public let order: Int?
    public let title: String?
    public let qualifications: [String]?
    public let designation: AwardDesignation?
    public let classification: AwardClassification?
    public let teamWinners: [TeamAwardWinner]?
    public let individualWinners: [String]?

    enum CodingKeys: String, CodingKey {
        case id, event, order, title, qualifications, designation, classification
        case teamWinners       = "teamWinners"
        case individualWinners = "individualWinners"
    }
}

// MARK: - Season

public struct Season: Codable, Identifiable, Hashable, Sendable {
    public let id: Int?
    public let name: String?
    public let program: IdInfo?
    public let start: Date?
    public let end: Date?
    public let yearsStart: Int?
    public let yearsEnd: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, program, start, end
        case yearsStart = "years_start"
        case yearsEnd   = "years_end"
    }
}

// MARK: - Program

public struct Program: Codable, Identifiable, Hashable, Sendable {
    public let id: Int?
    public let abbr: String?
    public let name: String?
}

// MARK: - API Error

public struct APIError: Codable, Sendable {
    public let code: Int?
    public let message: String?
}
