//
//  RpositoryListView.swift
//  MMEX
//
//  2024-10-11: Created by George Ef (george.a.ef@gmail.com)
//

import SwiftUI

struct RepositoryListView<
    ListType: ListProtocol, GroupType: GroupProtocol, SearchType: SearchProtocol,
    GroupNameView: View, ItemNameView: View, ItemInfoView: View,
    EditView: View
>: View
where GroupType.MainRepository == ListType.MainRepository,
      SearchType.MainData == ListType.MainRepository.RepositoryData
{
    typealias MainRepository = ListType.MainRepository
    typealias MainData = MainRepository.RepositoryData
    typealias GroupChoice = GroupType.GroupChoice

    @State private var alertIsPresented = false
    @State private var alertMessage: String?

    @EnvironmentObject var env: EnvironmentManager
    @ObservedObject var vm: ViewModel
    var features: RepositoryFeatures
    var vmList: ListType
    @State var groupChoice: GroupChoice
    @Binding var vmGroup: GroupType
    @Binding var search: SearchType
    let initData: MainData
    @ViewBuilder var groupNameView: (_ g: Int, _ name: String?) -> GroupNameView
    @ViewBuilder var itemNameView: (_ data: MainData) -> ItemNameView
    @ViewBuilder var itemInfoView: (_ data: MainData) -> ItemInfoView
    @ViewBuilder var editView: (_ data: Binding<MainData>, _ edit: Bool) -> EditView

    @State var newData: MainData? = nil
    @State var deleteData: Bool = false
    @State var createIsPresented = false

    var body: some View {
        return List {
            HStack {
                Menu(content: {
                    Picker("", selection: $groupChoice) {
                        ForEach(GroupChoice.allCases, id: \.self) { choice in
                            Text("\(choice.fullName)")
                                .font(.subheadline)
                                .tag(choice)
                        }
                    }
                    //.scaledToFit()
                    //.labelsHidden()
                    //.pickerStyle(MenuPickerStyle())
                }, label: { (
                    Text("\(groupChoice.rawValue) ") +
                    Text(Image(systemName: "chevron.up.chevron.down"))
                ) } )
                .onChange(of: groupChoice) {
                    vm.unloadGroup(vmGroup)
                    vm.loadGroup(vmGroup, choice: groupChoice)
                    vm.searchGroup(vmGroup, search: search)
                }
                .padding(.vertical, -5)
                //.padding(.trailing, 50)
                //.border(.red)

                // dummy button in order to force some spacing
                Button(action: {}){
                    Text("").frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderlessButtonStyle())
                //.border(.red)

                if features.canSearch {
                    HStack {
                        NavigationLink(
                            destination: RepositorySearchAreaView(area: $search.area)
                        ) {
                            Text("Search area")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            //.border(.red)
                        }
                        //.border(.red)
                    }
                }
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
            //.border(.red)

            switch vmGroup.state {
            case .ready:
                ForEach(0 ..< vmGroup.value.count, id: \.self) { g in
                    if vmGroup.value[g].isVisible {
                        groupView(g)
                    }
                }
            case .loading:
                HStack {
                    Text("Loading data ...")
                    ProgressView()
                }
            case .error:
                HStack {
                    Text("Load error ...")
                    ProgressView()
                }.tint(.red)
            case .idle:
                Button(action: { Task {
                    await load()
                } } ) {
                    HStack {
                        Text("Load data")
                    }
                }
                .listRowBackground(Color.clear)
                .padding()
                //.background(.secondary)
                .foregroundColor(.secondary)
            }
        }
        //.listStyle(.plain)
        .listSectionSpacing(.compact)
        //.border(.red)
        .toolbar {
            if features.canCreate {
                Button(
                    action: { createIsPresented = true },
                    label: { Image(systemName: "plus") }
                )
                .accessibilityLabel("New " + MainData.dataName.0)
            }
        }
        //.modifier(RepositorySearchModifier(
        //    canSearch: features.canSearch, text: $search.key, prompt: search.prompt
        //) )
        .searchable(text: $search.key, prompt: search.prompt)
        .textInputAutocapitalization(.never)
        .onChange(of: search.key) { _, newValue in
            vm.searchGroup(vmGroup, search: search, expand: true)
        }
        .navigationTitle(MainData.dataName.1)
        .onAppear {
            if deleteData || newData != nil { return }
            log.debug("DEBUG: RepositoryListView.onAppear()")
            groupChoice = vmGroup.choice
            Task { await load() }
        }
        .refreshable {
            if deleteData || newData != nil { return }
            log.debug("DEBUG: RepositoryListView.refreshable()")
            vm.unloadGroup(vmGroup)
            vm.unloadList(vmList)
            await load()
        }
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage!),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $createIsPresented) {
            RepositoryCreateView(
                vm: vm,
                features: features,
                data: initData,
                newData: $newData,
                isPresented: $createIsPresented,
                editView: editView
            )
            .onDisappear {
                guard newData != nil else { return }
                log.debug("DEBUG: RepositoryListView.RepositoryCreateView.onDisappear()")
                Task {
                    await vm.reloadList(nil as MainData?, newData)
                    vm.searchGroup(vmGroup, search: search)
                    newData = nil
                }
            }
        }
    }

    private func load() async {
        log.trace("DEBUG: RepositoryListView.load(main=\(Thread.isMainThread))")
        await vm.loadList(vmList)
        vm.loadGroup(vmGroup, choice: groupChoice)
        vm.searchGroup(vmGroup, search: search)
    }

    func groupView(_ g: Int) -> some View { Group { if vmGroup.state == .ready {
        Section(header: Group {
            if !GroupChoice.isSingleton.contains(vmGroup.choice) {
                HStack {
                    Button(
                        action: { vmGroup.value[g].isExpanded.toggle() }
                    ) {
                        env.theme.group.view(
                            nameView: { groupNameView(g, vmGroup.value[g].name) },
                            count: vmGroup.value[g].dataId.count,
                            isExpanded: vmGroup.value[g].isExpanded
                        )
                    }
                }
            }
        }//.padding(.top, -10)
        ) {
            if vmGroup.value[g].isExpanded {
                switch vmList.data.state {
                case .ready:
                    ForEach(vmGroup.value[g].dataId, id: \.self) { id in
                        if let data = vmList.data.value[id], search.match(vm, data) {
                            itemView(data)
                        }
                        
                    }
                case .loading:
                    HStack {
                        Text("Loading data ...")
                        ProgressView()
                    }
                case .error:
                    HStack {
                        Text("Load error ...")
                        ProgressView()
                    }.tint(.red)
                case .idle:
                    Button(action: { Task {
                        await load()
                    } } ) {
                        HStack {
                            Text("Load data")
                        }
                    }
                    .listRowBackground(Color.clear)
                    .padding()
                    //.background(.secondary)
                    .foregroundColor(.secondary)
                }
            }
        }
    } } }

    @ViewBuilder
    func itemView(_ data: MainData) -> some View {
        NavigationLink(
            destination: RepositoryReadView(
                vm: vm,
                features: features,
                data: data,
                newData: $newData,
                deleteData: $deleteData,
                editView: editView
            )
            //.onAppear {
            //    newData = nil
            //    deleteData = false
            //}
                .onDisappear {
                    guard deleteData || newData != nil else { return }
                    log.debug("DEBUG: RepositoryListView.RepositoryReadView.onDisappear")
                    Task {
                        await vm.reloadList(data, newData)
                        vm.searchGroup(vmGroup, search: search)
                        newData = nil
                        deleteData = false
                    }
                }
        ) {
            env.theme.item.view(
                nameView: { itemNameView(data) },
                infoView: { itemInfoView(data) }
            )
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if features.canDelete { Button {
                let deleteError = vm.delete(data)
                if deleteError != nil {
                    alertMessage = deleteError
                    alertIsPresented = true
                } else {
                    Task {
                        await vm.reloadList(data, nil)
                        vm.searchGroup(vmGroup, search: search)
                    }
                }
            } label: {
                Label("Delete", systemImage: vm.isUsed(data) == false ? "trash.fill" : "trash.slash.fill")
            }.tint(vm.isUsed(data) == false ? .red : .gray) }

            if features.canCopy { Button {
                // TODO
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }.tint(.indigo) }
        }
    }
}

struct RepositorySearchModifier: ViewModifier {
    let canSearch: Bool
    @Binding var text: String
    var prompt: String

    // problem: double copy of content
    // problem: if canSearch == false, an empty area is shown in place of search
    func body(content: Content) -> some View {
        if canSearch {
            content
                .searchable(text: $text, prompt: prompt)
                .textInputAutocapitalization(.never)
        } else {
            content
        }
    }
}

struct RepositorySearchAreaView<RepositoryData: DataProtocol>: View {
    @Binding var area: [SearchArea<RepositoryData>]

    var body: some View {
        List{
            Section(header: Text("Search area")) {
                ForEach(0 ..< area.count, id: \.self) { i in
                    Button(action: {
                        area[i].isSelected.toggle()
                        if area.first(where: { $0.isSelected }) == nil { area[0].isSelected = true }
                    } ) {
                        HStack {
                            Text(area[i].name)
                            Spacer()
                            if area[i].isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview("Account") {
    let env = EnvironmentManager.sampleData
    AccountListView(
        vm: ViewModel(env: env)
    )
    .environmentObject(env)
}