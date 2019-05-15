//
//  Comment.swift
//  Hacker News
//
//  Created by Jonathan on 5/14/19.
//  Copyright © 2019 Jonathan. All rights reserved.
//

import Foundation
import RealmSwift

class Comment: Object {
    @objc dynamic var id = 0
    @objc dynamic var by = ""
    let kids = List<Int>()
    @objc dynamic var parent = 0
    @objc dynamic var time = Date()
    @objc dynamic var text = ""
    @objc dynamic var type = ""
    @objc dynamic var deleted = false
    @objc dynamic var dead = false

    var replies = List<Comment>()
    @objc dynamic var nestLevel = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }

}

struct LocalComment: Codable {
    let by: String?
    let id: Int
    let kids: [Int]?
    let parent: Int
    let text: String?
    let time: Date
    let type: String
    let deleted: Bool?
    let dead: Bool?

    func buildCommentObject() -> Comment {
        let comment = Comment()
        
        comment.id = id
        comment.by = by ?? ""
        
        if (kids != nil) {
            comment.kids.append(objectsIn: kids!)
        }
        
        comment.parent = parent
        comment.text = text ?? ""
        comment.time = time
        comment.type = type
        comment.deleted = deleted ?? false
        comment.dead = dead ?? false
        
        return comment
    }
}

