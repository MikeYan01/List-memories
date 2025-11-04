//
//  PhotoComponents.swift
//  List
//
//  Created by Linyi Yan on 11/4/25.
//

import SwiftUI
import PhotosUI

// Multiple photos picker
struct MultiplePhotosPickerView: View {
    @Binding var photosData: [Data]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingDeleteAlert = false
    @State private var photoToDelete: Int?
    
    let maxPhotos = 18

    var body: some View {
        VStack(spacing: 12) {
            if !photosData.isEmpty {
                // Photo grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(photosData.enumerated()), id: \.offset) { index, photoData in
                        if let uiImage = UIImage(data: photoData) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .clipped()
                                
                                // Delete button
                                Button {
                                    photoToDelete = index
                                    showingDeleteAlert = true
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(.black.opacity(0.5)))
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Add more button
                    if photosData.count < maxPhotos {
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: maxPhotos - photosData.count, matching: .images) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(.pink)
                                Text("\(photosData.count)/\(maxPhotos)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // Initial photo picker
                PhotosPicker(selection: $selectedItems, maxSelectionCount: maxPhotos, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundStyle(.pink.opacity(0.5))
                        
                        Text("添加照片 (最多\(maxPhotos)张)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        if let image = UIImage(data: data) {
                            if let compressedData = compressImage(image) {
                                photosData.append(compressedData)
                            }
                        }
                    }
                }
                selectedItems = []
            }
        }
        .alert("删除照片", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let index = photoToDelete {
                    photosData.remove(at: index)
                }
            }
        } message: {
            Text("确定要删除这张照片吗？")
        }
    }
    
    private func compressImage(_ image: UIImage) -> Data? {
        let maxSize: CGFloat = 1200
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage?.jpegData(compressionQuality: 0.8)
    }
}

// Photo carousel for detail view
struct PhotoCarouselView: View {
    let photosData: [Data]
    @State private var selectedPhotoIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(photosData.enumerated()), id: \.offset) { index, photoData in
                        if let uiImage = UIImage(data: photoData) {
                            Button {
                                selectedPhotoIndex = index
                            } label: {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 280, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .clipped()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if photosData.count > 1 {
                HStack {
                    Spacer()
                    Text("\(photosData.count) 张照片")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedPhotoIndex.map { PhotoIndex(index: $0, photosData: photosData) } },
            set: { selectedPhotoIndex = $0?.index }
        )) { photoIndex in
            PhotoGalleryView(photosData: photoIndex.photosData, initialIndex: photoIndex.index)
        }
    }
}

// Helper struct for fullScreenCover
struct PhotoIndex: Identifiable {
    let id = UUID()
    let index: Int
    let photosData: [Data]
}

// Full-screen photo gallery with swipe
struct PhotoGalleryView: View {
    let photosData: [Data]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    
    init(photosData: [Data], initialIndex: Int) {
        self.photosData = photosData
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                TabView(selection: $currentIndex) {
                    ForEach(Array(photosData.enumerated()), id: \.offset) { index, photoData in
                        if let uiImage = UIImage(data: photoData) {
                            GeometryReader { geometry in
                                ScrollView([.horizontal, .vertical]) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                }
                            }
                            .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicator
                VStack {
                    Spacer()
                    if photosData.count > 1 {
                        Text("\(currentIndex + 1) / \(photosData.count)")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// Compact photo thumbnail for first photo in list
struct PhotoThumbnail: View {
    let photosData: [Data]
    
    var body: some View {
        if let firstPhoto = photosData.first, let uiImage = UIImage(data: firstPhoto) {
            ZStack(alignment: .bottomTrailing) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if photosData.count > 1 {
                    Text("+\(photosData.count - 1)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.7))
                        .clipShape(Capsule())
                        .padding(4)
                }
            }
        }
    }
}
