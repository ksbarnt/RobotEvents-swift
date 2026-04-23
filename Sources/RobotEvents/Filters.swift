// Filters.swift
// Strongly-typed query parameter structs for every endpoint.

import Foundation

// MARK: - Events

public struct EventFilters: Sendable {
    /// Filter by Event IDs.
    public var ids: [Int]?
    /// Filter by Event SKUs.
    public var skus: [String]?
    /// Filter by Team IDs that participated.
    public var teams: [Int]?
    /// Filter by Season IDs.
    public var seasons: [Int]?
    /// Filter by start date (ISO 8601).
    public var start: Date?
    /// Filter by end date (ISO 8601).
    public var end: Date?
    /// Filter by region string.
    public var region: String?
    /// Filter by event level.
    public var levels: [EventLevel]?
    /// Only return events with at least one team registered to the authenticated user.
    public var myEvents: Bool?
    /// Filter by event type.
    public var eventTypes: [EventType]?

    public init(
        ids: [Int]? = nil,
        skus: [String]? = nil,
        teams: [Int]? = nil,
        seasons: [Int]? = nil,
        start: Date? = nil,
        end: Date? = nil,
        region: String? = nil,
        levels: [EventLevel]? = nil,
        myEvents: Bool? = nil,
        eventTypes: [EventType]? = nil
    ) {
        self.ids = ids; self.skus = skus; self.teams = teams
        self.seasons = seasons; self.start = start; self.end = end
        self.region = region; self.levels = levels
        self.myEvents = myEvents; self.eventTypes = eventTypes
    }
}

// MARK: - Event sub-resources

public struct EventTeamFilters: Sendable {
    public var numbers: [String]?
    public var registered: Bool?
    public var grades: [Grade]?
    public var countries: [String]?
    public var myTeams: Bool?

    public init(
        numbers: [String]? = nil,
        registered: Bool? = nil,
        grades: [Grade]? = nil,
        countries: [String]? = nil,
        myTeams: Bool? = nil
    ) {
        self.numbers = numbers; self.registered = registered
        self.grades = grades; self.countries = countries; self.myTeams = myTeams
    }
}

public struct EventSkillFilters: Sendable {
    public var teams: [Int]?
    public var types: [SkillType]?

    public init(teams: [Int]? = nil, types: [SkillType]? = nil) {
        self.teams = teams; self.types = types
    }
}

public struct EventAwardFilters: Sendable {
    public var teams: [Int]?
    public var winners: [String]?

    public init(teams: [Int]? = nil, winners: [String]? = nil) {
        self.teams = teams; self.winners = winners
    }
}

public struct DivisionMatchFilters: Sendable {
    public var teams: [Int]?
    public var rounds: [Int]?
    public var instances: [Int]?
    public var matchNums: [Int]?

    public init(
        teams: [Int]? = nil,
        rounds: [Int]? = nil,
        instances: [Int]? = nil,
        matchNums: [Int]? = nil
    ) {
        self.teams = teams; self.rounds = rounds
        self.instances = instances; self.matchNums = matchNums
    }
}

public struct DivisionRankingFilters: Sendable {
    public var teams: [Int]?
    public var ranks: [Int]?

    public init(teams: [Int]? = nil, ranks: [Int]? = nil) {
        self.teams = teams; self.ranks = ranks
    }
}

// MARK: - Teams

public struct TeamFilters: Sendable {
    public var ids: [Int]?
    public var numbers: [String]?
    public var events: [Int]?
    public var registered: Bool?
    public var programs: [Int]?
    public var grades: [Grade]?
    public var countries: [String]?
    public var myTeams: Bool?

    public init(
        ids: [Int]? = nil,
        numbers: [String]? = nil,
        events: [Int]? = nil,
        registered: Bool? = nil,
        programs: [Int]? = nil,
        grades: [Grade]? = nil,
        countries: [String]? = nil,
        myTeams: Bool? = nil
    ) {
        self.ids = ids; self.numbers = numbers; self.events = events
        self.registered = registered; self.programs = programs
        self.grades = grades; self.countries = countries; self.myTeams = myTeams
    }
}

public struct TeamEventFilters: Sendable {
    public var skus: [String]?
    public var seasons: [Int]?
    public var start: Date?
    public var end: Date?
    public var levels: [EventLevel]?

    public init(
        skus: [String]? = nil,
        seasons: [Int]? = nil,
        start: Date? = nil,
        end: Date? = nil,
        levels: [EventLevel]? = nil
    ) {
        self.skus = skus; self.seasons = seasons
        self.start = start; self.end = end; self.levels = levels
    }
}

public struct TeamMatchFilters: Sendable {
    public var events: [Int]?
    public var seasons: [Int]?
    public var rounds: [Int]?
    public var instances: [Int]?
    public var matchNums: [Int]?

    public init(
        events: [Int]? = nil,
        seasons: [Int]? = nil,
        rounds: [Int]? = nil,
        instances: [Int]? = nil,
        matchNums: [Int]? = nil
    ) {
        self.events = events; self.seasons = seasons
        self.rounds = rounds; self.instances = instances; self.matchNums = matchNums
    }
}

public struct TeamRankingFilters: Sendable {
    public var events: [Int]?
    public var ranks: [Int]?
    public var seasons: [Int]?

    public init(events: [Int]? = nil, ranks: [Int]? = nil, seasons: [Int]? = nil) {
        self.events = events; self.ranks = ranks; self.seasons = seasons
    }
}

public struct TeamSkillFilters: Sendable {
    public var events: [Int]?
    public var types: [SkillType]?
    public var seasons: [Int]?

    public init(events: [Int]? = nil, types: [SkillType]? = nil, seasons: [Int]? = nil) {
        self.events = events; self.types = types; self.seasons = seasons
    }
}

public struct TeamAwardFilters: Sendable {
    public var events: [Int]?
    public var seasons: [Int]?

    public init(events: [Int]? = nil, seasons: [Int]? = nil) {
        self.events = events; self.seasons = seasons
    }
}

// MARK: - Programs

public struct ProgramFilters: Sendable {
    public var ids: [Int]?

    public init(ids: [Int]? = nil) { self.ids = ids }
}

// MARK: - Seasons

public struct SeasonFilters: Sendable {
    public var ids: [Int]?
    public var programs: [Int]?
    public var teams: [Int]?
    public var start: Date?
    public var end: Date?
    public var active: Bool?

    public init(
        ids: [Int]? = nil,
        programs: [Int]? = nil,
        teams: [Int]? = nil,
        start: Date? = nil,
        end: Date? = nil,
        active: Bool? = nil
    ) {
        self.ids = ids; self.programs = programs; self.teams = teams
        self.start = start; self.end = end; self.active = active
    }
}

public struct SeasonEventFilters: Sendable {
    public var skus: [String]?
    public var teams: [Int]?
    public var start: Date?
    public var end: Date?
    public var levels: [EventLevel]?

    public init(
        skus: [String]? = nil,
        teams: [Int]? = nil,
        start: Date? = nil,
        end: Date? = nil,
        levels: [EventLevel]? = nil
    ) {
        self.skus = skus; self.teams = teams
        self.start = start; self.end = end; self.levels = levels
    }
}
