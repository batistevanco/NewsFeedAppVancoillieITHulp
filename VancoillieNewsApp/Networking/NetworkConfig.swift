//
//  NetworkConfig.swift
//  VancoillieNewsApp
//
//  Created by Batiste Vancoillie on 11/10/2025.
//


import Foundation

enum NetworkConfig {
    static let baseURL = URL(string: "https://www.vancoillieithulp.be/news")!

    static let sharedSession: URLSession = {
        // 50 MB memory, 200 MB disk cache
        let cache = URLCache(memoryCapacity: 50 * 1024 * 1024,
                             diskCapacity: 200 * 1024 * 1024,
                             diskPath: "URLCache")
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .reloadRevalidatingCacheData
        cfg.urlCache = cache
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 40
        return URLSession(configuration: cfg)
    }()
}