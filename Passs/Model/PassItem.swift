//
//  Group.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import Foundation

@objc
protocol PassItem {
    var uuid: UUID { get }
    var title: String? { get }
    var username: String? { get }
    var password: String? { get }
    var iconId: Int { get }
    var url: String? { get }
}

@objc
protocol PassGroup {
    var title: String? { get }
    var items: [PassItem] { get }
}
