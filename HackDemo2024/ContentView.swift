//
//  ContentView.swift
//  HackDemo2024
//
//  Created by Dev Patel on 6/29/24.
//

import SwiftUI
import Combine
import Foundation
//import GoogleMaps

struct EventsResponse: Codable {
    let events: [Event]
}

struct Event: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let startTime: Int
    let endTime: Int
    let locations: [Location]
    let sponsor: String
    let eventType: String
    let points: Int
    let isAsync: Bool
    let mapImageUrl: String
    let isPro: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "eventId"
        case name
        case description
        case startTime
        case endTime
        case locations
        case sponsor
        case eventType
        case points
        case isAsync
        case mapImageUrl
        case isPro
    }
    var startDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(startTime))
    }
    
    var endDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(endTime))
    }
}

struct Location: Codable {
    let description: String
    let tags: [String]
    let latitude: Double
    let longitude: Double
}


struct ContentView: View {
    @StateObject private var viewModel = EventViewModel()
    
    var body: some View {
        NavigationView {
            ZStack{
                Image("Background")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    HStack {
                        Button(action: {
                            viewModel.selectedDate = .feb23
                            print("Selected Feb 23")
                        }) {
                            Text("Feb 23")
                                .padding()
                                .background(viewModel.selectedDate == .feb23 ? Color.blue : Color.white.opacity(0.65))
                                .foregroundColor(.white)
                                .cornerRadius(10)

                        }
                        Button(action: {
                            viewModel.selectedDate = .feb24
                            print("Selected Feb 24")
                        }) {
                            Text("Feb 24")
                                .padding()
                                .background(viewModel.selectedDate == .feb24 ? Color.blue :  Color.white.opacity(0.65))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        Button(action: {
                            viewModel.selectedDate = .feb25
                            print("Selected Feb 25")
                        }) {
                            Text("Feb 25")
                                .padding()
                                .background(viewModel.selectedDate == .feb25 ? Color.blue :  Color.white.opacity(0.65))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    
                    EventListView(events: viewModel.events(for: viewModel.selectedDate))
                        .onAppear {
                            viewModel.fetchEvents()
                        }
                }
                .navigationBarTitle("Events")
            }
        }
    }
}





class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var selectedDate: SelectedDate = .feb23
    
    enum SelectedDate {
        case feb23
        case feb24
        case feb25
        
        var dateString: String {
            switch self {
            case .feb23: return "Feb 23, 2024"
            case .feb24: return "Feb 24, 2024"
            case .feb25: return "Feb 25, 2024"
            }
        }
    }
    
    func fetchEvents() {
        apiCall().getEvents { eventsResponse in
            self.events = eventsResponse.events
            print("Fetched events: \(self.events.count)")
        }
    }
    
    func events(for date: SelectedDate) -> [Event] {
        let filteredEvents = events.filter { event in
            let eventDate = DateFormatter.tabDateFormatter.string(from: event.startDate)
            let isMatching = eventDate == date.dateString
            print("Event date: \(eventDate), Filter date: \(date.dateString), isMatching: \(isMatching)")
            return isMatching
        }
        
        print("Filtered events: \(filteredEvents.count) for \(date.dateString)")
        return filteredEvents
    }
}





struct EventListView: View {
    let events: [Event]
    @State private var selectedEvent: Event?
    @State private var isPresentingDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(events) { event in
                    Button(action: {
                        selectedEvent = event
                        isPresentingDetail = true
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(event.description)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("Starts: \(DateFormatter.eventTimeFormatter.string(from: event.startDate))")
                                .foregroundColor(.white)
                            Text("Ends: \(DateFormatter.eventTimeFormatter.string(from: event.endDate))")
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.65))
                                .shadow(radius: 3)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
    }
}





struct EventDetailView: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(event.name)
                .font(.largeTitle)
                .bold()
            
            Text(event.description)
                .font(.body)
            
            Text("Starts: \(DateFormatter.eventDateFormatter.string(from: event.startDate))")
            Text("Ends: \(DateFormatter.eventDateFormatter.string(from: event.endDate))")
            
            Text("Location:")
            ForEach(event.locations, id: \.description) { location in
                VStack(alignment: .leading) {
                    Text(location.description)
                    //show maps here
                                    }
                .padding(.bottom, 10)
            }
            
            Text("Sponsor: \(event.sponsor)")
            Text("Type: \(event.eventType)")
            Text("Points: \(event.points)")
            Text("Async: \(event.isAsync ? "Yes" : "No")")
            if let url = URL(string: event.mapImageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
    }
}



extension DateFormatter {
    static let eventDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let eventTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let tabDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

extension Date {
    static func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.date(from: dateString)
    }
    
    static var feb23: Date {
        return dateFromString("Feb 23, 2024")!
    }
    
    static var feb24: Date {
        return dateFromString("Feb 24, 2024")!
    }
    
    static var feb25: Date {
        return dateFromString("Feb 25, 2024")!
    }
}


class apiCall {
    func getEvents(completion: @escaping (EventsResponse) -> ()) {
        guard let url = URL(string: "https://adonix.hackillinois.org/event") else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error fetching events: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data returned")
                return
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            
            do {
                let eventsResponse = try JSONDecoder().decode(EventsResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(eventsResponse)
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        .resume()
    }
}

#Preview {
    ContentView()
}
