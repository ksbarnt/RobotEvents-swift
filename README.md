# RobotEvents Swift

A Swift library for the [RobotEvents Public API v2](https://www.robotevents.com/api/v2).

## Requirements

- Swift 5.9+
- iOS 16+ / macOS 13+ / watchOS 9+ / tvOS 16+

## Installation

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/RobotEvents.git", from: "1.0.0")
],
targets: [
    .target(name: "MyTarget", dependencies: ["RobotEvents"])
]
```

Or add it in Xcode via **File → Add Package Dependencies**.

## Authentication

Obtain a Bearer token from [robotevents.com](https://www.robotevents.com/api/v2).

```swift
// Pass directly
let client = try RobotEventsClient(apiKey: "your_token_here")

// Or set the environment variable ROBOT_EVENTS_API_KEY
let client = try RobotEventsClient()
```

## Quick Start

```swift
import RobotEvents

let client = try RobotEventsClient(apiKey: "your_token_here")

// Fetch a single event
let event = try await client.event(id: 12345)
print(event.name, event.start ?? "TBD")

// List events filtered by season and level
let result = try await client.events(
    filters: EventFilters(seasons: [181], levels: [.state])
)
for event in result.data {
    print(event.sku, event.name)
}

// Fetch ALL pages automatically
let allTeams = try await client.allPages { page, perPage in
    try await client.eventTeams(eventID: 12345, page: page, perPage: perPage)
}
print("Total teams:", allTeams.count)

// Stream pages lazily
for try await page in client.pages({ page, perPage in
    try await client.teams(
        filters: TeamFilters(programs: [1]),
        page: page, perPage: perPage
    )
}) {
    print("Page \(page.meta.currentPage) of \(page.meta.lastPage)")
    page.data.forEach { print($0.number, $0.teamName ?? "") }
}
```

## API Reference

### Events
| Method | Endpoint |
|--------|----------|
| `events(filters:page:perPage:)` | `GET /events` |
| `event(id:)` | `GET /events/{id}` |
| `eventTeams(eventID:filters:page:perPage:)` | `GET /events/{id}/teams` |
| `eventSkills(eventID:filters:page:perPage:)` | `GET /events/{id}/skills` |
| `eventAwards(eventID:filters:page:perPage:)` | `GET /events/{id}/awards` |
| `divisionMatches(eventID:divisionID:filters:page:perPage:)` | `GET /events/{id}/divisions/{div}/matches` |
| `divisionRankings(eventID:divisionID:filters:page:perPage:)` | `GET /events/{id}/divisions/{div}/rankings` |
| `divisionFinalistRankings(eventID:divisionID:filters:page:perPage:)` | `GET /events/{id}/divisions/{div}/finalistRankings` |

### Teams
| Method | Endpoint |
|--------|----------|
| `teams(filters:page:perPage:)` | `GET /teams` |
| `team(id:)` | `GET /teams/{id}` |
| `teamEvents(teamID:filters:page:perPage:)` | `GET /teams/{id}/events` |
| `teamMatches(teamID:filters:page:perPage:)` | `GET /teams/{id}/matches` |
| `teamRankings(teamID:filters:page:perPage:)` | `GET /teams/{id}/rankings` |
| `teamSkills(teamID:filters:page:perPage:)` | `GET /teams/{id}/skills` |
| `teamAwards(teamID:filters:page:perPage:)` | `GET /teams/{id}/awards` |

### Programs
| Method | Endpoint |
|--------|----------|
| `programs(filters:page:perPage:)` | `GET /programs` |
| `program(id:)` | `GET /programs/{id}` |

### Seasons
| Method | Endpoint |
|--------|----------|
| `seasons(filters:page:perPage:)` | `GET /seasons` |
| `season(id:)` | `GET /seasons/{id}` |
| `seasonEvents(seasonID:filters:page:perPage:)` | `GET /seasons/{id}/events` |

## Pagination

Every list endpoint returns `PaginatedResult<T>` with `.data` and `.meta`.

```swift
// Manual pagination
var page = 1
repeat {
    let result = try await client.events(page: page, perPage: 250)
    process(result.data)
    if page >= result.meta.lastPage { break }
    page += 1
} while true

// Auto-paginate (convenience)
let all = try await client.allPages { page, perPage in
    try await client.events(page: page, perPage: perPage)
}

// Lazy async stream
for try await page in client.pages({ p, pp in
    try await client.events(page: p, perPage: pp)
}) { ... }
```

## Error Handling

```swift
do {
    let event = try await client.event(id: 99999)
} catch RobotEventsError.httpError(let code, let message) {
    print("API error \(code): \(message ?? "unknown")")
} catch RobotEventsError.decodingError(let underlying) {
    print("Decode failed:", underlying)
} catch {
    print("Unexpected:", error)
}
```

Rate-limiting (HTTP 429) is handled automatically with an exponential backoff
using the server-provided `Retry-After` header.

## License

MIT
