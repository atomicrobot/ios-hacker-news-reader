//
//  StoriesViewModel.swift
//  Hacker News
//
//  Created by Jonathan on 5/13/19.
//  Copyright © 2019 Jonathan. All rights reserved.
//

import Foundation
import RealmSwift

class StoriesViewModel {
    var topStoryIds: [Int]
    var storyObjects: [Story]
    var delegate: StoryDelegate?
    let FETCH_COUNT = 20
    
    var numRows: Int {
        get {
            return storyObjects.count
        }
    }
    
    init() {
        topStoryIds = [Int]()
        storyObjects = [Story]()
    }
    
    func loadTopStories() {
        let url = URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                self.delegate?.handleClientError(error)
                debugPrint(error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    self.delegate?.handleServerError(response)
                    return
            }

            if (httpResponse.mimeType == "application/json") {
                if let data = data {
                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
                    if let ids = json as? [Int] {
                        
                        self.topStoryIds.append(contentsOf: ids)
                        
                        // Let's just start w/ the top 10
                        let top10 = ids[0..<self.FETCH_COUNT]

                        let loadStoriesGroup = DispatchGroup()

                        // Fetch the content of each story
                        for id in top10 {
                            loadStoriesGroup.enter()
                            
                            self.loadStory(id, completed: { (success) in
                                loadStoriesGroup.leave()
                            })
                        }

                        loadStoriesGroup.notify(queue: .main) {
                            self.delegate?.didFinishInitialLoad()
                        }
                    } else {
                        self.delegate?.handleClientError(nil)
                    }
                } else {
                    self.delegate?.handleClientError(nil)
                }
            } else {
                self.delegate?.handleClientError(nil)
            }
        }
        task.resume()
    }
    
    private func loadStory(_ id: Int, completed: @escaping (_ success: Bool) -> Void) {
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
                    completed(false)
                    self.delegate?.handleServerError(response)
                    return
            }
            
            if (httpResponse.mimeType == "application/json") {
                let decoder = JSONDecoder()
                if let data = data {
                    if let localStory = try? decoder.decode(LocalStory.self, from: data) {
                        let story = localStory.buildStoryObject()

                        DispatchQueue.main.async {
                            let realm = try! Realm()
                            
                            try! realm.write {
                                realm.add(story, update: true)
                            }

                            self.storyObjects.append(story)
                            
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

protocol StoryDelegate {
    func didFinishInitialLoad()
    func handleClientError(_ error: Error?)
    func handleServerError(_ response: URLResponse?)
}
