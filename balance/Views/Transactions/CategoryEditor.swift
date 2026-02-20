import SwiftUI

// MARK: - Add/Edit Category View
struct CategoryEditorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var categories: [Category]
    
    let editingCategory: Category?  // اگه nil باشه → Add، اگه نه → Edit
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "questionmark.circle.fill"
    @State private var selectedColor: Color = .blue
    @State private var showIconPicker = false
    @State private var showColorPicker = false
    
    init(categories: Binding<[Category]>, editingCategory: Category? = nil) {
        self._categories = categories
        self.editingCategory = editingCategory
        
        // اگه داره edit می‌کنه، مقادیر رو پر کن
        if let category = editingCategory {
            _name = State(initialValue: category.name)
            _selectedIcon = State(initialValue: category.icon)
            _selectedColor = State(initialValue: Color(hex: category.colorHex) ?? .blue)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Name
                Section("Category Name") {
                    TextField("e.g. Groceries", text: $name)
                }
                
                // Icon Picker
                Section("Icon") {
                    Button {
                        showIconPicker = true
                    } label: {
                        HStack {
                            Image(systemName: selectedIcon)
                                .font(.system(size: 32))
                                .foregroundColor(selectedColor)
                                .frame(width: 50, height: 50)
                                .background(selectedColor.opacity(0.2))
                                .cornerRadius(10)
                            
                            Text("Choose Icon")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Color Picker
                Section("Color") {
                    ColorPicker("Category Color", selection: $selectedColor, supportsOpacity: false)
                }
                
                // Preview
                Section("Preview") {
                    HStack {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 24))
                            .foregroundColor(selectedColor)
                        
                        Text(name.isEmpty ? "Category Name" : name)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedColor.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .navigationTitle(editingCategory == nil ? "Add Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingCategory == nil ? "Add" : "Save") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon)
            }
        }
    }
    
    private func saveCategory() {
        let category = Category(
            id: editingCategory?.id ?? UUID().uuidString,
            name: name,
            icon: selectedIcon,
            colorHex: selectedColor.toHex()
        )
        
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            // Edit موجود
            categories[index] = category
        } else {
            // Add جدید
            categories.append(category)
        }
        
        dismiss()
    }
}

// MARK: - Icon Picker
struct IconPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedIcon: String
    
    let icons = [
        // Food & Drink
        "cart.fill", "basket.fill", "fork.knife", "cup.and.saucer.fill",
        "wineglass.fill", "takeoutbag.and.cup.and.straw.fill",
        
        // Transportation
        "car.fill", "bus.fill", "tram.fill", "airplane", "bicycle",
        "fuelpump.fill", "parkingsign.circle.fill",
        
        // Home
        "house.fill", "bed.double.fill", "lamp.desk.fill", "lightbulb.fill",
        "shower.fill", "washer.fill", "refrigerator.fill",
        
        // Shopping
        "bag.fill", "gift.fill", "giftcard.fill", "tshirt.fill",
        "shoe.fill", "creditcard.fill",
        
        // Entertainment
        "film.fill", "tv.fill", "gamecontroller.fill", "headphones",
        "music.note", "guitar", "ticket.fill",
        
        // Health & Fitness
        "heart.fill", "cross.case.fill", "pill.fill", "syringe.fill",
        "figure.walk", "dumbbell.fill", "sportscourt.fill",
        
        // Education
        "book.fill", "graduationcap.fill", "pencil", "backpack.fill",
        
        // Finance
        "dollarsign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill",
        "bitcoinsign.circle.fill", "banknote.fill", "chart.line.uptrend.xyaxis",
        
        // Work
        "briefcase.fill", "laptopcomputer", "desktopcomputer", "printer.fill",
        
        // Communication
        "phone.fill", "envelope.fill", "message.fill", "video.fill",
        
        // Other
        "star.fill", "heart.circle.fill", "flag.fill", "calendar",
        "clock.fill", "bell.fill", "globe", "location.fill"
    ]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 32))
                                .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                .frame(width: 60, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Category Model
struct Category: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var icon: String
    var colorHex: String
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}

// MARK: - Preview
#Preview {
    CategoryEditorView(categories: .constant([]))
}
