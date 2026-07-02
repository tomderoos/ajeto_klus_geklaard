import SwiftUI

struct RoomBadge: View {
    let room: Room
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: room.iconName)
                .font(.system(size: compact ? 9 : 10, weight: .semibold))
            Text(room.name)
                .font(AjetoFont.body(compact ? 10 : 11, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(AjetoColor.greenInk)
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(AjetoColor.mint, in: Capsule())
    }
}
