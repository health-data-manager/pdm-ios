//
//  CarePlan.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// A care plan. Eventually this will contain the information required to completely populate it.
struct CarePlan {
    var title: String
    var description: String
    var name: String?
    var link: String?

    init(title: String, description: String, name: String?=nil, link: String?=nil) {
        self.title = title
        self.description = description
        self.name = name
        self.link = link
    }

    func jsonValue() -> [String: Any] {
        var result = [
            "title": title,
            "description": description
        ]
        if let name = name {
            result["name"] = name
        }
        if let link = link {
            result["link"] = link
        }
        return result
    }
}
