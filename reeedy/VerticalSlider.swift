import SwiftUI

struct VerticalSlider: View {
    @Binding var value: Float
    var inRange: ClosedRange<Float> = 0...1

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Track
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))

                // Filled Track
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.8))
                    .frame(height: geometry.size.height * CGFloat(self.value / self.inRange.upperBound))

                // Thumb
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 2)
                    .frame(width: 24, height: 24)
                    .offset(y: (geometry.size.height - 24) * CGFloat(self.value / self.inRange.upperBound))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged {
                        let newValue = 1 - Float($0.location.y / geometry.size.height)
                        self.value = min(max(newValue, self.inRange.lowerBound), self.inRange.upperBound)
                    }
            )
        }
    }
}
