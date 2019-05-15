//
//  CommentsViewModel.swift
//  Hacker News
//
//  Created by Jonathan on 5/14/19.
//  Copyright © 2019 Jonathan. All rights reserved.
//

import Foundation
import RealmSwift

class CommentsViewModel {
    let story: Story
    var delegate: CommentsViewDelegate?
    let commentGroup: DispatchGroup
    let flatCommentsList: List<Comment>

    init(story: Story) {
        self.story = story
        
        self.commentGroup = DispatchGroup()
        self.flatCommentsList = List<Comment>()
    }
    
    /**
     Performs the initial loading of comments
     */
    func loadComments() {
        // For each top level comment for this Story...
        for commentId in story.kids {
            // Enter a dispatch group so we can track when all tasks are completed
            commentGroup.enter()
            
            // Fetch the comment
            loadComment(commentId) { (success) in
                // Now leave the dispatch group
                self.commentGroup.leave()
            }
        }
        
        // When all tasks have completed
        commentGroup.notify(queue: .main) {
            // Okay, now we should have ALL comments loaded for the initial story. We need to build a huge object with all the things
            
            // First loop through all the top level comments
            for topLevelId in self.story.kids {
                let realm = try! Realm()

                // Find the Comment
                if let topLevelComment = realm.object(ofType: Comment.self, forPrimaryKey: topLevelId) {
                    // Append Comment to our master list
                    self.flatCommentsList.append(topLevelComment)
                    
                    // Now do a deep traverse of all the kid comments
                    self.traverseComments(masterList: self.flatCommentsList, parentComment: topLevelComment, nestLevel: 0)
                }
            }

            let total = self.flatCommentsList.count
            let descendants = self.story.descendants
            let deleted = self.flatCommentsList.filter { $0.deleted }.count
            let flagged = self.flatCommentsList.filter { $0.dead }.count
            
            debugPrint("Flat height: \(total)   Descendents: \(descendants)   Deleted: \(deleted)   Flagged: \(flagged)")

            // Done processing, tell the delegate
            self.delegate?.didFinishInitialLoad()
        }
    }
    
    /**
     Traverses a Comment object's kids, and adds those comments to the list of replies
     
     - Parameter masterList: The list that we are adding to
     - Parameter parentComment: The comment whose kids we are fetching
     - Parameter nestLevel: The current nested level of this parent comment, used for display
     */
    func traverseComments(masterList: List<Comment>, parentComment: Comment, nestLevel: Int) {
        let realm = try! Realm()
        
        // First set the nest level of this comment
        try! realm.write {
            parentComment.nestLevel = nestLevel
        }
        
        // Loop over the parent's kids
        for commentId in parentComment.kids {
            // Find the Comment from the DB
            if let kid = realm.object(ofType: Comment.self, forPrimaryKey: commentId) {
                // Append this to our master flat list
                masterList.append(kid)
                
                // Update the parent's list of replies
                try! realm.write {
                    parentComment.replies.append(kid)
                }

                // Traverse the kid's comments
                traverseComments(masterList: masterList, parentComment: kid, nestLevel: nestLevel + 1)
            }
        }
    }
    
    /**
     Fetches a specified comment from the server
     
     - Parameter id: The ID of the comment to fetch
     - Parameter completed: The callback function
     */
    private func loadComment(_ id: Int, completed: @escaping (_ success: Bool) -> Void) {
        let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                self.delegate?.handleClientError(error)
                debugPrint(error)
                completed(false)
                
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    self.delegate?.handleServerError(response)
                    completed(false)
                    return
            }
            
            if (httpResponse.mimeType == "application/json") {
                let decoder = JSONDecoder()
                if let data = data {
                    if let localComment = try? decoder.decode(LocalComment.self, from: data) {
                        let comment = localComment.buildCommentObject()
                        
                        // Load the kids
                        for reply in comment.kids {
                            self.commentGroup.enter()
                            self.loadComment(reply, completed: { (success) in
                                self.commentGroup.leave()
                            })
                        }

                        DispatchQueue.main.async {
                            let realm = try! Realm()
                            
                            try! realm.write {
                                realm.add(comment, update: true)
                            }

                            completed(true)
                        }
                    } else {
                        completed(false)
                    }
                } else {
                    completed(false)
                }
            } else {
                completed(false)
            }
        }
        task.resume()
    }
}

protocol CommentsViewDelegate {
    func didFinishInitialLoad()
    func handleClientError(_ error: Error?)
    func handleServerError(_ response: URLResponse?)
}
