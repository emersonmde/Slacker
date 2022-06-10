//
//  ContentView.swift
//  Slacker
//
//  Created by Matthew Emerson on 6/7/22.
//

import SwiftUI
import CoreData


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Reminder.trigger, ascending: true)],
        animation: .default)
    private var reminders: FetchedResults<Reminder>
    
    @State
    private var reminderInput: String = ""

    @FocusState
    private var inputIsFocused: Bool
                
    @State
    private var editing = false

    @Environment(\.colorScheme)
    var colorScheme

    var body: some View {
        let isDarkMode = colorScheme == .dark
        NavigationView {
            VStack {
                List {
                    ForEach(reminders) { reminder in
                        Text("\(reminder.text!) at \(reminder.trigger!, formatter: itemFormatter)")
                    }
                    .onDelete(perform: deleteReminders)
                }
                .listStyle(.plain)
                .navigationTitle("Reminders")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        EditButton()
                    }
                }
                Spacer()
                HStack {
                    let focusTextColor = isDarkMode ? Color(UIColor.white) : Color(UIColor.black)
                    let textColor = Color(UIColor.darkGray)
                    Text("Remind me")
                        .foregroundColor(self.editing ? focusTextColor : textColor)
                        .font(.system(.body, design: .monospaced))
                    // TODO: iOS 16 supports axis vertical
                    TextField("[what] [when]", text: $reminderInput, onEditingChanged: { edit in
                        self.editing = edit
                    })
                        .focused($inputIsFocused)
                        .textInputAutocapitalization(.never)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit {
                            if let (what, when) = parseReminderText(reminderInput) {
                                addReminder(what, when)
                                reminderInput = ""
                            }
                        }
                }.padding([.horizontal], 10)

            }
        }
    }
    
    private func parseReminderText(_ text: String) -> (String, Date)? {
        let pattern = "(?<reminderText>.+) in (?<value>\\d+) (?<unit>hour|minute|second)s?$"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        var reminderText: String?
        var value: Int?
        var unit: Calendar.Component?
        if let match = regex?.firstMatch(in: text, range: NSRange(location: 0, length: text.count)) {
            if let reminderTextRange = Range(match.range(withName: "reminderText"), in: text) {
                reminderText = String(text[reminderTextRange])
            }
            
            if let valueRange = Range(match.range(withName: "value"), in: text) {
                value = Int(text[valueRange]) ?? 1
            }
            
            if let unitRange = Range(match.range(withName: "unit"), in: text) {
                let unitString = String(text[unitRange])
                switch unitString {
                case "hour":
                    unit = .hour
                case "minute":
                    unit = .minute
                case "second":
                    unit = .second
                default:
                    unit = .hour
                }
            }
        }
        
        if reminderText != nil && value != nil && unit != nil {
            let when = Calendar.current.date(
                byAdding: unit!,
                value: value!,
                to: Date())
            return (reminderText!, when!)
        }
        
        return nil
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    private func addReminder(_ reminderText: String, _ date: Date) {
        requestNotificationPermissions()
        withAnimation {
            let newReminder = Reminder(context: viewContext)
            newReminder.uuid = UUID()
            newReminder.trigger = date
            newReminder.text = reminderText

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            
            if let notificationText = newReminder.text, let notificationId: String = newReminder.uuid?.uuidString {
                
                let content = UNMutableNotificationContent()
                content.title = "Slacker"
                content.subtitle = notificationText
                content.sound = UNNotificationSound.default

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                // choose a random identifier
                let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

                // add our notification request
                UNUserNotificationCenter.current().add(request)
                
            }
        }
    }

    private func deleteReminders(offsets: IndexSet) {
        let reminderObjects = offsets.map { reminders[$0] }
        let reminderUuids = reminderObjects.compactMap { $0.uuid }
        let reminderUuidStrings = reminderUuids.map { $0.uuidString }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reminderUuidStrings)
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
    }
}
