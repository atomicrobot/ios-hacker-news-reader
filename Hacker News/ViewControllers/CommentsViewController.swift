//
//  CommentsViewController.swift
//  Hacker News
//
//  Created by Jonathan on 5/14/19.
//  Copyright © 2019 Jonathan. All rights reserved.
//

import UIKit
import SVProgressHUD

class CommentsViewController: UIViewController {
    var viewModel: CommentsViewModel?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        SVProgressHUD.show(withStatus: "Loading comments")
    }
}

extension CommentsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.flatCommentsList.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let comment = viewModel?.flatCommentsList[indexPath.row] else {
            fatalError("Could not find comment object")
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as? CommentCell else {
            fatalError("Could not find comment cell")
        }

        // Special handling for deleted comments
        if (comment.deleted) {
            cell.lblText.text = "<removed>"
        } else if (comment.dead) {
            cell.lblText.text = "<flagged>"
        } else {
            let data = comment.text.data(using: .utf8)
            cell.lblText.attributedText = try? NSAttributedString(data: data!, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        }

        cell.leadingConstraint.constant = CGFloat(Int(10 + (comment.nestLevel * 20)))
        
        return cell
    }
}

extension CommentsViewController: CommentsViewDelegate {
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
        SVProgressHUD.dismiss()

        guard let tableView = tableView else {
            return
        }

        tableView.reloadData()
    }
}

class CommentCell: UITableViewCell {
    @IBOutlet weak var lblText: UILabel!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
}
