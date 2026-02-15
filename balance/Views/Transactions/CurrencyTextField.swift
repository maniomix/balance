import SwiftUI

// MARK: - Currency TextField with Live Formatting
struct CurrencyTextField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState.Binding var isFocused: Bool
    
    @State private var internalText: String = ""
    @State private var textWidth: CGFloat = 0
    
    private var currencySymbol: String {
        DS.Format.currencySymbol()
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Hidden text to measure width
            Text(internalText)
                .font(DS.Typography.number)
                .opacity(0)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            textWidth = geo.size.width
                        }
                        .onChange(of: internalText) { _, _ in
                            textWidth = geo.size.width
                        }
                    }
                )
            
            HStack(spacing: 0) {
                TextField("", text: $internalText)
                    .keyboardType(.decimalPad)
                    .font(DS.Typography.number)
                    .foregroundColor(.clear) // Hide the actual text
                    .focused($isFocused)
                    .onChange(of: internalText) { oldValue, newValue in
                        updateText(newValue)
                    }
                    .onChange(of: text) { oldValue, newValue in
                        if newValue.isEmpty && !internalText.isEmpty {
                            internalText = ""
                        }
                    }
                    .onAppear {
                        if !text.isEmpty {
                            internalText = formatForDisplay(text)
                        }
                    }
                
                Spacer()
            }
            .overlay(
                HStack(spacing: 4) {
                    // Show the formatted text
                    Text(internalText.isEmpty ? placeholder : internalText)
                        .font(DS.Typography.number)
                        .foregroundColor(internalText.isEmpty ? DS.Colors.subtext : DS.Colors.text)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: internalText)
                    
                    // Currency symbol next to text
                    if !internalText.isEmpty {
                        Text(currencySymbol)
                            .font(DS.Typography.number)
                            .foregroundColor(DS.Colors.text.opacity(0.6))
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                .padding(.leading, 12)
                .allowsHitTesting(false)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: internalText.isEmpty)
            )
        }
        .frame(height: 44)
        .padding(.horizontal, 12)
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isFocused ? DS.Colors.accent : DS.Colors.grid, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private func updateText(_ newValue: String) {
        let withoutSeparators = newValue.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        let cleaned = cleanInput(withoutSeparators)
        
        // Animate the change
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            text = cleaned
        }
        
        let formatted = formatForDisplay(cleaned)
        if formatted != internalText {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                internalText = formatted
            }
        }
    }
    
    private func cleanInput(_ input: String) -> String {
        var result = ""
        var hasDecimal = false
        
        for char in input {
            if char.isNumber {
                result.append(char)
            } else if char == "." && !hasDecimal {
                result.append(".")
                hasDecimal = true
            }
        }
        
        return result
    }
    
    private func formatForDisplay(_ input: String) -> String {
        guard !input.isEmpty else { return "" }
        
        let parts = input.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integerPart = String(parts.first ?? "")
        
        let formattedInteger = addThousandsSeparator(integerPart)
        
        if parts.count > 1 {
            var decimalPart = String(parts[1])
            if decimalPart.count > 2 {
                decimalPart = String(decimalPart.prefix(2))
            }
            return formattedInteger + "," + decimalPart
        }
        
        return formattedInteger
    }
    
    private func addThousandsSeparator(_ number: String) -> String {
        guard !number.isEmpty else { return "" }
        
        let clean = number
        guard !clean.isEmpty else { return "" }
        
        let reversed = String(clean.reversed())
        var result = ""
        
        for (index, char) in reversed.enumerated() {
            if index > 0 && index % 3 == 0 {
                result.append(".")
            }
            result.append(char)
        }
        
        return String(result.reversed())
    }
}

// MARK: - Compact Currency TextField (for Category Budgets)
struct CompactCurrencyTextField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    
    @State private var internalText: String = ""
    
    private var currencySymbol: String {
        DS.Format.currencySymbol()
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            TextField("", text: $internalText)
                .keyboardType(.decimalPad)
                .font(DS.Typography.number)
                .foregroundColor(.clear)
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
                .onChange(of: internalText) { oldValue, newValue in
                    updateText(newValue)
                }
                .onChange(of: text) { oldValue, newValue in
                    if newValue.isEmpty && !internalText.isEmpty {
                        internalText = ""
                    }
                }
                .onAppear {
                    if !text.isEmpty {
                        internalText = formatForDisplay(text)
                    }
                }
            
            HStack(spacing: 4) {
                Spacer()
                
                Text(internalText.isEmpty ? "0" : internalText)
                    .font(DS.Typography.number)
                    .foregroundColor(internalText.isEmpty ? DS.Colors.subtext : DS.Colors.text)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: internalText)
                
                if !internalText.isEmpty {
                    Text(currencySymbol)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.Colors.text.opacity(0.5))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .allowsHitTesting(false)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: internalText.isEmpty)
        }
        .padding(10)
        .frame(width: 120)
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
    }
    
    private func updateText(_ newValue: String) {
        let withoutSeparators = newValue.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        let cleaned = cleanInput(withoutSeparators)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            text = cleaned
        }
        
        let formatted = formatForDisplay(cleaned)
        if formatted != internalText {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                internalText = formatted
            }
        }
    }
    
    private func cleanInput(_ input: String) -> String {
        var result = ""
        var hasDecimal = false
        
        for char in input {
            if char.isNumber {
                result.append(char)
            } else if char == "." && !hasDecimal {
                result.append(".")
                hasDecimal = true
            }
        }
        
        return result
    }
    
    private func formatForDisplay(_ input: String) -> String {
        guard !input.isEmpty else { return "" }
        
        let parts = input.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integerPart = String(parts.first ?? "")
        
        let formattedInteger = addThousandsSeparator(integerPart)
        
        if parts.count > 1 {
            var decimalPart = String(parts[1])
            if decimalPart.count > 2 {
                decimalPart = String(decimalPart.prefix(2))
            }
            return formattedInteger + "," + decimalPart
        }
        
        return formattedInteger
    }
    
    private func addThousandsSeparator(_ number: String) -> String {
        guard !number.isEmpty else { return "" }
        
        let clean = number
        guard !clean.isEmpty else { return "" }
        
        let reversed = String(clean.reversed())
        var result = ""
        
        for (index, char) in reversed.enumerated() {
            if index > 0 && index % 3 == 0 {
                result.append(".")
            }
            result.append(char)
        }
        
        return String(result.reversed())
    }
}
