//
//  AboutView.swift
//  locale
//
//  Created by Adrian Martushev on 5/7/24.
//
import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var currentUser: CurrentUserViewModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Button(action: {
                        currentUser.showAbout = false
                    }) {
                        Image(systemName: "arrow.left")
                            .font(Font.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("text-bold"))
                            .opacity(0.7)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color("background-element"))
                            )
                            .outerShadow()
                    }
                    
                    Text("How to/FAQs")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color("text-bold"))
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .navigationTitle("")
                .navigationBarHidden(true)
                
                ScrollView {
                    AboutSectionItem(
                        title: "🚨 Sending Panic Alerts",
                        description: "To send a panic alert when you're in trouble or witness an event, follow these simple steps:\n\n1. Open the app and tap on the 'Panic' button located in the main navigation bar.\n\n2. Confirm your current location on the map and send the alert.\n\n3. Press the 'Send Alert' button to broadcast your alert to all users within a 10-mile radius. An alert notification will be sent out, and nearby users will be prompted to respond."
                    )
                    
                    AboutSectionItem(
                        title: "💸 Getting Paid",
                        description: "Earn money by being one of the first responders to upload useful footage of the event or alert area. Here’s how to get paid:\n\n1. Respond to an alert by navigating to the location using the Maps directions.\n\n2. Once at the location, use the app to record or upload footage of the event.\n\n3. Submit your footage through the app by following the on-screen instructions.\n\n4. Payments are automatically processed if your footage is among the first received and meets the required criteria. Ensure your Stripe account is connected to receive payments."
                    )
                    
                    AboutSectionItem(
                        title: "🔗 Connecting Your Stripe Account",
                        description: "To receive payments securely and efficiently, you must connect your Stripe account to the app. Here's how to do it:\n\n1. Tap on your balance in the app's menu, right below your profile photo. \n\n2. Tap 'Connect with Stripe' to start the setup.\n\n3. You will be redirected to a secure Stripe web page. Follow the instructions to log in to your existing Stripe account or create a new one.\n\n4. Once authenticated, grant the necessary permissions for the app to issue payments to your Stripe account.\n\n5. Return to the app after successful connection. You're now ready to receive payments directly to your bank account through Stripe."
                    )
                    
                    AboutSectionItem(
                        title: "📍 Finding Nearby Alerts",
                        description: "Stay aware of incidents around you and respond quickly using the app's alert system. Here's how to find nearby alerts:\n\n1. View a live map that shows active alerts highlighted within your vicinity.\n\n2. Alerts within a 10-mile radius of your location will automatically appear. Tap on any alert icon to view more details.\n\n3. Get directions to the alert location by tapping 'Get Directions', which integrates directly with your phone’s mapping software.\n4. Respond to the alert by following the directions provided and start recording or assisting as needed."
                    )
                }
            }
            .padding()
        }
        .background {
            Color("background")
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct AboutSectionItem: View {
    var title: String
    var description: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .padding(.bottom, 5)
            
            Text(description)
                .font(.system(size: 14, weight: .regular))
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
        }
        .foregroundColor(Color("text-bold"))
        .padding(.top, 20)
    }
}


#Preview {
    AboutView()
}
