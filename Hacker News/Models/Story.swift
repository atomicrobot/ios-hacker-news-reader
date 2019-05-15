//
//  Story.swift
//  Hacker News
//
//  Created by Jonathan on 5/13/19.
//  Copyright © 2019 Jonathan. All rights reserved.
//

import Foundation
import RealmSwift

class Story: Object {
    @objc dynamic var id = 0
    @objc dynamic var by = ""
    @objc dynamic var descendants = 0
    let kids = List<Int>()
    @objc dynamic var score = 0
    @objc dynamic var time = Date()
    @objc dynamic var title = ""
    @objc dynamic var type = ""
    @objc dynamic var url = ""

    override static func primaryKey() -> String? {
        return "id"
    }

}

struct LocalStory: Codable {
    let by: String
    let descendants: Int?
    let id: Int
    let kids: [Int]?
    let score: Int
    let time: Int
    let title: String
    let type: String
    let url: String?
    
    func buildStoryObject() -> Story {
        let story = Story()
        
        story.by = by
        story.descendants = descendants ?? 0
        story.id = id
        
        if (kids != nil) {
            story.kids.append(objectsIn: kids!)
        }
        
        story.score = score
        story.time = Date(timeIntervalSince1970: Double(time))
        story.title = title
        story.type = type
        story.url = url ?? ""
        
        return story
    }
}

enum ItemType: String {
    case job
    case story
    case comment
    case poll
    case pollopt
}
