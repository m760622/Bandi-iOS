//
//  SearchTabController.swift
//  BandiNew
//
//  Created by Siddha Tiwari on 4/28/18.
//  Copyright © 2018 Siddha Tiwari. All rights reserved.
//

import UIKit
import CoreData
import LNPopupController

class SearchTabController: UIViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let navBar = navigationController {
            navBar.navigationBar.prefersLargeTitles = true
            navBar.extendedLayoutIncludesOpaqueBars = true
        }
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        title = "Search"
        updateRecentSearchesTable()
        setupViews()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var searchCancelled = false
    
    lazy var searchController: SearchController = {
        let sb = SearchController(searchResultsController: nil)
        sb.delegate = self
        sb.searchBar.delegate = self
        sb.searchResultsUpdater = self
        sb.obscuresBackgroundDuringPresentation = false
        sb.hidesNavigationBarDuringPresentation = true
        sb.searchBar.placeholder = "Search Youtube"
        sb.dimsBackgroundDuringPresentation = false
        return sb
    }()
    
    lazy var musicTableView: SearchMusicTableView = {
        let tv = SearchMusicTableView(frame: .zero, style: .grouped)
        //tv.backgroundColor = .red
        tv.queueMusic = { music in
            TEMPSessionData.queueMusic.append(music)
        }
        tv.handleMusicTapped = {
            self.searchController.searchBar.endEditing(true)
        }
        tv.handleScroll = { isUp in
            self.searchController.searchBar.endEditing(true)
        }
        tv.bottomReached = {
            DispatchQueue.global(qos: .userInitiated).async {
                MusicFetcher.fetchYoutubeNextPage(handler: { (youtubeVideos) -> Void in
                    if let youtubeVideos = youtubeVideos {
                        let filteredVideos = youtubeVideos.filter({ song in
                            return !self.musicTableView.musicArray.contains(song)
                        })
                        self.musicTableView.musicArray = self.musicTableView.musicArray + filteredVideos
                        DispatchQueue.main.async {
                            self.musicTableView.reloadData()
                        }
                    }
                })
            }
        }
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    lazy var suggestionsTableView: SearchSuggestionsTableView = {
        let tv = SearchSuggestionsTableView(frame: .zero)
        //tv.backgroundColor = .green
        tv.isHidden = true
        tv.suggestionSelected = { suggestion in
            self.searchController.searchBar.text = suggestion
            self.searchController.searchBar.endEditing(true)
            self.updateSearchResults()
        }
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    lazy var recentSearchesTableView: RecentSearchesTableView = {
        let tv = RecentSearchesTableView(frame: .zero, style: UITableViewStyle.grouped)
        tv.rowSelected = { searchString in
            self.searchController.searchBar.text = searchString
            self.updateSearchResults()
            self.suggestionsTableView.isHidden = true
            tv.isHidden = true
        }
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    func setupViews() {
        view.addSubview(musicTableView)
        view.addSubview(recentSearchesTableView)
        view.addSubview(suggestionsTableView)
        
        NSLayoutConstraint.activate([
            recentSearchesTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            recentSearchesTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            recentSearchesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recentSearchesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            suggestionsTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            suggestionsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            suggestionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            musicTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            musicTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            musicTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            musicTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        updateSearchSuggestions()
        if !searchCancelled {
            suggestionsTableView.isHidden = false
            recentSearchesTableView.isHidden = true
        } else {
            recentSearchesTableView.isHidden = false
            suggestionsTableView.isHidden = true
            searchCancelled = false
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        updateRecentSearchesTable()
        searchCancelled = true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            suggestionsTableView.contentInset.bottom = keyboardSize.height
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        suggestionsTableView.contentInset.bottom = 0
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        suggestionsTableView.isHidden = true
        suggestionsTableView.suggestions.removeAll()
        suggestionsTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        updateSearchResults()
    }
    
    func updateSearchSuggestions() {
        let searchBarText = self.searchController.searchBar.text!
        if !searchBarText.isEmpty {
            DispatchQueue.global(qos: .userInitiated).async {
                MusicFetcher.fetchYoutubeAutocomplete(searchQuery: searchBarText, handler: { suggestions in
                    self.suggestionsTableView.suggestions = suggestions
                    DispatchQueue.main.async {
                        self.suggestionsTableView.reloadData()
                    }
                })
            }
        }
    }
    
//    func setCollectionBackground() {
//        if self.musicTableView.musicArray.count == 0 {
//            self.musicTableView.showNoResults()
//        } else {
//            self.musicTableView.backgroundView = nil
//        }
//    }
    
    func updateRecentSearchesTable() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        DispatchQueue.global(qos: .userInteractive).async {
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<RecentSearches> = RecentSearches.fetchRequest()
            do {
                let recentSearches = try context.fetch(fetchRequest)
                var recentSearchStrings: [String] = []
                for recentSearch in recentSearches {
                    let recentSearch = recentSearch.recentSearch
                    recentSearchStrings.append(recentSearch!)
                }
                self.recentSearchesTableView.recentSearches = recentSearchStrings
                DispatchQueue.main.async {
                    self.recentSearchesTableView.clearButton.isHidden = self.recentSearchesTableView.recentSearches.count == 0
                    self.recentSearchesTableView.reloadData()
                }
            } catch let error {
                print("error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func updateSearchResults() {
        let searchBarText = self.searchController.searchBar.text!
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        DispatchQueue.global(qos: .userInteractive).async {
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<RecentSearches> = RecentSearches.fetchRequest()
            var searchFound = false
            do {
                let recentSearches = try context.fetch(fetchRequest)
                for recentSearch in recentSearches {
                    let recentSearch = recentSearch.recentSearch
                    searchFound = searchBarText == recentSearch
                    if searchFound { break }
                }
                if !searchFound {
                    let entity = NSEntityDescription.entity(forEntityName: "RecentSearches", in: context)
                    let newRecentSearch = NSManagedObject(entity: entity!, insertInto: context)
                    newRecentSearch.setValue(searchBarText, forKey: "recentSearch")
                    try context.save()
                }
            } catch let error {
                print("error: \(error.localizedDescription)")
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            MusicFetcher.fetchYoutube(keywords: searchBarText) { (youtubeVideos) -> Void in
                //                    DispatchQueue.main.async {
                //                        self.musicTableView.showLoading()
                //                    }
                if let youtubeVideos = youtubeVideos {
                    self.musicTableView.musicArray = youtubeVideos
                    DispatchQueue.main.async {
                        self.musicTableView.setContentOffset(.zero, animated: false)
                        self.musicTableView.reloadData()
                        dispatchGroup.leave()
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                //self.setCollectionBackground()
            }
        }
    }
    
}
