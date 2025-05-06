import SwiftUI

struct RecentReadingsSection: View {
    let readings: [BloodPressureReading]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Recent Readings")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: AllReadingsView()) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(readings.prefix(5)) { reading in
                        ReadingCard(reading: reading)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
