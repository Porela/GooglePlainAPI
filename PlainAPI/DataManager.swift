//
//  DataManager.swift
//  PlainAPI
//
//  Created by anton Shepetuha on 13.03.17.
//  Copyright © 2017 anton Shepetuha. All rights reserved.
//

import Foundation
import Alamofire


class DataManager {
    
    private class func getCorrectDataAndTime(dateString : String) -> String{
        var result = dateString
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mmxxxxxx"
        if let dateFromString = formatter.date(from: dateString) {
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let stringFromDate = formatter.string(from: dateFromString)
            result = stringFromDate
        }
        return result
    }
    class func requestAPI(from: String, to: String, responseData : @escaping (_ response: ([APIData]))-> Void ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: Date())
        let parameters = [
            "request": [
                "slice": [
                    [
                        "origin": from,
                        "destination": to,
                        "date": date
                    ]
                ],
                "passengers": [
                    "adultCount": 1,
                    "infantInLapCount": 0,
                    "infantInSeatCount": 0,
                    "childCount": 0,
                    "seniorCount": 0
                ],
                "solutions": 20,
                "refundable": false
            ]
            
        ]
        Alamofire.request("https://www.googleapis.com/qpxExpress/v1/trips/search?key=AIzaSyAAjAlJzRHFdEs7AsXlP1GzuxAPhoTXk6M", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            if let JSON = response.result.value{
                if let resp = JSON as? NSDictionary {
                    var reponseData = [APIData]()
                    guard let trips =  resp["trips"] as? NSDictionary else { responseData(reponseData); return}
                    guard let tripOptions = trips["tripOption"] as? NSArray else {responseData(reponseData); return}
                    for trip in tripOptions{
                        let currentData = APIData()
                        guard let currentTrip = trip as? NSDictionary else {break}
                        if let saleTotal = currentTrip["saleTotal"] as? String
                        {
                            currentData.price = saleTotal
                        }
                        if let slice = currentTrip["slice"] as? NSArray {
                            if let firstSlice = slice[0] as? NSDictionary {
                                if let segment = firstSlice["segment"] as? NSArray {
                                    currentData.sliceCount = segment.count - 1
                                    if let  firstSegment = segment[0] as? NSDictionary {
                                        if let leg = firstSegment["leg"] as? NSArray {
                                            if let firstLeg = leg[0] as? NSDictionary {
                                                let departureTime = firstLeg["departureTime"] as? String
                                                currentData.departure = self.getCorrectDataAndTime(dateString: departureTime!)
                                            }
                                        }
                                    }
                                }
                            }
                            if let lastSlice = slice.lastObject as? NSDictionary {
                                if let segment = lastSlice["segment"] as? NSArray {
                                    if let  lastSegment = segment.lastObject as? NSDictionary {
                                        if let leg = lastSegment["leg"] as? NSArray {
                                            if let lastLeg = leg.lastObject as? NSDictionary {
                                                let arrivalTime = lastLeg["arrivalTime"] as? String
                                                currentData.arrival = self.getCorrectDataAndTime(dateString: arrivalTime!)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        reponseData.append(currentData)
                    }
                    responseData(reponseData)
                }
            }
        }
    }
}

