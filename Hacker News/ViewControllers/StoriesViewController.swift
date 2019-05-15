//
//  StoriesViewController.swift
//  Hacker News
//
//  Created by Jonathan on 5/13/19.
//  Copyright © 2019 Jonathan. All rights reserved.
//

import UIKit
import RealmSwift
import SVProgressHUD

class StoriesViewController: UIViewController {
    var viewModel: StoriesViewModel?
    var notificationToken: NotificationToken? = nil
    var activeStory: Story?

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        SVProgressHUD.show(withStatus: "Loading stories")
        
        // Do any additional setup after loading the view.
        viewModel = StoriesViewModel()
        viewModel?.delegate = self
        viewModel?.loadTopStories()

        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showComments" {
            if let destinationController = segue.destination as? CommentsViewController {
                // Setup view model first
                guard let story = activeStory else {
                    return
                }

                let commentsViewModel = CommentsViewModel(story: story)
                commentsViewModel.loadComments()
                commentsViewModel.delegate = destinationController
                
                destinationController.viewModel = commentsViewModel
            }
        }
    }

}

extension StoriesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.numRows ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let story = viewModel?.storyObjects[indexPath.row] else {
            fatalError()
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "storyCell", for: indexPath) as? StoryCell else {
            fatalError()
        }
        
        cell.story = story
        cell.delegate = self
        
        cell.lblTitle.text = story.title
        cell.btnShowComments.setTitle("\(story.descendants) comments", for: .normal)
        cell.btnShowComments.isEnabled = (story.descendants > 0)

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.minute, .hour, .day]

        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: story.time, to: Date())

        cell.lblDateTime.text = formatter.string(from: interval)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let story = viewModel?.storyObjects[indexPath.row] else {
            return
        }

        guard let url = URL(string: story.url) else {
            return
        }

        UIApplication.shared.open(url)
    }
}

extension StoriesViewController: StoryDelegate {
    func handleClientError(_ error: Error?) {
        var strError = ""
        
        if (error == nil) {
            strError = "An unknown error occurred"
        } else {
            strError = error!.localizedDescription
        }
        
        let alert = UIAlertController(title: "Error", message: strError, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        alert.addAction(action)
        
        show(alert, sender: self)
    }
    
    func handleServerError(_ response: URLResponse?) {
        var strError = ""
        
        strError = "An unknown error occurred fetching data from the server"

        let alert = UIAlertController(title: "Error", message: strError, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        alert.addAction(action)
        
        show(alert, sender: self)
    }
    
    func didFinishInitialLoad() {
        tableView.reloadData()
        
        SVProgressHUD.dismiss()
    }
}

extension StoriesViewController: StoryCellDelegate {
    func showComments(story: Story) {
        activeStory = story
        performSegue(withIdentifier: "showComments", sender: self)
    }
    
    
}

class StoryCell: UITableViewCell {
    var story: Story?
    var delegate: StoryCellDelegate?
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var btnShowComments: UIButton!
    @IBOutlet weak var lblDateTime: UILabel!

    @IBAction func didTapViewComments(_ sender: Any) {
        guard let story = story else {
            return
        }
        
        delegate?.showComments(story: story)
    }
}

protocol StoryCellDelegate {
    func showComments(story: Story)
}
