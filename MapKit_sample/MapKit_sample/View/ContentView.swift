//
//  ContentView.swift
//  MapKit_sample
//
//  Created by Mizuno Hikaru on 2024/01/17.
//

import SwiftUI
import MapKit

struct ContentView: View {
    // 位置情報の取得や更新を担当
    @StateObject private var locationManager = LocationManager()
    // 地図上のカメラの位置を管理する変数
    @State private var cameraPosition: MapCameraPosition = .region(.userRegion)
    
    @State private var searchText = ""
    // 検索結果（地図上の場所）を保持する配列
    @State private var results = [MKMapItem]()
    // ユーザーが地図上で選択した場所（MKMapItem）を保持する変数
    @State private var mapSelection: MKMapItem?
    @State private var showDetials = false
    // ユーザーが経路案内を要求したかどうかを示す
    @State private var getDirections = false
    // 経路が地図上に表示されているかどうかを示す
    @State private var routeDisplaying = false
    // 現在表示されている経路（MKRoute）を保持する変数
    @State private var route: MKRoute?
    // 経路の目的地（MKMapItem）を保持する変数
    @State private var routeDestination: MKMapItem?
    
    var body: some View {
        Map(position: $cameraPosition, selection: $mapSelection) {
            //            Marker("My location", systemImage: "paperplane", coordinate: .userLocation)
            //                .tint(.blue)
            
            // ユーザーの位置情報
            UserAnnotation()
            
            Annotation("My location", coordinate: .userLocation) {
                ZStack{
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.blue.opacity(0.25))
                    
                    Circle()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.white)
                    
                    Circle()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(.blue)
                }
            }
            
            ForEach(results, id: \.self) { item in
                // ルートが表示されている場合
                if routeDisplaying {
                    // ルートの目的地のマーカーのみを表示
                    if item == routeDestination {
                        let placemark = item.placemark
                        Marker(placemark.name ?? "", coordinate: placemark.coordinate)
                    }
                } else {
                    let placemark = item.placemark
                    Marker(placemark.name ?? "", coordinate: placemark.coordinate)
                }
            }
            
            if let route {
                // ポリライン
                MapPolyline(route.polyline)
                    .stroke(.blue)
            }
        }
        // Search TextField
        .overlay(alignment: .bottom){
            TextField("Search for a location ...", text: $searchText)
                .font(.subheadline)
                .padding(12)
                .background(.white)
                .padding()
                .shadow(radius: 10)
        }
        // 検索ボタン 又は、TextFieldに入力するときに実行される
        .onSubmit(of: .text) {
            Task { await searchPlaces() }
        }
        .onChange(of: getDirections, { oldValue, newValue in
            if newValue {
                fetchRoute()
            }
        })
        .onChange(of: mapSelection, { oldValue, newValue in
            // newValue が nil でない場合は、showDetials ( 位置の詳細 )を表示
            showDetials = newValue != nil
        })
        .sheet(isPresented: $showDetials, content: {
            LocationDetailsView(mapSelection: $mapSelection, show: $showDetials, getDirections: $getDirections)
                .presentationDetents([.height(340)])
            // sheetが表示された後もマップビューに指示できるようにする
                .presentationBackgroundInteraction(.enabled(upThrough: .height(340)))
                .presentationCornerRadius(12)
        })
        .mapControls {
            MapCompass()
            MapScaleView()
            MapPitchToggle() // MapStyle 3D or 2D
            MapUserLocationButton() // ユーザーの位置情報にアクセス
        }
    }
}

extension ContentView {
    // ユーザーが入力したテキスト（searchText）を使用して地域を検索
    func searchPlaces() async {
        // 検索リクエストを作成
        let request = MKLocalSearch.Request()
        // ユーザーが入力したテキストを基に場所を検索
        request.naturalLanguageQuery = searchText
        // 検索リクエストの地域（region） = ユーザーの現在地（.userRegion）
        request.region = .userRegion
        
        // 非同期に検索を開始
        let results = try? await MKLocalSearch(request: request).start()
        // 検索結果（results）はMKMapItemの配列として保存
        self.results = results?.mapItems ?? []
    }
    
    // ユーザーの現在地から選択した場所までのルートを取得
    func fetchRoute() {
        // ユーザーが地図上で選択した場所（mapSelection）が存在する場合
        if let mapSelection {
            // ルートリクエストを作成
            let request = MKDirections.Request()
            // リクエストの出発地点（source） = ユーザーの現在地（.userLocation）
            request.source = MKMapItem(placemark: .init(coordinate: .userLocation))
            //　リクエストの目的地（destination） = ユーザーが地図上で選択した場所（mapSelection）
            request.destination = mapSelection
            
            // Task : 非同期の操作を表すための型
            Task {
                // 非同期にルートを計算
                let result = try? await MKDirections(request: request).calculate()
                // 最初のルート（routes.first）を取得し、routeに保存
                route = result?.routes.first
                // ルートの目的地（routeDestination）はユーザーが地図上で選択した場所（mapSelection）に設定
                routeDestination = mapSelection
                
                // アニメーションを適用
                withAnimation(.snappy) {
                    // ルートが表示
                    routeDisplaying = true
                    // 詳細情報が非表示
                    showDetials = false
                    
                    if let rect = route?.polyline.boundingMapRect, routeDisplaying {
                        // カメラの位置がルートに合わせて更新
                        cameraPosition = .rect(rect)
                    }
                }
            }
        }
    }
}

extension CLLocationCoordinate2D {
    // ユーザーの位置情報
    static var userLocation: CLLocationCoordinate2D {
        return .init(latitude: 25.76, longitude: -80.19)
    }
}

extension MKCoordinateRegion {
    static var userRegion: MKCoordinateRegion {
        return .init(center: .userLocation,
                     latitudinalMeters: 10000,
                     longitudinalMeters: 10000)
    }
}

#Preview {
    ContentView()
}
