//
//  ParseChatViewController.swift
//  ParseChat
//
//  Copyright © 2018 jmaciel. All rights reserved.
//

import UIKit
import Parse

class ParseChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var chatMessagesTableView: UITableView!
    
    var chatMessages: [PFObject] = []
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        //refreshControl.addTarget(self, action: #selector(ParseChatViewController.didPullToRefresh(_:)), for: .valueChanged)
        //chatMessagesTableView.insertSubview(refreshControl, at: 0)
        
        chatMessagesTableView.delegate = self as UITableViewDelegate
        chatMessagesTableView.dataSource = self as UITableViewDataSource
        chatMessagesTableView.rowHeight = UITableView.automaticDimension
        chatMessagesTableView.estimatedRowHeight = 50
        retrieveChatMessages()
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.retrieveChatMessages), userInfo: nil, repeats: true)
    }
    
    @IBAction func logoutUser(_ sender: UIButton) {
        PFUser.logOutInBackground(block: {(error) -> Void in
            self.performSegue(withIdentifier: "logoutSegue", sender: nil)
        })
    }
    
    @IBAction func SendMessage(_ sender: UIButton) {
        let chatMessage = PFObject(className: "Message")
        chatMessage["text"] = messageTextField.text ?? ""
        chatMessage["user"] = PFUser.current() // sets user name
        chatMessage.saveInBackground { (success, error) in
            if success {
                print("The message was saved!")
                self.messageTextField.text = ""
            } else if let error = error {
                print("Problem saving message: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func didPullToRefresh(_ refreshControl: UIRefreshControl){
        retrieveChatMessages()
    }
    
    @objc func retrieveChatMessages() {
        let query = PFQuery(className: "Message")
        query.addDescendingOrder("createdAt")
        query.limit = 20
        query.includeKey("user")
        query.findObjectsInBackground { (messages, error) in
            if let messages = messages {
                self.chatMessages =  messages
                self.chatMessagesTableView.reloadData()
                self.refreshControl.endRefreshing()
            }
            else {
                print(error!.localizedDescription)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatCell
        let chatMessage = chatMessages[indexPath.row]
        
        cell.messageLabel.text = chatMessage["text"] as? String
        
        // Sets the username
        if let user = chatMessage["user"] as? PFUser {
            cell.usernameLabel.text = user.username
        } else {
            cell.usernameLabel.text = "🤖"
        }
        return cell
    }
}
