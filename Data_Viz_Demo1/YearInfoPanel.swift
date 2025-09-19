//
//  YearInfoPanel.swift
//  Data_Viz_Demo1
//
//  A panel that displays decade-specific information about polio data
//

import SwiftUI

struct YearInfoPanel: View {
    @Binding var currentYear: Int
    
    // Decade data embedded directly
    private let decadeData: [String: (summary: String, bullets: [String])] = [
        "1980s": (
            summary: "The 1980s marked the turning point when the world believed polio could be stopped. Local successes in Brazil and the Dominican Republic proved elimination was possible, and by 1988 the fight became a global mission.",
            bullets: [
                "Global cases: ~350,000 annually (1980) → ~60,000 (1989).",
                "Brazil's National Immunization Days slash cases from thousands to ~70 in two years.",
                "Dominican Republic eliminates polio (1983), showing national eradication was possible.",
                "Global Polio Eradication Initiative (1988) launched, uniting WHO, UNICEF, Rotary, and CDC."
            ]
        ),
        "1990s": (
            summary: "The 1990s proved eradication could happen at scale. Regions were certified polio-free, and leaders like Nelson Mandela rallied millions to join the movement.",
            bullets: [
                "Global cases: ~60,000 (1990) → ~7,000 (1999).",
                "Americas certified polio-free (1994), the first WHO region.",
                "Nelson Mandela's \"Kick Polio Out of Africa\" (1996) mobilized 50+ countries.",
                "Western Pacific (1997) and Europe (1998) record last cases, preparing for certification."
            ]
        ),
        "2000s": (
            summary: "By the 2000s, polio was cornered to a few countries, but setbacks from misinformation and weak systems showed progress was fragile.",
            bullets: [
                "Global cases: ~7,000 (2000) → ~1,300 (2009).",
                "Western Pacific certified polio-free (2000), covering 1.6B people.",
                "Vaccination suspension in northern Nigeria (2003) sparks outbreaks in dozens of countries.",
                "By 2006, only four countries remained endemic: Afghanistan, India, Nigeria, and Pakistan."
            ]
        ),
        "2010s": (
            summary: "The 2010s brought major triumphs, with India ending polio and two strains eradicated, but outbreaks in under-vaccinated areas showed the last mile would be difficult.",
            bullets: [
                "Global cases: ~1,300 (2010) → ~175 (2019).",
                "India records its last case (2011) — a landmark in a country of 1.2B people.",
                "Polio type 2 (2015) and type 3 (2019) declared eradicated worldwide.",
                "WHO declares polio a global health emergency (2014), reminding the world the job isn't done."
            ]
        ),
        "2020s": (
            summary: "The 2020s have been defined by resilience: Africa was certified polio-free, COVID-19 disrupted campaigns, and new vaccines were deployed as the virus reached historic lows.",
            bullets: [
                "Global cases: ~175 (2020) → ~20 (2024).",
                "Africa certified wild polio-free (2020), protecting 1.8B people.",
                "Next-gen vaccine (nOPV2) rolled out (2021) to fight dangerous flare-ups.",
                "Polio remains a Public Health Emergency (2025), with wild virus only in Afghanistan and Pakistan."
            ]
        )
    ]
    
    // Get current decade string
    private var currentDecade: String {
        if currentYear >= 2020 {
            return "2020s"
        } else if currentYear >= 2010 {
            return "2010s"
        } else if currentYear >= 2000 {
            return "2000s"
        } else if currentYear >= 1990 {
            return "1990s"
        } else {
            return "1980s"
        }
    }
    
    // Get decade data for current year
    private var currentDecadeData: (summary: String, bullets: [String])? {
        decadeData[currentDecade]
    }
    
    // Get subtitle for current decade
    private var decadeSubtitle: String {
        switch currentDecade {
        case "1980s":
            return "The Beginning of a Global Effort"
        case "1990s":
            return "Regional Victories & Bold Leadership"
        case "2000s":
            return "Closing In, But Facing Setbacks"
        case "2010s":
            return "Near Elimination, New Challenges"
        case "2020s":
            return "The Final Push"
        default:
            return ""
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Decade header with subtitle in dark glass frame
            VStack(alignment: .leading, spacing: 4) {
                Text(currentDecade)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(decadeSubtitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
            )
            .padding(.bottom, 20)
            
            // Summary text - fixed height container
            if let data = currentDecadeData {
                Text(data.summary)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)
                    .frame(minHeight: 60, maxHeight: 60, alignment: .topLeading)
                    .padding(.bottom, 20)
                
                // Bullet points - fixed height container
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(data.bullets.enumerated()), id: \.offset) { index, bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "globe.americas.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(width: 16, alignment: .center)
                            
                            Text(bullet)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 52, alignment: .top)
                    }
                }
                .frame(height: 220)  // Adjusted height for tighter spacing
            }
            
            Spacer(minLength: 0)  // Take up any remaining space
            
            // Timeline preview dots
            HStack(spacing: 12) {
                ForEach(["1980s", "1990s", "2000s", "2010s", "2020s"], id: \.self) { decade in
                    Circle()
                        .fill(currentDecade == decade ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentDecade == decade ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentDecade)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
        }
        .padding(.horizontal, 30)
        .padding(.top, 25)
        .padding(.bottom, 20)
        .frame(width: 400, height: 500)
        .fixedSize()  // Ensure the frame stays fixed size
        .background(.regularMaterial.opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.3), value: currentDecade)  // Smooth decade transitions
    }
}

#Preview {
    YearInfoPanel(currentYear: .constant(2012))
        .frame(width: 600, height: 600)
        .padding()
}