//
//  ConfirmSafetyView.swift
//  Panic Attack
//
//  Created by Adrian Martushev on 6/30/24.
//

import SwiftUI


struct ConfirmSafetyView : View {
    @Binding var showConfirmSafety : Bool
    
    var onConfirm: () -> Void
    
    
    var body: some View {
        VStack(spacing : 0) {
            HStack {
                Button {
                    showConfirmSafety = false

                } label: {
                    Image(systemName : "xmark")
                        .foregroundColor(Color("text-bold"))
                        .opacity(0.7)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color("background-element"))
                        )
                        .outerShadow()
                }
                Spacer()
                
                Text("Criminal Activity")
                    .font(.system(size: 18, weight : .bold))
                    .foregroundColor(Color("text-bold"))
                    .offset(x : -10)


                Spacer()

            }
            .padding()
            
            Text(verbatim: "Panic Attack can’t be used to send alerts to the police for criminal activity. In order to alert police to a crime happening please contact 911.")
                .font(.system(size: 14, weight : .medium))
                .foregroundColor(Color("text-bold"))
                .padding(.horizontal)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            

            
            HStack(spacing : 15) {
                
                
                Button {
                    withAnimation {
                        showConfirmSafety = false
                        self.onConfirm()

                    }
                } label: {
                    HStack(spacing : 0) {
                        
                        Text("I understand")
                            .font(.system(size : 16, weight : .bold))
                            .foregroundColor(.white)
                    }
                    .frame( width : 200, height : 40)
                    .background(.blue)
                    .cornerRadius(10)
                    .shadow(color: Color("shadow-black"), radius: 3, x: 2, y: 2)
                }

            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
        

        }
        .frame(width : 350)
        .background(Color("background"))
        .cornerRadius(15)
        .outerShadow()
    }
}


#Preview {
    ConfirmSafetyView(showConfirmSafety: .constant(false), onConfirm: {
        print("test")
    })
}
