/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

import SwiftUI
import AVFoundation
import UserNotifications
import DeviceKit

func getKernelVersion() -> String? {
    var unameInfo = utsname()
    uname(&unameInfo)
    
    let release = withUnsafePointer(to: &unameInfo.version) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(cString: $0)
        }
    }
    
    return release
}

@main
struct kfdApp: App {
    @State private var output = ""
    @State private var audioPlayer: AVAudioPlayer?
    
    func printOutput(string: String) {
        print(string)
        output.append(string + "\n")
    }
    
    func setupAudioPlayer(resourceURL: URL?) {
        audioPlayer = try? AVAudioPlayer(contentsOf: resourceURL!)
        audioPlayer?.prepareToPlay()
    }
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("nice")
            } else {
                // Handle authorization denied
            }
        }
    }
    
    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Welcome Back!"
        content.body = "Your app has launched after a device startup."

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false) // Change the timeInterval as needed

        let request = UNNotificationRequest(identifier: "startupNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                // Handle notification scheduling error
            } else {
                // Notification scheduled successfully
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(output: $output).onAppear {
                let device = Device.current
                printOutput(string: "[*] kfdbreak 0.0.1")
                printOutput(string: "[*] model name: \(Device.identifier)")
                printOutput(string: "[*] software version: \(device.systemName ?? "iOS") \(device.systemVersion ?? "16.1.2")")
                printOutput(string: "[*] kernel version: \(getKernelVersion() ?? "unknown")")
                
                printOutput(string: "") // newline:fr:
                
                requestNotificationAuthorization()
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus == .authorized {
                        scheduleNotification()
                    } else {
                        requestNotificationAuthorization()
                    }
                }
                
                /*
                setupAudioPlayer(resourceURL: Bundle.main.url(forResource: "start", withExtension: "mp3"))
                audioPlayer?.play()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    setupAudioPlayer(resourceURL: Bundle.main.url(forResource: "lexapro", withExtension: "mp3"))
                    audioPlayer?.play()
                }
                 */
            }
        }
    }
}
