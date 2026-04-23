// RobotEventsClient.swift
// Public entry point for the RobotEvents Swift library.

import Foundation

/// A Swift client for the RobotEvents Public API v2.
///
/// ## Usage
/// ```swift
/// let client = try RobotEventsClient(apiKey: "your_bearer_token")
///
/// // Fetch a single event
/// let event = try await client.event(id: 12345)
///
/// // List events with filters
/// let result = try await client.events(
///     filters: EventFilters(seasons: [181], levels: [.state])
/// )
/// print(result.data.map(\.name))
///
/// // Auto-paginate all results
/// let allTeams = try await client.allPages { page, perPage in
///     try await client.eventTeams(eventID: 12345, page: page, perPage: perPage)
/// }
/// ```
///
/// ## Authentication
/// Obtain a Bearer token from https://www.robotevents.com/api/v2 and pass it
/// as `apiKey`, or set the `ROBOT_EVENTS_API_KEY` environment variable.
public final class RobotEventsClient: Sendable {

    private let http: HTTPClient

    // MARK: - Initialiser

    /// Create a new client.
    /// - Parameters:
    ///   - apiKey: Bearer token. Falls back to the `ROBOT_EVENTS_API_KEY` env var.
    ///   - session: Custom `URLSession` (defaults to `.shared`).
    public init(
        apiKey: String? = nil,
        session: URLSession = .shared
    ) throws {
        let key = apiKey ?? ProcessInfo.processInfo.environment["ROBOT_EVENTS_API_KEY"]
        guard let key, !key.isEmpty else { throw RobotEventsError.missingAPIKey }
        self.http = HTTPClient(apiKey: key, session: session)
    }

    // MARK: - Pagination helper

    /// Fetch every page of a paginated endpoint and return a flat array.
    ///
    /// - Parameters:
    ///   - perPage: Items per page (max 250).
    ///   - fetch: Closure that fetches one page.
    public func allPages<T: Codable & Sendable>(
        perPage: Int = 250,
        fetch: (Int, Int) async throws -> PaginatedResult<T>
    ) async throws -> [T] {
        var all: [T] = []
        var page = 1
        repeat {
            let result = try await fetch(page, perPage)
            all.append(contentsOf: result.data)
            if page >= result.meta.lastPage { break }
            page += 1
        } while true
        return all
    }

    /// Lazily iterate pages, yielding one `PaginatedResult` at a time.
    public func pages<T: Codable & Sendable>(
        perPage: Int = 250,
        fetch: @escaping (Int, Int) async throws -> PaginatedResult<T>
    ) -> AsyncThrowingStream<PaginatedResult<T>, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var page = 1
                    repeat {
                        let result = try await fetch(page, perPage)
                        continuation.yield(result)
                        if page >= result.meta.lastPage { break }
                        page += 1
                    } while true
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Events

    /// `GET /events` — List events.
    public func events(
        filters: EventFilters = EventFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Event> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "id[]", values: filters.ids)
        q += HTTPClient.arrayItems(key: "sku[]", values: filters.skus)
        q += HTTPClient.arrayItems(key: "team[]", values: filters.teams)
        q += HTTPClient.arrayItems(key: "season[]", values: filters.seasons)
        q += HTTPClient.item(key: "start", value: HTTPClient.format(date: filters.start))
        q += HTTPClient.item(key: "end", value: HTTPClient.format(date: filters.end))
        q += HTTPClient.item(key: "region", value: filters.region)
        q += HTTPClient.arrayItems(key: "level[]", values: filters.levels?.map(\.rawValue))
        q += HTTPClient.item(key: "myEvents", value: filters.myEvents.map { $0 ? "true" : "false" })
        q += HTTPClient.arrayItems(key: "eventTypes[]", values: filters.eventTypes?.map(\.rawValue))
        return try await http.get(path: "events", queryItems: q)
    }

    /// `GET /events/{id}` — Fetch a single event.
    public func event(id: Int) async throws -> Event {
        try await http.get(path: "events/\(id)")
    }

    /// `GET /events/{id}/teams` — Teams at a given event.
    public func eventTeams(
        eventID: Int,
        filters: EventTeamFilters = EventTeamFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Team> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "number[]", values: filters.numbers)
        q += HTTPClient.item(key: "registered", value: filters.registered.map { $0 ? "true" : "false" })
        q += HTTPClient.arrayItems(key: "grade[]", values: filters.grades?.map(\.rawValue))
        q += HTTPClient.arrayItems(key: "country[]", values: filters.countries)
        q += HTTPClient.item(key: "myTeams", value: filters.myTeams.map { $0 ? "true" : "false" })
        return try await http.get(path: "events/\(eventID)/teams", queryItems: q)
    }

    /// `GET /events/{id}/skills` — Skills runs at a given event.
    public func eventSkills(
        eventID: Int,
        filters: EventSkillFilters = EventSkillFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Skill> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "team[]", values: filters.teams)
        q += HTTPClient.arrayItems(key: "type[]", values: filters.types?.map(\.rawValue))
        return try await http.get(path: "events/\(eventID)/skills", queryItems: q)
    }

    /// `GET /events/{id}/awards` — Awards at a given event.
    public func eventAwards(
        eventID: Int,
        filters: EventAwardFilters = EventAwardFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Award> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "team[]", values: filters.teams)
        q += HTTPClient.arrayItems(key: "winner[]", values: filters.winners)
        return try await http.get(path: "events/\(eventID)/awards", queryItems: q)
    }

    /// `GET /events/{id}/divisions/{div}/matches` — Matches for a division.
    public func divisionMatches(
        eventID: Int,
        divisionID: Int,
        filters: DivisionMatchFilters = DivisionMatchFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Match> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "team[]", values: filters.teams)
        q += HTTPClient.arrayItems(key: "round[]", values: filters.rounds)
        q += HTTPClient.arrayItems(key: "instance[]", values: filters.instances)
        q += HTTPClient.arrayItems(key: "matchnum[]", values: filters.matchNums)
        return try await http.get(
            path: "events/\(eventID)/divisions/\(divisionID)/matches",
            queryItems: q
        )
    }

    /// `GET /events/{id}/divisions/{div}/rankings` — Qualification rankings.
    public func divisionRankings(
        eventID: Int,
        divisionID: Int,
        filters: DivisionRankingFilters = DivisionRankingFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Ranking> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "team[]", values: filters.teams)
        q += HTTPClient.arrayItems(key: "rank[]", values: filters.ranks)
        return try await http.get(
            path: "events/\(eventID)/divisions/\(divisionID)/rankings",
            queryItems: q
        )
    }

    /// `GET /events/{id}/divisions/{div}/finalistRankings` — Finalist rankings.
    public func divisionFinalistRankings(
        eventID: Int,
        divisionID: Int,
        filters: DivisionRankingFilters = DivisionRankingFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Ranking> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "team[]", values: filters.teams)
        q += HTTPClient.arrayItems(key: "rank[]", values: filters.ranks)
        return try await http.get(
            path: "events/\(eventID)/divisions/\(divisionID)/finalistRankings",
            queryItems: q
        )
    }

    // MARK: - Teams

    /// `GET /teams` — List teams.
    public func teams(
        filters: TeamFilters = TeamFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Team> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "id[]", values: filters.ids)
        q += HTTPClient.arrayItems(key: "number[]", values: filters.numbers)
        q += HTTPClient.arrayItems(key: "event[]", values: filters.events)
        q += HTTPClient.item(key: "registered", value: filters.registered.map { $0 ? "true" : "false" })
        q += HTTPClient.arrayItems(key: "program[]", values: filters.programs)
        q += HTTPClient.arrayItems(key: "grade[]", values: filters.grades?.map(\.rawValue))
        q += HTTPClient.arrayItems(key: "country[]", values: filters.countries)
        q += HTTPClient.item(key: "myTeams", value: filters.myTeams.map { $0 ? "true" : "false" })
        return try await http.get(path: "teams", queryItems: q)
    }

    /// `GET /teams/{id}` — Fetch a single team.
    public func team(id: Int) async throws -> Team {
        try await http.get(path: "teams/\(id)")
    }

    /// `GET /teams/{id}/events` — Events a team has attended.
    public func teamEvents(
        teamID: Int,
        filters: TeamEventFilters = TeamEventFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Event> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "sku[]", values: filters.skus)
        q += HTTPClient.arrayItems(key: "season[]", values: filters.seasons)
        q += HTTPClient.item(key: "start", value: HTTPClient.format(date: filters.start))
        q += HTTPClient.item(key: "end", value: HTTPClient.format(date: filters.end))
        q += HTTPClient.arrayItems(key: "level[]", values: filters.levels?.map(\.rawValue))
        return try await http.get(path: "teams/\(teamID)/events", queryItems: q)
    }

    /// `GET /teams/{id}/matches` — Matches a team has played.
    public func teamMatches(
        teamID: Int,
        filters: TeamMatchFilters = TeamMatchFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Match> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "event[]", values: filters.events)
        q += HTTPClient.arrayItems(key: "season[]", values: filters.seasons)
        q += HTTPClient.arrayItems(key: "round[]", values: filters.rounds)
        q += HTTPClient.arrayItems(key: "instance[]", values: filters.instances)
        q += HTTPClient.arrayItems(key: "matchnum[]", values: filters.matchNums)
        return try await http.get(path: "teams/\(teamID)/matches", queryItems: q)
    }

    /// `GET /teams/{id}/rankings` — Rankings for a team.
    public func teamRankings(
        teamID: Int,
        filters: TeamRankingFilters = TeamRankingFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Ranking> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "event[]", values: filters.events)
        q += HTTPClient.arrayItems(key: "rank[]", values: filters.ranks)
        q += HTTPClient.arrayItems(key: "season[]", values: filters.seasons)
        return try await http.get(path: "teams/\(teamID)/rankings", queryItems: q)
    }

    /// `GET /teams/{id}/skills` — Skills runs by a team.
    public func teamSkills(
        teamID: Int,
        filters: TeamSkillFilters = TeamSkillFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Skill> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "event[]", values: filters.events)
        q += HTTPClient.arrayItems(key: "type[]", values: filters.types?.map(\.rawValue))
        q += HTTPClient.arrayItems(key: "season[]", values: filters.seasons)
        return try await http.get(path: "teams/\(teamID)/skills", queryItems: q)
    }

    /// `GET /teams/{id}/awards` — Awards received by a team.
    public func teamAwards(
        teamID: Int,
        filters: TeamAwardFilters = TeamAwardFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Award> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "event[]", values: filters.events)
        q += HTTPClient.arrayItems(key: "season[]", values: filters.seasons)
        return try await http.get(path: "teams/\(teamID)/awards", queryItems: q)
    }

    // MARK: - Programs

    /// `GET /programs` — List programs.
    public func programs(
        filters: ProgramFilters = ProgramFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Program> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "id[]", values: filters.ids)
        return try await http.get(path: "programs", queryItems: q)
    }

    /// `GET /programs/{id}` — Fetch a single program.
    public func program(id: Int) async throws -> Program {
        try await http.get(path: "programs/\(id)")
    }

    // MARK: - Seasons

    /// `GET /seasons` — List seasons.
    public func seasons(
        filters: SeasonFilters = SeasonFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Season> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "id[]", values: filters.ids)
        q += HTTPClient.arrayItems(key: "program[]", values: filters.programs)
        q += HTTPClient.arrayItems(key: "team[]", values: filters.teams)
        q += HTTPClient.item(key: "start", value: HTTPClient.format(date: filters.start))
        q += HTTPClient.item(key: "end", value: HTTPClient.format(date: filters.end))
        q += HTTPClient.item(key: "active", value: filters.active.map { $0 ? "true" : "false" })
        return try await http.get(path: "seasons", queryItems: q)
    }

    /// `GET /seasons/{id}` — Fetch a single season.
    public func season(id: Int) async throws -> Season {
        try await http.get(path: "seasons/\(id)")
    }

    /// `GET /seasons/{id}/events` — Events in a given season.
    public func seasonEvents(
        seasonID: Int,
        filters: SeasonEventFilters = SeasonEventFilters(),
        page: Int = 1,
        perPage: Int = 25
    ) async throws -> PaginatedResult<Event> {
        var q = HTTPClient.pageItems(page: page, perPage: perPage)
        q += HTTPClient.arrayItems(key: "sku[]", values: filters.skus)
        q += HTTPClient.arrayItems(key: "team[]", values: filters.teams)
        q += HTTPClient.item(key: "start", value: HTTPClient.format(date: filters.start))
        q += HTTPClient.item(key: "end", value: HTTPClient.format(date: filters.end))
        q += HTTPClient.arrayItems(key: "level[]", values: filters.levels?.map(\.rawValue))
        return try await http.get(path: "seasons/\(seasonID)/events", queryItems: q)
    }
}
