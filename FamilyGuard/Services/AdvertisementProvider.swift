// AdvertisementProvider.swift
// FamilyGuard
//
// ЗАЧЕМ ЭТОТ ФАЙЛ:
// Абстракция для показа рекламы (AdMob/AppLovin).
// Обеспечивает возможность бесплатного использования приложения.
//
// КРИТИЧЕСКОЕ ПРАВИЛО APPLE:
// Реклама полностью изолирована от персональных данных ребёнка и токенов Screen Time!

import SwiftUI

public protocol AdvertisementProvider {
    func loadBanner() -> AnyView
    var isReady: Bool { get }
}

public final class MockAdvertisementProvider: AdvertisementProvider {
    public init() {}
    public var isReady: Bool { false }
    public func loadBanner() -> AnyView {
        AnyView(EmptyView())
    }
}

public struct BannerView: View {
    public let provider: AdvertisementProvider
    
    public init(provider: AdvertisementProvider = MockAdvertisementProvider()) {
        self.provider = provider
    }
    
    public var body: some View {
        if provider.isReady {
            provider.loadBanner()
        }
    }
}
