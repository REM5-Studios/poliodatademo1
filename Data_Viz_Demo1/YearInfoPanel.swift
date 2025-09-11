//
//  YearInfoPanel.swift
//  Data_Viz_Demo1
//
//  A panel that displays year-specific information about polio data
//

import SwiftUI

struct YearInfoPanel: View {
    @Binding var currentYear: Int
    
    // Get timeline data for current year
    private var timelineEntry: TimelineEntry? {
        DataLoader.shared.timeline[currentYear]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Year and Category header - smaller text at top
            HStack(alignment: .top) {
                Text(String(currentYear))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.8))
                
                if let category = timelineEntry?.category {
                    Text("•")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 4)
                    
                    // Replace "Key Milestone Towards Eradication" with shorter version
                    let displayCategory = category == "Key Milestone Towards Eradication" ? "Key Eradication Milestone" : category
                    Text(displayCategory)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(.bottom, 12)
            
            // Headline - large bold font
            Text(timelineEntry?.headline ?? "Polio Data \(currentYear)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)
            
            // Subtext
            Text(timelineEntry?.subtext ?? "Visualizing global polio case data for \(currentYear)")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 20)
            
            Spacer()  // Push image to bottom
            
            // Timeline image - cycles through 1, 2, 3
            let imageNumber = ((currentYear - 1980) % 3) + 1
            let imageName = "timelineimage\(imageNumber)"
            
            Image(imageName)
                .resizable()
                .aspectRatio(1.0, contentMode: .fill)  // Fill the square frame
                .frame(maxWidth: .infinity)
                .frame(height: 230)  // Fixed height
                .background(Color.black)  // Background in case image doesn't fill
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(30)
        .frame(width: 400, height: 500)
        .fixedSize()  // Ensure the frame stays fixed size
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    YearInfoPanel(currentYear: .constant(1988))
        .frame(width: 600, height: 600)
        .padding()
}