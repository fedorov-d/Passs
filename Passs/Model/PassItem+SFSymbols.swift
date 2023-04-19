//
//  PassItem+SFSymbols.swift
//  Passs
//
//  Created by Dmitry on 18.04.2023.
//

import Foundation

extension PassItem {
    var iconSymbol: String {
        switch iconId {
        case 0: return "key"
        case 1: return "globe"
        case 2: return "exclamationmark.circle"
        case 3: return "server.rack"
        case 4: return "pin.circle"
        case 5: return "message"
        case 6: return "gear"
        case 7: return "pencil"
        case 8: return "rectangle.connected.to.line.below"
        case 9: return "book"
        case 10: return "at"
        default: return "ellipsis.rectangle"
        }
    }
}
