//
//  ThemeManager.swift
//  List
//
//  Created by Linyi Yan on 11/7/25.
//

import Combine
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system:
            return "theme.system".localized()
        case .light:
            return "theme.light".localized()
        case .dark:
            return "theme.dark".localized()
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AccentColor: String, CaseIterable, Identifiable {
    case pink
    case blue
    case purple
    case orange
    case green
    case red
    case teal
    case indigo
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .pink:
            return "color.pink".localized()
        case .blue:
            return "color.blue".localized()
        case .purple:
            return "color.purple".localized()
        case .orange:
            return "color.orange".localized()
        case .green:
            return "color.green".localized()
        case .red:
            return "color.red".localized()
        case .teal:
            return "color.teal".localized()
        case .indigo:
            return "color.indigo".localized()
        }
    }
    
    var color: Color {
        switch self {
        case .pink:
            return .pink
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .orange:
            return .orange
        case .green:
            return .green
        case .red:
            return .red
        case .teal:
            return .teal
        case .indigo:
            return .indigo
        }
    }
    
    // Icon for color preview
    var icon: String {
        "circle.fill"
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }
    
    @Published var accentColor: AccentColor {
        didSet {
            UserDefaults.standard.set(accentColor.rawValue, forKey: "accentColor")
        }
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .system
        
        let savedColor = UserDefaults.standard.string(forKey: "accentColor") ?? AccentColor.pink.rawValue
        self.accentColor = AccentColor(rawValue: savedColor) ?? .pink
    }
}

// Extension to easily access theme color throughout the app
extension Color {
    static var appAccent: Color {
        ThemeManager.shared.accentColor.color
    }
}

extension ShapeStyle where Self == Color {
    static var appAccent: Color {
        ThemeManager.shared.accentColor.color
    }
}

