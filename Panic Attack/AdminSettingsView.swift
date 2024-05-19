//
//  AdminSettingsView.swift
//  locale
//
//  Created by Adrian Martushev on 5/7/24.
//

import SwiftUI


struct AdminSettingsView: View {
    @EnvironmentObject var currentUser : CurrentUserViewModel
    @EnvironmentObject var adminVM : AdminViewModel

    
    
    var body: some View {
        
        ZStack {
            VStack {
                
                HStack {
                    Button(action: {
                        currentUser.showAdmin = false
                    }, label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))

                            .foregroundColor(Color("text-bold"))

                    })
                    
                    Text("Admin Settings")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color("text-bold"))
                    
                    Spacer()
                }
                .padding()
                .padding(.bottom)

                HStack {
                    Text("Responders")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color("text-bold"))
                    .padding(.leading, 5)
                    
                    Spacer()
                }
                .padding(.leading)
                
                VStack(spacing : 0) {
                    
                    VStack {
                        AccountStepperView(value: $adminVM.maxResponders, baseColor: .blue, icon: "person.3.fill", title: "Max Responders", updateValue: adminVM.updateMaxResponders)

                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    HStack {
                        Text("This is the number of people that can get paid to respond to an alert")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color("text-bold"))
                            .padding(.horizontal, 10)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    VStack {
                        AccountStepperView(value: $adminVM.paymentPerUpload, baseColor: .green, icon: "dollarsign", title: "Payment Per Upload", isFinancial: true, updateValue: adminVM.updatePaymentPerUpload)

                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("This is the amount each responder gets paid for uploading footage of an alert")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color("text-bold"))
                            .padding(.horizontal, 10)
                    }
                    .padding(.bottom)

                }
                .background(Color("background-element"))
                .cornerRadius(25)
                .shadow(color : Color("shadow-white"), radius : 1, x : -1, y : -1)
                .shadow(color : Color("shadow-black"), radius : 3, x : 2, y : 2)
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color("background"))
        }
    }
}


struct AccountStepperView : View {
    
    @EnvironmentObject var currentUser : CurrentUserViewModel
    
    @Binding var value : Int
    
    var baseColor : Color
    var icon : String
    var title : String
    var isFinancial = false
            
    var updateValue: (Int) -> Void

    var body: some View {
        HStack {
            ZStack {
                
                Circle()
                    .frame(width : 35, height : 35)
                    .foregroundStyle(
                        baseColor.gradient.shadow(.inner(color: .white.opacity(0.3), radius: 10, x: 3, y: 3))
                    )
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .bold))

            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("text-bold"))
                .padding(.leading, 5)
            
            Spacer()
            
            
            HStack (spacing: 0){
                Button {
                    if value > 0 {
                        value -= 1
                        generateHapticFeedback()
                        updateValue(value)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("text-bold"))
                        .frame(width : 20, height : 20)
                        .background(Color("background-element"))
                        .cornerRadius(5)
                        .outerShadow()
                }
                
                if isFinancial {
                    Text("$\(value)")
                        .font(.system(size: 18, weight: .medium))
                        .padding(.horizontal, 10)
                } else {
                    Text("\(value)")
                        .font(.system(size: 18, weight: .medium))
                        .padding(.horizontal, 10)
                }


                
                Button {
                    value += 1
                    generateHapticFeedback()
                    updateValue(value)

                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("text-bold"))
                        .frame(width : 20, height : 20)
                        .background(Color("background-element"))
                        .cornerRadius(5)
                        .outerShadow()
                }

            }

        }
        .padding(.bottom)
    }
}



class AdminViewModel : ObservableObject {
    
    @Published var paymentPerUpload : Int = 0
    @Published var maxResponders : Int = 0
    
    
    init() {
        fetchAdminDetails()
    }
    
    func fetchAdminDetails() {
        database.collection("config").document("config").addSnapshotListener { [self] snapshot, error in
            guard let document = snapshot else {
                print("Error fetching document: \(error!)")
                return
            }
                        
            self.paymentPerUpload = document.get("paymentPerUpload") as? Int ?? 0
            self.maxResponders = document.get("maxResponders") as? Int ?? 0
            
        }
    }
    
    func updateMaxResponders(newMaxResponders: Int) {
        database.collection("config").document("config").setData([
            "maxResponders": newMaxResponders,
        ], merge: true) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Updated max responders")
            }
        }
    }
    
    func updatePaymentPerUpload(newPaymentPerUpload: Int) {
        database.collection("config").document("config").setData([
            "paymentPerUpload": newPaymentPerUpload
        ], merge: true) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Updated payment per upload")
            }
        }
    }
}



#Preview {
    AdminSettingsView()
        .environmentObject(CurrentUserViewModel())
        .environmentObject(AdminViewModel())

}
