//
//  ViewController.swift
//  OfflineDownloadWithAVFoundation
//
//  Created by Testpress on 31/08/23.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    @IBOutlet weak var playerContainer: UIView!
    var playBackURL = URL(string: "https://d384padtbeqfgy.cloudfront.net/transcoded/8r65J7EY6NP/video.m3u8")!
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupPlayerView()
    }
    
    func setupPlayerView(){
        player = AVPlayer(url: playBackURL)
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player

        addChild(playerViewController!)
        playerContainer.addSubview(playerViewController!.view)
        playerViewController!.view.frame = playerContainer.bounds
    }
}

