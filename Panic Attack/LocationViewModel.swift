
//
//  LocationViewManager.swift
//  locale
//
//  Created by Adrian Martushev on 3/2/24.
//

import Foundation
import Firebase
import FirebaseAuth
import CoreLocation
import MapKit


struct LocationAlert : Identifiable, Hashable {
    var id : String
    var lat : Double
    var lng : Double
    var userID : String
    var userName : String
    var profilePhoto : String
    var dateSent : Date
}

let empty_alert = LocationAlert(id: "anonymous", lat: 37.7749, lng: 122.4194, userID: "anonymous", userName : "", profilePhoto: "", dateSent: Date())


class LocationViewModel : NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var locationAlerts: [LocationAlert] = [empty_alert]
    private var locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var locationString = ""
    @Published var locationToDisplay : LocationAlert = empty_alert

    @Published var currentUserID : String?
    @Published var didUpdateDatabaseLocation = false
    
    
    func listen () {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            self.currentUserID = user?.uid
        }
    }
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.listen()
    }
    
    // Respond to authorization status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            case .notDetermined:
                // Request when-in-use authorization initially
                manager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                // Handle case where user has denied or restricted location services
                break
            case .authorizedWhenInUse, .authorizedAlways:
                // Permission granted, start location updates
                manager.startUpdatingLocation()
                fetchLocationAlerts()
            @unknown default:
                break
        }
    }
    
    // Handle location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // San Francisco coordinates
        let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        
        DispatchQueue.main.async { [weak self] in
            self?.userLocation = defaultLocation
            self?.updateUsersLocationInFirestore()
        }
    }
    
    func updateUsersLocationInFirestore() {
        guard let location = self.userLocation else {
            print("Location data is nil, cannot update.")
            return
        }
        
        guard let userID = self.currentUserID else {
            print("User ID is unavailable.")
            return
        }
        
        if !didUpdateDatabaseLocation {
            
            let userInfo = database.collection("users").document(userID)
            
            let data = [
                "lat": location.coordinate.latitude,
                "lng": location.coordinate.longitude
            ]
            
            userInfo.updateData(data) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("User data successfully updated: \(data)")
                    self.didUpdateDatabaseLocation = true
                }
            }
        }
    }

    
    
    func fetchLocationAlerts() {
        
        print("Fetching all global alerts from the last 24 hours within a 10-mile radius")

        let db = Firestore.firestore()
        let locationAlertsCollection = db.collection("locationAlerts")
        let usersCollection = db.collection("users")

        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let oneDayAgoTimestamp = Timestamp(date: oneDayAgo)

        locationAlertsCollection.whereField("dateSent", isGreaterThan: oneDayAgoTimestamp).getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }

            var alerts: [LocationAlert] = []
            let dispatchGroup = DispatchGroup()

            for doc in documents {
                let data = doc.data()
                if let lat = data["latitude"] as? Double, let lng = data["longitude"] as? Double {
                    let alertLocation = CLLocation(latitude: lat, longitude: lng)
                    
                    if let userLocation = self.userLocation {
                        let distanceInMeters = userLocation.distance(from: alertLocation)
                        
                        // Convert 10 miles to meters
                        let tenMilesInMeters = 16093.4

                        if distanceInMeters <= tenMilesInMeters {
                            let userID = data["userID"] as? String ?? ""
                            dispatchGroup.enter()

                            usersCollection.document(userID).getDocument { (userDocSnapshot, error) in
                                guard let userData = userDocSnapshot?.data(), error == nil else {
                                    print("Error fetching user data: \(error!)")
                                    dispatchGroup.leave()
                                    return
                                }

                                let alert = LocationAlert(
                                    id: doc.documentID,
                                    lat: lat,
                                    lng: lng,
                                    userID: userID,
                                    userName: userData["name"] as? String ?? "Unknown",
                                    profilePhoto: userData["profilePhoto"] as? String ?? "",
                                    dateSent: (data["dateSent"] as? Timestamp)?.dateValue() ?? Date()
                                )

                                alerts.append(alert)
                                dispatchGroup.leave()
                            }
                        }
                    }

                }
            }

            dispatchGroup.notify(queue: .main) {
                print("Got location alerts within a 10-mile radius: \(alerts)")
                self.locationAlerts = alerts
            }
        }
    }

    
    func sendLocationAlert(currentUserID : String, completion: @escaping (Bool, String) -> Void) {
        // Ensure there's a valid user location to work with
        guard let userLocation = self.userLocation else {
            print("User location is not available.")
            completion(false, "Please enable your location in settings")
            return
        }

        let db = Firestore.firestore() // Reference to Firestore
        let locationAlertsCollection = db.collection("locationAlerts")
        
        // Create a dictionary representing the data to save
        let alertData: [String: Any] = [
            "latitude": userLocation.coordinate.latitude,
            "longitude": userLocation.coordinate.longitude,
            "userID": currentUserID,
            "dateSent": Timestamp(date: Date()),
            "locationString": self.locationString
        ]

        // Add a new document to the "locationAlerts" collection
        locationAlertsCollection.addDocument(data: alertData) { error in
            if let error = error {
                print("Error adding document: \(error.localizedDescription)")
                completion(false, "Failed to send panic alert: \(error.localizedDescription)")
            } else {
                self.sendAlertToAllUsers()
                self.fetchLocationAlerts()
                completion(true, "Panic Alert Sent!")
            }
        }
    }
    
    func deleteLocationAlert(locationID : String) {
        database.collection("locationAlerts").document(locationID).delete { error in
            if let error = error {
                print("Error removing document: \(error)")
            } else {
                print("Document successfully removed!")
                self.fetchLocationAlerts()
            }
        }
    }
    
    
    /// Sends a notification request to the server.
    /// - Parameters:
    ///   - deviceToken: The device token as a string.
    ///   - alert: The message for the alert.
    ///   - badge: The badge number for the app icon.
    func sendNotification(deviceToken: String, alert: String, badge: Int) {
        // Ensure the URL matches your server's endpoint
        guard let url = URL(string: "\(base_url)/sendNotification/") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Construct the JSON body with the device token, alert, and badge
        let body: [String: Any] = [
            "token": deviceToken,
            "alert": alert,
            "badge": badge,
            "sound": "default"  // Assuming your server expects this; adjust as needed
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Failed to serialize JSON body: \(error.localizedDescription)")
            return
        }
        
        // Create and start a data task to send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle the response or error
            if let error = error {
                print("Client error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Server returned an error")
                return
            }
            
            print("Notification sent successfully")
        }
        
        task.resume()
    }
    
    
    func sendAlertToAllUsers() {
        let db = Firestore.firestore() // Reference to Firestore
        let usersCollection = db.collection("users") // Assuming your user data is stored here
        
        print("Sending alert to all users in a 10 mile radius")
        guard let location = userLocation else {
            print("User location not available")
            return
        }
        
        let currentLat = location.coordinate.latitude
        let currentLng = location.coordinate.longitude
        let latDelta = 0.145 // Approximation for 10 miles in latitude
        let lngDelta = 0.145 // Approximation for 10 miles in longitude

        // Calculate the bounding coordinates
        let minLat = currentLat - latDelta
        let maxLat = currentLat + latDelta
        let minLng = currentLng - lngDelta
        let maxLng = currentLng + lngDelta

        // Query users within latitude range who have notifications turned on
        usersCollection.whereField("isPushOn", isEqualTo: true)
                       .whereField("lat", isGreaterThanOrEqualTo: minLat)
                       .whereField("lat", isLessThanOrEqualTo: maxLat)
                       .getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let userData = document.data()
                    print("Sending alert to userID : \(document.documentID)")
                    if let userLat = userData["lat"] as? Double,
                       let userLng = userData["lng"] as? Double,
                       userLng >= minLng && userLng <= maxLng {
                        
                        // Check if the user's longitude is within the range
                        guard let pushToken = userData["pushToken"] as? String else {
                            print("Push token not found for user: \(document.documentID)")
                            continue
                        }
                        
                        // Assuming you have a predefined alert message and badge number
                        let alertMessage = "New location alert"
                        let badgeNumber = 1 // Customize this as necessary
                        
                        // Send a notification to each user within the specified range
                        self.sendNotification(deviceToken: pushToken, alert: alertMessage, badge: badgeNumber)
                    }
                }
            }
        }
    }
    
    
    func sendAlertToAllAdmins() {
        let db = Firestore.firestore() // Reference to Firestore
        let usersCollection = db.collection("users") // Assuming your user data is stored here
        
        // Query users within latitude range who have notifications turned on
        usersCollection.whereField("isAdmin", isEqualTo: true)
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        let userData = document.data()
                        print("Sending alert to userID : \(document.documentID)")

                        guard let pushToken = userData["pushToken"] as? String else {
                            print("Push token not found for user: \(document.documentID)")
                            continue
                        }
                        
                        // Assuming you have a predefined alert message and badge number
                        let alertMessage = "A user has uploaded a video. View it at www.thepanicattack.app/videos"
                        let badgeNumber = 1 // Customize this as necessary
                        
                        // Send a notification to each user within the specified range
                        self.sendNotification(deviceToken: pushToken, alert: alertMessage, badge: badgeNumber)
                    }
                }
            }
                           
    }
}
