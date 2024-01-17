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
    
    // アニメーションの一部としてビュー間でレイアウト情報を共有するために使用
    @Namespace private var locationSpace
    // 地図の現在の表示領域を保持するための変数
    // ユーザーが地図を移動またはズームしたときに更新されます
    @State private var viewingRegion: MKCoordinateRegion?
    
    @State private var searchText: String = ""
    @State private var showSearch: Bool = false
    @State private var showDialog: Bool = false
    @State private var isStandard: Bool = true
    
    // 検索結果（地図上の場所）を保持する配列
    @State private var results = [MKMapItem]()
    // ユーザーが地図上で選択した場所（MKMapItem）を保持する変数
    @State private var mapSelection: MKMapItem?
    @State private var showDetails: Bool = false
    // ユーザーが経路案内を要求したかどうかを示す
    @State private var getDirections: Bool = false
    // 経路が地図上に表示されているかどうかを示す
    @State private var routeDisplaying: Bool = false
    // 現在表示されている経路（MKRoute）を保持する変数
    @State private var route: MKRoute?
    // 経路の目的地（MKMapItem）を保持する変数
    @State private var routeDestination: MKMapItem?
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $mapSelection, scope: locationSpace) {
                //            Annotation("My location", coordinate: .userLocation) {
                //                ZStack{
                //                    Circle()
                //                        .frame(width: 100, height: 100)
                //                        .foregroundStyle(.blue.opacity(0.25))
                //
                //                    Circle()
                //                        .frame(width: 20, height: 20)
                //                        .foregroundStyle(.white)
                //
                //                    Circle()
                //                        .frame(width: 12, height: 12)
                //                        .foregroundStyle(.blue)
                //                }
                //            }
                
                // ユーザーの位置情報
                UserAnnotation()
                
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
            // 地図のカメラ（表示領域）が変更された (ユーザーが地図を移動またはズーム) ときに実行される処理
            .onMapCameraChange({ ctx in
                // ctx.region（地図の新しい表示領域）
                viewingRegion = ctx.region
            })
            // Search TextField
            //        .overlay(alignment: .bottom){
            //            TextField("Search for a location ...", text: $searchText)
            //                .font(.subheadline)
            //                .padding(12)
            //                .background(.white)
            //                .padding()
            //                .shadow(radius: 10)
            //        }
            .overlay(alignment: .bottomTrailing) {
                VStack(spacing: 15) {
                    MapCompass(scope: locationSpace)
                    MapPitchToggle(scope: locationSpace) // MapStyle 3D or 2D
                    MapUserLocationButton(scope: locationSpace) // ユーザーの位置情報にアクセス
                    Image(systemName: "swirl.circle.righthalf.filled")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .onTapGesture {
                            showDialog = true
                        }
                }
                .buttonBorderShape(.circle)
                .padding()
            }
            .mapScope(locationSpace)
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            // Search Bar
            .searchable(text: $searchText, isPresented: $showSearch)
            // Showing Trasnlucent ToolBar
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            // ルートが表示されているかどうかに応じてナビゲーションバーのツールバーを表示または非表示にする処理
            .toolbar(routeDisplaying ? .hidden: .visible, for: .navigationBar)
            // getDirections の値が変更されたときに実行される処理
            .onChange(of: getDirections, { oldValue, newValue in
                if newValue {
                    fetchRoute()
                }
            })
            // mapSelection の値が変更されたときに実行される処理
            .onChange(of: mapSelection, { oldValue, newValue in
                // newValue が nil でない場合は、showDetials ( 位置の詳細 )を表示
                showDetails = newValue != nil
            })
            // showSearch の値が変更されたときに実行される処理
            .onChange(of: showSearch, initial: false) {
                if !showSearch {
                    // 検索結果を初期化
                    results.removeAll(keepingCapacity: false)
                    showDetails = false
                    // アニメーションを伴って地図のカメラ位置をユーザーの領域（userRegion）に戻します
                    withAnimation(.snappy) {
                        cameraPosition = .region(.userRegion)
                    }
                }
            }
            .sheet(isPresented: $showDetails, content: {
                LocationDetailsView(mapSelection: $mapSelection, show: $showDetails, getDirections: $getDirections)
                    .presentationDetents([.height(340)])
                // sheetが表示された後もマップビューに指示できるようにする
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(340)))
                    .presentationCornerRadius(12)
                    .interactiveDismissDisabled(true)
            })
            .mapStyle(isStandard ? .standard() : .hybrid)
            // Dialog
            .confirmationDialog("Dialog Title", isPresented: $showDialog) {
                Button("normal"){
                    isStandard = true
                }
                Button("hybrid"){
                    isStandard = false
                }
                Button("Cansel", role: .cancel){}
            } message: {
                Text("マップスタイルを変更できます")
            }
            .mapControls {
                MapScaleView()
            }
            // 画面の下部にビューを追加するための処理
            .safeAreaInset(edge: .bottom) {
                if routeDisplaying {
                    Button("End Route") {
                        // Closing The Route and Setting the Selection
                        withAnimation(.snappy) {
                            routeDisplaying = false
                            showDetails = true
                            mapSelection = routeDestination
                            routeDestination = nil
                            route = nil
                            cameraPosition = .region(.userRegion)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.red.gradient)
                    .cornerRadius(15)
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
        }
        // 検索ボタン 又は、TextFieldに入力するときに実行される
        .onSubmit (of: .search) {
            Task {
                guard !searchText.isEmpty else { return }
                await searchPlaces()
            }
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
        request.region = viewingRegion ?? .userRegion
        
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
            request.source = .init(placemark: .init(coordinate: .userLocation))
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
                    showDetails = false
                    
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
