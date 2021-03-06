//
//  SearchMusicTableViewCell.swift
//  BandiNew
//
//  Created by Siddha Tiwari on 5/5/18.
//  Copyright © 2018 Siddha Tiwari. All rights reserved.
//

import UIKit
import LayoutKit

class SearchMusicTableViewCell: MusicTableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    var addMusic: (() -> ())?
    var musicTapped: (()->())?
    
    let addButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "plus-96")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = Constants.Colors().primaryColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func setupViews() {
        super.setupViews()
        
        //contentView.backgroundColor = Constants.Colors().darkTableCell
        
        contentView.addSubview(thumbnailImageView)
        thumbnailImageView.addSubview(durationLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(artistLabel)
        contentView.addSubview(interactionButton)
        contentView.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 50),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 65),
            thumbnailImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 15),
            thumbnailImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            durationLabel.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: -2),
            durationLabel.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: -2),
            
            titleLabel.heightAnchor.constraint(equalToConstant: 25),
            titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -5),
            
            artistLabel.heightAnchor.constraint(equalToConstant: 25),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            artistLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            artistLabel.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -5),
            
            interactionButton.topAnchor.constraint(equalTo: self.topAnchor),
            interactionButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            interactionButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            interactionButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            addButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16),
            addButton.widthAnchor.constraint(equalToConstant: 30),
            addButton.heightAnchor.constraint(equalToConstant: 30)
            ])
        
        interactionButton.addTarget(self, action: #selector(cellTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }
    
    @objc func cellTapped() {
        musicTapped?()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let tabBar = appDelegate.mainTabBarController
        let musicDetails = tabBar.musicDetailsController
        musicDetails.showLoading()
        musicDetails.pause()
        tabBar.presentPopupBar(withContentViewController: musicDetails, openPopup: true, animated: true, completion: nil)
        let videoId = music?.id!["id"] as! String
        MusicFetcher.fetchYoutubeVideoUrl(videoID: videoId, quality: "CHANGE THIS", handler: { (videoURL) in
            DispatchQueue.main.async {
                if let trimmedURL = videoURL?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
                    musicDetails.playingMusic = self.music
                    musicDetails.updateVideo(videoURLString: trimmedURL)
                    musicDetails.play()
                }
            }
        })
    }
    
    @objc func addButtonTapped() {
        addMusic!()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
