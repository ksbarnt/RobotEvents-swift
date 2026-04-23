// RobotEventsTests.swift
// Basic unit tests covering model decoding and query item building.

import XCTest
@testable import RobotEvents

final class RobotEventsTests: XCTestCase {

    // MARK: - Model decoding

    func testEventDecoding() throws {
        let json = """
        {
            "id": 1,
            "sku": "RE-VRC-23-1234",
            "name": "Test Event",
            "start": "2024-01-15T08:00:00.000Z",
            "end": "2024-01-15T18:00:00.000Z",
            "season": { "id": 181, "name": "2023-2024 VRC Season", "code": null },
            "program": { "id": 1, "name": "VRC", "code": "VRC" },
            "location": {
                "venue": "Test Venue",
                "city": "Test City",
                "country": "United States",
                "address_1": "123 Main St",
                "coordinates": { "lat": 40.7128, "lon": -74.0060 }
            },
            "divisions": [{ "id": 1, "name": "Research", "order": 1 }],
            "level": "State",
            "ongoing": false,
            "awards_finalized": true,
            "event_type": "tournament"
        }
        """
        let event = try HTTPClient.decoder.decode(Event.self, from: Data(json.utf8))
        XCTAssertEqual(event.id, 1)
        XCTAssertEqual(event.sku, "RE-VRC-23-1234")
        XCTAssertEqual(event.season.id, 181)
        XCTAssertEqual(event.program.code, "VRC")
        XCTAssertEqual(event.level, .state)
        XCTAssertEqual(event.eventType, .tournament)
        XCTAssertEqual(event.location.city, "Test City")
        XCTAssertEqual(event.location.coordinates?.lat, 40.7128, accuracy: 0.0001)
        XCTAssertEqual(event.divisions.count, 1)
        XCTAssertNotNil(event.start)
    }

    func testTeamDecoding() throws {
        let json = """
        {
            "id": 42,
            "number": "1234A",
            "team_name": "Bot Busters",
            "robot_name": "Crusher",
            "organization": "ACME School",
            "registered": true,
            "program": { "id": 1, "name": "VRC", "code": null },
            "grade": "High School",
            "location": { "country": "United States", "city": "Detroit" }
        }
        """
        let team = try HTTPClient.decoder.decode(Team.self, from: Data(json.utf8))
        XCTAssertEqual(team.id, 42)
        XCTAssertEqual(team.number, "1234A")
        XCTAssertEqual(team.teamName, "Bot Busters")
        XCTAssertEqual(team.grade, .highSchool)
        XCTAssertEqual(team.registered, true)
    }

    func testMatchDecoding() throws {
        let json = """
        {
            "id": 99,
            "event": { "id": 1, "name": "Test Event" },
            "division": { "id": 1, "name": "Research" },
            "round": 2,
            "instance": 1,
            "matchnum": 5,
            "scored": true,
            "name": "Qualification Match 5",
            "alliances": [
                {
                    "color": "red",
                    "score": 120,
                    "teams": [
                        { "team": { "id": 42, "name": "1234A" }, "sitting": false }
                    ]
                },
                {
                    "color": "blue",
                    "score": 95,
                    "teams": [
                        { "team": { "id": 43, "name": "5678B" }, "sitting": false }
                    ]
                }
            ]
        }
        """
        let match = try HTTPClient.decoder.decode(Match.self, from: Data(json.utf8))
        XCTAssertEqual(match.id, 99)
        XCTAssertEqual(match.round, 2)
        XCTAssertEqual(match.alliances.count, 2)
        XCTAssertEqual(match.alliances[0].color, .red)
        XCTAssertEqual(match.alliances[0].score, 120)
        XCTAssertEqual(match.alliances[1].color, .blue)
    }

    func testRankingDecoding() throws {
        let json = """
        {
            "id": 10,
            "event": { "id": 1, "name": "Test Event" },
            "division": { "id": 1, "name": "Research" },
            "rank": 3,
            "team": { "id": 42, "name": "1234A" },
            "wins": 5, "losses": 1, "ties": 0,
            "wp": 10, "ap": 8, "sp": 150,
            "high_score": 180,
            "average_points": 145.6,
            "total_points": 730
        }
        """
        let ranking = try HTTPClient.decoder.decode(Ranking.self, from: Data(json.utf8))
        XCTAssertEqual(ranking.rank, 3)
        XCTAssertEqual(ranking.wins, 5)
        XCTAssertEqual(ranking.highScore, 180)
        XCTAssertEqual(ranking.averagePoints, 145.6, accuracy: 0.01)
    }

    func testSeasonDecoding() throws {
        let json = """
        {
            "id": 181,
            "name": "2023-2024 VRC: Over Under",
            "program": { "id": 1, "name": "VRC" },
            "start": "2023-05-01T00:00:00.000Z",
            "end": "2024-04-30T00:00:00.000Z",
            "years_start": 2023,
            "years_end": 2024
        }
        """
        let season = try HTTPClient.decoder.decode(Season.self, from: Data(json.utf8))
        XCTAssertEqual(season.id, 181)
        XCTAssertEqual(season.yearsStart, 2023)
        XCTAssertEqual(season.yearsEnd, 2024)
    }

    func testPaginatedResultDecoding() throws {
        let json = """
        {
            "meta": {
                "current_page": 1,
                "last_page": 3,
                "per_page": 25,
                "total": 72,
                "from": 1,
                "to": 25
            },
            "data": [
                { "id": 1, "abbr": "VRC", "name": "VEX Robotics Competition" }
            ]
        }
        """
        let result = try HTTPClient.decoder.decode(
            PaginatedResult<Program>.self,
            from: Data(json.utf8)
        )
        XCTAssertEqual(result.meta.currentPage, 1)
        XCTAssertEqual(result.meta.lastPage, 3)
        XCTAssertEqual(result.meta.total, 72)
        XCTAssertEqual(result.data.count, 1)
        XCTAssertEqual(result.data[0].abbr, "VRC")
    }

    // MARK: - Query item builder

    func testArrayItemsBuilder() {
        let items = HTTPClient.arrayItems(key: "season[]", values: [181, 182])
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0], URLQueryItem(name: "season[]", value: "181"))
        XCTAssertEqual(items[1], URLQueryItem(name: "season[]", value: "182"))
    }

    func testArrayItemsBuilderNil() {
        let items = HTTPClient.arrayItems(key: "season[]", values: nil as [Int]?)
        XCTAssertTrue(items.isEmpty)
    }

    func testSingleItemBuilder() {
        let items = HTTPClient.item(key: "region", value: "California")
        XCTAssertEqual(items, [URLQueryItem(name: "region", value: "California")])
    }

    func testSingleItemBuilderNil() {
        let items = HTTPClient.item(key: "region", value: nil as String?)
        XCTAssertTrue(items.isEmpty)
    }

    func testPageItems() {
        let items = HTTPClient.pageItems(page: 3, perPage: 100)
        XCTAssertTrue(items.contains(URLQueryItem(name: "page", value: "3")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "per_page", value: "100")))
    }

    // MARK: - Error handling

    func testMissingAPIKeyThrows() {
        XCTAssertThrowsError(try RobotEventsClient(apiKey: "")) { error in
            XCTAssertEqual(error as? RobotEventsError, .missingAPIKey)
        }
    }

    func testErrorDescription() {
        let err = RobotEventsError.httpError(statusCode: 404, message: "Not found")
        XCTAssertEqual(err.errorDescription, "HTTP 404: Not found")
    }
}

extension RobotEventsError: Equatable {
    public static func == (lhs: RobotEventsError, rhs: RobotEventsError) -> Bool {
        switch (lhs, rhs) {
        case (.missingAPIKey, .missingAPIKey): return true
        case (.invalidURL, .invalidURL): return true
        case (.httpError(let lCode, _), .httpError(let rCode, _)): return lCode == rCode
        default: return false
        }
    }
}
