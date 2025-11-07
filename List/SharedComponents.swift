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
                .foregroundStyle(.pink.opacity(0.5))
            
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
                .foregroundStyle(.pink)
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

// Star rating display (non-interactive) - Shows 5 stars based on 10-point scale
struct StarRatingView: View {
    let rating: Int  // 0-10
    let maxRating: Int = 5
    
    private var starRating: Double {
        Double(rating) / 2.0  // Convert 10-point to 5-star
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                let starValue = starRating - Double(index - 1)
                
                if starValue >= 1 {
                    // Full star
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                } else if starValue > 0 {
                    // Half star
                    Image(systemName: "star.leadinghalf.filled")
                        .foregroundStyle(.yellow)
                } else {
                    // Empty star
                    Image(systemName: "star")
                        .foregroundStyle(.gray.opacity(0.3))
                }
            }
            
            // Show numeric rating
            if rating > 0 {
                Text("\(rating)/10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
        .font(.system(size: 16))
    }
}

// Interactive 10-point rating picker
struct RatingPicker: View {
    @Binding var rating: Int
    let maxRating: Int = 10
    
    var body: some View {
        VStack(spacing: 16) {
            // Star visualization
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    let starValue = Double(rating) / 2.0 - Double(index - 1)
                    
                    if starValue >= 1 {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    } else if starValue > 0 {
                        Image(systemName: "star.leadinghalf.filled")
                            .foregroundStyle(.yellow)
                    } else {
                        Image(systemName: "star")
                            .foregroundStyle(.gray.opacity(0.3))
                    }
                }
                .font(.system(size: 24))
            }
            
            // Numeric rating display
            if rating > 0 {
                Text(String(format: "rating.points".localized(), rating))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.pink)
            } else {
                Text("rating.unrated".localized())
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            // Number picker grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(1...maxRating, id: \.self) { number in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            rating = number
                        }
                    } label: {
                        Text("\(number)")
                            .font(.system(size: 18, weight: number == rating ? .bold : .regular))
                            .foregroundStyle(number == rating ? .white : .primary)
                            .frame(width: 44, height: 44)
                            .background(number == rating ? Color.pink : Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Clear rating button
            if rating > 0 {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        rating = 0
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

// Rating row for detail view
struct RatingRow: View {
    let rating: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundStyle(.pink)
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
            .background(isSelected ? Color.pink : Color.gray.opacity(0.2))
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
