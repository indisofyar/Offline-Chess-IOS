//
//  Cuisine.swift
//  Restaurant Tracker
//

import Foundation

enum Cuisine: String, CaseIterable, Identifiable, Codable {
    case american
    case british
    case chinese
    case french
    case indian
    case italian
    case japanese
    case korean
    case mediterranean
    case mexican
    case middleEastern
    case thai
    case vietnamese
    case cafe
    case bakery
    case bar
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .american: return "American"
        case .british: return "British"
        case .chinese: return "Chinese"
        case .french: return "French"
        case .indian: return "Indian"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .mediterranean: return "Mediterranean"
        case .mexican: return "Mexican"
        case .middleEastern: return "Middle Eastern"
        case .thai: return "Thai"
        case .vietnamese: return "Vietnamese"
        case .cafe: return "Café"
        case .bakery: return "Bakery"
        case .bar: return "Bar"
        case .other: return "Other"
        }
    }

    var emoji: String {
        switch self {
        case .american: return "🍔"
        case .british: return "🥧"
        case .chinese: return "🥟"
        case .french: return "🥐"
        case .indian: return "🍛"
        case .italian: return "🍝"
        case .japanese: return "🍣"
        case .korean: return "🍲"
        case .mediterranean: return "🫒"
        case .mexican: return "🌮"
        case .middleEastern: return "🧆"
        case .thai: return "🍜"
        case .vietnamese: return "🍲"
        case .cafe: return "☕️"
        case .bakery: return "🥖"
        case .bar: return "🍸"
        case .other: return "🍽️"
        }
    }
}
