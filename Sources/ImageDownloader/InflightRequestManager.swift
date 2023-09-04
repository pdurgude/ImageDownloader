//
//  InflightRequestTracker.swift
//
//  Created by Prathamesh Durgude on 04/09/23.
//

import Foundation

actor InflightRequestManager {
  static let shared = InflightRequestManager()
  
  private var inflightRequests = [URL : [CheckedContinuation<Void, Never>]]()
  
  private init() { }
  
  private func isRequestInflight(for url: URL) -> Bool {
    inflightRequests[url] != nil
  }
  
  private func addInflightRequest(for url: URL) {
    guard inflightRequests[url] == nil else {
      return
    }
    
    inflightRequests[url] = [CheckedContinuation<Void, Never>]()
  }
}

extension InflightRequestManager {

  func removeInflightRequest(for url: URL) {
    guard isRequestInflight(for: url) else { return }
    
    print("Will remove inflight requests for \(url)")
    
    if let waitingContinuations = inflightRequests[url] {
      for continuation in waitingContinuations {
        continuation.resume()
      }
    }
    inflightRequests[url]?.removeAll()
    inflightRequests[url] = nil
  }
  
  func waitForInflightRequest(for url: URL) async {
    if isRequestInflight(for: url) {
      await withCheckedContinuation({ continuation in
        inflightRequests[url]?.append(continuation)
      })
    } else {
      addInflightRequest(for: url)
    }
  }
}
