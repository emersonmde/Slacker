//
//  ContentView.swift
//  Slacker
//
//  Created by Matthew Emerson on 6/7/22.
//

import SwiftUI
import CoreData

struct MyTextFieldStyle: TextFieldStyle {
    @Binding var focused: Bool
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(focused ? .white : .gray)
//        .padding(10)
//        .background(
//            RoundedRectangle(cornerRadius: 10, style: .continuous)
//                .stroke(focused ? Color.red : Color.gray, lineWidth: 3)
//        ).padding()
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Reminder.trigger, ascending: true)],
        animation: .default)
    private var reminders: FetchedResults<Reminder>
    
    @State
    private var input: String = "Remind me to [what] [when]"

    @FocusState
    private var inputIsFocused: Bool
                
    @State private var editing = false

    
    
    class ViewModel: ObservableObject {
        @Published var input = "Remind me to " {
            didSet {
                if input.prefix(13) != "Remind me to " {
                    input = "Remind me to " + input
                }
            }
        }
    }

    @ObservedObject var viewModel = ViewModel()


    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(reminders) { reminder in
                        NavigationLink {
                            Text("Reminder at \(reminder.trigger!, formatter: itemFormatter)")
                        } label: {
                            Text("\(reminder.text!) \(reminder.trigger!, formatter: itemFormatter)")
                        }

                    }
                    .onDelete(perform: deleteReminders)
                }
                .listStyle(.plain)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addReminder) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                Spacer()
                TextField("Remind me to [what] [when]", text: $viewModel.input, onEditingChanged: { edit in
                    self.editing = edit
                })
                    .focused($inputIsFocused)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(MyTextFieldStyle(focused: $editing))
                    .font(.system(.body, design: .monospaced))

            }
        }
    }

    private func addReminder() {
        withAnimation {
            let newItem = Reminder(context: viewContext)
            newItem.trigger = Date()
            newItem.text = "reminder"

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteReminders(offsets: IndexSet) {
        withAnimation {
            offsets.map { reminders[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
