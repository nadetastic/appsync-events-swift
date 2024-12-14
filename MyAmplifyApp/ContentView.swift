import SwiftUI
import Foundation
import CryptoKit

struct ContentView: View {
    @State private var socket: URLSessionWebSocketTask?
    @State private var messages: [String] = []

    let REALTIME_DOMAIN = "abcd1234.appsync-realtime-api.us-east-1.amazonaws.com"
    let HTTP_DOMAIN = "abcd1234.appsync-api.us-east-1.amazonaws.com"
    let API_KEY = "da2-abcd1234"
    
    var authorization: [String: String] {
        ["x-api-key": API_KEY, "host": HTTP_DOMAIN]
    }
    
    func getAuthProtocol() -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: authorization)
        let base64 = jsonData.base64EncodedString()
        let header = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "header-\(header)"
    }
    
    func connect() {
        let url = URL(string: "wss://\(REALTIME_DOMAIN)/event/realtime")!
        var request = URLRequest(url: url)
        request.setValue("aws-appsync-event-ws, \(getAuthProtocol())", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        
        socket = URLSession.shared.webSocketTask(with: request)
        
        socket?.resume()
        
        receiveMessages()
        
        let connectionInit = ["type": "connection_init"]
        sendMessage(connectionInit)
        
    }
    
    func receiveMessages() {
        socket?.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        DispatchQueue.main.async {
                            self.messages.append(text)
                        }
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            DispatchQueue.main.async {
                                self.messages.append(text)
                            }
                        }
                    @unknown default:
                        break
                    }
                case .failure(let error):
                    print("WebSocket receive error: \(error)")
                }
                
             
                self.receiveMessages()
            }
    }
    
    func sendMessage(_ message: [String: Any]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            socket?.send(.string(jsonString)) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                }
            }
        }
    }
    
    func subscribeToChannel(channel: String) {
        let subscribeMessage: [String: Any] = [
            "type": "subscribe",
            "id": UUID().uuidString,
            "channel": channel,
            "authorization": authorization
        ]
        sendMessage(subscribeMessage)
    }
    
    var body: some View {
        VStack {
            Text("AppSync Events")
            
            Button(action: {
                subscribeToChannel(channel: "/default/*")
            }){ Text("Subscribe to default channel")}
                
            List(messages, id: \.self) { message in
                Text(message)
            }
        }
        .onAppear {
            connect()
        }
    }
}
