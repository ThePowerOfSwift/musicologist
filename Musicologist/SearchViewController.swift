//
//  SearchViewController.swift
//  Musicologist
//
//  Created by Robert Mogos on 23/05/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import UIKit
import AVFoundation
import ApiAI
import Nuke

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var recordButton: RecordingButton!
  @IBOutlet weak var debugVoiceLabel: UILabel!
  
  let speechController = SpeechController()
  var isRecording: Bool = false
  var searchText: String = ""
  var results: SearchResults?
  let apiAI = ApiAI()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.tableView.register(UINib.init(nibName: "SongCell", bundle: nil), forCellReuseIdentifier: "songCell")
    
    let conf = AIDefaultConfiguration()
    conf.clientAccessToken = "b2a8a05cfbdb4162bbdfb9c2f4e48a4e"
    apiAI.configuration = conf
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return results?.nbHits ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = self.tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath) as! SongCell
    
    let hit = results!.allHits[indexPath.row]
    cell.headerLabel?.text = hit["trackName"] as? String
    cell.footLabel?.text = hit["artistName"] as? String
    
    if let hitImageString = hit["artworkUrl100"] as? String,
      let imageURL = URL(string: hitImageString) {
      Nuke.loadImage(
        with: imageURL,
        options: ImageLoadingOptions(
          placeholder: #imageLiteral(resourceName: "song"),
          transition: .fadeIn(duration: 0.33)
        ),
        into: cell.songView
      )
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    play(position: indexPath.row)
  }
  
  
  func display(results: SearchResults) {
    self.results = results
    self.tableView.reloadData()
  }
  
  @IBAction func recordPressed(_ sender: Any) {
    toogleRecording()
  }
  
  func play(position: Int) {
    if let results = results,
          results.allHits.count > position {
    //let hit = results.allHits[position]
    let fakeString = "https://open.spotify.com/track/7fSGbZLhWlAiCC3HDPAULu?si=apG9IN1XQRuXigIBYTLz6Q"
    let mediaURL = URL(string: fakeString) //hit["trackViewUrl"] as! String)
     UIApplication.shared.open(mediaURL!,
                               options: [:],
                               completionHandler: nil)
    }
  }
}

// MARK: - Speech to text
extension SearchViewController {
  func toogleRecording() {
    isRecording = !isRecording
    recordButton.animate(isRecording)
    
    if !isRecording {
      speechController.stopRecording()
      search(self.searchText)
      return
    }
    
    speechController.startRecording(textHandler: {[weak self] (text, final) in
      self?.searchText = text
      self?.debugVoiceLabel.text = "You: \(text)"
      if final {
        self?.toogleRecording()
        return
      }
      }, errorHandler: { [weak self] error in
        self?.handleVoiceError(error)
    })
  }
}


// MARK: - Intent detection
extension SearchViewController {
  func search(_ text: String) {
    let textRequest = apiAI.textRequest()
    textRequest?.query = text
    textRequest?.setCompletionBlockSuccess({ [weak self] (request, response) in
      self?.handleAIResponse(response!)
      }, failure: { [weak self] (request, error) in
        self?.handleVoiceError(error)
    })
    apiAI.enqueue(textRequest)
  }
  
  func handleVoiceError(_ error: Error?) {
    
  }
  
  func handleAIResponse(_ response: Any) {
    guard let aiResponse = AIResponse(response: response), let aiResult = aiResponse.result else {
      return
    }
    
    if let replyText = aiResult.fulfillment.speech {
      speak(replyText)
      debugVoiceLabel.text = "Tara: \(replyText)"
    }
    
    if let intent = aiResult.metadata.intentName {
      switch intent {
      case "Results":
        if let data = aiResult.parameters["data"] as? AIResponseParameter {
          handleData(data)
        }
        break
      case "Results - select.number":
        if let position = aiResult.parameters["position"] as? AIResponseParameter {
          handlePositionData(position)
        }
        break
      default:
        print("Done")
      }
    }
  }
  
  func handleData(_ data: AIResponseParameter) {
    do {
      let searchResults = try SearchResults(content: data.rawValue as! [String: Any], disjunctiveFacets: [])
      display(results: searchResults)
    } catch let e {
      print(e)
    }
  }
  
  func handlePositionData(_ data: AIResponseParameter) {
    if let position = Int(data.stringValue) {
      play(position: position)
    }
  }
}

// MARK: - text to speech

extension SearchViewController {
  func speak(_ text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.volume = 1.0
    let synth = AVSpeechSynthesizer()
    synth.speak(utterance)
  }
}
