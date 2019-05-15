//
//  Hacker_NewsTests.swift
//  Hacker NewsTests
//
//  Created by Jonathan on 5/13/19.
//  Copyright © 2019 Jonathan. All rights reserved.
//

import XCTest
import RealmSwift
@testable import Hacker_News

// A base class which each of your Realm-using tests should inherit from rather
// than directly from XCTestCase
class TestCaseBase: XCTestCase {
    override func setUp() {
        super.setUp()
        
        // Use an in-memory Realm identified by the name of the current test.
        // This ensures that each test can't accidentally access or modify the data
        // from other tests or the application itself, and because they're in-memory,
        // there's nothing that needs to be cleaned up.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
    }
}

class Hacker_NewsTests: TestCaseBase {

    func generateLocalStory(includeDescendants: Bool, includeKids: Bool, includeUrl: Bool) -> LocalStory {
        let by = "by"
        
        var descendants: Int? = nil
        if includeDescendants {
            descendants = 5
        }
        
        let id = 1
        
        var kids: [Int]? = nil
        if includeKids {
            kids = [1,4]
        }
        
        let score = 10
        
        let time = Int(Date().timeIntervalSince1970)
        let title = "My title"
        let type = "story"
        
        var url: String? = nil
        if (includeUrl) {
            url = "https://google.com"
        }

        let localStory = LocalStory(by: by, descendants: descendants, id: id, kids: kids, score: score, time: time, title: title, type: type, url: url)

        return localStory
    }
    
    /**
     story1
       comment1
         comment2
           comment3
         comment4
           comment5
     */
    func generateLocalComments() {
        let localComment1 = LocalComment(by: "By", id: 1, kids: [2,4], parent: 1, text: "My awesome comment 1", time: Date(), type: "comment", deleted: false, dead: false)
        let localComment2 = LocalComment(by: "By", id: 2, kids: [3], parent: 1, text: "My awesome comment 2", time: Date(), type: "comment", deleted: false, dead: false)
        let localComment3 = LocalComment(by: "By", id: 3, kids: nil, parent: 2, text: "My awesome comment 3", time: Date(), type: "comment", deleted: false, dead: false)
        let localComment4 = LocalComment(by: "By", id: 4, kids: [5], parent: 1, text: "My awesome comment 4", time: Date(), type: "comment", deleted: false, dead: false)
        let localComment5 = LocalComment(by: "By", id: 5, kids: nil, parent: 4, text: "My awesome comment 5", time: Date(), type: "comment", deleted: false, dead: false)
        
        let localCommentObj1 = localComment1.buildCommentObject()
        let localCommentObj2 = localComment2.buildCommentObject()
        let localCommentObj3 = localComment3.buildCommentObject()
        let localCommentObj4 = localComment4.buildCommentObject()
        let localCommentObj5 = localComment5.buildCommentObject()

        let realm = try! Realm()

        try! realm.write {
            realm.add(localCommentObj1)
            realm.add(localCommentObj2)
            realm.add(localCommentObj3)
            realm.add(localCommentObj4)
            realm.add(localCommentObj5)
        }
    }
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateRealmStoryFromLocalStory() {
        let localStory = generateLocalStory(includeDescendants: true, includeKids: true, includeUrl: true)
        let storyObject = localStory.buildStoryObject()
        
        XCTAssert(localStory.id == storyObject.id)
        XCTAssert(localStory.by == storyObject.by)
        XCTAssert(localStory.descendants == storyObject.descendants)
        XCTAssert(localStory.kids?.count == storyObject.kids.count)

        for index in 0 ..< localStory.kids!.count {
            XCTAssert(localStory.kids![index] == storyObject.kids[index])
        }

        XCTAssert(localStory.score == storyObject.score)
        XCTAssert(localStory.time == Int(storyObject.time.timeIntervalSince1970))
        XCTAssert(localStory.title == storyObject.title)
        XCTAssert(localStory.type == storyObject.type)
        XCTAssert(localStory.url == storyObject.url)
    }
    
    func testCreateRealmStoryFromLocalStory_noDescendants() {
        let localStory = generateLocalStory(includeDescendants: false, includeKids: true, includeUrl: true)
        let storyObject = localStory.buildStoryObject()
        
        XCTAssert(localStory.id == storyObject.id)
        XCTAssert(localStory.by == storyObject.by)
        XCTAssert(0 == storyObject.descendants)
        XCTAssert(localStory.kids?.count == storyObject.kids.count)
        
        for index in 0 ..< localStory.kids!.count {
            XCTAssert(localStory.kids![index] == storyObject.kids[index])
        }
        
        XCTAssert(localStory.score == storyObject.score)
        XCTAssert(localStory.time == Int(storyObject.time.timeIntervalSince1970))
        XCTAssert(localStory.title == storyObject.title)
        XCTAssert(localStory.type == storyObject.type)
        XCTAssert(localStory.url == storyObject.url)
    }
    
    func testCreateRealmStoryFromLocalStory_noKids() {
        let localStory = generateLocalStory(includeDescendants: true, includeKids: false, includeUrl: true)
        let storyObject = localStory.buildStoryObject()
        
        XCTAssert(localStory.id == storyObject.id)
        XCTAssert(localStory.by == storyObject.by)
        XCTAssert(localStory.descendants == storyObject.descendants)
        XCTAssert(0 == storyObject.kids.count)
        XCTAssert(localStory.score == storyObject.score)
        XCTAssert(localStory.time == Int(storyObject.time.timeIntervalSince1970))
        XCTAssert(localStory.title == storyObject.title)
        XCTAssert(localStory.type == storyObject.type)
        XCTAssert(localStory.url == storyObject.url)
    }

    func testBuildingFlatListOfComments() {
        let flatList = List<Comment>()
        let localStory = generateLocalStory(includeDescendants: true, includeKids: true, includeUrl: true)
        let storyObject = localStory.buildStoryObject()

        let myViewModel = CommentsViewModel(story: storyObject)
        
        generateLocalComments()
        
        let realm = try! Realm()
        if let firstComment = realm.object(ofType: Comment.self, forPrimaryKey: 1) {
            flatList.append(firstComment)
            myViewModel.traverseComments(masterList: flatList, parentComment: firstComment, nestLevel: 0)

            XCTAssert(flatList.count == 5)
            let comment1 = flatList[0]
            let comment2 = flatList[1]
            let comment3 = flatList[2]
            let comment4 = flatList[3]
            let comment5 = flatList[4]

            // Comment1
            XCTAssert(comment1.replies.count == 2)
            XCTAssert(comment1.nestLevel == 0)
            
            // Comment2
            XCTAssert(comment2.replies.count == 1)
            XCTAssert(comment2.nestLevel == 1)
            
            // Comment3
            XCTAssert(comment3.replies.count == 0)
            XCTAssert(comment3.nestLevel == 2)
            
            // Comment4
            XCTAssert(comment4.replies.count == 1)
            XCTAssert(comment4.nestLevel == 1)
            
            // Comment5
            XCTAssert(comment5.replies.count == 0)
            XCTAssert(comment5.nestLevel == 2)
            
        } else {
            XCTAssert(false)
        }

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
