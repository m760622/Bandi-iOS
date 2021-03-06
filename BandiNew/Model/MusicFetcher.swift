//
//  MusicFetcher.swift
//  BandiNew
//
//  Created by Siddha Tiwari on 4/28/18.
//  Copyright © 2018 Siddha Tiwari. All rights reserved.
//

import UIKit

class MusicFetcher {
    
    static let baseYoutubeApiUrlString = "https://www.googleapis.com/youtube/v3/"
    static let youtubeApiKey = APIKeys().youtubeKey
    static let songsCache = NSCache<NSString, Song>()
    static var nextPageToken: String?
    static var lastSearchQuery: String?
    static let maxYoutubeResults = "14"
    
    static func fetchYoutubeNextPage(handler: @escaping (_ music: [Song]?) -> Void) {
        if nextPageToken != nil && lastSearchQuery != nil {
            let urlParameters: Dictionary<String, String> = [
                "q" : lastSearchQuery!,
                "pageToken" : nextPageToken!,
                "maxResults" : maxYoutubeResults,
                "part" : "snippet",
                "key" : youtubeApiKey
            ]
            let urlString = baseYoutubeApiUrlString + "search?" + parametersToString(parameters: urlParameters)
            getVideoList(urlString: urlString, handler: { videoIds in
                getVideoDetails(videoIds: videoIds, handler: handler)
            })
        }
    }
    
    static func fetchYoutube(keywords: String, handler: @escaping (_ music: [Song]?) -> Void) {
        let keywordsReplaced = keywords.replacingOccurrences(of: " ", with: "+")
        lastSearchQuery = keywordsReplaced
        let urlParameters: Dictionary<String, String> = [
            "q" : keywordsReplaced,
            "part" : "id",
            "relevanceLanguage" : "en",
            "type" : "video",
            "maxResults" : maxYoutubeResults,
            "key" : youtubeApiKey,
        ]
        let urlString = baseYoutubeApiUrlString + "search?" + parametersToString(parameters: urlParameters)
        getVideoList(urlString: urlString, handler: { videoIds in
            getVideoDetails(videoIds: videoIds, handler: handler)
        })
    }
    
    static func getVideoList(urlString: String, handler: @escaping (_ videoIds: [String]) -> Void) {
        var videoIds: [String] = []
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) -> Void in
            do {
                if data != nil {
                    if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String : Any] {
                        //print(jsonResult)
                        nextPageToken = jsonResult["nextPageToken"] as? String
                        if let items = jsonResult["items"] as? [AnyObject]? {
                            for item in items! {
                                let id = item["id"] as! Dictionary<String, Any>
                                let videoId = id["videoId"] as? String
                                if videoId != nil {
                                    videoIds.append(videoId!)
                                }
                            }
                            handler(videoIds)
                        }
                    }
                } else {
                    print("no json data")
                }
            }
            catch {
                print("json error: \(error)")
            }
        }).resume()
    }
    
    static func getVideoDetails(videoIds: [String], handler: @escaping (_ music: [Song]?) -> Void) {
        let videoIdsAppended = videoIds.joined(separator: ",")
        let urlParameters: Dictionary<String, String>  = [
            "id" : videoIdsAppended,
            "part" : "snippet,contentDetails",
            "key" : youtubeApiKey,
        ]
        let urlString = baseYoutubeApiUrlString + "videos?" + parametersToString(parameters: urlParameters)
        let url = URL(string: urlString)
        
        var songs: [Song] = []
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) -> Void in
            do {
                if data != nil {
                    if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String : Any] {
                        //print(jsonResult)
                        if let items = jsonResult["items"] as? [AnyObject]? {
                            for item in items! {
                                let id  = [
                                    "type" : "youtube#video",
                                    "id" : item["id"] as! String,
                                    ]
                                if let cachedSong = songsCache.object(forKey: id["id"]! as NSString) {
                                    songs.append(cachedSong)
                                    continue
                                }
                                
                                let snippet = item["snippet"] as! Dictionary<String, Any>
                                let liveBroadcastContent = snippet["liveBroadcastContent"] as! String
                                if liveBroadcastContent == "live" {
                                    continue
                                }
                                let contentDetails = item["contentDetails"] as! Dictionary<String, Any>
                                let thumbnails = snippet["thumbnails"] as! Dictionary<String, Any>
                                
                                let title = snippet["title"] as! String
                                let artist = snippet["channelTitle"] as! String
                                let duration = contentDetails["duration"] as! String
                                let thumbnailsDetail = [
                                    "small" : (thumbnails["default"] as! Dictionary<String, Any>)["url"] as! String,
                                    "wide" : (thumbnails["medium"] as! Dictionary<String, Any>)["url"] as! String,
                                    "large" : (thumbnails["high"] as! Dictionary<String, Any>)["url"] as! String,
                                    ]
                                
                                let song = Song(title: title, artist: artist, id: id, liveBroadcastContent: liveBroadcastContent, duration: duration, thumbnails: thumbnailsDetail)
                                songs.append(song)
                            }
                            handler(songs)
                        }
                    }
                } else {
                    print("no json data")
                }
            }
            catch {
                print("json error: \(error)")
            }
        }).resume()
    }
    
    static func fetchYoutubeVideoUrl(videoID: String, quality: String, handler: @escaping (_ videoURL: String?) -> Void) {
        let urlParameters = [
            "url" : "www.youtube.com/watch?v=\(videoID)",
            ]
        let requestString = "\(APIKeys().serverAddress)/?" + parametersToString(parameters: urlParameters)
        let requestURL = URL(string: requestString)
        URLSession.shared.dataTask(with: requestURL!, completionHandler: { (data, response, error) -> Void in
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String : Any] {
                    let directVideoURL = jsonResult["url"] as? String
                    handler(directVideoURL!)
                }
            }
            catch {
                print("json error: \(error)")
            }
        }).resume()
    }
    
    static func fetchYoutubeAutocomplete(searchQuery: String, handler: @escaping (_ suggestions: [String]) -> Void) {
        let updatedSearch = searchQuery.replacingOccurrences(of: " ", with: "+")
        let urlParameters = [
            "client" : "firefox",
            "ds" : "yt",
            "q" : updatedSearch,
            "hl" : "en",
        ]
        let requestString = "https://suggestqueries.google.com/complete/search?" + parametersToString(parameters: urlParameters)
        let requestURL = URL(string: requestString)
        URLSession.shared.downloadTask(with: requestURL!) { (data, response, error) in
            do {
                if data != nil {
                    let text = try String(contentsOf: data!.absoluteURL, encoding: .utf8)
                    let textData = text.data(using: .utf8)
                    if let jsonResult = try JSONSerialization.jsonObject(with: textData!, options: .allowFragments) as? [Any]{
                        let suggestions = jsonResult[1] as! [String]
                        handler(suggestions)
                    }
                }
            }
            catch {
                print("error: \(error)")
            }
        }.resume()
    }
    
    static func parametersToString(parameters: Dictionary<String, String>) -> String {
        return (parameters.compactMap({ (key, value) -> String in
            return "\(key)=\(value)"
        }) as Array).joined(separator: "&")
    }
    
}
