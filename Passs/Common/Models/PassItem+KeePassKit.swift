//
//  PassItem+KeePassKit.swift
//  Passs
//
//  Created by Dmitry Fedorov on 25.03.2021.
//

import Foundation
import KeePassKit

extension KPKEntry: PassItem {}
extension KPKGroup: PassGroup {
    var items: [PassItem] {
        return self.entries
    }
}
