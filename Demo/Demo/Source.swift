//
//  Source.swift
//  Demo
//
//  Created by Muukii on 2022/01/29.
//

import Foundation

#if canImport(AsyncDisplayKit)
import AsyncDisplayKit
#warning("✅")
func run_AsyncDisplayKit() {
  ASVideoNode()
}
#endif

#if canImport(JAYSON)
import JAYSON
#warning("✅")
func run_JAYSON() {
  let j = JAYSON.JSON.init()
}
#endif

#if canImport(SSZipArchive)
import SSZipArchive
#warning("✅")
#endif

#if canImport(Alamofire)
#warning("✅")
func run_Alamofire() {
  let j = Alamofire.Session()
}
#endif

#if canImport(Moya)
import Moya
#endif
//import RxSwift


//func run() {
//  
//  Observable<Void>.create { _ in
//    
//    return Disposables.create()
//  }
//  
//}
