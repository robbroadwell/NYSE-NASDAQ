//
//  DataController.swift
//  xTrade
//
//  Created by Rob Broadwell on 6/12/18.
//  Copyright © 2018 Rob Broadwell. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

class DataController: NetworkDelegate {
    
    public var stocks: Results<Stock>!
    public var sorted = List<Stock>()
    
    private var symbols: [String] {
        let nyse = NYSE.symbols.lines
        let nasdaq = Nasdaq.symbols.lines
//        return nyse + nasdaq
        return nasdaq
    }
    
    func initialize() {
        GlobalNetworkController.register(delegate: self)
        
        let realm = try! Realm()
        
        for symbol in symbols {
            if !symbol.contains("^") {
                try! realm.write {
                    realm.create(Stock.self, value: ["id": symbol, "symbol": symbol], update: true)
                }
            }
        }
        
        stocks = realm.objects(Stock.self)
        
        guard let stocks = self.stocks else { return }
        
        for stock in stocks {
            if stock.needsRefresh() {
                
                GlobalNetworkController.fetchData(for: stock, andEndpoint: .company)
                GlobalNetworkController.fetchData(for: stock, andEndpoint: .quote)
                GlobalNetworkController.fetchData(for: stock, andEndpoint: .stats)
                
                try! realm.write {
                    stock.fetched = Date()
                }
            }
        }
        
        sorted.removeAll()
        sorted.append(objectsIn: stocks.sorted(byKeyPath: "name", ascending: true))
    }
    
    func networkManager(didFinishTaskFor endpoint: NetworkDataEndpoint, with data: Data) {
        if endpoint == .company {
            updateCompanyWithData(data)
        }
        
        if endpoint == .quote {
            updateQuoteWithData(data)
        }
        
        if endpoint == .stats {
            updateStatisticsWithData(data)
        }
    }
    
    func networkManager(didFinishTaskFor endpoint: NetworkDataEndpoint, with error: Error) {
        print(error)
    }
    
    private func updateStatisticsWithData(_ data: Data) {
        let json = JSON(data)
        let realm = try! Realm()
        
        try! realm.write() {
            realm.create(Stock.self, value: ["id": json["symbol"].stringValue,
                                             "symbol": json["symbol"].stringValue,
                                             "dividendYield": json["dividendYield"].doubleValue,
                                             "returnOnEquity": json["returnOnEquity"].doubleValue,
                                             "profitMargin": json["profitMargin"].doubleValue,
                                             "priceToBook": json["priceToBook"].doubleValue], update: true)
            
        }
        
    }
    
    private func updateCompanyWithData(_ data: Data) {
        let json = JSON(data)
        let realm = try! Realm()
        
        try! realm.write() {
            realm.create(Stock.self, value: ["id": json["symbol"].stringValue,
                                             "symbol": json["symbol"].stringValue,
                                             "name": json["companyName"].stringValue,
                                             "exchange": json["exchange"].stringValue,
                                             "industry": json["industry"].stringValue,
                                             "sector": json["sector"].stringValue,
                                             "ceo": json["CEO"].stringValue,
                                             "issueType": json["issueType"].stringValue], update: true)
            
        }
    }
    
    private func updateQuoteWithData(_ data: Data) {
        let json = JSON(data)
        let realm = try! Realm()
        
        try! realm.write() {
            realm.create(Stock.self, value: ["id": json["symbol"].stringValue,
                                             "symbol": json["symbol"].stringValue,
                                             "price": json["latestPrice"].doubleValue,
                                             "priceToEarnings": json["peRatio"].doubleValue,
                                             "week52high": json["week52high"].doubleValue,
                                             "week52low": json["week52low"].doubleValue,
                                             "marketCap": json["marketCap"].doubleValue], update: true)
            
        }
    }
}

let GlobalDataController = DataController()