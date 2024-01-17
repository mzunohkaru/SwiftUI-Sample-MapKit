//
//  LocationDetailsView.swift
//  MapKit_sample
//
//  Created by Mizuno Hikaru on 2024/01/17.
//

import SwiftUI
import MapKit

struct LocationDetailsView: View {
    
    @Binding var mapSelection: MKMapItem?
    @Binding var show: Bool
    @State private var lookAroundScene: MKLookAroundScene?
    @Binding var getDirections: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text(mapSelection?.placemark.name ?? "")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button{
                    show.toggle()
                    mapSelection = nil
                } label: {
                     Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.gray, Color(.systemGray6))
                }
            }
            .padding(.top, 20)
            
            Text(mapSelection?.placemark.title ?? "")
                .font(.footnote)
                .foregroundStyle(.gray)
                .lineLimit(2)
                .padding(.trailing)
            
            if let scene = lookAroundScene {
                LookAroundPreview(initialScene: scene)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding()
            } else {
                ContentUnavailableView("No preview available", systemImage: "eye.slash")
            }
            
            HStack(spacing: 24) {
                Button {
                    if let mapSelection {
                        mapSelection.openInMaps()
                    }
                } label: {
                    Text("Open in Maps")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 170, height: 48)
                        .background(.green)
                        .cornerRadius(12)
                }
                
                Button {
                    getDirections = true
                    show = false
                } label: {
                    Text("Get Directions")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 170, height: 48)
                        .background(.blue)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        // Sheetの位置詳細ページが開かれた時に呼ばれる
        .onAppear {
            print("DEBUG: Did call on appear")
            fetchLookAroundPreview()
        }
        // 別の地点を選択する時に呼ばれる
        .onChange(of: mapSelection) { oldValue, newValue in
            print("DEBUG: Did call on change")
            fetchLookAroundPreview()
        }
    }
}

extension LocationDetailsView {
    // 選択された地図の項目に対して "Look Around"（周囲を見る） プレビューを取得する
    func fetchLookAroundPreview() {
        // マップが選択されている場合
        if let mapSelection {
            // 新しいプレビューを取得する前に、前のプレビューをリセットする
            lookAroundScene = nil
            // メインスレッドをブロックすることなく時間のかかる操作を行う
            Task {
                // 選択された地図の項目に対する"Look Around"プレビューをリクエストするためのもの
                let request = MKLookAroundSceneRequest(mapItem: mapSelection)
                // リクエストから"Look Around"シーンを非同期に取得し、結果をlookAroundSceneに保存
                lookAroundScene = try? await request.scene
            }
        }
    }
}
