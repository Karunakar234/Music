import SwiftUI

enum AppTab: String, CaseIterable {
    case home = "Home"
    case search = "Search"
    case library = "Library"

    var iconName: String {
        switch self {
        case .home:
            "house.fill"
        case .search:
            "magnifyingglass"
        case .library:
            "books.vertical.fill"
        }
    }
}
