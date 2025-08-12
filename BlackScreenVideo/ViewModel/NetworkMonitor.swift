//
//  NetworkMonitor.swift
//  BlackScreenVideo
//
//  Created by Yahya A Shawish on 06/08/2025.
//


import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor() // Singleton

    @Published var isConnected: Bool = true

    private var monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                print("check network connection \(path.status)")
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
