//
//  SharedComponents.swift
//  List
//
//  Created by Linyi Yan on 11/3/25.
//

import SwiftUI

// Empty state view
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.appAccent.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// Detail row component
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.appAccent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }
}

// Custom partially-filled star for precise rating display
struct PartiallyFilledStar: View {
    let fillPercentage: Double // 0.0 to 1.0
    let size: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background (empty star)
            Image(systemName: "star")
                .font(.system(size: size))
                .foregroundStyle(.gray.opacity(0.3))
            
            // Foreground (filled portion)
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(.yellow)
                .mask(
                    GeometryReader { geometry in
                        Rectangle()
                            .frame(width: geometry.size.width * fillPercentage)
                    }
                )
        }
    }
}

// Star rating display (non-interactive) - Shows 5 stars based on 100-point scale
struct StarRatingView: View {
    let rating: Int  // 0-100
    let maxRating: Int = 5
    let size: CGFloat = 16
    
    private var starRating: Double {
        Double(rating) / 20.0  // Convert 100-point to 5-star (100/20 = 5)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                let starValue = starRating - Double(index - 1)
                
                if starValue >= 1 {
                    // Full star
                    Image(systemName: "star.fill")
                        .font(.system(size: size))
                        .foregroundStyle(.yellow)
                } else if starValue > 0 {
                    // Partially filled star (precise)
                    PartiallyFilledStar(fillPercentage: starValue, size: size)
                } else {
                    // Empty star
                    Image(systemName: "star")
                        .font(.system(size: size))
                        .foregroundStyle(.gray.opacity(0.3))
                }
            }
            
            // Show numeric rating
            if rating > 0 {
                Text("\(rating)/100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
}

// Interactive 100-point rating picker with multiple input methods
struct RatingPicker: View {
    @Binding var rating: Int
    let maxRating: Int = 100
    
    @State private var inputMethod: InputMethod = .slider
    @State private var textInput: String = ""
    
    enum InputMethod {
        case slider
        case quick
        case precise
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Star visualization with large numeric display
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { index in
                        let starValue = Double(rating) / 20.0 - Double(index - 1)
                        
                        if starValue >= 1 {
                            Image(systemName: "star.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.yellow)
                        } else if starValue > 0 {
                            PartiallyFilledStar(fillPercentage: starValue, size: 28)
                        } else {
                            Image(systemName: "star")
                                .font(.system(size: 28))
                                .foregroundStyle(.gray.opacity(0.3))
                        }
                    }
                }
                
                // Large numeric rating display
                if rating > 0 {
                    Text("\(rating)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.appAccent)
                    +
                    Text("/100")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text("rating.unrated".localized())
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
            
            // Input method selector
            Picker("Input Method", selection: $inputMethod) {
                Text("rating.input.slider".localized()).tag(InputMethod.slider)
                Text("rating.input.quick".localized()).tag(InputMethod.quick)
                Text("rating.input.precise".localized()).tag(InputMethod.precise)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Different input methods
            Group {
                switch inputMethod {
                case .slider:
                    SliderInputView(rating: $rating)
                case .quick:
                    QuickRatingView(rating: $rating)
                case .precise:
                    PreciseInputView(rating: $rating, textInput: $textInput)
                }
            }
            .frame(minHeight: 200)
            
            // Clear rating button
            if rating > 0 {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        rating = 0
                        textInput = ""
                    }
                } label: {
                    Text("rating.clear".localized())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// Slider input (0-100 with smooth control)
struct SliderInputView: View {
    @Binding var rating: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Slider(value: Binding(
                get: { Double(rating) },
                set: { rating = Int($0) }
            ), in: 0...100, step: 1)
            .tint(.appAccent)
            
            HStack {
                Text("0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("50")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding()
    }
}

// Quick rating buttons (by 10s, plus common values)
struct QuickRatingView: View {
    @Binding var rating: Int
    
    let quickValues = [
        [60, 65, 70, 75, 80],
        [82, 85, 88, 90, 92],
        [95, 97, 98, 99, 100]
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("rating.common_ratings".localized())
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ForEach(quickValues.indices, id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    ForEach(quickValues[rowIndex], id: \.self) { value in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                rating = value
                            }
                        } label: {
                            Text("\(value)")
                                .font(.system(size: 16, weight: value == rating ? .bold : .regular))
                                .foregroundStyle(value == rating ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(value == rating ? Color.appAccent : Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
    }
}

// Precise numeric input (0-100 with keyboard)
struct PreciseInputView: View {
    @Binding var rating: Int
    @Binding var textInput: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("rating.enter_value".localized())
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                TextField("0", text: $textInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 32, weight: .semibold))
                    .frame(width: 100, height: 60)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isFocused)
                    .onChange(of: textInput) { oldValue, newValue in
                        // Filter to only allow numbers
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            textInput = filtered
                        }
                        
                        // Update rating if valid
                        if let value = Int(filtered), value <= 100 {
                            rating = value
                        } else if !filtered.isEmpty {
                            // If over 100, cap at 100
                            textInput = "100"
                            rating = 100
                        }
                    }
                    .onAppear {
                        if rating > 0 {
                            textInput = "\(rating)"
                        }
                    }
                
                Text("/ 100")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            // Quick increment/decrement
            HStack(spacing: 20) {
                Button {
                    if rating > 0 {
                        rating -= 1
                        textInput = "\(rating)"
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(rating > 0 ? .appAccent : .gray.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(rating == 0)
                
                Button {
                    if rating < 100 {
                        rating += 1
                        textInput = "\(rating)"
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(rating < 100 ? .appAccent : .gray.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(rating == 100)
            }
        }
        .padding()
    }
}

// Rating row for detail view
struct RatingRow: View {
    let rating: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundStyle(.appAccent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("rating.label".localized())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                StarRatingView(rating: rating)
            }
        }
        .padding(.vertical, 4)
    }
}

// Filter chip component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.appAccent : Color.gray.opacity(0.2))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// Flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
