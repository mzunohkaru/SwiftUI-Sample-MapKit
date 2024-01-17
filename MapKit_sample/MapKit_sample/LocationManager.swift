//
//  LocationManager.swift
//  MapKit_sample
//
//  Created by Mizuno Hikaru on 2024/01/17.
//

import Foundation
import CoreLocation

// 位置情報へのアクセス許可の状態が変更されたときに通知を受け取ります
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    override init() {
        print("LocationManagerを初期化")
        super.init()
        requestPermission() // 位置情報へのアクセス許可をリクエスト
        locationManager.startUpdatingLocation()
    }
    
    private func requestPermission() {
        Task {
            //位置情報のサービスが有効の場合
            if CLLocationManager.locationServicesEnabled() {
                print("位置情報のサービスが有効")
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
            }
            
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                print("リクエストを送信")
                locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                print("すでに許可されています")
            @unknown default:
                print("未知の認証ステータス")
            }
        }
    }
    
    // 位置情報へのアクセス許可の状態が変更されたときに呼び出されます
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            // .notDetermined: ユーザーがまだこのアプリに対する位置情報へのアクセス許可を決定していない状態
            // .restricted: 親の制御や企業のポリシーなどにより、アプリが位置情報へのアクセスを制限されている状態
            // .denied: ユーザーがこのアプリに対する位置情報へのアクセスを拒否した状態
        case .notDetermined, .restricted, .denied:
            print("リクエストを送信")
            locationManager.requestWhenInUseAuthorization()
            // .authorizedWhenInUse: ユーザーがアプリが前面にあるときのみ位置情報へのアクセスを許可した状態
            // .authorizedAlways: ユーザーがアプリがバックグラウンドにあるときも位置情報へのアクセスを許可した状態
        case .authorizedWhenInUse, .authorizedAlways:
            print("すでに許可されています")
        default:
            print("未知の認証ステータス")
        }
    }
}
