import SwiftUI

struct PhotoGalleryView: View {
    let photos: [ChorePhoto]
    @State private var fullScreen: GalleryIndex?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    if let image = PhotoStorage.load(photo.filename) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 220, height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture { fullScreen = GalleryIndex(value: index) }
                    }
                }
            }
            .padding(.horizontal)
        }
        .fullScreenCover(item: $fullScreen) { idx in
            FullScreenGallery(photos: photos, startIndex: idx.value) {
                fullScreen = nil
            }
        }
    }
}

struct GalleryIndex: Identifiable {
    let value: Int
    var id: Int { value }
}

private struct FullScreenGallery: View {
    let photos: [ChorePhoto]
    let startIndex: Int
    let onClose: () -> Void

    @State private var currentIndex: Int

    init(photos: [ChorePhoto], startIndex: Int, onClose: @escaping () -> Void) {
        self.photos = photos
        self.startIndex = startIndex
        self.onClose = onClose
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    if let image = PhotoStorage.load(photo.filename) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white, .black.opacity(0.5))
                    .padding()
            }
        }
    }
}
