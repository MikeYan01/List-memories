//
//  LocalizationManager.swift
//  List
//
//  Created by Linyi Yan on 11/7/25.
//

import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .chinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }
    
    var icon: String {
        switch self {
        case .chinese:
            return "🇨🇳"
        case .english:
            return "🇺🇸"
        }
    }
}

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            updateBundle()
        }
    }
    
    private var bundle: Bundle = .main
    
    init() {
        // Load saved language preference, default to Chinese
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.chinese.rawValue
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .chinese
        updateBundle()
    }
    
    private func updateBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = .main
        }
    }
    
    func localizedString(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}

// Helper for SwiftUI
extension String {
    func localized() -> String {
        return LocalizationManager.shared.localizedString(self)
    }
}

// Date formatting helper
extension Date {
    func formattedSimple() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: self)
    }
}
