//
//  MyAmplifyAppApp.swift
//  MyAmplifyApp
//
//  Created by Kiuna, Dan on 12/11/24.
//
import Amplify
import Authenticator
import AWSCognitoAuthPlugin
import SwiftUI

@main
struct MyAmplifyAppApp: App {
    
    init(){
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure(with: .amplifyOutputs)
            print("Hi")
        } catch {
            print("Unable to configure Amplify \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
