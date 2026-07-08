import SwiftUI

/// Ronde avatar met initialen. Twee formaten via `size`: normaal (24-32) voor
/// rows en compact (18-20) voor lijst-samenvattingen.
struct PersonAvatar: View {
    let person: Person
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: person.colorHex))
            Text(person.initials)
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().stroke(Color.white, lineWidth: 1.5)
        )
    }
}

/// Groep van overlappende avatars, links-uitgelijnd. Bij meer dan `maxVisible`
/// personen wordt de laatste vervangen door een "+N"-teller.
struct AvatarStack: View {
    let people: [Person]
    var size: CGFloat = 22
    var maxVisible: Int = 3

    private var overflowCount: Int {
        max(0, people.count - maxVisible)
    }

    private var visible: [Person] {
        overflowCount == 0 ? people : Array(people.prefix(maxVisible - 1))
    }

    var body: some View {
        HStack(spacing: -size * 0.35) {
            ForEach(visible) { person in
                PersonAvatar(person: person, size: size)
            }
            if overflowCount > 0 {
                ZStack {
                    Circle().fill(AjetoColor.faint)
                    Text("+\(overflowCount + 1)")
                        .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: size, height: size)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            }
        }
    }
}
