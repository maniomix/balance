import SwiftUI
import Combine
import Charts
import UIKit
import UserNotifications
import ZIPFoundation
import UniformTypeIdentifiers
import CryptoKit
import FirebaseAuth



// MARK: - Localization

// MARK: - Localization

enum L10n {
    static var current: String {
        UserDefaults.standard.string(forKey: "app.language") ?? "en"
    }
    
    static func t(_ key: String) -> String {
        translations[current]?[key] ?? translations["en"]?[key] ?? key
    }
    
    private static let translations: [String: [String: String]] = [
        "en": [
            // Tabs
            "tab.dashboard": "Dashboard",
            "tab.transactions": "Transactions",
            "tab.budget": "Budget",
            "tab.insights": "Insights",
            "tab.settings": "Settings",
            
            // Dashboard
            "dashboard.title": "Balance",
            "dashboard.data_for_month": "Data For this Month",
            "dashboard.start_from_zero": "Start from zero",
            "dashboard.set_budget_first": "Set your monthly budget first. Analysis will start immediately.",
            "dashboard.daily_trend": "Daily spending trend",
            "dashboard.no_trend_data": "No trend data yet. Add a few transactions.",
            "dashboard.category_breakdown": "Category breakdown",
            "dashboard.payment_breakdown": "Payment breakdown",
            "dashboard.cash_vs_card": "Cash vs Card",
            "dashboard.no_payment_data": "No payment data yet. Add transactions to see breakdown.",
            "dashboard.payment_insight_cash_heavy": "You047re using mostly cash. Consider tracking card expenses too.",
            "dashboard.payment_insight_card_heavy": "Most expenses are on card. Good for tracking!",
            "dashboard.payment_insight_balanced": "Nice balance between cash and card payments.",
            "dashboard.category_breakdown_empty": "Once you add transactions, category totals will appear here.",
            "dashboard.advisor_insights": "Advisor insights",
            "dashboard.honest_no_blame": "Honest, no blame",
            "dashboard.add_expenses": "Add a few everyday expenses for a more accurate assessment.",
            "dashboard.quick_actions": "Quick recommended actions",
            "dashboard.no_action_needed": "No urgent action needed. Stay consistent.",
            "dashboard.step1_title": "Step 1: Set your monthly budget",
            "dashboard.step1_desc": "Without a budget, the numbers have no target. Set a realistic budget—then we take control step by step.",
            "dashboard.go_to_budget": "Go to Budget",
            "dashboard.delete_month": "Delete Month Data",
            "dashboard.delete_month_msg": "This will permanently delete all transactions and data for this month. This action cannot be undone.",
            "dashboard.delete_confirm": "Delete",
            "dashboard.month_cleared": "This month has already been cleared. There is nothing left to delete.",
            "dashboard.month_deleted": "This month's data has been successfully deleted",
            "dashboard.this_month": "This month",
            
            // Month Picker
            "month.this_month": "This month",
            
            // Budget Status
            "status.stable": "status.stable",
            "status.stable_desc": "Spending is under control. Keep the pattern.",
            "status.needs_attention": "status.needs_attention",
            "status.needs_attention_desc": "You're approaching the budget limit. Review discretionary spending.",
            "status.budget_pressure": "status.budget_pressure",
            "status.budget_pressure_desc": "Spending is very high. Reduce non‑essential costs.",
            "status.analysis_paused": "Analysis paused",
            "status.analysis_paused_desc": "Dashboard and insights unlock after you set a budget.",
            "status.budget_set": "Budget set",
            "status.budget_set_desc": "You can now add transactions and get real analysis.",
            
            // KPIs
            "kpi.spent": "Spent",
            "kpi.remaining": "Remaining",
            "kpi.daily_avg": "Daily avg",
            
            // Budget
            "budget.title": "Budget",
            "budget.set_monthly": "Set a monthly budget",
            "budget.keep_realistic": "Keep it realistic. You can adjust it anytime.",
            "budget.start": "Start",
            "budget.update": "Update",
            "budget.this_month": "This month",
            "budget.budget_used": "Budget used",
            "budget.used_percent": "used",
            "budget.spent": "Spent",
            "budget.remaining": "Remaining",
            "budget.month_not_complete": "Month not complete yet",
            "budget.on_track": "On track",
            "budget.over_budget": "Over budget",
            "budget.saved_vs_prev": "Saved vs previous month",
            "budget.total_saved": "Total saved (past months)",
            "budget.category_budgets": "Category budgets",
            "budget.category_caps_desc": "Optional: set caps per category. Leave empty for no cap.",
            "budget.allocated": "Allocated",
            "budget.unallocated": "Unallocated",
            "budget.caps_exceed": "Category caps exceed total budget",
            "budget.caps_exceed_desc": "Reduce one or more category budgets so allocation stays within the monthly total.",
            
            // Transactions
            "transactions.title": "Transactions",
            "transactions.set_budget_btn": "Set budget",
            "transactions.no_transactions": "No transactions this month.",
            "transactions.start_simple": "Start with a simple expense. Consistency beats perfection.",
            "transactions.select": "Select",
            "transactions.select_all": "Select All",
            "transactions.delete": "Delete",
            "transactions.cancel": "Cancel",
            "transactions.search_placeholder": "Search category / note",
            "transactions.delete_confirm": "transactions.delete_confirm",
            "transactions.delete_multiple": "Delete %d transactions?",
            "transactions.cannot_undo": "transactions.cannot_undo",
            "transactions.deleted": "%d transaction deleted",
            "transactions.undo": "Undo",
            "transactions.view_attachment": "View attachment",
            "transactions.edit": "Edit",
            
            // Add/Edit Transaction
            "transaction.add": "Add expense",
            "transaction.edit": "Edit expense",
            "transaction.amount": "Amount",
            "transaction.amount_placeholder": "e.g. 250.00",
            "transaction.category": "Category",
            "transaction.add_category": "Add",
            "transaction.new_category": "New Category",
            "transaction.new_category_msg": "Enter a name for your custom category",
            "transaction.new_category_placeholder": "e.g. Coffee",
            "transaction.date": "Date",
            "transaction.note": "Note (optional)",
            "transaction.note_placeholder": "e.g. groceries",
            "transaction.attachment": "Attachment (optional)",
            "transaction.add_attachment": "Add image or file",
            "transaction.attach_photo": "Take Photo",
            "transaction.attach_file": "Choose File",
            "transaction.save": "Save",
            "transaction.save_changes": "Save changes",
            "transaction.close": "Close",
            "transaction.advisor_note": "Advisor note: accurate tracking is the fastest path to control.",
            "transaction.payment_method": "Payment Method",
            
            // Filters
            "filters.title": "Filters",
            "filters.categories": "Categories",
            "filters.all": "All",
            "filters.clear": "Clear",
            "filters.tip_one_category": "Tip: select at least one category.",
            "filters.date_range": "Date range",
            "filters.from": "From",
            "filters.to": "To",
            "filters.date_range_off": "Off — showing all dates in the selected month.",
            "filters.amount_range": "Amount range",
            "filters.min": "Min (€)",
            "filters.max": "Max (€)",
            "filters.amount_example": "Amounts are in EUR. Example: 12.50",
            "filters.reset": "Reset",
            "filters.apply": "Apply",
            "filters.close": "Close",
            
            // Import
            "import.title": "Import",
            "import.from_csv": "Import transactions from CSV",
            "import.csv_columns": "Recommended CSV columns (header row preferred):",
            "import.csv_format": "date (required), amount (required, EUR), category (required), note (optional)",
            "import.duplicate_note": "Note: If you import the same CSV again, Balance will only add transactions that aren't already in the app (duplicates are skipped).",
            "import.choose_file": "Choose CSV file",
            "import.xlsx_tip": "Tip: If your file is .xlsx, export it as CSV in Excel, then import here.",
            "import.columns": "Columns",
            "import.header_row": "Header row",
            "import.preview": "Preview",
            "import.import_btn": "Import into Balance",
            "import.mode_title": "Import Mode",
            "import.mode_message": "You have %d existing transaction(s). Do you want to keep them and add the imported data (Merge), or delete them and keep only the imported data (Replace)?",
            "import.mode_merge": "Merge",
            "import.mode_replace": "Replace",
            "import.done": "Done",
            
            // Insights
            "insights.title": "Insights",
            "insights.not_ready": "Insights are not ready",
            "insights.set_budget_first": "Set your monthly budget first to unlock analysis.",
            "insights.analytical_report": "Analytical report",
            "insights.trend_pressure": "This trend will pressure your budget",
            "insights.trend_pressure_desc": "End-of-month projection is above budget. Prioritize cutting discretionary costs.",
            "insights.approaching_limit": "Approaching the limit",
            "insights.approaching_limit_desc": "To stay in control, trim one discretionary category slightly.",
            "insights.projection_note": "Projection uses a robust daily average (reduces the impact of one unusual day). New transactions refine the estimate.",
            "insights.insights_title": "Insights",
            "insights.no_data": "Not enough data yet. Add a few transactions.",
            "insights.notifications": "Notifications",
            "insights.notifications_desc": "Get reminders to review your budget and spending.",
            "insights.notification_status": "Notification status",
            "insights.send_test": "Send test notification",
            "insights.test_tip": "Tip: turn notifications on, then tap the test button.",
            "insights.export": "Export",
            "insights.export_share": "Share",
            "insights.export_desc": "Export your month as Excel, CSV, or PDF report.",
            "insights.export_excel": "Excel",
            "insights.export_csv": "CSV",
            "insights.export_pdf": "PDF Report",
            "insights.export_tip": "Tip: Excel export includes multiple sheets (Summary, Transactions, Categories, Daily).",
            "insights.ai_analysis": "AI analysis",
            "insights.ai_powered": "Powered by cloud",
            "insights.ai_desc": "Get a smarter explanation of what drove your spending and what to do next.",
            "insights.ai_analyze": "Analyze this month",
            
            // AI Insights
            "ai.title": "AI insights",
            "ai.close": "Close",
            "ai.tip": "Tip: AI-generated insights based on your spending data. Results may be imperfect — use as guidance.",
            "ai.analyzing": "Analyzing…",
            "ai.run_analysis": "Run analysis",
            "ai.reanalyze": "Re-analyze",
            "ai.last_analyzed": "Last analyzed: %@",
            "ai.summary": "Summary",
            "ai.insights": "Insights",
            "ai.actions": "Recommended actions",
            "ai.risk": "Risk",
            "ai.risk_level": "Risk level",
            "ai.error": "Couldn't analyze",
            
            // Settings
            "settings.title": "Settings",
            "settings.legal": "Legal & Support",
            "settings.support_email": "Support Email",
            "settings.report_bug": "Report Bug",
            "settings.licenses": "Licenses",
            "settings.app_settings": "App Settings",
            "settings.currency": "Currency",
            "settings.language": "Language",
            "settings.language_note": "Note: Language change will take effect immediately.",
            "settings.developer": "Developer",
            "settings.developed_by": "Developed by",
            "settings.version": "Version",
            "settings.build": "Build",
            "settings.about": "About Balance",
            "settings.about_desc": "Balance is a personal finance app designed to help you control your spending, step by step. Track expenses, set budgets, and gain insights into your financial habits.",
            "settings.feature_privacy": "Privacy first - all data stored locally",
            "settings.feature_insights": "Smart insights and projections",
            "settings.feature_ai": "AI-powered analysis",
            "settings.feature_import": "Import & export transactions",
            
            // Categories
            "category.groceries": "Groceries",
            "category.rent": "Rent",
            "category.bills": "Bills",
            "category.transport": "Transport",
            "category.health": "Health",
            "category.education": "Education",
            "category.dining": "Dining",
            "category.shopping": "Shopping",
            "category.entertainment": "Entertainment",
            "category.other": "Other",
            
            // Payment Methods
            "payment.cash": "Cash",
            "payment.card": "Card",
            
            // Common
            "common.ok": "OK",
            "common.done": "Done",
            "common.yes": "Yes",
            "common.no": "No",
            "common.close": "Close",
            "common.cancel": "Cancel",
            "common.delete": "Delete",
            "common.save": "Save",
            "common.edit": "Edit",
            "common.add": "Add",
            "common.trash": "Trash",
            
            // Recurring Transactions
            "recurring.title": "Recurring Transactions",
            "recurring.empty": "No recurring transactions yet",
            "recurring.empty_desc": "Add recurring transactions like salary, rent, or subscriptions",
            "recurring.add": "Add Recurring",
            "recurring.edit": "Edit Recurring",
            "recurring.daily": "Daily",
            "recurring.weekly": "Weekly",
            "recurring.monthly": "Monthly",
            "recurring.yearly": "Yearly",
            "recurring.frequency": "Frequency",
            "recurring.start_date": "Start Date",
            "recurring.end_date": "End Date (Optional)",
            "recurring.next_occurrence": "Next",
            "recurring.active": "Active",
            "recurring.inactive": "Inactive",
            "recurring.auto_generated": "Auto-generated",
            
            // Goals
            "goals.title": "Goals & Savings",
            "goals.empty": "No goals yet",
            "goals.empty_desc": "Set goals to track your savings progress",
            "goals.add": "Add Goal",
            "goals.edit": "Edit Goal",
            "goals.name": "Goal Name",
            "goals.target": "Target Amount",
            "goals.current": "Current Amount",
            "goals.deadline": "Deadline (Optional)",
            "goals.category": "Category",
            "goals.emoji": "Emoji",
            "goals.color": "Color",
            "goals.progress": "Progress",
            "goals.remaining": "Remaining",
            "goals.completed": "Completed",
            "goals.overdue": "Overdue",
            "goals.days_left": "days left",
            "goals.add_funds": "Add Funds",
            "goal.savings": "Savings",
            "goal.purchase": "Purchase",
            "goal.travel": "Travel",
            "goal.education": "Education",
            "goal.emergency": "Emergency Fund",
            "goal.other": "Other",
            
            // Charts
            "charts.title": "Advanced Charts",
            "charts.spending_trend": "Spending Trend",
            "charts.category_pie": "Category Distribution",
            "charts.income_expense": "Income vs Expense",
            "charts.monthly_comparison": "Monthly Comparison",
            "charts.last_3_months": "Last 3 Months",
            "charts.last_6_months": "Last 6 Months",
            "charts.this_year": "This Year",
            "charts.average": "Average",
        ],
        
        "de": [
            // Tabs
            "tab.dashboard": "Übersicht",
            "tab.transactions": "Transaktionen",
            "tab.budget": "Budget",
            "tab.insights": "Einblicke",
            "tab.settings": "Einstellungen",
            
            // Dashboard
            "dashboard.title": "Balance",
            "dashboard.data_for_month": "Daten für diesen Monat",
            "dashboard.start_from_zero": "Bei Null beginnen",
            "dashboard.set_budget_first": "Legen Sie zuerst Ihr monatliches Budget fest. Die Analyse beginnt sofort.",
            "dashboard.daily_trend": "Täglicher Ausgabentrend",
            "dashboard.no_trend_data": "Noch keine Trenddaten. Fügen Sie ein paar Transaktionen hinzu.",
            "dashboard.category_breakdown": "Kategorienaufschlüsselung",
            "dashboard.payment_breakdown": "Zahlungsaufschlüsselung",
            "dashboard.cash_vs_card": "Bargeld vs. Karte",
            "dashboard.no_payment_data": "Noch keine Zahlungsdaten. Fügen Sie Transaktionen hinzu, um die Aufschlüsselung zu sehen.",
            "dashboard.payment_insight_cash_heavy": "Sie verwenden hauptsächlich Bargeld. Erwägen Sie, auch Kartenausgaben zu verfolgen.",
            "dashboard.payment_insight_card_heavy": "Die meisten Ausgaben erfolgen per Karte. Gut zum Verfolgen!",
            "dashboard.payment_insight_balanced": "Schönes Gleichgewicht zwischen Bar- und Kartenzahlungen.",
            "dashboard.category_breakdown_empty": "Sobald Sie Transaktionen hinzufügen, werden hier Kategoriensummen angezeigt.",
            "dashboard.advisor_insights": "Berater-Einblicke",
            "dashboard.honest_no_blame": "Ehrlich, ohne Vorwürfe",
            "dashboard.add_expenses": "Fügen Sie ein paar alltägliche Ausgaben für eine genauere Bewertung hinzu.",
            "dashboard.quick_actions": "Schnelle empfohlene Aktionen",
            "dashboard.no_action_needed": "Keine dringende Aktion erforderlich. Bleiben Sie konsequent.",
            "dashboard.step1_title": "Schritt 1: Legen Sie Ihr monatliches Budget fest",
            "dashboard.step1_desc": "Ohne Budget haben die Zahlen kein Ziel. Legen Sie ein realistisches Budget fest – dann übernehmen wir Schritt für Schritt die Kontrolle.",
            "dashboard.go_to_budget": "Zum Budget gehen",
            "dashboard.delete_month": "Daten dieses Monats löschen?",
            "dashboard.delete_month_msg": "Alle Transaktionen, das monatliche Budget und die Kategorienlimits für diesen Monat werden dauerhaft gelöscht.",
            "dashboard.delete_confirm": "Löschen",
            "dashboard.month_cleared": "Dieser Monat wurde bereits gelöscht. Es gibt nichts mehr zu löschen.",
            "dashboard.month_deleted": "Die Daten dieses Monats wurden erfolgreich gelöscht",
            "dashboard.this_month": "Dieser Monat",
            
            // Month Picker
            "month.this_month": "Dieser Monat",
            
            // Budget Status
            "status.stable": "Stabil",
            "status.stable_desc": "Die Ausgaben sind unter Kontrolle. Behalten Sie das Muster bei.",
            "status.needs_attention": "Erfordert Aufmerksamkeit",
            "status.needs_attention_desc": "Sie nähern sich dem Budgetlimit. Überprüfen Sie diskretionäre Ausgaben.",
            "status.budget_pressure": "Budgetdruck",
            "status.budget_pressure_desc": "Die Ausgaben sind sehr hoch. Reduzieren Sie nicht-essentielle Kosten.",
            "status.analysis_paused": "Analyse pausiert",
            "status.analysis_paused_desc": "Dashboard und Einblicke werden freigeschaltet, nachdem Sie ein Budget festgelegt haben.",
            "status.budget_set": "Budget festgelegt",
            "status.budget_set_desc": "Sie können jetzt Transaktionen hinzufügen und echte Analysen erhalten.",
            
            // KPIs
            "kpi.spent": "Ausgegeben",
            "kpi.remaining": "Verbleibend",
            "kpi.daily_avg": "Tagesd. Ø",
            
            // Budget
            "budget.title": "Budget",
            "budget.set_monthly": "Monatliches Budget festlegen",
            "budget.keep_realistic": "Bleiben Sie realistisch. Sie können es jederzeit anpassen.",
            "budget.start": "Start",
            "budget.update": "Aktualisieren",
            "budget.this_month": "Dieser Monat",
            "budget.budget_used": "Budget verwendet",
            "budget.used_percent": "verwendet",
            "budget.spent": "Ausgegeben",
            "budget.remaining": "Verbleibend",
            "budget.month_not_complete": "Monat noch nicht abgeschlossen",
            "budget.on_track": "Auf Kurs",
            "budget.over_budget": "Über Budget",
            "budget.saved_vs_prev": "Gespart ggü. Vormonat",
            "budget.total_saved": "Gesamt gespart (vergangene Monate)",
            "budget.category_budgets": "Kategorienbudgets",
            "budget.category_caps_desc": "Optional: Legen Sie Obergrenzen pro Kategorie fest. Leer lassen für keine Obergrenze.",
            "budget.allocated": "Zugewiesen",
            "budget.unallocated": "Nicht zugewiesen",
            "budget.caps_exceed": "Kategoriengrenzen überschreiten Gesamtbudget",
            "budget.caps_exceed_desc": "Reduzieren Sie ein oder mehrere Kategorienbudgets, damit die Zuteilung innerhalb der monatlichen Summe bleibt.",
            
            // Transactions
            "transactions.title": "Transaktionen",
            "transactions.start_simple": "Beginnen Sie mit einer einfachen Ausgabe. Beständigkeit schlägt Perfektion.",
            "transactions.select": "Auswählen",
            "transactions.select_all": "Alle auswählen",
            "transactions.delete": "Löschen",
            "transactions.cancel": "Abbrechen",
            "transactions.search_placeholder": "Kategorie / Notiz suchen",
            "transactions.delete_confirm": "Transaktion löschen?",
            "transactions.delete_multiple": "%d Transaktionen löschen?",
            "transactions.cannot_undo": "Diese Aktion kann nicht rückgängig gemacht werden.",
            "transactions.deleted": "%d Transaktion gelöscht",
            "transactions.undo": "Rückgängig",
            "transactions.view_attachment": "Anhang ansehen",
            "transactions.edit": "Bearbeiten",
            
            // Add/Edit Transaction
            "transaction.add": "Ausgabe hinzufügen",
            "transaction.edit": "Ausgabe bearbeiten",
            "transaction.amount": "Betrag",
            "transaction.amount_placeholder": "z.B. 250.00",
            "transaction.category": "Kategorie",
            "transaction.add_category": "Hinzufügen",
            "transaction.new_category": "Neue Kategorie",
            "transaction.new_category_msg": "Erstellen Sie eine benutzerdefinierte Kategorie für Ihre Transaktionen.",
            "transaction.new_category_placeholder": "z.B. Kaffee",
            "transaction.date": "Datum",
            "transaction.note": "Notiz (optional)",
            "transaction.note_placeholder": "z.B. Lebensmittel",
            "transaction.attachment": "Anhang (optional)",
            "transaction.add_attachment": "Bild oder Datei hinzufügen",
            "transaction.attach_photo": "Fotobibliothek",
            "transaction.attach_file": "Dateien",
            "transaction.save": "Speichern",
            "transaction.save_changes": "Änderungen speichern",
            "transaction.close": "Schließen",
            "transaction.advisor_note": "Beraterhinweis: Genaue Verfolgung ist der schnellste Weg zur Kontrolle.",
            "transaction.payment_method": "Zahlungsmethode",
            
            // Filters
            "filters.title": "Filter",
            "filters.categories": "Kategorien",
            "filters.all": "Alle",
            "filters.clear": "Löschen",
            "filters.tip_one_category": "Tipp: Wählen Sie mindestens eine Kategorie aus.",
            "filters.date_range": "Datumsbereich",
            "filters.from": "Von",
            "filters.to": "Bis",
            "filters.date_range_off": "Aus — zeigt alle Daten im ausgewählten Monat.",
            "filters.amount_range": "Betragsbereich",
            "filters.min": "Min (€)",
            "filters.max": "Max (€)",
            "filters.amount_example": "Beträge sind in EUR. Beispiel: 12.50",
            "filters.reset": "Zurücksetzen",
            "filters.apply": "Anwenden",
            "filters.close": "Schließen",
            
            // Import
            "import.title": "Import",
            "import.from_csv": "Transaktionen aus CSV importieren",
            "import.csv_columns": "Empfohlene CSV-Spalten (Kopfzeile bevorzugt):",
            "import.csv_format": "Datum (erforderlich), Betrag (erforderlich, EUR), Kategorie (erforderlich), Notiz (optional)",
            "import.duplicate_note": "Hinweis: Wenn Sie dieselbe CSV erneut importieren, fügt Balance nur Transaktionen hinzu, die noch nicht in der App sind (Duplikate werden übersprungen).",
            "import.choose_file": "CSV-Datei auswählen",
            "import.xlsx_tip": "Tipp: Wenn Ihre Datei .xlsx ist, exportieren Sie sie als CSV in Excel und importieren Sie sie dann hier.",
            "import.columns": "Spalten",
            "import.header_row": "Kopfzeile",
            "import.preview": "Vorschau",
            "import.import_btn": "In Balance importieren",
            "import.mode_title": "Importmodus",
            "import.mode_message": "Sie haben %d bestehende Transaktion(en). Möchten Sie diese behalten und die importierten Daten hinzufügen (Zusammenführen) oder sie löschen und nur die importierten Daten behalten (Ersetzen)?",
            "import.mode_merge": "Zusammenführen",
            "import.mode_replace": "Ersetzen",
            "import.done": "Fertig",
            
            // Insights
            "insights.title": "Einblicke",
            "insights.not_ready": "Einblicke sind nicht bereit",
            "insights.set_budget_first": "Legen Sie zuerst Ihr monatliches Budget fest, um die Analyse freizuschalten.",
            "insights.analytical_report": "Analysebericht",
            "insights.trend_pressure": "Dieser Trend wird Ihr Budget belasten",
            "insights.trend_pressure_desc": "Die Prognose für das Monatsende liegt über dem Budget. Priorisieren Sie die Kürzung diskretionärer Kosten.",
            "insights.approaching_limit": "Annäherung an das Limit",
            "insights.approaching_limit_desc": "Um die Kontrolle zu behalten, kürzen Sie eine diskretionäre Kategorie leicht.",
            "insights.projection_note": "Die Projektion verwendet einen robusten Tagesdurchschnitt (reduziert die Auswirkungen eines ungewöhnlichen Tages). Neue Transaktionen verfeinern die Schätzung.",
            "insights.insights_title": "Einblicke",
            "insights.no_data": "Noch nicht genug Daten. Fügen Sie ein paar Transaktionen hinzu.",
            "insights.notifications": "Benachrichtigungen",
            "insights.notifications_desc": "Erhalten Sie Erinnerungen, um Ihr Budget und Ihre Ausgaben zu überprüfen.",
            "insights.notification_status": "Benachrichtigungsstatus",
            "insights.send_test": "Testbenachrichtigung senden",
            "insights.test_tip": "Tipp: Aktivieren Sie Benachrichtigungen und tippen Sie dann auf die Testschaltfläche.",
            "insights.export": "Export",
            "insights.export_share": "Teilen",
            "insights.export_desc": "Exportieren Sie Ihren Monat als saubere Tabelle für Excel oder als CSV.",
            "insights.export_excel": "Excel",
            "insights.export_csv": "CSV",
            "insights.export_tip": "Tipp: Excel-Export enthält mehrere Blätter (Zusammenfassung, Transaktionen, Kategorien, Täglich).",
            "insights.ai_analysis": "KI-Analyse",
            "insights.ai_powered": "Cloud-basiert",
            "insights.ai_desc": "Erhalten Sie eine intelligentere Erklärung darüber, was Ihre Ausgaben verursacht hat und was als nächstes zu tun ist.",
            "insights.ai_analyze": "Diesen Monat analysieren",
            
            // AI Insights
            "ai.title": "KI-Einblicke",
            "ai.close": "Schließen",
            "ai.tip": "Tipp: KI-generierte Einblicke basierend auf Ihren Ausgabendaten. Ergebnisse können unvollkommen sein – nutzen Sie sie als Orientierung.",
            "ai.analyzing": "Analysieren…",
            "ai.run_analysis": "Analyse ausführen",
            "ai.reanalyze": "Erneut analysieren",
            "ai.last_analyzed": "Zuletzt analysiert: %@",
            "ai.summary": "Zusammenfassung",
            "ai.insights": "Einblicke",
            "ai.actions": "Empfohlene Aktionen",
            "ai.risk": "Risiko",
            "ai.risk_level": "Risikoniveau",
            "ai.error": "Konnte nicht analysieren",
            
            // Settings
            "settings.title": "Einstellungen",
            "settings.app_settings": "App-Einstellungen",
            "settings.currency": "Währung",
            "settings.language": "Sprache",
            "settings.language_note": "Hinweis: Sprachänderung wird sofort wirksam.",
            "settings.developer": "Entwickler",
            "settings.developed_by": "Entwickelt von",
            "settings.version": "Version",
            "settings.build": "Build",
            "settings.about": "Über Balance",
            "settings.about_desc": "Balance ist eine persönliche Finanz-App, die Ihnen hilft, Ihre Ausgaben Schritt für Schritt zu kontrollieren. Verfolgen Sie Ausgaben, legen Sie Budgets fest und gewinnen Sie Einblicke in Ihre finanziellen Gewohnheiten.",
            "settings.feature_privacy": "Datenschutz zuerst - alle Daten lokal gespeichert",
            "settings.feature_insights": "Intelligente Einblicke und Prognosen",
            "settings.feature_ai": "KI-gestützte Analyse",
            "settings.feature_import": "Transaktionen importieren und exportieren",
            
            // Categories
            "category.groceries": "Lebensmittel",
            "category.rent": "Miete",
            "category.bills": "Rechnungen",
            "category.transport": "Transport",
            "category.health": "Gesundheit",
            "category.education": "Bildung",
            "category.dining": "Gastronomie",
            "category.shopping": "Einkaufen",
            "category.entertainment": "Unterhaltung",
            "category.other": "Sonstiges",
            
            // Common
            "common.ok": "common.ok",
            "common.done": "Fertig",
            "common.yes": "Ja",
            "common.no": "Nein",
            "common.close": "Schließen",
            "common.cancel": "Abbrechen",
            "common.delete": "Löschen",
            "common.save": "Speichern",
            "common.edit": "Bearbeiten",
            "common.add": "Hinzufügen",
            "common.trash": "Papierkorb",
            
            // Legal & Support
            "settings.legal": "Rechtliches & Support",
            "settings.support_email": "Support-E-Mail",
            "settings.report_bug": "Fehler melden",
            "settings.licenses": "Open-Source-Lizenzen",
            "settings.app_license": "App-Lizenz",
            
            // Attachment
            "attachment.title": "Anhang",
            "attachment.document": "Dokument angehängt",
            
            // Payment Methods
            "payment.cash": "Bargeld",
            "payment.card": "Karte",
        ],
        
        "es": [
            // Tabs
            "tab.dashboard": "Panel",
            "tab.transactions": "Transacciones",
            "tab.budget": "Presupuesto",
            "tab.insights": "Perspectivas",
            "tab.settings": "Ajustes",
            
            // Dashboard
            "dashboard.title": "Balance",
            "dashboard.data_for_month": "Datos de este mes",
            "dashboard.start_from_zero": "Empezar desde cero",
            "dashboard.set_budget_first": "Establezca primero su presupuesto mensual. El análisis comenzará de inmediato.",
            "dashboard.daily_trend": "Tendencia de gastos diarios",
            "dashboard.no_trend_data": "Aún no hay datos de tendencia. Agregue algunas transacciones.",
            "dashboard.category_breakdown": "Desglose por categoría",
            "dashboard.payment_breakdown": "Desglose de pagos",
            "dashboard.cash_vs_card": "Efectivo vs Tarjeta",
            "dashboard.no_payment_data": "Aún no hay datos de pago. Agregue transacciones para ver el desglose.",
            "dashboard.payment_insight_cash_heavy": "Está usando principalmente efectivo. Considere rastrear también los gastos con tarjeta.",
            "dashboard.payment_insight_card_heavy": "La mayoría de los gastos son con tarjeta. ¡Bueno para rastrear!",
            "dashboard.payment_insight_balanced": "Buen equilibrio entre pagos en efectivo y con tarjeta.",
            "dashboard.category_breakdown_empty": "Una vez que agregue transacciones, los totales por categoría aparecerán aquí.",
            "dashboard.advisor_insights": "Perspectivas del asesor",
            "dashboard.honest_no_blame": "Honesto, sin culpa",
            "dashboard.add_expenses": "Agregue algunos gastos cotidianos para una evaluación más precisa.",
            "dashboard.quick_actions": "Acciones rápidas recomendadas",
            "dashboard.no_action_needed": "No se necesita acción urgente. Manténgase consistente.",
            "dashboard.step1_title": "Paso 1: Establezca su presupuesto mensual",
            "dashboard.step1_desc": "Sin un presupuesto, los números no tienen objetivo. Establezca un presupuesto realista, luego tomaremos el control paso a paso.",
            "dashboard.go_to_budget": "Ir al Presupuesto",
            "dashboard.delete_month": "¿Eliminar datos de este mes?",
            "dashboard.delete_month_msg": "Todas las transacciones, el presupuesto mensual y los límites de categoría para este mes se eliminarán permanentemente.",
            "dashboard.delete_confirm": "Eliminar",
            "dashboard.month_cleared": "Este mes ya ha sido borrado. No queda nada por eliminar.",
            "dashboard.month_deleted": "Los datos de este mes se eliminaron exitosamente",
            "dashboard.this_month": "Este mes",
            
            // Month Picker
            "month.this_month": "Este mes",
            
            // Budget Status
            "status.stable": "Estable",
            "status.stable_desc": "Los gastos están bajo control. Mantenga el patrón.",
            "status.needs_attention": "Requiere atención",
            "status.needs_attention_desc": "Se está acercando al límite del presupuesto. Revise los gastos discrecionales.",
            "status.budget_pressure": "Presión presupuestaria",
            "status.budget_pressure_desc": "Los gastos son muy altos. Reduzca los costos no esenciales.",
            "status.analysis_paused": "Análisis en pausa",
            "status.analysis_paused_desc": "El panel y las perspectivas se desbloquean después de establecer un presupuesto.",
            "status.budget_set": "Presupuesto establecido",
            "status.budget_set_desc": "Ahora puede agregar transacciones y obtener análisis reales.",
            
            // KPIs
            "kpi.spent": "Gastado",
            "kpi.remaining": "Restante",
            "kpi.daily_avg": "Prom. diario",
            
            // Budget
            "budget.title": "Presupuesto",
            "budget.set_monthly": "Establecer presupuesto mensual",
            "budget.keep_realistic": "Sé realista. Puedes ajustarlo en cualquier momento.",
            "budget.start": "Comenzar",
            "budget.update": "Actualizar",
            "budget.this_month": "Este mes",
            "budget.budget_used": "Presupuesto usado",
            "budget.used_percent": "usado",
            "budget.spent": "Gastado",
            "budget.remaining": "Restante",
            "budget.month_not_complete": "Mes aún no completado",
            "budget.on_track": "En camino",
            "budget.over_budget": "Sobre presupuesto",
            "budget.saved_vs_prev": "Ahorrado vs mes anterior",
            "budget.total_saved": "Total ahorrado (meses pasados)",
            "budget.category_budgets": "Presupuestos por categoría",
            "budget.category_caps_desc": "Opcional: establezca límites por categoría. Deje vacío para sin límite.",
            "budget.allocated": "Asignado",
            "budget.unallocated": "No asignado",
            "budget.caps_exceed": "Los límites de categoría exceden el presupuesto total",
            "budget.caps_exceed_desc": "Reduzca uno o más presupuestos de categoría para que la asignación permanezca dentro del total mensual.",
            
            // Transactions
            "transactions.title": "Transacciones",
            "transactions.select": "Seleccionar",
            "transactions.select_all": "Seleccionar todo",
            "transactions.delete": "Eliminar",
            "transactions.cancel": "Cancelar",
            "transactions.search_placeholder": "Buscar categoría / nota",
            "transactions.delete_confirm": "¿Eliminar transacción?",
            "transactions.delete_multiple": "¿Eliminar %d transacciones?",
            "transactions.cannot_undo": "Esta acción no se puede deshacer.",
            "transactions.deleted": "%d transacción eliminada",
            "transactions.undo": "Deshacer",
            "transactions.view_attachment": "Ver adjunto",
            "transactions.edit": "Editar",
            
            // Add/Edit Transaction
            "transaction.add": "Agregar gasto",
            "transaction.edit": "Editar gasto",
            "transaction.amount": "Cantidad",
            "transaction.amount_placeholder": "ej. 250.00",
            "transaction.category": "Categoría",
            "transaction.add_category": "Agregar",
            "transaction.new_category": "Nueva categoría",
            "transaction.new_category_msg": "Cree una categoría personalizada para sus transacciones.",
            "transaction.new_category_placeholder": "ej. Café",
            "transaction.date": "Fecha",
            "transaction.note": "Nota (opcional)",
            "transaction.note_placeholder": "ej. comestibles",
            "transaction.attachment": "Adjunto (opcional)",
            "transaction.add_attachment": "Agregar imagen o archivo",
            "transaction.attach_photo": "Biblioteca de fotos",
            "transaction.attach_file": "Archivos",
            "transaction.save": "Guardar",
            "transaction.save_changes": "Guardar cambios",
            "transaction.close": "Cerrar",
            "transaction.advisor_note": "Nota del asesor: el seguimiento preciso es el camino más rápido hacia el control.",
            "transaction.payment_method": "Método de pago",
            
            // Filters
            "filters.title": "Filtros",
            "filters.categories": "Categorías",
            "filters.all": "Todos",
            "filters.clear": "Limpiar",
            "filters.tip_one_category": "Consejo: seleccione al menos una categoría.",
            "filters.date_range": "Rango de fechas",
            "filters.from": "Desde",
            "filters.to": "Hasta",
            "filters.date_range_off": "Desactivado — mostrando todas las fechas en el mes seleccionado.",
            "filters.amount_range": "Rango de cantidad",
            "filters.min": "Mín (€)",
            "filters.max": "Máx (€)",
            "filters.amount_example": "Las cantidades están en EUR. Ejemplo: 12.50",
            "filters.reset": "Restablecer",
            "filters.apply": "Aplicar",
            "filters.close": "Cerrar",
            
            // Import
            "import.title": "Importar",
            "import.from_csv": "Importar transacciones desde CSV",
            "import.csv_columns": "Columnas CSV recomendadas (se prefiere fila de encabezado):",
            "import.csv_format": "fecha (requerida), cantidad (requerida, EUR), categoría (requerida), nota (opcional)",
            "import.duplicate_note": "Nota: Si importa el mismo CSV nuevamente, Balance solo agregará transacciones que aún no estén en la aplicación (se omiten duplicados).",
            "import.choose_file": "Elegir archivo CSV",
            "import.xlsx_tip": "Consejo: Si su archivo es .xlsx, expórtelo como CSV en Excel, luego impórtelo aquí.",
            "import.columns": "Columnas",
            "import.header_row": "Fila de encabezado",
            "import.preview": "Vista previa",
            "import.import_btn": "Importar en Balance",
            "import.mode_title": "Modo de importación",
            "import.mode_message": "Tiene %d transacción(es) existente(s). ¿Desea conservarlas y agregar los datos importados (Combinar) o eliminarlas y conservar solo los datos importados (Reemplazar)?",
            "import.mode_merge": "Combinar",
            "import.mode_replace": "Reemplazar",
            "import.done": "Hecho",
            
            // Insights
            "insights.title": "Perspectivas",
            "insights.not_ready": "Las perspectivas no están listas",
            "insights.set_budget_first": "Establezca primero su presupuesto mensual para desbloquear el análisis.",
            "insights.analytical_report": "Informe analítico",
            "insights.trend_pressure": "Esta tendencia presionará su presupuesto",
            "insights.trend_pressure_desc": "La proyección de fin de mes está por encima del presupuesto. Priorice recortar costos discrecionales.",
            "insights.approaching_limit": "Acercándose al límite",
            "insights.approaching_limit_desc": "Para mantener el control, reduzca ligeramente una categoría discrecional.",
            "insights.projection_note": "La proyección utiliza un promedio diario robusto (reduce el impacto de un día inusual). Las nuevas transacciones refinan la estimación.",
            "insights.insights_title": "Perspectivas",
            "insights.no_data": "Aún no hay suficientes datos. Agregue algunas transacciones.",
            "insights.notifications": "Notificaciones",
            "insights.notifications_desc": "Reciba recordatorios para revisar su presupuesto y gastos.",
            "insights.notification_status": "Estado de notificación",
            "insights.send_test": "Enviar notificación de prueba",
            "insights.test_tip": "Consejo: active las notificaciones, luego toque el botón de prueba.",
            "insights.export": "Exportar",
            "insights.export_share": "Compartir",
            "insights.export_desc": "Exporte su mes como una tabla limpia para Excel o como CSV.",
            "insights.export_excel": "Excel",
            "insights.export_csv": "CSV",
            "insights.export_tip": "Consejo: la exportación de Excel incluye varias hojas (Resumen, Transacciones, Categorías, Diario).",
            "insights.ai_analysis": "Análisis de IA",
            "insights.ai_powered": "Impulsado por la nube",
            "insights.ai_desc": "Obtenga una explicación más inteligente de lo que impulsó sus gastos y qué hacer a continuación.",
            "insights.ai_analyze": "Analizar este mes",
            
            // AI Insights
            "ai.title": "Perspectivas de IA",
            "ai.close": "Cerrar",
            "ai.tip": "Consejo: Perspectivas generadas por IA basadas en sus datos de gastos. Los resultados pueden ser imperfectos: úselos como guía.",
            "ai.analyzing": "Analizando…",
            "ai.run_analysis": "Ejecutar análisis",
            "ai.reanalyze": "Volver a analizar",
            "ai.last_analyzed": "Último análisis: %@",
            "ai.summary": "Resumen",
            "ai.insights": "Perspectivas",
            "ai.actions": "Acciones recomendadas",
            "ai.risk": "Riesgo",
            "ai.risk_level": "Nivel de riesgo",
            "ai.error": "No se pudo analizar",
            
            // Settings
            "settings.title": "Ajustes",
            "settings.app_settings": "Ajustes de la aplicación",
            "settings.currency": "Moneda",
            "settings.language": "Idioma",
            "settings.language_note": "Nota: El cambio de idioma tendrá efecto inmediatamente.",
            "settings.developer": "Desarrollador",
            "settings.developed_by": "Desarrollado por",
            "settings.version": "Versión",
            "settings.build": "Compilación",
            "settings.about": "Acerca de Balance",
            "settings.about_desc": "Balance es una aplicación de finanzas personales diseñada para ayudarlo a controlar sus gastos, paso a paso. Rastree gastos, establezca presupuestos y obtenga información sobre sus hábitos financieros.",
            "settings.feature_privacy": "Privacidad primero - todos los datos almacenados localmente",
            "settings.feature_insights": "Perspectivas y proyecciones inteligentes",
            "settings.feature_ai": "Análisis impulsado por IA",
            "settings.feature_import": "Importar y exportar transacciones",
            
            // Categories
            "category.groceries": "Comestibles",
            "category.rent": "Alquiler",
            "category.bills": "Facturas",
            "category.transport": "Transporte",
            "category.health": "Salud",
            "category.education": "Educación",
            "category.dining": "Comidas",
            "category.shopping": "Compras",
            "category.entertainment": "Entretenimiento",
            "category.other": "Otro",
            
            // Common
            "common.ok": "common.ok",
            "common.done": "Hecho",
            "common.yes": "Sí",
            "common.no": "common.no",
            "common.close": "Cerrar",
            "common.cancel": "Cancelar",
            "common.delete": "Eliminar",
            "common.save": "Guardar",
            "common.edit": "Editar",
            "common.add": "Agregar",
            "common.trash": "Papelera",
            
            // Legal & Support
            "settings.legal": "Legal y Soporte",
            "settings.support_email": "Correo de soporte",
            "settings.report_bug": "Reportar un error",
            "settings.licenses": "Licencias de código abierto",
            "settings.app_license": "Licencia de la aplicación",
            
            // Attachment
            "attachment.title": "Adjunto",
            "attachment.document": "Documento adjunto",
            
            // Payment Methods
            "payment.cash": "Efectivo",
            "payment.card": "Tarjeta",
        ],
        
        "fa": [
            // Tabs
            "tab.dashboard": "داشبورد",
            "tab.transactions": "تراکنش‌ها",
            "tab.budget": "بودجه",
            "tab.insights": "تحلیل‌ها",
            "tab.settings": "تنظیمات",
            
            // Dashboard
            "dashboard.title": "تراز",
            "dashboard.data_for_month": "داده‌های این ماه",
            "dashboard.start_from_zero": "از صفر شروع کنید",
            "dashboard.set_budget_first": "ابتدا بودجه ماهانه خود را تعیین کنید. تحلیل بلافاصله شروع می‌شود.",
            "dashboard.daily_trend": "روند هزینه روزانه",
            "dashboard.no_trend_data": "هنوز داده‌ای برای روند وجود ندارد. چند تراکنش اضافه کنید.",
            "dashboard.category_breakdown": "تفکیک دسته‌بندی",
            "dashboard.payment_breakdown": "تفکیک روش پرداخت",
            "dashboard.cash_vs_card": "نقدی در مقابل کارت",
            "dashboard.no_payment_data": "هنوز داده پرداختی وجود ندارد. برای مشاهده تفکیک، تراکنش اضافه کنید.",
            "dashboard.payment_insight_cash_heavy": "بیشتر از نقدی استفاده میu200cکنید. پیگیری هزینهu200cهای کارتی را هم در نظر بگیرید.",
            "dashboard.payment_insight_card_heavy": "بیشتر هزینهu200cها با کارت است. برای پیگیری عالی است!",
            "dashboard.payment_insight_balanced": "تعادل خوبی بین پرداختu200cهای نقدی و کارتی.",
            "dashboard.category_breakdown_empty": "پس از اضافه کردن تراکنش‌ها، مجموع دسته‌بندی‌ها اینجا نمایش داده می‌شود.",
            "dashboard.advisor_insights": "تحلیل‌های مشاور",
            "dashboard.honest_no_blame": "صادقانه، بدون سرزنش",
            "dashboard.add_expenses": "چند هزینه روزمره اضافه کنید برای ارزیابی دقیق‌تر.",
            "dashboard.quick_actions": "اقدامات سریع پیشنهادی",
            "dashboard.no_action_needed": "نیازی به اقدام فوری نیست. ثابت قدم باشید.",
            "dashboard.step1_title": "گام ۱: بودجه ماهانه خود را تعیین کنید",
            "dashboard.step1_desc": "بدون بودجه، اعداد هدفی ندارند. یک بودجه واقع‌بینانه تعیین کنید—سپس گام به گام کنترل را به دست می‌گیریم.",
            "dashboard.go_to_budget": "برو به بودجه",
            "dashboard.delete_month": "داده‌های این ماه حذف شود؟",
            "dashboard.delete_month_msg": "تمام تراکنش‌ها، بودجه ماهانه و محدودیت‌های دسته‌بندی برای این ماه برای همیشه حذف خواهند شد.",
            "dashboard.delete_confirm": "حذف",
            "dashboard.month_cleared": "این ماه قبلاً پاک شده است. چیزی برای حذف باقی نمانده.",
            "dashboard.month_deleted": "داده‌های این ماه با موفقیت حذف شد",
            "dashboard.this_month": "این ماه",
            
            // Month Picker
            "month.this_month": "این ماه",
            
            // Budget Status
            "status.stable": "پایدار",
            "status.stable_desc": "هزینه‌ها تحت کنترل است. این الگو را حفظ کنید.",
            "status.needs_attention": "نیاز به توجه",
            "status.needs_attention_desc": "به محدودیت بودجه نزدیک می‌شوید. هزینه‌های اختیاری را بررسی کنید.",
            "status.budget_pressure": "فشار بودجه",
            "status.budget_pressure_desc": "هزینه‌ها بسیار زیاد است. هزینه‌های غیرضروری را کاهش دهید.",
            "status.analysis_paused": "تحلیل متوقف شده",
            "status.analysis_paused_desc": "داشبورد و تحلیل‌ها پس از تعیین بودجه فعال می‌شوند.",
            "status.budget_set": "بودجه تعیین شد",
            "status.budget_set_desc": "اکنون می‌توانید تراکنش اضافه کنید و تحلیل واقعی دریافت کنید.",
            
            // KPIs
            "kpi.spent": "خرج شده",
            "kpi.remaining": "باقیمانده",
            "kpi.daily_avg": "میانگین روزانه",
            
            // Budget
            "budget.title": "بودجه",
            "budget.set_monthly": "بودجه ماهانه تعیین کنید",
            "budget.keep_realistic": "واقع‌بینانه باشید. می‌توانید هر زمان تغییرش دهید.",
            "budget.start": "شروع",
            "budget.update": "بروزرسانی",
            "budget.this_month": "این ماه",
            "budget.budget_used": "بودجه مصرف شده",
            "budget.used_percent": "استفاده شده",
            "budget.spent": "خرج شده",
            "budget.remaining": "باقیمانده",
            "budget.month_not_complete": "ماه هنوز کامل نشده",
            "budget.on_track": "در مسیر",
            "budget.over_budget": "بیش از بودجه",
            "budget.saved_vs_prev": "پس‌انداز نسبت به ماه قبل",
            "budget.total_saved": "کل پس‌انداز (ماه‌های گذشته)",
            "budget.category_budgets": "بودجه دسته‌بندی‌ها",
            "budget.category_caps_desc": "اختیاری: سقف برای هر دسته تعیین کنید. برای بدون سقف خالی بگذارید.",
            "budget.allocated": "تخصیص داده شده",
            "budget.unallocated": "تخصیص نیافته",
            "budget.caps_exceed": "سقف دسته‌بندی‌ها از کل بودجه بیشتر است",
            "budget.caps_exceed_desc": "یک یا چند بودجه دسته‌بندی را کاهش دهید تا تخصیص در کل ماهانه باقی بماند.",
            
            // Transactions
            "transactions.title": "تراکنش‌ها",
            "transactions.before_add": "قبل از اضافه کردن تراکنش",
            "transactions.select": "انتخاب",
            "transactions.select_all": "انتخاب همه",
            "transactions.delete": "حذف",
            "transactions.cancel": "لغو",
            "transactions.search_placeholder": "جستجوی دسته‌بندی / یادداشت",
            "transactions.delete_confirm": "تراکنش حذف شود؟",
            "transactions.delete_multiple": "%d تراکنش حذف شود؟",
            "transactions.cannot_undo": "این عمل قابل بازگشت نیست.",
            "transactions.deleted": "%d تراکنش حذف شد",
            "transactions.undo": "بازگشت",
            "transactions.view_attachment": "مشاهده پیوست",
            "transactions.edit": "ویرایش",
            
            // Add/Edit Transaction
            "transaction.add": "افزودن هزینه",
            "transaction.edit": "ویرایش هزینه",
            "transaction.amount": "مبلغ",
            "transaction.amount_placeholder": "مثلاً 250.00",
            "transaction.category": "دسته‌بندی",
            "transaction.add_category": "افزودن",
            "transaction.new_category": "دسته‌بندی جدید",
            "transaction.new_category_msg": "یک دسته‌بندی سفارشی برای تراکنش‌های خود ایجاد کنید.",
            "transaction.new_category_placeholder": "مثلاً قهوه",
            "transaction.date": "تاریخ",
            "transaction.note": "یادداشت (اختیاری)",
            "transaction.note_placeholder": "مثلاً خواربار",
            "transaction.attachment": "پیوست (اختیاری)",
            "transaction.add_attachment": "افزودن عکس یا فایل",
            "transaction.attach_photo": "کتابخانه عکس",
            "transaction.attach_file": "فایل‌ها",
            "transaction.save": "ذخیره",
            "transaction.save_changes": "ذخیره تغییرات",
            "transaction.close": "بستن",
            "transaction.advisor_note": "یادداشت مشاور: ثبت دقیق، سریع‌ترین راه به کنترل است.",
            "transaction.payment_method": "روش پرداخت",
            
            // Filters
            "filters.title": "فیلترها",
            "filters.categories": "دسته‌بندی‌ها",
            "filters.all": "همه",
            "filters.clear": "پاک کردن",
            "filters.tip_one_category": "نکته: حداقل یک دسته‌بندی انتخاب کنید.",
            "filters.date_range": "بازه تاریخ",
            "filters.from": "از",
            "filters.to": "تا",
            "filters.date_range_off": "خاموش — نمایش تمام تاریخ‌ها در ماه انتخاب شده.",
            "filters.amount_range": "بازه مبلغ",
            "filters.min": "حداقل (€)",
            "filters.max": "حداکثر (€)",
            "filters.amount_example": "مبالغ به یورو هستند. مثال: 12.50",
            "filters.reset": "بازنشانی",
            "filters.apply": "اعمال",
            "filters.close": "بستن",
            
            // Import
            "import.title": "ورود داده",
            "import.from_csv": "وارد کردن تراکنش‌ها از CSV",
            "import.csv_columns": "ستون‌های CSV پیشنهادی (سطر سرتیتر ترجیح داده می‌شود):",
            "import.csv_format": "تاریخ (ضروری)، مبلغ (ضروری، یورو)، دسته‌بندی (ضروری)، یادداشت (اختیاری)",
            "import.duplicate_note": "توجه: اگر همان CSV را دوباره وارد کنید، تراز فقط تراکنش‌هایی را اضافه می‌کند که قبلاً در برنامه نیستند (تکراری‌ها رد می‌شوند).",
            "import.choose_file": "انتخاب فایل CSV",
            "import.xlsx_tip": "نکته: اگر فایل شما .xlsx است، آن را به عنوان CSV در اکسل ذخیره کنید، سپس اینجا وارد کنید.",
            "import.columns": "ستون‌ها",
            "import.header_row": "سطر سرتیتر",
            "import.preview": "پیش‌نمایش",
            "import.import_btn": "وارد کردن در تراز",
            "import.mode_title": "حالت وارد کردن",
            "import.mode_message": "شما %d تراکنش موجود دارید. آیا می‌خواهید آنها را نگه دارید و داده‌های وارد شده را اضافه کنید (ادغام)، یا آنها را حذف کنید و فقط داده‌های وارد شده را نگه دارید (جایگزینی)?",
            "import.mode_merge": "ادغام",
            "import.mode_replace": "جایگزینی",
            "import.done": "تمام",
            
            // Insights
            "insights.title": "تحلیل‌ها",
            "insights.not_ready": "تحلیل‌ها آماده نیست",
            "insights.set_budget_first": "ابتدا بودجه ماهانه خود را تعیین کنید تا تحلیل فعال شود.",
            "insights.analytical_report": "گزارش تحلیلی",
            "insights.trend_pressure": "این روند به بودجه شما فشار وارد می‌کند",
            "insights.trend_pressure_desc": "پیش‌بینی پایان ماه بالاتر از بودجه است. اولویت را به کاهش هزینه‌های اختیاری بدهید.",
            "insights.approaching_limit": "نزدیک به محدودیت",
            "insights.approaching_limit_desc": "برای حفظ کنترل، یک دسته‌بندی اختیاری را اندکی کاهش دهید.",
            "insights.projection_note": "پیش‌بینی از میانگین روزانه قوی استفاده می‌کند (تأثیر یک روز غیرعادی را کاهش می‌دهد). تراکنش‌های جدید تخمین را بهبود می‌بخشند.",
            "insights.insights_title": "تحلیل‌ها",
            "insights.no_data": "هنوز داده کافی وجود ندارد. چند تراکنش اضافه کنید.",
            "insights.notifications": "اعلان‌ها",
            "insights.notifications_desc": "یادآوری‌هایی برای بررسی بودجه و هزینه‌های خود دریافت کنید.",
            "insights.notification_status": "وضعیت اعلان",
            "insights.send_test": "ارسال اعلان آزمایشی",
            "insights.test_tip": "نکته: اعلان‌ها را روشن کنید، سپس دکمه آزمایش را بزنید.",
            "insights.export": "خروجی",
            "insights.export_share": "اشتراک‌گذاری",
            "insights.export_desc": "ماه خود را به عنوان جدول تمیز برای اکسل یا CSV خروجی بگیرید.",
            "insights.export_excel": "اکسل",
            "insights.export_csv": "CSV",
            "insights.export_tip": "نکته: خروجی اکسل شامل چندین برگه است (خلاصه، تراکنش‌ها، دسته‌بندی‌ها، روزانه).",
            "insights.ai_analysis": "تحلیل هوش مصنوعی",
            "insights.ai_powered": "قدرت گرفته از ابر",
            "insights.ai_desc": "توضیح هوشمندانه‌تری از عوامل هزینه‌ها و اقدامات بعدی دریافت کنید.",
            "insights.ai_analyze": "تحلیل این ماه",
            
            // AI Insights
            "ai.title": "تحلیل‌های هوش مصنوعی",
            "ai.close": "بستن",
            "ai.tip": "نکته: تحلیل‌های تولید شده توسط هوش مصنوعی بر اساس داده‌های هزینه شما. نتایج ممکن است ناقص باشند — از آنها به عنوان راهنما استفاده کنید.",
            "ai.analyzing": "در حال تحلیل…",
            "ai.run_analysis": "اجرای تحلیل",
            "ai.reanalyze": "تحلیل مجدد",
            "ai.last_analyzed": "آخرین تحلیل: %@",
            "ai.summary": "خلاصه",
            "ai.insights": "تحلیل‌ها",
            "ai.actions": "اقدامات پیشنهادی",
            "ai.risk": "ریسک",
            "ai.risk_level": "سطح ریسک",
            "ai.error": "امکان تحلیل وجود نداشت",
            
            // Settings
            "settings.title": "تنظیمات",
            "settings.app_settings": "تنظیمات برنامه",
            "settings.currency": "واحد پول",
            "settings.language": "زبان",
            "settings.language_note": "توجه: تغییر زبان بلافاصله اعمال می‌شود.",
            "settings.developer": "توسعه‌دهنده",
            "settings.developed_by": "توسعه یافته توسط",
            "settings.version": "نسخه",
            "settings.build": "ساخت",
            "settings.about": "درباره تراز",
            "settings.about_desc": "تراز یک برنامه مالی شخصی است که برای کمک به شما در کنترل هزینه‌هایتان، گام به گام طراحی شده است. هزینه‌ها را ردیابی کنید، بودجه تعیین کنید و از عادات مالی خود بینش کسب کنید.",
            "settings.feature_privacy": "حریم خصوصی اول - تمام داده‌ها به صورت محلی ذخیره می‌شوند",
            "settings.feature_insights": "تحلیل‌ها و پیش‌بینی‌های هوشمند",
            "settings.feature_ai": "تحلیل با قدرت هوش مصنوعی",
            "settings.feature_import": "وارد و خارج کردن تراکنش‌ها",
            
            // Categories
            "category.groceries": "خواربار",
            "category.rent": "اجاره",
            "category.bills": "قبوض",
            "category.transport": "حمل و نقل",
            "category.health": "سلامت",
            "category.education": "آموزش",
            "category.dining": "غذا بیرون",
            "category.shopping": "خرید",
            "category.entertainment": "سرگرمی",
            "category.other": "سایر",
            
            // Common
            "common.ok": "باشه",
            "common.done": "تمام",
            "common.yes": "بله",
            "common.no": "خیر",
            "common.close": "بستن",
            "common.cancel": "لغو",
            "common.delete": "حذف",
            "common.save": "ذخیره",
            "common.edit": "ویرایش",
            "common.add": "افزودن",
            "common.trash": "سطل زباله",
            
            // Legal & Support
            "settings.legal": "قانونی و پشتیبانی",
            "settings.support_email": "ایمیل پشتیبانی",
            "settings.report_bug": "گزارش باگ",
            "settings.licenses": "مجوزهای منبع باز",
            "settings.app_license": "مجوز برنامه",
            
            // Attachment
            "attachment.title": "پیوست",
            "attachment.document": "سند پیوست شده",
            
            // Payment Methods
            "payment.cash": "نقدی",
            "payment.card": "کارت",
        ],
    ]
}
// MARK: - Root

struct ContentView: View {
    @State private var store: Store = Store()
    @State private var selectedTab: Tab = .dashboard
    @State private var showLaunchScreen = true
    @AppStorage("app.language") private var appLanguage: String = "en"
    @State private var uiRefreshID = UUID()
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var firestoreManager = FirestoreManager()

    @Environment(\.scenePhase) private var scenePhase

    // Debounced persistence
    @State private var saveWorkItem: DispatchWorkItem? = nil

    // Failsafe autosave (covers cases where Store is a reference type and onChange(of: store) won't fire)
    @State private var lastAutoSave: Date = .distantPast
    private let autosaveIntervalSeconds: TimeInterval = 3.0
    private let autosaveTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    // Debounced smart-rule evaluation to prevent repeated scheduling/firing
    @State private var notifEvalWorkItem: DispatchWorkItem? = nil
    @State private var didSyncNotifications: Bool = false

    @AppStorage("notifications.enabled")
    private var notificationsEnabled: Bool = false

    private let saveDebounceSeconds: TimeInterval = 0.6
    private let notifEvalDebounceSeconds: TimeInterval = 0.9
    
    // MARK: - Helper Functions
    
    /// Save store to both local and cloud (user-specific)
    private func saveStore() {
        guard let userId = authManager.currentUser?.uid else { return }
        
        // Save locally with user ID
        store.save(userId: userId)
        
        // Debounced save to cloud
        saveWorkItem?.cancel()
        let task = DispatchWorkItem {
            Task {
                do {
                    try await firestoreManager.saveStore(store, userId: userId)
                } catch {
                    print("❌ Error saving to cloud: \(error)")
                }
            }
        }
        saveWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounceSeconds, execute: task)
    }

    var body: some View {
            Group {
                if authManager.isAuthenticated {
                    // User is logged in - show main app
                    ZStack {
                        if showLaunchScreen {
                            LaunchScreenView {
                                showLaunchScreen = false
                            }
                            .transition(.opacity)
                        } else {
                            mainAppView
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.4), value: showLaunchScreen)
                } else {
                    // User not logged in - show authentication
                    AuthenticationView()
                        .environmentObject(authManager)
                }
            }
            .onChange(of: authManager.currentUser?.uid) { oldValue, newValue in
                // When user changes (login/logout/switch), load their data
                if let userId = newValue {
                    // User logged in - load their data
                    store = Store.load(userId: userId)
                    
                    // Sync from cloud
                    Task {
                        do {
                            if let cloudStore = try await firestoreManager.loadStore(userId: userId) {
                                store = cloudStore
                            }
                        } catch {
                            print("Error loading from cloud: \(error)")
                        }
                    }
                } else {
                    // User logged out - clear data
                    store = Store()
                }
            }
        }
        
        private var mainAppView: some View {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    EmailVerificationBanner()
                    
                    TabView(selection: $selectedTab){
                DashboardView(store: $store, goToBudget: { selectedTab = .budget })
                    .tabItem { Label(L10n.t("tab.dashboard"), systemImage: "gauge.with.dots.needle.50percent") }
                    .tag(Tab.dashboard)

                TransactionsView(store: $store, goToBudget: { selectedTab = .budget })
                    .tabItem { Label(L10n.t("tab.transactions"), systemImage: "list.bullet.rectangle") }
                    .tag(Tab.transactions)

                BudgetView(store: $store)
                    .tabItem { Label(L10n.t("tab.budget"), systemImage: "target") }
                    .tag(Tab.budget)

                InsightsView(store: $store, goToBudget: { selectedTab = .budget })
                    .tabItem { Label(L10n.t("tab.insights"), systemImage: "sparkles") }
                    .tag(Tab.insights)

                SettingsView(store: $store)
                    .tabItem { Label(L10n.t("tab.settings"), systemImage: "gearshape") }
                    .tag(Tab.settings)
            }
            .environmentObject(firestoreManager)
            } // Close VStack
            .onAppear {
                // اجازه بده نوتیف‌ها داخل برنامه هم بنر بشن
                UNUserNotificationCenter.current().delegate =
                    NotificationCenterDelegate.shared

                // اگر قبلاً نوتیف روشن بوده، ruleها فعال باشن
                // (فقط یکبار در هر اجرای برنامه سینک کن تا نوتیف تکراری ساخته نشه)
                if notificationsEnabled && !didSyncNotifications {
                    didSyncNotifications = true
                    Task {
                        await Notifications.syncAll(store: store)
                    }
                }
            }
            .onChange(of: store) { _, newStore in
                // هر تغییری در store (اضافه/ادیت/حذف ترنزکشن)
                // ruleها رو با debounce بررسی کن تا نوتیف تکراری ساخته/فایر نشه
                guard notificationsEnabled else { return }

                notifEvalWorkItem?.cancel()
                let item = DispatchWorkItem {
                    Task {
                        await Notifications.evaluateSmartRules(store: newStore)
                    }
                }
                notifEvalWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + notifEvalDebounceSeconds, execute: item)
            }
            .onChange(of: store) { _, newValue in
                // Debounce saves to avoid writing on every keystroke / UI state change.
                saveWorkItem?.cancel()
                let item = DispatchWorkItem {
                    newValue.save()
                }
                saveWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounceSeconds, execute: item)
            }
            // Failsafe periodic autosave (handles reference-type Store mutations that don't trigger onChange(of: store))
            .onReceive(autosaveTimer) { _ in
                let now = Date()
                guard now.timeIntervalSince(lastAutoSave) >= autosaveIntervalSeconds else { return }
                // Only autosave when the launch screen is gone (avoid saving during initial load)
                guard showLaunchScreen == false else { return }
                saveStore()
                lastAutoSave = now
            }
            // Ensure we save when the app is backgrounded / suspended
            .onChange(of: scenePhase) { _, phase in
                if phase == .inactive || phase == .background {
                    saveStore()
                    lastAutoSave = Date()
                }
            }
            .tint(DS.Colors.accent)
            .id(uiRefreshID)
            .onChange(of: appLanguage) { _, _ in
                // Force entire UI refresh when language changes
                uiRefreshID = UUID()
            }
            .task(id: authManager.isAuthenticated) {
                if authManager.isAuthenticated, let userId = authManager.currentUser?.uid {
                    // Sync when user logs in
                    do {
                        let syncedStore = try await firestoreManager.syncStore(store, userId: userId)
                        store = syncedStore
                        saveStore() // Save with userId
                    } catch {
                        print("Sync error: \(error)")
                    }
                } else {
                    // User logged out - reset store
                    store = Store()
                    showLaunchScreen = true
                }
            }
            .task {
                // Check and process recurring transactions daily
                if authManager.isAuthenticated {
                    RecurringTransactionManager.processRecurringTransactions(store: &store)
                }
            }
        }
    }
}

enum Tab: Hashable { case dashboard, transactions, budget, insights, settings }
// Shared category list used across views
private var categories: [Category] { Category.allCases }


// ذخیره تاریخچه ایمپورت (hash دیتاست)
enum ImportHistory {
    private static let key = "imports.hashes.v1"

    static func load() -> Set<String> {
        let arr = UserDefaults.standard.stringArray(forKey: key) ?? []
        return Set(arr)
    }

    static func contains(_ hash: String) -> Bool {
        load().contains(hash)
    }

    static func append(_ hash: String) {
        var set = load()
        set.insert(hash)
        UserDefaults.standard.set(Array(set), forKey: key)
    }
}

enum ImportDeduper {
    static func signature(for t: Transaction) -> String {
        let note = t.note.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate] // yyyy-MM-dd
        let day = iso.string(from: t.date)

        // اگر Category RawRepresentable هست، rawValue بهتره؛ وگرنه description
        let cat = String(describing: t.category)

        // amount فرض: cents (Int)
        return "\(day)|\(t.amount)|\(cat)|\(note)"
    }

    static func datasetHash(transactions: [Transaction]) -> String {
        let lines = transactions.map(signature(for:)).sorted()
        let joined = lines.joined(separator: "\n")
        let digest = SHA256.hash(data: Data(joined.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Haptics
// MARK: - Backup Manager

// MARK: - Haptics

// MARK: - Haptics

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    static func rigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    // Complex patterns
    static func transactionAdded() {
        soft()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            medium()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                success()
            }
        }
    }
    
    static func transactionDeleted() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            light()
        }
    }
    
    static func budgetExceeded() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            warning()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                heavy()
            }
        }
    }
    
    static func monthChanged() {
        rigid()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            soft()
        }
    }
    
    static func longPressStart() {
        medium()
    }
    
    static func contextMenuOpened() {
        soft()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            light()
        }
    }
    
    static func exportSuccess() {
        medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            success()
        }
    }
    
    static func backupCreated() {
        rigid()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            success()
        }
    }
    
    static func backupRestored() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            success()
        }
    }
    
    static func importSuccess() {
        medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            success()
        }
    }
}


// MARK: - PDF Exporter

struct PDFExporter {
    static func makePDF(
        monthKey: String,
        currency: String,
        summary: Analytics.MonthSummary,
        transactions: [Transaction],
        categories: [Analytics.CategoryRow]
    ) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Balance App",
            kCGPDFContextAuthor: "Balance",
            kCGPDFContextTitle: "Monthly Report - \(monthKey)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            drawPage(context: context.cgContext, pageRect: pageRect, monthKey: monthKey, currency: currency, summary: summary, transactions: transactions, categories: categories)
        }
        
        return data
    }
    
    private static func drawPage(context: CGContext, pageRect: CGRect, monthKey: String, currency: String, summary: Analytics.MonthSummary, transactions: [Transaction], categories: [Analytics.CategoryRow]) {
        var y: CGFloat = 50
        let margin: CGFloat = 50
        let contentWidth = pageRect.width - (margin * 2)
        
        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 28, weight: .bold), .foregroundColor: UIColor.label]
        "Balance - Monthly Report".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 50
        
        // Month
        let monthAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .medium), .foregroundColor: UIColor.secondaryLabel]
        monthKey.draw(at: CGPoint(x: margin, y: y), withAttributes: monthAttrs)
        y += 60
        
        // Summary cards
        let cardWidth = (contentWidth - 20) / 2
        let cardHeight: CGFloat = 80
        
        drawCard(context: context, rect: CGRect(x: margin, y: y, width: cardWidth, height: cardHeight), title: "Budget", value: formatMoney(summary.budgetCents, currency: currency), color: UIColor.systemBlue)
        drawCard(context: context, rect: CGRect(x: margin + cardWidth + 20, y: y, width: cardWidth, height: cardHeight), title: "Spent", value: formatMoney(summary.totalSpent, currency: currency), color: UIColor.systemRed)
        y += cardHeight + 15
        
        drawCard(context: context, rect: CGRect(x: margin, y: y, width: cardWidth, height: cardHeight), title: "Remaining", value: formatMoney(summary.remaining, currency: currency), color: summary.remaining >= 0 ? UIColor.systemGreen : UIColor.systemOrange)
        drawCard(context: context, rect: CGRect(x: margin + cardWidth + 20, y: y, width: cardWidth, height: cardHeight), title: "Daily Average", value: formatMoney(summary.dailyAvg, currency: currency), color: UIColor.systemPurple)
        y += cardHeight + 40
        
        // Categories
        let sectionAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: UIColor.label]
        "Top Categories".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttrs)
        y += 35
        
        let topCats = Array(categories.prefix(5))
        let maxVal = topCats.map { $0.total }.max() ?? 1
        
        for cat in topCats {
            let catAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .medium), .foregroundColor: UIColor.label]
            cat.category.title.draw(at: CGPoint(x: margin, y: y + 8), withAttributes: catAttrs)
            
            let percentage = CGFloat(cat.total) / CGFloat(maxVal)
            let barWidth = (contentWidth - 140) * percentage
            let barRect = CGRect(x: margin + 110, y: y + 3, width: barWidth, height: 25)
            context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.3).cgColor)
            context.fill(barRect)
            
            let valAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: UIColor.label]
            formatMoney(cat.total, currency: currency).draw(at: CGPoint(x: barRect.maxX + 8, y: y + 8), withAttributes: valAttrs)
            
            y += 35
        }
        
        // Transactions section
        y += 20
        "Recent Transactions".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttrs)
        y += 35
        
        let recentTx = Array(transactions.prefix(10))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        for tx in recentTx {
            let txAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11, weight: .regular), .foregroundColor: UIColor.label]
            dateFormatter.string(from: tx.date).draw(at: CGPoint(x: margin, y: y), withAttributes: txAttrs)
            tx.category.title.draw(at: CGPoint(x: margin + 70, y: y), withAttributes: txAttrs)
            
            let note = tx.note.isEmpty ? "—" : String(tx.note.prefix(15)) + (tx.note.count > 15 ? "..." : "")
            note.draw(at: CGPoint(x: margin + 170, y: y), withAttributes: txAttrs)
            
            let amountColor = tx.type == .income ? UIColor.systemGreen : UIColor.label
            let amtAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11, weight: .semibold), .foregroundColor: amountColor]
            let prefix = tx.type == .expense ? "-" : "+"
            "\(prefix)\(formatMoney(tx.amount, currency: currency))".draw(at: CGPoint(x: margin + 320, y: y), withAttributes: amtAttrs)
            
            y += 28
        }
        
        // Footer
        y = pageRect.height - 50
        let footerAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9, weight: .regular), .foregroundColor: UIColor.secondaryLabel]
        let dateFormatter2 = DateFormatter()
        dateFormatter2.dateStyle = .long
        dateFormatter2.timeStyle = .short
        "Generated on \(dateFormatter2.string(from: Date())) • Balance App".draw(at: CGPoint(x: margin, y: y), withAttributes: footerAttrs)
    }
    
    private static func drawCard(context: CGContext, rect: CGRect, title: String, value: String, color: UIColor) {
        context.setFillColor(color.withAlphaComponent(0.1).cgColor)
        context.fill(rect)
        context.setStrokeColor(color.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(2)
        context.stroke(rect)
        
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: UIColor.secondaryLabel]
        title.draw(at: CGPoint(x: rect.minX + 12, y: rect.minY + 12), withAttributes: titleAttrs)
        
        let valueAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 20, weight: .bold), .foregroundColor: color]
        value.draw(at: CGPoint(x: rect.minX + 12, y: rect.minY + 38), withAttributes: valueAttrs)
    }
    
    private static func formatMoney(_ cents: Int, currency: String) -> String {
        let value = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        
        switch currency {
        case "EUR": formatter.currencySymbol = "€"
        case "USD": formatter.currencySymbol = "$"
        case "GBP": formatter.currencySymbol = "£"
        case "JPY": formatter.currencySymbol = "¥"
        case "CAD": formatter.currencySymbol = "C$"
        default: break
        }
        
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) \(currency)"
    }
}


// MARK: - Launch Screen Animation

private struct LaunchScreenView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 20
    @State private var taglineOpacity: Double = 0
    @State private var circleScale: CGFloat = 0
    @State private var circleOpacity: Double = 0
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            DS.Colors.bg.ignoresSafeArea()
            
            // Animated background circle - آبی بنفش
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0x667EEA).opacity(0.15),  // آبی بنفش روشن
                            Color(hex: 0x764BA2).opacity(0.08),  // بنفش
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .scaleEffect(circleScale)
                .opacity(circleOpacity)
            
            VStack(spacing: 24) {
                // Logo - بدون آیکون، فقط متن
                VStack(spacing: 8) {
                    // App name با گرادینت آبی-بنفش
                    Text("Balance")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: 0x667EEA),  // آبی
                                    Color(hex: 0x96a8fa)   // بنفش
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)
                    
                    // Tagline
                    Text("Control your spending, step by step")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(DS.Colors.subtext)
                        .offset(y: taglineOffset)
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Phase 1: Background circle (0-0.4s)
        withAnimation(.easeOut(duration: 0.8)) {
            circleScale = 1.0
            circleOpacity = 1.0
        }
        
        // Phase 2: Title slides up (0.3-1.0s)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75, blendDuration: 0).delay(0.3)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
        // Phase 3: Tagline fades in (0.6-1.2s)
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            taglineOffset = 0
            taglineOpacity = 1.0
        }
        
        // Phase 4: Hold for a moment, then dismiss (total: 2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                // Fade everything out
                titleOpacity = 0
                taglineOpacity = 0
                circleOpacity = 0
            }
            
            // Complete after fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onComplete()
            }
        }
    }
}

// MARK: - Dashboard

private struct DashboardView: View {
    @Binding var store: Store
    let goToBudget: () -> Void
    @State private var showAdd = false
    @State private var trendSelectedDay: Int? = nil
    @EnvironmentObject private var firestoreManager: FirestoreManager
    @EnvironmentObject private var authManager: AuthManager

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return fmt.string(from: store.selectedMonth)
    }

    private var todayDay: String {
        let cal = Calendar.current
        let day = cal.component(.day, from: Date())
        return "\(day)"
    }

    private func dateString(forDay day: Int) -> String {
        var cal = Calendar.current
        cal.locale = .current
        var comps = cal.dateComponents([.year, .month], from: store.selectedMonth)
        comps.day = day
        let d = cal.date(from: comps) ?? store.selectedMonth

        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("d MMM yyyy")
        return fmt.string(from: d)
    }
    
    @State private var showDeleteMonthConfirm = false
    @State private var showTrashAlert = false
    @State private var trashAlertText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header

                    if store.budgetTotal <= 0 {
                        SetupCard(goToBudget: goToBudget)
                    } else {
                        kpis
                        trendCard
                        categoryCard
                        paymentBreakdownCard  // ← جدید
                        advisorInsightsCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .navigationTitle(L10n.t("dashboard.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 🔴 دکمه حذف کل ماه (سمت چپ)
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // If there is nothing to delete for the selected month, show a message instead of asking again.
                        let hasTx = !Analytics.monthTransactions(store: store).isEmpty
                        let hasBudget = store.budgetTotal > 0
                        let hasCaps = store.totalCategoryBudgets() > 0
                        let hasAnything = hasTx || hasBudget || hasCaps

                        if hasAnything {
                            showDeleteMonthConfirm = true
                        } else {
                            trashAlertText = "This month has already been cleared. There is nothing left to delete."
                            showTrashAlert = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DS.Colors.danger)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete this month")
                }
                
                // 🔄 Sync Status (وسط)
                ToolbarItem(placement: .principal) {
                    SyncStatusView(firestoreManager: firestoreManager, store: $store)
                }

                // ➕ دکمه اضافه کردن (سمت راست – همونی که داشتی)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.medium()
                        if store.budgetTotal <= 0 {
                            goToBudget()
                        } else {
                            showAdd = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(DS.Colors.text)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add transaction")
                }
            }
        }
        .alert(L10n.t("dashboard.delete_month"), isPresented: $showDeleteMonthConfirm) {
            Button(L10n.t("common.delete"), role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    store.clearMonthData(for: store.selectedMonth)
                }
                
                // Save
                if let userId = authManager.currentUser?.uid {
                    store.save(userId: userId)
                    Task {
                        try? await firestoreManager.saveStore(store, userId: userId)
                    }
                }
                
                Haptics.success()
                trashAlertText = "This month's data has been successfully deleted"
                showTrashAlert = true
            }

            Button("common.cancel", role: .cancel) {}
        } message: {
            Text(L10n.t("dashboard.delete_month_msg"))
        }
        .alert(L10n.t("common.trash"), isPresented: $showTrashAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(trashAlertText)
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionSheet(store: $store, initialMonth: store.selectedMonth)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(todayDay)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(DS.Colors.text.opacity(1))

                            Text(monthTitle)
                                .font(DS.Typography.title)
                                .foregroundStyle(DS.Colors.text)
                        }
                        Text(L10n.t("dashboard.data_for_month"))
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                    }

                    Spacer()
                    MonthPicker(selectedMonth: $store.selectedMonth)
                }

                if store.budgetTotal <= 0 {
                    DS.StatusLine(
                        title: "Start from zero",
                        detail: "Set your monthly budget first. Analysis will start immediately.",
                        level: .watch
                    )
                } else {
                    if let capPressure = Analytics.categoryCapPressure(store: store) {
                        DS.StatusLine(title: capPressure.title, detail: capPressure.detail, level: capPressure.level)
                    } else {
                        let pressure = Analytics.budgetPressure(store: store)
                        DS.StatusLine(title: pressure.title, detail: pressure.detail, level: pressure.level)
                    }
                }
            }
        }
    }

    private var kpis: some View {
        let summary = Analytics.monthSummary(store: store)
        let isOverBudget = summary.remaining < 0
        
        return HStack(spacing: 12) {
            KPI(title: L10n.t("kpi.spent"), value: DS.Format.money(summary.totalSpent), isNegative: false)
                .frame(maxWidth: .infinity)
            KPI(title: L10n.t("kpi.remaining"), value: DS.Format.money(summary.remaining), isNegative: isOverBudget)
                .frame(maxWidth: .infinity)
            KPI(title: L10n.t("kpi.daily_avg"), value: DS.Format.money(summary.dailyAvg), isNegative: false)
                .frame(maxWidth: .infinity)
        }
    }

    private var trendCard: some View {
        let points = Analytics.dailySpendPoints(store: store)
        let daysWithTransactions = getDaysWithTransactions()
        
        return DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.t("dashboard.daily_trend"))
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)

                if points.isEmpty {
                    Text(L10n.t("dashboard.no_trend_data"))
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.subtext)
                        .padding(.vertical, 6)
                } else {
                    Chart {
                        // Area fill
                        ForEach(points) { p in
                            AreaMark(
                                x: .value("Day", p.day),
                                yStart: .value("Baseline", 0),
                                yEnd: .value("Amount", p.amount)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        DS.Colors.accent.opacity(0.3),
                                        DS.Colors.accent.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        
                        // Line
                        ForEach(points) { p in
                            LineMark(
                                x: .value("Day", p.day),
                                y: .value("Amount", p.amount)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(DS.Colors.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        
                        // Points for days with transactions
                        ForEach(points.filter { daysWithTransactions.contains($0.day) }) { p in
                            PointMark(
                                x: .value("Day", p.day),
                                y: .value("Amount", p.amount)
                            )
                            .foregroundStyle(DS.Colors.accent)
                            .symbolSize(30)  // ← کوچیک‌تر (قبلاً 80 بود)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 5)) { _ in
                            AxisGridLine()
                                .foregroundStyle(DS.Colors.grid.opacity(0.5))
                            AxisValueLabel()
                                .foregroundStyle(DS.Colors.subtext)
                                .font(DS.Typography.caption)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisGridLine()
                                .foregroundStyle(DS.Colors.grid.opacity(0.5))
                            AxisTick()
                                .foregroundStyle(DS.Colors.grid)
                            AxisValueLabel {
                                if let vInt = value.as(Int.self) {
                                    Text(DS.Format.money(vInt))
                                        .foregroundStyle(DS.Colors.subtext)
                                        .font(DS.Typography.caption)
                                } else if let v = value.as(Double.self) {
                                    Text(DS.Format.money(Int(v.rounded())))
                                        .foregroundStyle(DS.Colors.subtext)
                                        .font(DS.Typography.caption)
                                }
                            }
                        }
                    }
                    .chartOverlay { proxy in
                        trendChartOverlay(proxy: proxy)
                    }
                    .frame(height: 200)
                }
            }
        }
    }
    
    // Helper to get days with transactions
    private func getDaysWithTransactions() -> Set<Int> {
        let monthTx = Analytics.monthTransactions(store: store)
        let calendar = Calendar.current
        
        var days = Set<Int>()
        for tx in monthTx {
            let day = calendar.component(.day, from: tx.date)
            days.insert(day)
        }
        return days
    }
    
    @ViewBuilder
    private func trendChartOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            if let plotAnchor = proxy.plotFrame {
                let frame = geo[plotAnchor]
                
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(trendDragGesture(proxy: proxy, frame: frame))
                    
                    if let selDay = trendSelectedDay {
                        trendTooltipView(
                            proxy: proxy,
                            frame: frame,
                            geo: geo,
                            selectedDay: selDay
                        )
                    }
                }
            }
        }
    }
    
    private func trendDragGesture(proxy: ChartProxy, frame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let loc = value.location
                guard frame.contains(loc) else { return }
                let xInPlot = loc.x - frame.minX
                
                var newDay: Int?
                if let d: Int = proxy.value(atX: xInPlot) {
                    newDay = d
                } else if let d: Double = proxy.value(atX: xInPlot) {
                    newDay = Int(d.rounded())
                }
                
                if let newDay, newDay != trendSelectedDay {
                    trendSelectedDay = newDay
                    Haptics.selection()
                }
            }
            .onEnded { _ in
                trendSelectedDay = nil
            }
    }
    
    @ViewBuilder
    private func trendTooltipView(
        proxy: ChartProxy,
        frame: CGRect,
        geo: GeometryProxy,
        selectedDay: Int
    ) -> some View {
        let points = Analytics.dailySpendPoints(store: store)
        
        let nearest = points.min { a, b in
            abs(a.day - selectedDay) < abs(b.day - selectedDay)
        }
        
        if let p = nearest,
           let xPos = proxy.position(forX: p.day),
           let yPos = proxy.position(forY: p.amount) {
            
            let x = frame.minX + xPos
            let y = frame.minY + yPos
            
            Path { path in
                path.move(to: CGPoint(x: x, y: frame.minY))
                path.addLine(to: CGPoint(x: x, y: frame.maxY))
            }
            .stroke(DS.Colors.text.opacity(0.35), lineWidth: 1)
            
            Circle()
                .fill(DS.Colors.text.opacity(0.18))
                .frame(width: 18, height: 18)
                .position(x: x, y: y)
            
            Circle()
                .fill(DS.Colors.text)
                .frame(width: 7, height: 7)
                .position(x: x, y: y)
            
            tooltipCard(point: p, x: x, y: y, geo: geo, frame: frame)
        }
    }
    
    @ViewBuilder
    private func tooltipCard(
        point: Analytics.DayPoint,
        x: CGFloat,
        y: CGFloat,
        geo: GeometryProxy,
        frame: CGRect
    ) -> some View {
        let tooltipW: CGFloat = 170
        let pad: CGFloat = 10
        let tx = min(max(x + 14, pad + tooltipW / 2), geo.size.width - pad - tooltipW / 2)
        let ty = max(frame.minY + 12, y - 44)
        
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(L10n.t("budget.spent"))
                    .font(DS.Typography.caption.weight(.semibold))
                    .foregroundStyle(DS.Colors.text)
                Spacer()
                Text(DS.Format.money(point.amount))
                    .font(DS.Typography.caption.weight(.semibold))
                    .foregroundStyle(DS.Colors.text)
            }
            
            Text(dateString(forDay: point.day))
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.subtext)
        }
        .padding(10)
        .frame(width: tooltipW, alignment: .leading)
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
        .position(x: tx, y: ty)
    }


    private var categoryCard: some View {
        let breakdown = Analytics.categoryBreakdown(store: store)
        let monthTx = Analytics.monthTransactions(store: store)

        // Build a spent map so we can show category caps even if a category isn't in top breakdown.
        var spentByCategory: [Category: Int] = [:]
        for t in monthTx { spentByCategory[t.category, default: 0] += t.amount }

        // Rows to show under the chart:
        // 1) Top categories by spend (up to 6)
        // 2) Any category that has a cap set (even if spend is zero) so the cap UI always appears
        let topCats: [Category] = breakdown.prefix(6).map { $0.category }
        let cappedCats: [Category] = Category.allCases.filter { store.categoryBudget(for: $0) > 0 }
        let orderedCats: [Category] = Array(NSOrderedSet(array: topCats + cappedCats))
            .compactMap { $0 as? Category }

        return DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.t("dashboard.category_breakdown"))
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)

                if breakdown.isEmpty {
                    Text(L10n.t("dashboard.category_breakdown_empty"))
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.subtext)
                        .padding(.vertical, 6)
                } else {
                    Chart(breakdown) { row in
                        BarMark(
                            x: .value("Amount", row.total),
                            y: .value("Category", row.category.title)
                        )
                        .cornerRadius(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: 0x0E0E10), Color.white],  // مشکی → سفید
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine().foregroundStyle(DS.Colors.grid)
                            AxisValueLabel().foregroundStyle(DS.Colors.subtext)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel().foregroundStyle(DS.Colors.subtext)
                        }
                    }
                    .frame(height: CGFloat(breakdown.count) * 32 + 50)  // 32px per category, همه قابل دید

                    Divider().overlay(DS.Colors.grid)

                    VStack(spacing: 10) {
                        ForEach(orderedCats, id: \.self) { c in
                            let spent = spentByCategory[c] ?? 0
                            let cap = store.categoryBudget(for: c)

                            if cap > 0 {
                                CategoryCapRow(category: c, spent: spent, cap: cap)
                            } else if spent > 0 {
                                CategoryTotalRow(category: c, spent: spent)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var paymentBreakdownCard: some View {
        let breakdown = Analytics.paymentBreakdown(store: store)
        let total = breakdown.reduce(0) { $0 + $1.total }
        
        return DS.Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(L10n.t("dashboard.payment_breakdown"))
                        .font(DS.Typography.section)
                        .foregroundStyle(DS.Colors.text)
                    Spacer()
                    Text(L10n.t("dashboard.cash_vs_card"))
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                }
                
                if breakdown.isEmpty {
                    Text(L10n.t("dashboard.no_payment_data"))
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.subtext)
                        .padding(.vertical, 6)
                } else {
                    // کارت‌های عمودی compact
                    VStack(spacing: 10) {
                        ForEach(breakdown) { item in
                            HStack(spacing: 12) {
                                // بخش چپ: آیکون با گرادیانت
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [DS.Colors.surface, DS.Colors.text],  // مشکی → سفید (هر دو)
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 60, height: 60)  // 70 → 60
                                        .shadow(color: Color.white.opacity(0.15), radius: 10, x: 0, y: 4)
                                    
                                    VStack(spacing: 3) {
                                        Image(systemName: item.method.icon)
                                            .font(.system(size: 22, weight: .semibold))  // 24 → 22
                                            .foregroundStyle(Color.black)  // همه مشکی
                                        
                                        Text("\(Int(item.percentage * 100))%")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))  // 16 → 14
                                            .foregroundStyle(Color.black)  // همه مشکی
                                    }
                                }
                                
                                // بخش راست: اطلاعات
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Text(item.method.displayName)
                                            .font(DS.Typography.body.weight(.semibold))
                                            .foregroundStyle(DS.Colors.text)
                                        
                                        Spacer()
                                        
                                    Text("\(Int(item.percentage * 100))%")
                                            .font(DS.Typography.caption.weight(.bold))
                                            .foregroundStyle(DS.Colors.text)  // همه سفید
                                    }
                                    
                                    // Progress bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                                .fill(DS.Colors.surface2)
                                                .frame(height: 6)
                                            
                                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [DS.Colors.surface, DS.Colors.text],  // مشکی → سفید (هر دو)
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: geo.size.width * item.percentage, height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                    
                                    Text(DS.Format.money(item.total))
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundStyle(DS.Colors.text)  // همه سفید
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(DS.Colors.surface2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(DS.Colors.grid, lineWidth: 1)  // همه خاکستری
                            )
                        }
                    }
                    
                    Divider().overlay(DS.Colors.grid)
                    
                    // Insights
                    if let cashItem = breakdown.first(where: { $0.method == .cash }),
                       let cardItem = breakdown.first(where: { $0.method == .card }) {
                        
                        let cashPercent = Int(cashItem.percentage * 100)
                        let cardPercent = Int(cardItem.percentage * 100)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: 0xFFD93D))
                            
                            if cashPercent > 70 {
                                Text(L10n.t("dashboard.payment_insight_cash_heavy"))
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            } else if cardPercent > 70 {
                                Text(L10n.t("dashboard.payment_insight_card_heavy"))
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            } else {
                                Text(L10n.t("dashboard.payment_insight_balanced"))
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(hex: 0xFFD93D).opacity(0.1))
                        )
                    }
                }
            }
        }
    }

    private var advisorInsightsCard: some View {
        let insights = Analytics.generateInsights(store: store).prefix(5)
        return DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(L10n.t("dashboard.advisor_insights"))
                        .font(DS.Typography.section)
                        .foregroundStyle(DS.Colors.text)
                    Spacer()
                    Text(L10n.t("dashboard.honest_no_blame"))
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                }

                if insights.isEmpty {
                    Text(L10n.t("dashboard.add_expenses"))
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.subtext)
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(insights)) { insight in
                            InsightRow(insight: insight)
                        }
                    }
                }
            }
        }
    }
}

private struct SetupCard: View {
    let goToBudget: () -> Void

    var body: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.t("dashboard.step1_title"))
                    .font(DS.Typography.section)
                    .foregroundStyle(DS.Colors.text)

                Text(L10n.t("dashboard.step1_desc"))
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.subtext)

                Button {
                    goToBudget()
                } label: {
                    HStack {
                        Image(systemName: "target")
                        Text(L10n.t("dashboard.go_to_budget"))
                    }
                }
                .buttonStyle(DS.PrimaryButton())
            }
        }
    }
}

// MARK: - Transactions

private struct TransactionsView: View {
    @Binding var store: Store
    let goToBudget: () -> Void

    @State private var viewingAttachment: Transaction? = nil
    @State private var inspectingTransaction: Transaction? = nil  // ← جدید
    @State private var showAdd = false
    @State private var showRecurring = false  // ← جدید
    @State private var search = ""
    @State private var searchScope: SearchScope = .thisMonth  // ← جدید
    @State private var showFilters = false
    @State private var selectedCategories: Set<Category> = []
    @State private var selectedPaymentMethods: Set<PaymentMethod> = Set(PaymentMethod.allCases)  // ← همه انتخاب شده
    @State private var useDateRange = false
    @State private var dateFrom = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var dateTo = Date()
    @State private var minAmountText = ""
    @State private var maxAmountText = ""
    @State private var editingTxID: UUID? = nil
    @State private var showImport = false

    // --- Multi-select state for Transactions screen ---
    @State private var isSelecting = false
    @State private var selectedTxIDs: Set<UUID> = []
    
    // --- Undo delete ---
    @State private var pendingUndo: [Transaction] = []
    @State private var showUndoBar: Bool = false
    @State private var undoWorkItem: DispatchWorkItem? = nil
    private let undoDelay: TimeInterval = 4.0
    private let undoAnim: Animation = .spring(response: 0.45, dampingFraction: 0.90)
    
    enum SearchScope: String, CaseIterable {
        case thisMonth = "This Month"
        case allTime = "All Time"
    }
    
    private func scheduleUndoCommit() {
        undoWorkItem?.cancel()

        withAnimation(undoAnim) {
            showUndoBar = true
        }

        let item = DispatchWorkItem {
            withAnimation(undoAnim) {
                pendingUndo.removeAll()
                showUndoBar = false
            }
        }

        undoWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + undoDelay, execute: item)
    }

    private func undoDelete() {
        undoWorkItem?.cancel()
        withAnimation(uiAnim) {
            // Remove from deleted list
            for tx in pendingUndo {
                store.deletedTransactionIds.removeAll { $0 == tx.id.uuidString }
            }
            store.transactions.append(contentsOf: pendingUndo)
        }
        pendingUndo.removeAll()
        showUndoBar = false
    }

    private let uiAnim = Animation.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.0)

    private var filtered: [Transaction] {
        // Choose source based on search scope
        let sourceTx = searchScope == .thisMonth
            ? Analytics.monthTransactions(store: store)
            : store.transactions

        // Text search
        var out = sourceTx
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let s = trimmed.lowercased()
            out = out.filter { $0.note.lowercased().contains(s) || $0.category.title.lowercased().contains(s) }
        }

        // Category filter
        if selectedCategories.count != store.allCategories.count {
            out = out.filter { selectedCategories.contains($0.category) }
        }
        
        // Payment method filter - فقط اگه همه انتخاب نشده باشن
        if !selectedPaymentMethods.isEmpty && selectedPaymentMethods.count != PaymentMethod.allCases.count {
            out = out.filter { selectedPaymentMethods.contains($0.paymentMethod) }
        }

        // Amount range filter (values are stored in euro cents)
        let minCents = DS.Format.cents(from: minAmountText)
        let maxCents = DS.Format.cents(from: maxAmountText)
        if minCents > 0 {
            out = out.filter { $0.amount >= minCents }
        }
        if maxCents > 0 {
            out = out.filter { $0.amount <= maxCents }
        }

        // Date range filter
        if useDateRange {
            let cal = Calendar.current
            let start = cal.startOfDay(for: dateFrom)
            // Include the entire end day
            let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: dateTo)) ?? dateTo
            out = out.filter { $0.date >= start && $0.date < end }
        }

        return out.sorted { $0.date > $1.date }  // Sort by date descending
    }

    private var activeFilterCount: Int {
        var n = 0
        if selectedCategories.count != store.allCategories.count { n += 1 }
        if !selectedPaymentMethods.isEmpty && selectedPaymentMethods.count != PaymentMethod.allCases.count { n += 1 }  // ← درست شد
        if useDateRange { n += 1 }
        if DS.Format.cents(from: minAmountText) > 0 || DS.Format.cents(from: maxAmountText) > 0 { n += 1 }
        return n
    }

    // --- Add state for pending delete confirmation (anchored to row)
    @State private var pendingDeleteID: UUID? = nil

    // Helper binding for single row delete confirmation dialog
    private var isRowDeleteDialogPresented: Binding<Bool> {
        Binding(
            get: { pendingDeleteID != nil },
            set: { presenting in
                if !presenting { pendingDeleteID = nil }
            }
        )
    }

    // Helper binding for bulk delete confirmation dialog
    private var isBulkDeleteDialogPresented: Binding<Bool> {
        Binding(
            get: { showBulkDeletePopover && isSelecting && !selectedTxIDs.isEmpty },
            set: { presenting in
                if !presenting { showBulkDeletePopover = false }
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()

                if store.budgetTotal <= 0 {
                    noBudgetView
                } else {
                    transactionsListView
                }
            }
            .navigationTitle(L10n.t("transactions.title"))
            .navigationTitle(L10n.t("transactions.title"))
            
            .toolbar { toolbarItems }
            .searchable(text: $search, prompt: L10n.t("transactions.search_placeholder"))
            .confirmationDialog(
                "Delete \(selectedTxIDs.count) transactions?",
                isPresented: isBulkDeleteDialogPresented,
                titleVisibility: .visible
            ) {
                Button(L10n.t("common.delete"), role: .destructive) {
                    // Capture selection first
                    let ids = selectedTxIDs

                    // stash for undo
                    pendingUndo = store.transactions.filter { ids.contains($0.id) }

                    // Dismiss dialog + exit selecting mode BEFORE mutating the list
                    showBulkDeletePopover = false
                    isSelecting = false
                    selectedTxIDs.removeAll()

                    withAnimation(uiAnim) {
                        // Track deleted IDs for sync
                        for id in ids {
                            if !store.deletedTransactionIds.contains(id.uuidString) {
                                store.deletedTransactionIds.append(id.uuidString)
                            }
                        }
                        store.transactions.removeAll { ids.contains($0.id) }
                    }
                    scheduleUndoCommit()
                }
                Button("common.cancel", role: .cancel) {
                    showBulkDeletePopover = false
                }
            } message: {
                Text("This action can’t be undone.")
            }
            .navigationDestination(isPresented: $showImport) {
                ImportTransactionsScreen(store: $store)
            }

        }
        .onAppear {
            // Default: select all (including custom categories)
            if selectedCategories.isEmpty {
                selectedCategories = Set(store.allCategories)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionSheet(store: $store, initialMonth: store.selectedMonth)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: editingWrapper) { wrapper in
            EditTransactionSheet(store: $store, transactionID: wrapper.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: Binding(
            get: { viewingAttachment },
            set: { viewingAttachment = $0 }
        )) { transaction in
            if let data = transaction.attachmentData, let type = transaction.attachmentType {
                AttachmentViewer(attachmentData: data, attachmentType: type)
            }
        }
        .sheet(item: Binding(
            get: { inspectingTransaction },
            set: { inspectingTransaction = $0 }
        )) { transaction in
            TransactionInspectSheet(transaction: transaction, store: $store)
        }
        .sheet(isPresented: $showRecurring) {
            RecurringTransactionsView(store: $store)
        }
        .fullScreenCover(isPresented: $showFilters) {
            TransactionsFilterSheet(
                selectedCategories: $selectedCategories,
                categories: store.allCategories,
                useDateRange: $useDateRange,
                dateFrom: $dateFrom,
                dateTo: $dateTo,
                minAmountText: $minAmountText,
                maxAmountText: $maxAmountText,
                selectedPaymentMethods: $selectedPaymentMethods  // ← جدید
            )
        }
        
    }
    
    // MARK: - Helper Views
    
    private var noBudgetView: some View {
        ScrollView {
            VStack(spacing: 14) {
                DS.Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.t("transactions.before_add"))
                            .font(DS.Typography.section)
                            .foregroundStyle(DS.Colors.text)

                        Text(L10n.t("transactions.set_budget_first"))
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.subtext)

                        Button {
                            goToBudget()
                        } label: {
                            HStack {
                                Image(systemName: "target")
                                Text(L10n.t("transactions.set_budget_btn"))
                            }
                        }
                        .buttonStyle(DS.PrimaryButton())
                    }
                }
            }
            .padding(16)
        }
    }
    
    private var transactionsListView: some View {
        List {
            if filtered.isEmpty {
                emptyStateView
            } else {
                transactionsList
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
        .animation(uiAnim, value: filtered)
        .animation(uiAnim, value: activeFilterCount)
        .animation(uiAnim, value: store.transactions)
        .onChange(of: search) { oldValue, newValue in
            // Reset to This Month when search is cleared
            if newValue.isEmpty && searchScope == .allTime {
                searchScope = .thisMonth
            }
        }
        .confirmationDialog(
            "transactions.delete_confirm",
            isPresented: isRowDeleteDialogPresented,
            titleVisibility: .visible
        ) {
            deleteDialogButtons
        } message: {
            Text(L10n.t("transactions.cannot_undo"))
        }
        .safeAreaInset(edge: .bottom) {
            if showUndoBar {
                undoBar
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.t("transactions.no_transactions"))
                .font(DS.Typography.section)
                .foregroundStyle(DS.Colors.text)
            Text(L10n.t("transactions.start_simple"))
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.subtext)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(DS.Colors.bg)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var transactionsList: some View {
        Group {
            // Search Scope Selector (if searching)
            if !search.isEmpty {
                Section {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(SearchScope.allCases, id: \.self) { scope in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        searchScope = scope
                                    }
                                    Haptics.selection()
                                } label: {
                                    Text(scope.rawValue)
                                        .font(.system(size: 13, weight: searchScope == scope ? .semibold : .medium))
                                        .foregroundStyle(searchScope == scope ? .black : DS.Colors.text)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            searchScope == scope ?
                                            Color.white :
                                            DS.Colors.surface2,
                                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Spacer()
                            
                            // Result count
                            Text("\(filtered.count) \(filtered.count == 1 ? "result" : "results")")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(DS.Colors.bg)
            }
            
            // Transactions grouped by day
            ForEach(Analytics.groupedByDay(filtered), id: \.day) { group in
                Section {
                    ForEach(group.items) { t in
                        transactionRowView(for: t)
                    }
                } header: {
                    Text(group.title)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                }
            }
        }
    }
    
    @ViewBuilder
    private func transactionRowView(for t: Transaction) -> some View {
        HStack(spacing: 10) {
            if isSelecting {
                selectionCheckmark(for: t)
            }
            
            TransactionRow(t: t)
                .contentShape(Rectangle())
                .onTapGesture {
                    handleRowTap(for: t)
                }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
        .contextMenu {
            contextMenuButtons(for: t)
        } preview: {
            TransactionInspectPreview(transaction: t)
        }
    }
    
    @ViewBuilder
    private func selectionCheckmark(for t: Transaction) -> some View {
        Image(systemName: selectedTxIDs.contains(t.id) ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(selectedTxIDs.contains(t.id) ? DS.Colors.positive : DS.Colors.subtext)
            .font(.system(size: 18))
            .onTapGesture {
                toggleSelection(for: t.id)
            }
    }
    
    @ViewBuilder
    private func contextMenuButtons(for t: Transaction) -> some View {
        Button {
            inspectingTransaction = t  // ← باز کردن صفحه کامل
        } label: {
            Label("Inspect", systemImage: "info.circle")
        }
        
        if t.attachmentData != nil, t.attachmentType != nil {
            Button {
                viewingAttachment = t
            } label: {
                Label(L10n.t("transactions.view_attachment"), systemImage: "paperclip")
            }
        }
        
        Button {
            withAnimation(uiAnim) {
                editingTxID = t.id
            }
        } label: {
            Label(L10n.t("transactions.edit"), systemImage: "pencil")
        }

        Button(role: .destructive) {
            pendingDeleteID = t.id
        } label: {
            Label(L10n.t("common.delete"), systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private var deleteDialogButtons: some View {
        Button(L10n.t("common.delete"), role: .destructive) {
            let id = pendingDeleteID
            pendingDeleteID = nil

            guard let id,
                  let tx = store.transactions.first(where: { $0.id == id }) else { return }

            Haptics.transactionDeleted()  // ← هاپتیک
            pendingUndo = [tx]
            withAnimation(uiAnim) {
                // Track deleted ID for sync
                if !store.deletedTransactionIds.contains(id.uuidString) {
                    store.deletedTransactionIds.append(id.uuidString)
                }
                store.transactions.removeAll { $0.id == id }
            }
            scheduleUndoCommit()
        }
        Button("common.cancel", role: .cancel) {
            pendingDeleteID = nil
        }
    }
    
    private var undoBar: some View {
        HStack {
            Text("\(pendingUndo.count) transaction deleted")
                .foregroundStyle(DS.Colors.text)

            Spacer()

            Button("Undo") {
                undoDelete()
            }
            .foregroundStyle(DS.Colors.positive)
        }
        .padding()
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .scaleEffect(0.98)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Helper Functions
    
    private func handleRowTap(for t: Transaction) {
        guard isSelecting else { return }
        toggleSelection(for: t.id)
    }
    
    private func toggleSelection(for id: UUID) {
        if selectedTxIDs.contains(id) {
            selectedTxIDs.remove(id)
        } else {
            selectedTxIDs.insert(id)
        }
        Haptics.selection()
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            leadingToolbar
        }
        ToolbarItem(placement: .topBarTrailing) {
            trailingToolbar
        }
    }

    @ViewBuilder
    private var leadingToolbar: some View {
        if isSelecting {
            Button(L10n.t("common.cancel")) {
                isSelecting = false
                selectedTxIDs.removeAll()
                showBulkDeletePopover = false
            }
            .foregroundStyle(DS.Colors.subtext)

            Button(L10n.t("common.delete")) {
                guard !selectedTxIDs.isEmpty else { return }
                showBulkDeletePopover = true
            }
            .buttonStyle(.plain)
            .foregroundStyle(DS.Colors.danger)
            .disabled(selectedTxIDs.isEmpty)
        } else {
            Button(L10n.t("transactions.select")) {
                isSelecting = true
                Haptics.selection()
            }
            .foregroundStyle(DS.Colors.subtext)
        }
    }

    @ViewBuilder
    private var trailingToolbar: some View {
        if isSelecting {
            Button(L10n.t("transactions.select_all")) {
                selectedTxIDs = Set(filtered.map { $0.id })
                Haptics.selection()
            }
            .foregroundStyle(DS.Colors.subtext)
        } else {
            TransactionsTrailingButtons(
                filtersActive: activeFilterCount > 0,
                showImport: $showImport,
                showFilters: $showFilters,
                showAdd: $showAdd,
                showRecurring: $showRecurring,  // ← جدید
                disabled: store.budgetTotal <= 0,
                uiAnim: uiAnim
            )
            .padding(.trailing, 6)
        }
    }

    // Helper binding for .sheet(item:) for edit transaction
    private var editingWrapper: Binding<UUIDWrapper?> {
        Binding<UUIDWrapper?>(
            get: { editingTxID.map { UUIDWrapper(id: $0) } },
            set: { editingTxID = $0?.id }
        )
    }
    // Add new state property for bulk delete popover
    @State private var showBulkDeletePopover = false
}

private struct TransactionsTrailingButtons: View {
    let filtersActive: Bool
    @Binding var showImport: Bool
    @Binding var showFilters: Bool
    @Binding var showAdd: Bool
    @Binding var showRecurring: Bool  // ← جدید
    let disabled: Bool
    let uiAnim: Animation

    var body: some View {
        HStack(spacing: 12) {
            // Recurring button
            Button {
                Haptics.light()
                showRecurring = true
            } label: {
                Image(systemName: "repeat.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Colors.text)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            
            Button { showImport = true } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Colors.text)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(disabled)

            Button { showFilters = true } label: {
                ZStack {
                    // Badge برای فیلتر فعال
                    if filtersActive {
                        Circle()
                            .fill(DS.Colors.positive)
                            .frame(width: 36, height: 36)
                    }
                    
                    Image(systemName: filtersActive
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(filtersActive ? Color.black : DS.Colors.text)
                }
                .frame(width: 36, height: 36)
                .animation(uiAnim, value: filtersActive)
            }
            .buttonStyle(.plain)
            .disabled(disabled)

            Button { showAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DS.Colors.text)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
    }
}

private struct ImportTransactionsSheet: View {
    @Binding var store: Store

    var body: some View {
        ImportTransactionsScreen(store: $store)
    }
}

private struct TransactionsFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedCategories: Set<Category>
    let categories: [Category]
    @Binding var useDateRange: Bool
    @Binding var dateFrom: Date
    @Binding var dateTo: Date
    @Binding var minAmountText: String
    @Binding var maxAmountText: String
    @Binding var selectedPaymentMethods: Set<PaymentMethod>  // ← جدید

    private var allSelected: Bool { selectedCategories.count == categories.count }
    private var allPaymentMethodsSelected: Bool { selectedPaymentMethods.count == PaymentMethod.allCases.count }  // ← جدید
    private let uiAnim = Animation.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.0)

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(L10n.t("filters.categories"))
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Button(allSelected ? "Clear" : "All") {
                                        withAnimation(uiAnim) {
                                            if allSelected {
                                                selectedCategories = []
                                            } else {
                                                selectedCategories = Set(categories)
                                            }
                                        }
                                    }
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                    .buttonStyle(.plain)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(categories, id: \.self) { c in
                                            let isOn = selectedCategories.contains(c)
                                            Button {
                                                withAnimation(uiAnim) {
                                                    if isOn {
                                                        selectedCategories.remove(c)
                                                    } else {
                                                        selectedCategories.insert(c)
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 8) {
                                                    Image(systemName: c.icon)
                                                    Text(c.title)
                                                }
                                                .font(DS.Typography.caption)
                                                .foregroundStyle(isOn ? DS.Colors.text : DS.Colors.subtext)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 9)
                                                .background(
                                                    (isOn ? c.tint.opacity(0.18) : DS.Colors.surface2),
                                                    in: RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                        .stroke(DS.Colors.grid, lineWidth: 1)
                                                )
                                                .animation(uiAnim, value: selectedCategories)
                                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                if selectedCategories.isEmpty {
                                    Text(L10n.t("filters.tip_one_category"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                }
                            }
                        }

                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(L10n.t("filters.payment_methods"))
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Button {
                                        Haptics.selection()
                                        withAnimation(uiAnim) {
                                            if allPaymentMethodsSelected {
                                                selectedPaymentMethods = []
                                            } else {
                                                selectedPaymentMethods = Set(PaymentMethod.allCases)
                                            }
                                        }
                                    } label: {
                                        Text(allPaymentMethodsSelected ? "Clear" : "All")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                    .buttonStyle(.plain)
                                }

                                HStack(spacing: 12) {
                                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                                        let isOn = selectedPaymentMethods.contains(method)
                                        Button {
                                            withAnimation(uiAnim) {
                                                if isOn {
                                                    selectedPaymentMethods.remove(method)
                                                } else {
                                                    selectedPaymentMethods.insert(method)
                                                }
                                                Haptics.selection()
                                            }
                                        } label: {
                                            HStack(spacing: 8) {
                                                ZStack {
                                                    if isOn {
                                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                            .fill(
                                                                LinearGradient(
                                                                    colors: method.gradientColors,
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                            )
                                                            .frame(width: 32, height: 32)
                                                    } else {
                                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                            .fill(method.accentColor.opacity(0.12))
                                                            .frame(width: 32, height: 32)
                                                    }
                                                    
                                                    Image(systemName: method.icon)
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundStyle(isOn ? .white : method.accentColor)
                                                }
                                                
                                                Text(method.displayName)
                                                    .font(DS.Typography.body.weight(isOn ? .semibold : .regular))
                                            }
                                            .foregroundStyle(isOn ? DS.Colors.text : DS.Colors.subtext)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                isOn ? DS.Colors.surface2 : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(
                                                        isOn ? method.accentColor.opacity(0.3) : DS.Colors.grid,
                                                        lineWidth: isOn ? 2 : 1
                                                    )
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                if selectedPaymentMethods.isEmpty {
                                    Text(L10n.t("filters.tip_one_payment_method"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                }
                            }
                        }

                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(L10n.t("filters.date_range"))
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Toggle("", isOn: $useDateRange)
                                        .onChange(of: useDateRange) { _, _ in
                                            withAnimation(uiAnim) { }
                                        }
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: 0x3A3A3C)))
                                        .animation(uiAnim, value: useDateRange)
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(useDateRange ? Color.clear : DS.Colors.surface2.opacity(0.6))
                                )

                                if useDateRange {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(L10n.t("filters.from"))
                                                .font(DS.Typography.caption)
                                                .foregroundStyle(DS.Colors.subtext)
                                            DatePicker("", selection: $dateFrom, displayedComponents: [.date])
                                                .labelsHidden()
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(L10n.t("filters.to"))
                                                .font(DS.Typography.caption)
                                                .foregroundStyle(DS.Colors.subtext)
                                            DatePicker("", selection: $dateTo, displayedComponents: [.date])
                                                .labelsHidden()
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                } else {
                                    Text(L10n.t("filters.date_range_off"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                        .transition(.opacity)
                                }
                            }
                        }

                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.t("filters.amount_range"))
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(L10n.t("filters.min"))
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        TextField("0.00", text: $minAmountText)
                                            .keyboardType(.decimalPad)
                                            .font(DS.Typography.number)
                                            .padding(10)
                                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(DS.Colors.grid, lineWidth: 1)
                                            )
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(L10n.t("filters.max"))
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        TextField("0.00", text: $maxAmountText)
                                            .keyboardType(.decimalPad)
                                            .font(DS.Typography.number)
                                            .padding(10)
                                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(DS.Colors.grid, lineWidth: 1)
                                            )
                                    }
                                }

                                Text(L10n.t("filters.amount_example"))
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }

                        HStack(spacing: 12) {
                            Button {
                                withAnimation(uiAnim) {
                                    selectedCategories = Set(categories)
                                    selectedPaymentMethods = Set(PaymentMethod.allCases)  // ← فیکس
                                    useDateRange = false
                                    dateFrom = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
                                    dateTo = Date()
                                    minAmountText = ""
                                    maxAmountText = ""
                                }
                                Haptics.success()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text(L10n.t("filters.reset"))
                                }
                            }
                            .buttonStyle(DS.PrimaryButton())

                            Button {
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(L10n.t("filters.apply"))
                                }
                            }
                            .buttonStyle(DS.PrimaryButton())
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(DS.Colors.subtext)
                }
            }
        }
    }
}

// MARK: - Budget

private struct BudgetView: View {
    @Binding var store: Store

    @State private var editingTotal = ""
    @State private var editingCategoryBudgets: [Category: String] = [:]
    @FocusState private var focus: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    DS.Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.t("budget.set_monthly"))
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)

                            Text(L10n.t("budget.keep_realistic"))
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.subtext)

                            HStack(spacing: 10) {
                                TextField("e.g. 3000.00", text: $editingTotal)
                                    .keyboardType(.decimalPad)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focus)
                                    .font(DS.Typography.number)
                                    .padding(11)
                                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(DS.Colors.grid, lineWidth: 1)
                                    )

                                Button(store.budgetTotal <= 0 ? "Start" : "Update") {
                                    let v = DS.Format.cents(from: editingTotal)
                                    store.budgetTotal = max(0, v)
                                    focus = false
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .frame(width: 140)
                            }

                            if store.budgetTotal <= 0 {
                                DS.StatusLine(
                                    title: L10n.t("status.analysis_paused"),
                                    detail: L10n.t("status.analysis_paused_desc"),
                                    level: .watch
                                )
                            } else {
                                DS.StatusLine(
                                    title: L10n.t("status.budget_set"),
                                    detail: L10n.t("status.budget_set_desc"),
                                    level: .ok
                                )
                            }
                        }
                    }

                    if store.budgetTotal > 0 {
                        DS.Card {
                            let summary = Analytics.monthSummary(store: store)
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.t("month.this_month"))
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                DS.Meter(
                                    title: "Budget used",
                                    value: summary.totalSpent,
                                    max: max(1, store.budgetTotal),
                                    hint: "\(DS.Format.percent(summary.spentRatio)) used"
                                )

                                Divider().overlay(DS.Colors.grid)

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L10n.t("budget.spent"))
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        Text(DS.Format.money(summary.totalSpent))
                                            .font(DS.Typography.number)
                                            .foregroundStyle(DS.Colors.text)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(L10n.t("budget.remaining"))
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        Text(DS.Format.money(summary.remaining))
                                            .font(DS.Typography.number)
                                            .foregroundStyle(summary.remaining >= 0 ? DS.Colors.text : DS.Colors.danger)
                                    }
                                }

                                // Saved metrics (shown below the main row)
                                Divider().overlay(DS.Colors.grid)

                                VStack(alignment: .leading, spacing: 6) {
                                    let delta = store.savedDeltaVsPreviousMonth(for: store.selectedMonth)
                                    let isNegative = delta < 0

                                    HStack {
                                        Text("Saved vs last month")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        Spacer()
                                        Text("\(delta >= 0 ? "+" : "")\(DS.Format.money(delta))")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(isNegative ? DS.Colors.danger : DS.Colors.positive)
                                    }

                                    HStack {
                                        Text("Total saved so far")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        Spacer()
                                        Text(DS.Format.money(store.totalSaved))
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(store.totalSaved < 0 ? DS.Colors.danger : DS.Colors.positive)
                                    }
                                }
                            }
                        }
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.t("budget.category_budgets"))
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                Text(L10n.t("budget.category_caps_desc"))
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)

                                Divider().overlay(DS.Colors.grid)

                                VStack(spacing: 10) {
                                    ForEach(categories, id: \.self) { c in
                                        HStack(spacing: 10) {
                                            HStack(spacing: 8) {
                                                Circle()
                                                    .fill(c.tint.opacity(0.18))
                                                    .frame(width: 26, height: 26)
                                                    .overlay(
                                                        Image(systemName: c.icon)
                                                            .foregroundStyle(c.tint)
                                                            .font(.system(size: 12, weight: .semibold))
                                                    )
                                                Text(c.title)
                                                    .font(DS.Typography.body)
                                                    .foregroundStyle(DS.Colors.text)
                                            }
                                            Spacer()

                                            TextField("0.00", text: Binding(
                                                get: { editingCategoryBudgets[c] ?? "" },
                                                set: { newVal in
                                                    editingCategoryBudgets[c] = newVal
                                                    let v = DS.Format.cents(from: newVal)
                                                    store.setCategoryBudget(v, for: c)
                                                }
                                            ))
                                            .keyboardType(.decimalPad)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .multilineTextAlignment(.trailing)
                                            .font(DS.Typography.number)
                                            .padding(10)
                                            .frame(width: 120)
                                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(DS.Colors.grid, lineWidth: 1)
                                            )
                                        }
                                    }
                                }

                                Divider().overlay(DS.Colors.grid)

                                let allocated = store.totalCategoryBudgets()
                                let remainingToAllocate = store.budgetTotal - allocated

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L10n.t("budget.allocated"))
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        Text(DS.Format.money(allocated))
                                            .font(DS.Typography.number)
                                            .foregroundStyle(DS.Colors.text)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(L10n.t("budget.unallocated"))
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                        Text(DS.Format.money(remainingToAllocate))
                                            .font(DS.Typography.number)
                                            .foregroundStyle(remainingToAllocate >= 0 ? DS.Colors.text : DS.Colors.danger)
                                    }
                                }

                                if allocated > store.budgetTotal {
                                    DS.StatusLine(
                                        title: "Category caps exceed total budget",
                                        detail: "Reduce one or more category budgets so allocation stays within the monthly total.",
                                        level: .watch
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .navigationTitle(L10n.t("budget.this_month"))
            .onAppear {
                editingTotal = store.budgetTotal > 0
                    ? String(format: "%.2f", Double(store.budgetTotal) / 100.0)
                    : ""
                var map: [Category: String] = [:]
                for c in Category.allCases {
                    let v = store.categoryBudget(for: c)
                    map[c] = v > 0 ? String(format: "%.2f", Double(v) / 100.0) : ""
                }
                editingCategoryBudgets = map
            }
        }
    }
}

// MARK: - Insights

private struct InsightsView: View {
    @Binding var store: Store
    let goToBudget: () -> Void
    @State private var showAI: Bool = false
    @State private var showAdvancedCharts: Bool = false
    
    @AppStorage("notifications.enabled") private var notificationsEnabled: Bool = false
    @State private var notifDetail: String? = nil
    
    @State private var shareURL: URL? = nil
    @State private var showShareSheet: Bool = false

    private struct TrendPoint: Identifiable {
        let id: Int          // day of month
        let euros: Double
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if store.budgetTotal <= 0 {
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.t("insights.not_ready"))
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                Text(L10n.t("insights.set_budget_first"))
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)

                                Button { goToBudget() } label: {
                                    HStack {
                                        Image(systemName: "target")
                                        Text(L10n.t("transactions.set_budget_btn"))
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                            }
                        }
                    } else {
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.t("insights.analytical_report"))
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                let proj = Analytics.projectedEndOfMonth(store: store)
                                let title =
                                    proj.level == .risk
                                    ? "This trend will pressure your budget"
                                    : "Approaching the limit"

                                let detail =
                                    proj.level == .risk
                                    ? "End-of-month projection is above budget. Prioritize cutting discretionary costs."
                                    : "To stay in control, trim one discretionary category slightly."

                                DS.StatusLine(
                                    title: title,
                                    detail: detail,
                                    level: proj.level
                                )
                                Text(L10n.t("insights.projection_note"))
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }

                        let insights = Analytics.generateInsights(store: store)
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Insights")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                if insights.isEmpty {
                                    Text(L10n.t("insights.no_data"))
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.subtext)
                                        .padding(.vertical, 6)
                                } else {
                                    VStack(spacing: 10) {
                                        ForEach(insights) { insight in
                                            InsightRow(insight: insight)
                                        }
                                    }
                                }
                            }
                        }
                        
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(L10n.t("insights.notifications"))
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Toggle("", isOn: $notificationsEnabled)
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: 0x3A3A3C)))
                                }

                                Text(L10n.t("insights.notifications_desc"))
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)

                                if let notifDetail {
                                    DS.StatusLine(
                                        title: "Notification status",
                                        detail: notifDetail,
                                        level: notificationsEnabled ? .ok : .watch
                                    )
                                }

                                Button {
                                    Task { await sendTestNotification() }
                                } label: {
                                    HStack {
                                        Image(systemName: "bell.badge")
                                        Text(L10n.t("insights.send_test"))
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .disabled(!notificationsEnabled)

                                Text(L10n.t("insights.test_tip"))
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }
                        
                        
                        
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(L10n.t("insights.export"))
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Text(L10n.t("insights.export_share"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                }

                                Text(L10n.t("insights.export_desc"))
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)

                                HStack(spacing: 10) {
                                    Button {
                                        Haptics.medium()
                                        exportMonth(format: .excel)
                                    } label: {
                                        HStack {
                                            Image(systemName: "tablecells")
                                            Text(L10n.t("insights.export_excel"))
                                        }
                                    }
                                    .buttonStyle(DS.PrimaryButton())

                                    Button {
                                        Haptics.medium()
                                        exportMonth(format: .csv)
                                    } label: {
                                        HStack {
                                            Image(systemName: "doc.plaintext")
                                            Text(L10n.t("insights.export_csv"))
                                        }
                                    }
                                    .buttonStyle(DS.PrimaryButton())
                                }
                                
                                Button {
                                    Haptics.medium()
                                    exportMonth(format: .pdf)
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.richtext")
                                        Text(L10n.t("insights.export_pdf"))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(DS.PrimaryButton())

                                Text(L10n.t("insights.export_tip"))
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }
                        
                        
                        // Advanced Charts
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "chart.xyaxis.line")
                                        .font(.system(size: 18))
                                        .foregroundStyle(DS.Colors.accent)
                                    
                                    Text(L10n.t("charts.title"))
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                }
                                
                                Text("View spending trends, category distribution, and monthly comparisons")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                Button {
                                    Haptics.light()
                                    showAdvancedCharts = true
                                } label: {
                                    HStack {
                                        Image(systemName: "chart.bar.xaxis")
                                        Text("View Advanced Charts")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(DS.PrimaryButton())
                            }
                        }
                        
                        
                        

                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(L10n.t("insights.ai_analysis"))
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Text(L10n.t("insights.ai_powered"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                }

                                Text(L10n.t("insights.ai_desc"))
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.subtext)

                                Button {
                                    showAI = true
                                } label: {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                        Text(L10n.t("insights.ai_analyze"))
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                            }
                        }
                        .sheet(isPresented: $showAI) {
                            AIInsightsView(store: $store)
                                .presentationDetents([.large])
                                .presentationDragIndicator(.visible)
                        }

                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.t("dashboard.quick_actions"))
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                let actions = Analytics.quickActions(store: store)
                                if actions.isEmpty {
                                    Text(L10n.t("dashboard.no_action_needed"))
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.subtext)
                                        .padding(.vertical, 6)
                                } else {
                                    VStack(spacing: 10) {
                                        ForEach(actions, id: \.self) { a in
                                            HStack(alignment: .top, spacing: 10) {
                                                Image(systemName: "checkmark.seal")
                                                    .foregroundStyle(DS.Colors.text)
                                                Text(a)
                                                    .font(DS.Typography.body)
                                                    .foregroundStyle(DS.Colors.text)
                                                Spacer(minLength: 0)
                                            }
                                            .padding(12)
                                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(DS.Colors.grid, lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .navigationTitle(L10n.t("tab.insights"))
            .onChange(of: notificationsEnabled) { _, newVal in
                if newVal {
                    Task {
                        await requestNotificationPermissionIfNeeded()
                        // Once permission is granted, schedule recurring reminders and evaluate rules.
                        await Notifications.syncAll(store: store)
                    }
                } else {
                    // Turning off only disables in-app usage; iOS-level permission stays in Settings.
                    notifDetail = "Notifications are turned off in the app."
                    Notifications.cancelAll()
                }
            }
            .onAppear {
                // Allow notifications to show even when the app is open (foreground).
                UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared

                if notificationsEnabled {
                    Task {
                        // Keep schedules fresh when returning to this screen.
                        await Notifications.syncAll(store: store)
                    }
                }
            }
            .onChange(of: store) { _, _ in
                // Re-evaluate smart rules as data changes (budget/transactions/etc.).
                guard notificationsEnabled else { return }
                Task { await Notifications.evaluateSmartRules(store: store) }
            }
            
            .sheet(isPresented: $showShareSheet) {
                if let shareURL {
                    ShareSheet(items: [shareURL])
                        .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showAdvancedCharts) {
                AdvancedChartsView(store: $store)
            }
        }
    }


    private func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                notifDetail = "Enabled. You can send a test notification now."
            }
            await Notifications.syncAll(store: store)
        case .denied:
            await MainActor.run {
                notificationsEnabled = false
                notifDetail = "Notifications are blocked in iOS Settings for this app. Enable them in Settings → Notifications."
            }
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                await MainActor.run {
                    if granted {
                        notifDetail = "Permission granted. Tap ‘Send test notification’."
                    } else {
                        notificationsEnabled = false
                        notifDetail = "Permission not granted. Toggle stayed off."
                    }
                }
                if granted {
                    await Notifications.syncAll(store: store)
                }
            } catch {
                await MainActor.run {
                    notificationsEnabled = false
                    notifDetail = "Couldn’t request permission: \(error.localizedDescription)"
                }
            }
        @unknown default:
            await MainActor.run {
                notifDetail = "Unknown notification status."
            }
        }
    }

    private func sendTestNotification() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        guard notificationsEnabled else {
            await MainActor.run { notifDetail = "Turn notifications on first." }
            return
        }

        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else {
            await MainActor.run {
                notificationsEnabled = false
                notifDetail = "Notifications are not authorized. Please enable them in iOS Settings."
            }
            return
        }

        center.removePendingNotificationRequests(withIdentifiers: ["balance.test.notification"])

        let content = UNMutableNotificationContent()
        content.title = "Balance — Test"
        content.body = "This is a test notification. If you see this, notifications are working."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let req = UNNotificationRequest(identifier: "balance.test.notification", content: content, trigger: trigger)

        do {
            try await center.add(req)
            await MainActor.run {
                notifDetail = "Test notification scheduled (in ~3 seconds)."
            }
        } catch {
            await MainActor.run {
                notifDetail = "Failed to schedule notification: \(error.localizedDescription)"
            }
        }
    }
    
    private enum ExportFormat {
        case csv
        case excel
        case pdf  // ← جدید

        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .excel: return "xlsx"
            case .pdf: return "pdf"
            }
        }
    }

    private func exportMonth(format: ExportFormat) {
        let summary = Analytics.monthSummary(store: store)
        let tx = Analytics.monthTransactions(store: store)
        let dailyPoints = Analytics.dailySpendPoints(store: store)
        let cats = Analytics.categoryBreakdown(store: store)

        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: store.selectedMonth)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let monthKey = String(format: "%04d-%02d", y, m)

        let filename = "Balance_\(monthKey).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            let data: Data
            switch format {
            case .csv:
                let csv = Exporter.makeCSV(
                    monthKey: monthKey,
                    currency: "EUR",
                    budgetCents: store.budgetTotal,
                    summary: summary,
                    transactions: tx,
                    categories: cats,
                    daily: dailyPoints
                )
                data = csv.data(using: String.Encoding.utf8) ?? Data()
            case .excel:
                let caps: [Category: Int] = Dictionary(uniqueKeysWithValues: Category.allCases.map { ($0, store.categoryBudget(for: $0)) })
                data = Exporter.makeXLSX(
                    monthKey: monthKey,
                    currency: "EUR",
                    budgetCents: store.budgetTotal,
                    categoryCapsCents: caps,
                    summary: summary,
                    transactions: tx,
                    categories: cats,
                    daily: dailyPoints
                )
            case .pdf:
                data = PDFExporter.makePDF(
                    monthKey: monthKey,
                    currency: "EUR",
                    summary: summary,
                    transactions: tx,
                    categories: cats
                )
            }

            try data.write(to: url, options: .atomic)
            Haptics.exportSuccess()  // ← هاپتیک export
            self.shareURL = url
            self.showShareSheet = true
        } catch {
            Haptics.error()  // ← هاپتیک خطا
            self.notifDetail = "Export failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Backup Manager

struct BackupManager {
    struct BackupData: Codable {
        let version: String = "1.0"
        let createdAt: Date
        let transactions: [Transaction]
        let budgetsByMonth: [String: Int]
        let customCategoryNames: [String]
        let categoryBudgetsByMonth: [String: [String: Int]]
        
        var transactionCount: Int { transactions.count }
        var sizeInBytes: Int { (try? JSONEncoder().encode(self).count) ?? 0 }
        var formattedSize: String {
            let bytes = Double(sizeInBytes)
            if bytes < 1024 {
                return "\(Int(bytes)) B"
            } else if bytes < 1024 * 1024 {
                return String(format: "%.1f KB", bytes / 1024)
            } else {
                return String(format: "%.1f MB", bytes / (1024 * 1024))
            }
        }
    }
    
    static func createBackup(from store: Store) -> BackupData {
        return BackupData(
            createdAt: Date(),
            transactions: store.transactions,
            budgetsByMonth: store.budgetsByMonth,
            customCategoryNames: store.customCategoryNames,
            categoryBudgetsByMonth: store.categoryBudgetsByMonth
        )
    }
    
    static func exportBackup(from store: Store) -> Data? {
        let backup = createBackup(from: store)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(backup)
    }
    
    enum BackupError: Error {
        case invalidFormat
        case unsupportedVersion
        
        var localizedDescription: String {
            switch self {
            case .invalidFormat: return "Invalid backup file format"
            case .unsupportedVersion: return "Unsupported backup version"
            }
        }
    }
    
    static func restoreBackup(_ data: Data, to store: inout Store, mode: RestoreMode) -> Result<Int, BackupError> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let backup = try? decoder.decode(BackupData.self, from: data) else {
            return .failure(.invalidFormat)
        }
        
        guard backup.version == "1.0" else {
            return .failure(.unsupportedVersion)
        }
        
        switch mode {
        case .merge:
            var existingSigs = Set<String>()
            for t in store.transactions {
                existingSigs.insert(transactionSignature(t))
            }
            
            var addedCount = 0
            for t in backup.transactions {
                let sig = transactionSignature(t)
                if !existingSigs.contains(sig) {
                    store.add(t)
                    existingSigs.insert(sig)
                    addedCount += 1
                }
            }
            
            for (key, value) in backup.budgetsByMonth {
                if store.budgetsByMonth[key] == nil {
                    store.budgetsByMonth[key] = value
                }
            }
            
            for cat in backup.customCategoryNames {
                if !store.customCategoryNames.contains(cat) {
                    store.customCategoryNames.append(cat)
                }
            }
            
            for (monthKey, catBudgets) in backup.categoryBudgetsByMonth {
                if store.categoryBudgetsByMonth[monthKey] == nil {
                    store.categoryBudgetsByMonth[monthKey] = catBudgets
                } else {
                    for (catKey, budget) in catBudgets {
                        if store.categoryBudgetsByMonth[monthKey]?[catKey] == nil {
                            store.categoryBudgetsByMonth[monthKey]?[catKey] = budget
                        }
                    }
                }
            }
            
            return .success(addedCount)
            
        case .replace:
            store.transactions.removeAll()
            store.budgetsByMonth.removeAll()
            store.customCategoryNames.removeAll()
            store.categoryBudgetsByMonth.removeAll()
            
            for t in backup.transactions {
                store.add(t)
            }
            
            store.budgetsByMonth = backup.budgetsByMonth
            store.customCategoryNames = backup.customCategoryNames
            store.categoryBudgetsByMonth = backup.categoryBudgetsByMonth
            
            return .success(backup.transactions.count)
        }
    }
    
    private static func transactionSignature(_ t: Transaction) -> String {
        let cal = Calendar.current
        let day = cal.startOfDay(for: t.date)
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        let dayStr = df.string(from: day)
        let noteNorm = t.note.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(dayStr)|\(t.amount)|\(t.category.storageKey)|\(noteNorm)"
    }
    
    static func exportBackupFile(store: Store) -> URL? {
        guard let data = exportBackup(from: store) else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let filename = "Balance_Backup_\(timestamp).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
    
    enum RestoreMode {
        case merge
        case replace
    }
}

// MARK: - Settings

private struct SettingsView: View {
    @Binding var store: Store
    @AppStorage("app.currency") private var selectedCurrency: String = "EUR"
    @AppStorage("app.language") private var selectedLanguage: String = "en"
    @State private var refreshID = UUID()
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var firestoreManager: FirestoreManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Profile Card
                    NavigationLink {
                        ProfileView(store: $store)
                    } label: {
                        DS.Card {
                            HStack(spacing: 12) {
                                // Avatar
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: 0x667EEA),
                                                Color(hex: 0x764BA2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(userInitial)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(userEmail)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(DS.Colors.text)
                                    
                                    Text("View Profile")
                                        .font(.system(size: 13))
                                        .foregroundStyle(DS.Colors.subtext)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Sign Out Button
                    Button {
                        Task {
                            do {
                                // Save to cloud before signing out
                                if let userId = authManager.currentUser?.uid {
                                    try? await firestoreManager.saveStore(store, userId: userId)
                                }
                                
                                // Sign out
                                try authManager.signOut()
                            } catch {
                                print("Error signing out: \(error)")
                            }
                        }
                    } label: {
                        DS.Card {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18))
                                    .foregroundStyle(DS.Colors.negative)
                                
                                Text("Sign Out")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(DS.Colors.negative)
                                
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Security Settings
                    DS.Card {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(DS.Colors.text)
                                Text("Security")
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)
                            }
                            
                            Divider().overlay(DS.Colors.grid)
                            
                            // Biometric Authentication
                            BiometricSettingRow()
                        }
                    }
                    
                    // Backup & Data
                    BackupDataSection(store: $store)
                    
                    // App Settings
                    DS.Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.t("settings.app_settings"))
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)
                            
                            Divider().overlay(DS.Colors.grid)
                            
                            // Currency
                            VStack(alignment: .leading, spacing: 6) {
                                Text(L10n.t("settings.currency"))
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                Picker("Currency", selection: $selectedCurrency) {
                                    Text("EUR (€)").tag("EUR")
                                    Text("USD ($)").tag("USD")
                                    Text("GBP (£)").tag("GBP")
                                    Text("JPY (¥)").tag("JPY")
                                    Text("CAD ($)").tag("CAD")
                                }
                                .pickerStyle(.menu)
                                .tint(DS.Colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(DS.Colors.grid, lineWidth: 1)
                                )
                            }
                            
                            Divider().overlay(DS.Colors.grid)
                            
                            // Language
                            VStack(alignment: .leading, spacing: 6) {
                                Text(L10n.t("settings.language"))
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                Picker("Language", selection: $selectedLanguage) {
                                    Text("English").tag("en")
                                    Text("Deutsch").tag("de")
                                    Text("Español").tag("es")
                                    Text("فارسی").tag("fa")
                                }
                                .pickerStyle(.menu)
                                .tint(DS.Colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(DS.Colors.grid, lineWidth: 1)
                                )
                            }
                            
                            Text(L10n.t("settings.language_note"))
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    }
                    
                    // Developer Info
                    DS.Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.t("settings.developer"))
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)
                            
                            Divider().overlay(DS.Colors.grid)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(L10n.t("settings.developed_by"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                    Spacer()
                                    Text("Mani")
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.text)
                                }
                                
                                HStack {
                                    Text(L10n.t("settings.version"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                    Spacer()
                                    Text("1.0.0")
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.text)
                                }
                                
                                HStack {
                                    Text(L10n.t("settings.build"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                    Spacer()
                                    Text("2026.01")
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.text)
                                }
                            }
                        }
                    }
                    
                    // About
                    DS.Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.t("settings.about"))
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)
                            
                            Text(L10n.t("settings.about_desc"))
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colors.subtext)
                            
                            Divider().overlay(DS.Colors.grid)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(Color(hex: 0x667EEA))
                                    Text(L10n.t("settings.feature_privacy"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.text)
                                }
                                
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .foregroundStyle(Color(hex: 0x667EEA))
                                    Text(L10n.t("settings.feature_insights"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.text)
                                }
                                
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(Color(hex: 0x667EEA))
                                    Text(L10n.t("settings.feature_ai"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.text)
                                }
                                
                                HStack {
                                    Image(systemName: "arrow.down.doc")
                                        .foregroundStyle(Color(hex: 0x667EEA))
                                    Text(L10n.t("settings.feature_import"))
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.text)
                                }
                            }
                        }
                    }
                    
                    // Legal & Support
                    DS.Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.t("settings.legal"))
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)
                            
                            Divider().overlay(DS.Colors.grid)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                // Firestore Test (Debug) - Commented out
                                /*
                                NavigationLink {
                                    FirestoreTestView()
                                } label: {
                                    HStack {
                                        Image(systemName: "network.badge.shield.half.filled")
                                            .foregroundStyle(.orange)
                                        Text("Test Firestore Connection")
                                            .font(DS.Typography.body)
                                            .foregroundStyle(DS.Colors.text)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Divider().overlay(DS.Colors.grid)
                                */
                                
                                // Support Email
                                Button {
                                    if let url = URL(string: "mailto:support@balanceapp.example.com?subject=Balance%20App%20Support") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "envelope")
                                            .foregroundStyle(Color(hex: 0x667EEA))
                                        Text(L10n.t("settings.support_email"))
                                            .font(DS.Typography.body)
                                            .foregroundStyle(DS.Colors.text)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Divider().overlay(DS.Colors.grid)
                                
                                // Report Bug
                                Button {
                                    if let url = URL(string: "mailto:support@balanceapp.example.com?subject=Bug%20Report&body=App%20Version:%201.0.0%0ABuild:%202026.01%0A%0ADescribe%20the%20issue:%0A") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "ladybug")
                                            .foregroundStyle(Color(hex: 0x667EEA))
                                        Text(L10n.t("settings.report_bug"))
                                            .font(DS.Typography.body)
                                            .foregroundStyle(DS.Colors.text)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Divider().overlay(DS.Colors.grid)
                                
                                // Show Onboarding
                                Button {
                                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                                } label: {
                                    HStack {
                                        Image(systemName: "play.circle")
                                            .foregroundStyle(Color(hex: 0x667EEA))
                                        Text("Show Onboarding")
                                            .font(DS.Typography.body)
                                            .foregroundStyle(DS.Colors.text)
                                        Spacer()
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 12))
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Divider().overlay(DS.Colors.grid)
                                
                                // Licenses
                                NavigationLink {
                                    LicensesView()
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundStyle(Color(hex: 0x667EEA))
                                        Text(L10n.t("settings.licenses"))
                                            .font(DS.Typography.body)
                                            .foregroundStyle(DS.Colors.text)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Divider().overlay(DS.Colors.grid)
                            
                            // Copyright
                            Text("© 2026 Mani. All rights reserved.")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .navigationTitle(L10n.t("settings.title"))
            .id(refreshID)
            .onChange(of: selectedLanguage) { _, _ in
                // Force UI refresh when language changes
                refreshID = UUID()
            }
        }
    }
    
    private var userEmail: String {
        authManager.currentUser?.email ?? "User"
    }
    
    private var userInitial: String {
        guard let email = authManager.currentUser?.email else {
            return "U"
        }
        return String(email.prefix(1)).uppercased()
    }
}

// MARK: - Backup & Data Section

private struct BackupDataSection: View {
    @Binding var store: Store
    @State private var showBackupAlert = false
    @State private var showRestoreAlert = false
    @State private var showRestorePicker = false
    @State private var backupStatus: String?
    @State private var isProcessing = false
    
    var body: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(DS.Colors.text)
                    Text("Backup & Data")
                        .font(DS.Typography.section)
                        .foregroundStyle(DS.Colors.text)
                }
                
                Divider().overlay(DS.Colors.grid)
                
                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Total Transactions")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.Colors.subtext)
                        Spacer()
                        Text("\(store.transactions.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Colors.text)
                    }
                    
                    HStack {
                        Text("Total Budgets")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.Colors.subtext)
                        Spacer()
                        Text("\(store.budgetsByMonth.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Colors.text)
                    }
                }
                
                Divider().overlay(DS.Colors.grid)
                
                // Backup Button
                Button {
                    showBackupAlert = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color(hex: 0x667EEA))
                        Text("Create Backup")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DS.Colors.text)
                        Spacer()
                        if isProcessing {
                            ProgressView()
                                .tint(DS.Colors.text)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DS.Colors.surface2)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                
                // Restore Button
                Button {
                    showRestoreAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                            .foregroundStyle(.orange)
                        Text("Restore from Backup")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DS.Colors.text)
                        Spacer()
                        if isProcessing {
                            ProgressView()
                                .tint(DS.Colors.text)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DS.Colors.surface2)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                
                if let status = backupStatus {
                    Text(status)
                        .font(.system(size: 12))
                        .foregroundStyle(status.contains("Success") ? .green : .red)
                        .padding(.top, 4)
                }
                
                Text("⚠️ Backups include all transactions, budgets, and settings. Store them safely!")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Colors.subtext)
            }
        }
        .alert("Create Backup", isPresented: $showBackupAlert) {
            Button("Create", role: .none) {
                createBackup()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will create a backup file with all your data. You can save it for safekeeping.")
        }
        .alert("Restore Backup", isPresented: $showRestoreAlert) {
            Button("Choose File", role: .none) {
                showRestorePicker = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("⚠️ Warning: This will REPLACE all current data with the backup. Make sure you have a recent backup before proceeding.")
        }
        .sheet(isPresented: $showRestorePicker) {
            BackupRestorePicker(store: $store) { success, message in
                backupStatus = message
                if success {
                    Haptics.backupRestored()
                } else {
                    Haptics.error()
                }
                isProcessing = false
            }
        }
    }
    
    private func createBackup() {
        isProcessing = true
        Haptics.medium()
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = BackupManager.exportBackupFile(store: store) else {
                DispatchQueue.main.async {
                    backupStatus = "❌ Failed to create backup"
                    isProcessing = false
                    Haptics.error()
                }
                return
            }
            
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    
                    // Find the topmost presented view controller
                    var topVC = rootVC
                    while let presented = topVC.presentedViewController {
                        topVC = presented
                    }
                    
                    activityVC.completionWithItemsHandler = { _, completed, _, _ in
                        if completed {
                            backupStatus = "✅ Backup created successfully!"
                            Haptics.backupCreated()
                        } else {
                            backupStatus = "❌ Backup cancelled"
                        }
                        isProcessing = false
                    }
                    
                    topVC.present(activityVC, animated: true)
                }
            }
        }
    }
}

// MARK: - Backup Restore Picker

struct BackupRestorePicker: UIViewControllerRepresentable {
    @Binding var store: Store
    let completion: (Bool, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(store: $store, completion: completion, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        @Binding var store: Store
        let completion: (Bool, String) -> Void
        let dismiss: DismissAction
        
        init(store: Binding<Store>, completion: @escaping (Bool, String) -> Void, dismiss: DismissAction) {
            self._store = store
            self.completion = completion
            self.dismiss = dismiss
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                completion(false, "❌ No file selected")
                dismiss()
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                completion(false, "❌ Cannot access file")
                dismiss()
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                var storeCopy = store
                
                let result = BackupManager.restoreBackup(data, to: &storeCopy, mode: .replace)
                switch result {
                case .success(let count):
                    store = storeCopy
                    completion(true, "✅ Backup restored successfully! \(count) transaction(s)")
                case .failure(let error):
                    completion(false, "❌ \(error.localizedDescription)")
                }
            } catch {
                completion(false, "❌ Error: \(error.localizedDescription)")
            }
            
            dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(false, "Cancelled")
            dismiss()
        }
    }
}

// MARK: - Licenses

private struct LicensesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Swift Packages Used
                LicenseCard(
                    name: "ZIPFoundation",
                    license: "MIT License",
                    copyright: "Copyright © 2017-2024 Thomas Zoechling",
                    text: """
                    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
                    
                    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
                    
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                    """
                )
                
                // Apple SF Symbols
                LicenseCard(
                    name: "SF Symbols",
                    license: "Apple License",
                    copyright: "Copyright © 2024 Apple Inc.",
                    text: """
                    SF Symbols are used in accordance with Apple's Human Interface Guidelines and are licensed for use in applications running on Apple platforms.
                    
                    The SF Symbols are provided for use in designing your app's user interface and may only be used to develop, test, and publish apps in Apple's app stores.
                    """
                )
                
                // SwiftUI
                LicenseCard(
                    name: "SwiftUI",
                    license: "Apple License",
                    copyright: "Copyright © 2024 Apple Inc.",
                    text: """
                    SwiftUI is a framework provided by Apple Inc. for building user interfaces across all Apple platforms using Swift.
                    
                    Licensed under the Apple Developer Agreement.
                    """
                )
                
                // Charts
                LicenseCard(
                    name: "Swift Charts",
                    license: "Apple License",
                    copyright: "Copyright © 2024 Apple Inc.",
                    text: """
                    Swift Charts is a framework provided by Apple Inc. for creating charts and data visualizations in SwiftUI.
                    
                    Licensed under the Apple Developer Agreement.
                    """
                )
                
                // App License
                DS.Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.t("settings.app_license"))
                            .font(DS.Typography.section)
                            .foregroundStyle(DS.Colors.text)
                        
                        Divider().overlay(DS.Colors.grid)
                        
                        Text("""
                        Balance is proprietary software developed by Mani. All rights reserved.
                        
                        This application and its content are protected by copyright and other intellectual property laws. You may not reverse engineer, decompile, or disassemble this application.
                        
                        Your data is stored locally on your device and is never transmitted to external servers (except when using the optional AI analysis feature).
                        """)
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .navigationTitle(L10n.t("settings.licenses"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LicenseCard: View {
    let name: String
    let license: String
    let copyright: String
    let text: String
    
    @State private var isExpanded = false
    
    var body: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name)
                                .font(DS.Typography.body.weight(.semibold))
                                .foregroundStyle(DS.Colors.text)
                            
                            Text(license)
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.Colors.subtext)
                    }
                }
                .buttonStyle(.plain)
                
                if isExpanded {
                    Divider().overlay(DS.Colors.grid)
                    
                    Text(copyright)
                        .font(DS.Typography.caption.weight(.semibold))
                        .foregroundStyle(DS.Colors.text)
                    
                    Text(text)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct AIInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var store: Store

    // Set this to your Cloudflare Worker endpoint.
    private let endpoint = URL(string: "https://empty-breeze-77fb.mani-acc7282.workers.dev/analyze")!

    @State private var isLoading: Bool = false
    @State private var errorText: String? = nil
    @State private var result: AIAnalysisResult? = nil
    @State private var lastAnalyzedAt: Date? = nil

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return fmt.string(from: store.selectedMonth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(L10n.t("ai.title"))
                                        .font(DS.Typography.title)
                                        .foregroundStyle(DS.Colors.text)
                                    Spacer()
                                    Button("Close") { dismiss() }
                                        .foregroundStyle(DS.Colors.subtext)
                                }

                                Text("\(monthTitle)")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)

                                Text(
                                    "Tip: AI-generated insights based on your spending data. Results may be imperfect — use as guidance."
                                )
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)

                                if let errorText {
                                    DS.StatusLine(
                                        title: "Couldn’t analyze",
                                        detail: errorText,
                                        level: .watch
                                    )
                                }

                                if isLoading {
                                    HStack(spacing: 10) {
                                        ProgressView()
                                        Text(L10n.t("ai.analyzing"))
                                            .font(DS.Typography.body)
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                    .padding(.vertical, 6)
                                }

                                Button {
                                    Task { await analyze() }
                                } label: {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text(result == nil ? "Run analysis" : "Re-analyze")
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .disabled(isLoading)

                                if let lastAnalyzedAt {
                                    Text("Last analyzed: \(DS.Format.relativeDateTime(lastAnalyzedAt))")
                                        .font(DS.Typography.caption)
                                        .foregroundStyle(DS.Colors.subtext)
                                }
                            }
                        }

                        if let result {
                            DS.Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(L10n.t("ai.summary"))
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)

                                    Text(result.summary)
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colors.text)
                                }
                            }

                            DS.Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Insights")
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)

                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(result.insights, id: \.self) { s in
                                            Text("• \(s)")
                                                .font(DS.Typography.body)
                                                .foregroundStyle(DS.Colors.text)
                                        }
                                    }
                                }
                            }

                            DS.Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(L10n.t("ai.actions"))
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)

                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(result.actions, id: \.self) { s in
                                            Text("• \(s)")
                                                .font(DS.Typography.body)
                                                .foregroundStyle(DS.Colors.text)
                                        }
                                    }
                                }
                            }

                            DS.Card {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(L10n.t("ai.risk"))
                                        .font(DS.Typography.section)
                                        .foregroundStyle(DS.Colors.text)

                                    DS.StatusLine(
                                        title: "Risk level",
                                        detail: result.riskLevel.uppercased(),
                                        level: result.riskLevelLevel
                                    )
                                }
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadCachedResultIfAvailable()
        }
    }

    private func analyze() async {
        guard !isLoading else { return }
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            let payload = AIAnalysisPayload.from(store: store)
            let reqData = try JSONEncoder().encode(payload)

            var req = URLRequest(url: endpoint)
            req.httpMethod = "POST"
            req.httpBody = reqData
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw NSError(domain: "AI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error \(http.statusCode). \(body)"])
            }

            let decoded = try JSONDecoder().decode(AIAnalysisResult.self, from: data)
            result = decoded
            lastAnalyzedAt = Date()
            saveCachedResult(decoded, analyzedAt: lastAnalyzedAt!)
        } catch {
            errorText = error.localizedDescription
        }
    }


    private var cacheKey: String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: store.selectedMonth)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        return String(format: "ai.analysis.%04d-%02d", y, m)
    }

    private func loadCachedResultIfAvailable() {
        // Load cached analysis per-month so reopening the sheet does not re-run.
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return }
        do {
            let cached = try JSONDecoder().decode(AICachedAnalysis.self, from: data)
            self.result = cached.result
            self.lastAnalyzedAt = cached.analyzedAt
        } catch {
            // If cache is corrupted or schema changed, ignore.
        }
    }

    private func saveCachedResult(_ result: AIAnalysisResult, analyzedAt: Date) {
        let cached = AICachedAnalysis(result: result, analyzedAt: analyzedAt)
        do {
            let data = try JSONEncoder().encode(cached)
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            // Ignore cache save failures.
        }
    }
}


private struct AICachedAnalysis: Codable {
    let result: AIAnalysisResult
    let analyzedAt: Date
}

private struct AIAnalysisPayload: Codable {
    struct DayTotal: Codable { let day: Int; let amount: Int }
    struct CategoryTotal: Codable { let name: String; let amount: Int }

    let month: String
    let budget: Int
    let totalSpent: Int
    let remaining: Int
    let dailyAvg: Int
    let daily: [DayTotal]
    let categories: [CategoryTotal]

    static func from(store: Store) -> AIAnalysisPayload {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: store.selectedMonth)
        let year = comps.year ?? 0
        let monthNum = comps.month ?? 0
        let monthStr = String(format: "%04d-%02d", year, monthNum)

        let summary = Analytics.monthSummary(store: store)
        let points = Analytics.dailySpendPoints(store: store)
        let breakdown = Analytics.categoryBreakdown(store: store)

        let daily = points.map { DayTotal(day: $0.day, amount: $0.amount) }
        let cats = breakdown.map { CategoryTotal(name: $0.category.title, amount: $0.total) }

        return AIAnalysisPayload(
            month: monthStr,
            budget: store.budgetTotal,
            totalSpent: summary.totalSpent,
            remaining: summary.remaining,
            dailyAvg: summary.dailyAvg,
            daily: daily,
            categories: cats
        )
    }
}

private struct AIAnalysisResult: Codable {
    let summary: String
    let insights: [String]
    let actions: [String]
    let riskLevel: String

    var riskLevelLevel: Level {
        switch riskLevel.lowercased() {
        case "ok": return .ok
        case "watch": return .watch
        case "risk": return .risk
        default: return .watch
        }
    }
}

// MARK: - Components

private struct CategoryTotalRow: View {
    let category: Category
    let spent: Int

    var body: some View {
        HStack {
            Text(category.title)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.text)
            Spacer()
            Text(DS.Format.money(spent))
                .font(DS.Typography.number)
                .foregroundStyle(DS.Colors.text)
        }
        .padding(12)
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
    }
}

private struct CategoryCapRow: View {
    let category: Category
    let spent: Int
    let cap: Int

    private var usedRatioRaw: Double {
        cap > 0 ? Double(spent) / Double(cap) : 0
    }

    private var barRatio: Double {
        min(1, max(0, usedRatioRaw))
    }

    private var levelColor: Color {
        if usedRatioRaw >= 1.0 { return DS.Colors.danger }
        if usedRatioRaw >= 0.90 { return DS.Colors.warning }
        return DS.Colors.positive
    }

    var body: some View {
        let remaining = cap - spent

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(category.title)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.text)

                Spacer()

                Text(DS.Format.money(spent))
                    .font(DS.Typography.number)
                    .foregroundStyle(DS.Colors.text)
            }

            HStack {
                Text("Category cap")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)

                Spacer()

                Text("\(DS.Format.percent(usedRatioRaw)) used")
                    .font(DS.Typography.caption)
                    .foregroundStyle(usedRatioRaw >= 0.90 ? levelColor : DS.Colors.subtext)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(DS.Colors.surface)

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DS.Colors.surface2, levelColor],  // surface2 → رنگ (روشن‌تر از مشکی کامل)
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * barRatio)
                        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: barRatio)
                }
            }
            .frame(height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(levelColor.opacity(0.3), lineWidth: 1)  // border با رنگ وضعیت
            )

            HStack {
                Text("Cap: \(DS.Format.money(cap))")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)

                Spacer()

                if remaining >= 0 {
                    Text("Remaining: \(DS.Format.money(remaining))")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                } else {
                    Text("Over: \(DS.Format.money(abs(remaining)))")
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.danger)
                }
            }
        }
        .padding(12)
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
    }
}

private struct KPI: View {
    let title: String
    let value: String
    var isNegative: Bool = false

    var body: some View {
        DS.Card(padding: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)
                Text(value)
                    .font(DS.Typography.number)
                    .foregroundStyle(isNegative ? DS.Colors.danger : DS.Colors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isNegative ? DS.Colors.danger.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

private struct TransactionRow: View {
    let t: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(t.category.tint.opacity(0.18))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: t.category.icon)
                            .foregroundStyle(t.category.tint)
                            .font(.system(size: 14, weight: .semibold))
                    )

                // 📎 Badge اگر attachment وجود دارد
                if t.attachmentData != nil || t.attachmentType != nil {
                    Circle()
                        .fill(DS.Colors.surface2)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "paperclip")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Colors.subtext)
                        )
                        .overlay(
                            Circle()
                                .stroke(DS.Colors.grid, lineWidth: 1)
                        )
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(t.category.title)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colors.text)

                    // آیکون روش پرداخت (کوچک)
                    Image(systemName: t.paymentMethod.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(t.paymentMethod.tint)
                        .padding(3)
                        .background(
                            Circle()
                                .fill(t.paymentMethod.tint.opacity(0.15))
                        )
                    
                    // علامت اینکه این ترنزکشن اتچمنت دارد
                    if t.attachmentData != nil {
                        Image(systemName: "paperclip")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x667EEA))
                    }
                }

                Text(t.note.isEmpty ? "—" : t.note)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)
                    .lineLimit(1)
            }

            Spacer()

            Text(
                t.type == .expense ?
                AttributedString("-") + DS.Format.moneyAttributed(t.amount) :
                AttributedString("+") + DS.Format.moneyAttributed(t.amount)
            )
            .font(DS.Typography.number)
            .foregroundStyle(t.type == .income ? Color.green.opacity(0.8) : DS.Colors.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(t.type == .income ? Color.green.opacity(0.05) : DS.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(t.type == .income ? Color.green.opacity(0.15) : DS.Colors.grid, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Transaction Inspect Sheet (Full)

private struct TransactionInspectSheet: View {
    let transaction: Transaction
    @Binding var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var showAttachment = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Card - Category & Type
                        DS.Card {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(transaction.category.tint.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: transaction.category.icon)
                                            .foregroundStyle(transaction.category.tint)
                                            .font(.system(size: 24, weight: .semibold))
                                    )
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(transaction.category.title)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(DS.Colors.text)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: transaction.type.icon)
                                            .font(.system(size: 12, weight: .semibold))
                                        Text(transaction.type.title)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundStyle(transaction.type == .income ? .green : DS.Colors.subtext)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Amount Card - بزرگ
                        DS.Card {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Amount")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(DS.Colors.subtext)
                                
                                Text(
                                    transaction.type == .expense ?
                                    AttributedString("-") + DS.Format.moneyAttributed(transaction.amount) :
                                    AttributedString("+") + DS.Format.moneyAttributed(transaction.amount)
                                )
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(transaction.type == .income ? .green : DS.Colors.text)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Details Card
                        DS.Card {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Details")
                                
                                InspectDetailRow(
                                    icon: "calendar",
                                    title: "Date & Time",
                                    value: formatDate(transaction.date)
                                )
                                
                                InspectDetailRow(
                                    icon: transaction.paymentMethod.icon,
                                    title: "Payment Method",
                                    value: transaction.paymentMethod.displayName
                                )
                            }
                        }
                        
                        // Note Card
                        if !transaction.note.isEmpty {
                            DS.Card {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "Note")
                                    
                                    Text(transaction.note)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(DS.Colors.text)
                                        .lineLimit(nil)  // ← بدون محدودیت!
                                }
                            }
                        }
                        
                        // Attachment Card
                        if transaction.attachmentData != nil, let type = transaction.attachmentType {
                            DS.Card {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "Attachment")
                                    
                                    Button {
                                        showAttachment = true
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "paperclip")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.blue)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(type == .image ? "Image" : "PDF Document")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundStyle(DS.Colors.text)
                                                
                                                Text("Tap to view")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundStyle(DS.Colors.subtext)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(DS.Colors.subtext)
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(DS.Colors.surface2)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // ID Card (برای debug)
                        DS.Card {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Transaction ID")
                                
                                Text(transaction.id.uuidString)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Inspect Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DS.Colors.subtext)
                    }
                }
            }
            .sheet(isPresented: $showAttachment) {
                if let data = transaction.attachmentData, let type = transaction.attachmentType {
                    AttachmentViewer(attachmentData: data, attachmentType: type)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Section Header
private struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(DS.Colors.subtext)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// Inspect Detail Row
private struct InspectDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Circle()
                .fill(DS.Colors.surface2)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Colors.text.opacity(0.7))
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.Colors.subtext)
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.text)
            }
            
            Spacer()
        }
    }
}

// MARK: - Transaction Inspect Preview

private struct TransactionInspectPreview: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header با icon و category
            HStack(spacing: 12) {
                Circle()
                    .fill(transaction.category.tint.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: transaction.category.icon)
                            .foregroundStyle(transaction.category.tint)
                            .font(.system(size: 20, weight: .semibold))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.category.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.Colors.text)
                    
                    Text(transaction.type.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(transaction.type == .income ? .green : DS.Colors.subtext)
                }
                
                Spacer()
            }
            
            // Amount - بزرگ و برجسته
            HStack {
                Text(
                    transaction.type == .expense ?
                    AttributedString("-") + DS.Format.moneyAttributed(transaction.amount) :
                    AttributedString("+") + DS.Format.moneyAttributed(transaction.amount)
                )
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(transaction.type == .income ? .green : DS.Colors.text)
                
                Spacer()
            }
            
            Divider()
                .background(DS.Colors.grid)
            
            // جزئیات
            VStack(alignment: .leading, spacing: 12) {
                // تاریخ
                DetailRow(
                    icon: "calendar",
                    title: "Date",
                    value: formatDate(transaction.date)
                )
                
                // روش پرداخت
                DetailRow(
                    icon: transaction.paymentMethod.icon,
                    title: "Payment",
                    value: transaction.paymentMethod.displayName
                )
                
                // توضیحات
                if !transaction.note.isEmpty {
                    DetailRow(
                        icon: "note.text",
                        title: "Note",
                        value: transaction.note,
                        maxLines: 2  // ← محدود در preview
                    )
                }
                
                // پیوست
                if transaction.attachmentData != nil {
                    DetailRow(
                        icon: "paperclip",
                        title: "Attachment",
                        value: "📎 \(transaction.attachmentType?.rawValue.capitalized ?? "File")"
                    )
                }
            }
        }
        .padding(20)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DS.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Helper view for detail rows
private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var maxLines: Int? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.Colors.subtext)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.subtext)
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Colors.text)
                    .lineLimit(maxLines)
            }
        }
    }
}

// MARK: - Attachment Viewer

private struct AttachmentViewer: View {
    let attachmentData: Data
    let attachmentType: AttachmentType
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    DS.Colors.bg.ignoresSafeArea()
                    
                    if attachmentType == .image, let uiImage = UIImage(data: attachmentData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = lastScale * value
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                            // Reset if zoomed out too much
                                            if scale < 1.0 {
                                                withAnimation(.spring(response: 0.3)) {
                                                    scale = 1.0
                                                    lastScale = 1.0
                                                    offset = .zero
                                                    lastOffset = .zero
                                                }
                                            }
                                            // Limit max zoom
                                            if scale > 4.0 {
                                                withAnimation(.spring(response: 0.3)) {
                                                    scale = 4.0
                                                    lastScale = 4.0
                                                }
                                            }
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            if scale > 1.0 {
                                                // محاسبه حد مجاز برای drag
                                                let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
                                                let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
                                                
                                                var newX = lastOffset.width + value.translation.width
                                                var newY = lastOffset.height + value.translation.height
                                                
                                                // محدود کردن به boundary
                                                newX = min(max(newX, -maxOffsetX), maxOffsetX)
                                                newY = min(max(newY, -maxOffsetY), maxOffsetY)
                                                
                                                offset = CGSize(width: newX, height: newY)
                                            }
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        }
                                )
                            )
                            .onTapGesture(count: 2) {
                                // Double tap to reset zoom
                                withAnimation(.spring(response: 0.3)) {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                            .padding()
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color(hex: 0x667EEA))
                            
                            Text(L10n.t("attachment.document"))
                                .font(DS.Typography.title)
                                .foregroundStyle(DS.Colors.text)
                            
                            Text("\(ByteCountFormatter.string(fromByteCount: Int64(attachmentData.count), countStyle: .file))")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    }
                }
            }
            .navigationTitle("Attachment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(DS.Colors.subtext)
                }
            }
        }
    }
}


private struct InsightRow: View {
    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(insight.level.color.opacity(0.18))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: insight.level.icon)
                        .foregroundStyle(insight.level.color)
                        .font(.system(size: 14, weight: .semibold))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(DS.Typography.body.weight(.semibold))
                    .foregroundStyle(DS.Colors.text)
                Text(insight.detail)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.subtext)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DS.Colors.grid, lineWidth: 1)
        )
    }
}

private struct MonthPicker: View {
    @Binding var selectedMonth: Date

    var body: some View {
        HStack(spacing: 8) {
            Button {
                Haptics.monthChanged()  // ← هاپتیک مخصوص
                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(DS.Colors.subtext)
                    .padding(8)
                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                Haptics.soft()  // ← light بجای soft
                selectedMonth = Date()
            } label: {
                Text(L10n.t("month.this_month"))
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                Haptics.monthChanged()  // ← هاپتیک مخصوص
                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(DS.Colors.subtext)
                    .padding(8)
                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}


private struct TransactionFormCard: View {
    @Binding var amountText: String
    @Binding var note: String
    @Binding var date: Date
    @Binding var category: Category
    @Binding var transactionType: TransactionType  // ← جدید

    let categories: [Category]
    let onAddCategory: () -> Void

    var body: some View {
        DS.Card {
            VStack(alignment: .leading, spacing: 10) {
                // Transaction Type Toggle
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            transactionType = .expense
                        }
                        Haptics.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 14))
                            Text("Expense")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(transactionType == .expense ? .white : DS.Colors.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            transactionType == .expense ?
                            Color.red : DS.Colors.surface2,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            transactionType = .income
                        }
                        Haptics.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Income")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(transactionType == .income ? .white : DS.Colors.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            transactionType == .income ?
                            Color.green : DS.Colors.surface2,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 6)
                
                Divider().overlay(DS.Colors.grid)
                
                Text(L10n.t("transaction.amount"))
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)

                TextField("e.g. 250.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(DS.Typography.number)
                    .padding(12)
                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DS.Colors.grid, lineWidth: 1)
                    )

                Divider().overlay(DS.Colors.grid)

                Text(L10n.t("transaction.category"))
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { c in
                            Button { category = c } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: c.icon)
                                    Text(c.title)
                                }
                                .font(DS.Typography.caption)
                                .foregroundStyle(category == c ? DS.Colors.text : DS.Colors.subtext)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(
                                    (category == c ? c.tint.opacity(0.18) : DS.Colors.surface2),
                                    in: RoundedRectangle(cornerRadius: 999, style: .continuous)
                                )
                                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: category)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .stroke(DS.Colors.grid, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        Button {
                            onAddCategory()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                Text(L10n.t("common.add"))
                            }
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 999, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 999, style: .continuous)
                                    .stroke(DS.Colors.grid, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().overlay(DS.Colors.grid)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("transaction.date"))
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                        DatePicker("", selection: $date, displayedComponents: [.date])
                            .labelsHidden()
                    }
                    Spacer()
                }

                Divider().overlay(DS.Colors.grid)

                Text(L10n.t("transaction.note"))
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Colors.subtext)

                TextField("e.g. groceries", text: $note)
                    .font(DS.Typography.body)
                    .padding(12)
                    .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DS.Colors.grid, lineWidth: 1)
                    )
            }
        }
    }
}


// MARK: - Add Transaction Sheet

struct AddTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var store: Store
    
    @State private var amountText = ""
    @State private var note = ""
    private let initialMonth: Date
    @State private var date: Date
    @State private var category: Category = .groceries
    @State private var paymentMethod: PaymentMethod = .card
    @State private var transactionType: TransactionType = .expense  // ← جدید
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var attachmentData: Data? = nil
    @State private var attachmentType: AttachmentType? = nil
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    @State private var showAttachmentOptions = false
    
    fileprivate init(store: Binding<Store>, initialMonth: Date) {
        self._store = store
        self.initialMonth = initialMonth

        let cal = Calendar.current
        let now = Date()

        // اگر ماه جاریه → امروز
        if cal.isDate(initialMonth, equalTo: now, toGranularity: .month) {
            self._date = State(initialValue: now)
        } else {
            // اگر ماه دیگه‌ست → روز اول ماه
            let comps = cal.dateComponents([.year, .month], from: initialMonth)
            let d = cal.date(
                from: DateComponents(
                    year: comps.year,
                    month: comps.month,
                    day: 1,
                    hour: 12
                )
            )
            self._date = State(initialValue: d ?? initialMonth)
        }
    }
    
    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(L10n.t("transaction.add"))
                            .font(DS.Typography.title)
                            .foregroundStyle(DS.Colors.text)
                        Spacer()
                        Button("Close") { dismiss() }
                            .foregroundStyle(DS.Colors.subtext)
                    }
                    .padding(.top, 8)
                    
                    TransactionFormCard(
                        amountText: $amountText,
                        note: $note,
                        date: $date,
                        category: $category,
                        transactionType: $transactionType,  // ← جدید
                        categories: store.allCategories,
                        onAddCategory: {
                            showAddCategory = true
                        }
                    )
                    
                    // ← کارت پیوست (جدید)
                    DS.Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.t("transaction.attachment"))
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                            
                            if let attachmentData, let attachmentType {
                                // نمایش پیوست موجود
                                HStack(spacing: 12) {
                                    // آیکون بر اساس نوع
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: 0x667EEA).opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: attachmentType == .image ? "photo" : "doc.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color(hex: 0x667EEA))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(attachmentType == .image ? "Image" : "Document")
                                            .font(DS.Typography.body)
                                            .foregroundStyle(DS.Colors.text)
                                        Text("\(ByteCountFormatter.string(fromByteCount: Int64(attachmentData.count), countStyle: .file))")
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                    
                                    Spacer()
                                    
                                    // دکمه حذف
                                    Button {
                                        withAnimation {
                                            self.attachmentData = nil
                                            self.attachmentType = nil
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(DS.Colors.subtext)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(12)
                                .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(DS.Colors.grid, lineWidth: 1)
                                )
                            } else {
                                // دکمه اضافه کردن پیوست
                                Button {
                                    showAttachmentOptions = true
                                } label: {
                                    HStack {
                                        Image(systemName: "paperclip")
                                        Text(L10n.t("transaction.add_attachment"))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(DS.ColoredButton())
                            }
                        }
                    }
                    
                    // ← کارت روش پرداخت (جدید)
                    DS.Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.t("transaction.payment_method"))
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                            
                            HStack(spacing: 12) {
                                ForEach(PaymentMethod.allCases, id: \.self) { method in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            paymentMethod = method
                                            Haptics.selection()
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            // آیکون با گرادیانت
                                            ZStack {
                                                if paymentMethod == method {
                                                    // Selected: gradient background
                                                    Circle()
                                                        .fill(
                                                            method == .card ?
                                                            LinearGradient(
                                                                colors: [DS.Colors.surface, DS.Colors.text],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ) :
                                                            method.gradient
                                                        )
                                                        .frame(width: 50, height: 50)
                                                        .shadow(
                                                            color: method == .card ? Color.white.opacity(0.2) : method.tint.opacity(0.4),
                                                            radius: 8,
                                                            x: 0,
                                                            y: 4
                                                        )
                                                } else {
                                                    // Unselected: subtle background
                                                    Circle()
                                                        .fill(
                                                            method == .card ?
                                                            DS.Colors.text.opacity(0.12) :
                                                            method.tint.opacity(0.12)
                                                        )
                                                        .frame(width: 50, height: 50)
                                                }
                                                
                                                Image(systemName: method.icon)
                                                    .font(.system(size: 22, weight: .semibold))
                                                    .foregroundStyle(
                                                        paymentMethod == method ?
                                                        (method == .card ? Color.black : .white) :
                                                        (method == .card ? DS.Colors.text : method.tint)
                                                    )
                                            }
                                            
                                            // نام روش
                                            Text(method.displayName)
                                                .font(DS.Typography.caption.weight(paymentMethod == method ? .semibold : .medium))
                                                .foregroundStyle(paymentMethod == method ? DS.Colors.text : DS.Colors.subtext)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(paymentMethod == method ? DS.Colors.surface2 : Color.clear)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(
                                                    paymentMethod == method ?
                                                    (method == .card ? DS.Colors.grid : method.tint.opacity(0.3)) :
                                                    DS.Colors.grid,
                                                    lineWidth: paymentMethod == method ? 2 : 1
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    Button {
                        let amount = DS.Format.cents(from: amountText)
                        guard amount > 0 else { return }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            store.add(Transaction(
                                amount: amount,
                                date: date,
                                category: category,
                                note: note,
                                paymentMethod: paymentMethod,
                                type: transactionType,
                                attachmentData: attachmentData,
                                attachmentType: attachmentType
                            ))
                        }
                        Haptics.transactionAdded()  // ← هاپتیک مخصوص
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(L10n.t("common.save"))
                        }
                    }
                    .buttonStyle(DS.PrimaryButton())
                    .disabled(DS.Format.cents(from: amountText) <= 0)
                    
                    Text(L10n.t("transaction.advisor_note"))
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Colors.subtext)
                    
                }
                .padding(16)
                .padding(.bottom, 24)
            }
        }
        .confirmationDialog("Add attachment", isPresented: $showAttachmentOptions) {
            Button(L10n.t("transaction.attach_photo")) {
                showImagePicker = true
            }
            Button(L10n.t("transaction.attach_file")) {
                showDocumentPicker = true
            }
            Button("common.cancel", role: .cancel) {}
        }
        .alert(L10n.t("transaction.new_category"), isPresented: $showAddCategory) {
            TextField("e.g. Coffee", text: $newCategoryName)
            Button("Add") {
                let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                store.addCustomCategory(name: trimmed)
                category = .custom(trimmed)
                newCategoryName = ""
            }
            Button("common.cancel", role: .cancel) {
                newCategoryName = ""
            }
        } message: {
            Text(L10n.t("transaction.new_category_msg"))
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(imageData: $attachmentData, attachmentType: $attachmentType)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(fileData: $attachmentData, attachmentType: $attachmentType)
        }
    }
}


private struct EditTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var store: Store
    let transactionID: UUID

    @State private var amountText = ""
    @State private var note = ""
    @State private var date: Date = Date()
    @State private var category: Category = .groceries
    @State private var paymentMethod: PaymentMethod = .card
    @State private var transactionType: TransactionType = .expense  // ← جدید
    @State private var showAddCategory = false
    @State private var newCategoryName = ""

    private var index: Int? {
        store.transactions.firstIndex { $0.id == transactionID }
    }

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(L10n.t("transaction.edit"))
                        .font(DS.Typography.title)
                        .foregroundStyle(DS.Colors.text)
                    Spacer()
                    Button("Close") { dismiss() }
                        .foregroundStyle(DS.Colors.subtext)
                        .buttonStyle(.plain)
                }

                TransactionFormCard(
                    amountText: $amountText,
                    note: $note,
                    date: $date,
                    category: $category,
                    transactionType: $transactionType,  // ← فیکس
                    categories: store.allCategories,
                    onAddCategory: {
                        showAddCategory = true
                    }
                )
                
                // ← کارت روش پرداخت (جدید)
                DS.Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.t("transaction.payment_method"))
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                        
                        HStack(spacing: 12) {
                            ForEach(PaymentMethod.allCases, id: \.self) { method in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        paymentMethod = method
                                        Haptics.selection()
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        // آیکون با گرادیانت
                                        ZStack {
                                            if paymentMethod == method {
                                                // Selected: gradient background
                                                Circle()
                                                    .fill(
                                                        method == .card ?
                                                        LinearGradient(
                                                            colors: [DS.Colors.surface, DS.Colors.text],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ) :
                                                        method.gradient
                                                    )
                                                    .frame(width: 50, height: 50)
                                                    .shadow(
                                                        color: method == .card ? Color.white.opacity(0.2) : method.tint.opacity(0.4),
                                                        radius: 8,
                                                        x: 0,
                                                        y: 4
                                                    )
                                            } else {
                                                // Unselected: subtle background
                                                Circle()
                                                    .fill(
                                                        method == .card ?
                                                        DS.Colors.text.opacity(0.12) :
                                                        method.tint.opacity(0.12)
                                                    )
                                                    .frame(width: 50, height: 50)
                                            }
                                            
                                            Image(systemName: method.icon)
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundStyle(
                                                    paymentMethod == method ?
                                                    (method == .card ? Color.black : .white) :
                                                    (method == .card ? DS.Colors.text : method.tint)
                                                )
                                        }
                                        
                                        // نام روش
                                        Text(method.displayName)
                                            .font(DS.Typography.caption.weight(paymentMethod == method ? .semibold : .medium))
                                            .foregroundStyle(paymentMethod == method ? DS.Colors.text : DS.Colors.subtext)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(paymentMethod == method ? DS.Colors.surface2 : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(
                                                paymentMethod == method ?
                                                (method == .card ? DS.Colors.grid : method.tint.opacity(0.3)) :
                                                DS.Colors.grid,
                                                lineWidth: paymentMethod == method ? 2 : 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // ← کارت نوع تراکنش
                DS.Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(DS.Typography.caption)
                            .foregroundStyle(DS.Colors.subtext)
                        
                        HStack(spacing: 10) {
                            ForEach(TransactionType.allCases, id: \.self) { type in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        transactionType = type
                                        Haptics.selection()
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(transactionType == type ? .white : type.color.opacity(0.65))
                                        
                                        Text(type.title)
                                            .font(.system(size: 14, weight: transactionType == type ? .semibold : .medium))
                                            .foregroundStyle(transactionType == type ? .white : DS.Colors.text.opacity(0.75))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(transactionType == type ? type.color.opacity(0.75) : type.color.opacity(0.06))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(
                                                transactionType == type ? type.color.opacity(0.25) : type.color.opacity(0.12),
                                                lineWidth: transactionType == type ? 1.5 : 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Button {
                    guard let idx = index else { return }
                    let amount = DS.Format.cents(from: amountText)
                    guard amount > 0 else { return }

                    let existingID = store.transactions[idx].id
                    let existingAttachmentData = store.transactions[idx].attachmentData
                    let existingAttachmentType = store.transactions[idx].attachmentType
                    
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        store.transactions[idx] = Transaction(
                            id: existingID,
                            amount: amount,
                            date: date,
                            category: category,
                            note: note,
                            paymentMethod: paymentMethod,
                            type: transactionType,
                            attachmentData: existingAttachmentData,
                            attachmentType: existingAttachmentType,
                            lastModified: Date()
                        )
                    }
                    Haptics.success()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(L10n.t("transaction.save_changes"))
                    }
                }
                .buttonStyle(DS.PrimaryButton())
                .disabled(DS.Format.cents(from: amountText) <= 0 || index == nil)

                Spacer()
            }
            .padding(16)
        }
        .onAppear {
            guard let idx = index else { return }
            let t = store.transactions[idx]
            amountText = String(format: "%.2f", Double(t.amount) / 100.0)
            note = t.note
            date = t.date
            category = t.category
            paymentMethod = t.paymentMethod
            transactionType = t.type  // ← جدید
        }
        .alert(L10n.t("transaction.new_category"), isPresented: $showAddCategory) {
            TextField("e.g. Coffee", text: $newCategoryName)
            Button("Add") {
                let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                store.addCustomCategory(name: trimmed)
                category = .custom(trimmed)
                newCategoryName = ""
            }
            Button("common.cancel", role: .cancel) {
                newCategoryName = ""
            }
        } message: {
            Text(L10n.t("transaction.new_category_msg"))
        }
    }
}


// MARK: - Design System

enum DS {
    enum Colors {
        // Core dark palette (NO blues)
        static let bg = Color.black
        static let surface  = Color(hex: 0x1C1C1E)   // روشن‌تر برای دکمه‌ها
        static let surface2 = Color(hex: 0x28282A)   // کمی روشن‌تر

        static let text = Color.white
        static let subtext = Color.white.opacity(0.70)
        static let grid = Color.white.opacity(0.10)

        // Accent stays neutral (white). Status uses only green/red.
        static let accent = Color.white
        static let buttonFill = Color.black

        static let positive = Color(hex: 0x2ED573)   // green
        static let warning  = Color(hex: 0xFF9F0A)   // orange (watch)
        static let danger   = Color(hex: 0xFF3B30)   // red
        static let negative = Color(hex: 0xFF3B30)   // same as danger (for errors)
    }

    enum Typography {
        static let title = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let section = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 14, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let number = Font.system(size: 16, weight: .semibold, design: .monospaced)
    }

    struct Card<Content: View>: View {
        var padding: CGFloat = 14
        @ViewBuilder var content: Content
        var body: some View {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(padding)
                .background(Colors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(DS.Colors.grid, lineWidth: 1)
                )
        }
    }

    struct PrimaryButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Color.black)  // متن مشکی
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)  // پس‌زمینه سفید
                )
                .opacity(configuration.isPressed ? 0.85 : 1.0)
        }
    }
    
    struct ColoredButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Color.white)  // متن سفید
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: 0x3A3A3C))  // خاکستری مشکی
                )
                .opacity(configuration.isPressed ? 0.85 : 1.0)
        }
    }
    
    struct TextFieldStyle: SwiftUI.TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .font(Typography.body)
                .padding(12)
                .background(Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Colors.grid, lineWidth: 1)
                )
                .foregroundStyle(Colors.text)
        }
    }
    
    /// Beautiful empty state component
    struct EmptyState: View {
        let icon: String
        let title: String
        let message: String
        var actionTitle: String? = nil
        var action: (() -> Void)? = nil
        
        var body: some View {
            VStack(spacing: Spacing.lg) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Colors.subtext.opacity(0.5))
                
                // Text
                VStack(spacing: Spacing.sm) {
                    Text(title)
                        .font(Typography.section)
                        .foregroundStyle(Colors.text)
                    
                    Text(message)
                        .font(Typography.body)
                        .foregroundStyle(Colors.subtext)
                        .multilineTextAlignment(.center)
                }
                
                // Action button
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                    }
                    .buttonStyle(PrimaryButton())
                    .padding(.horizontal, Spacing.xl)
                }
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity)
        }
    }

    struct StatusLine: View {
        let title: String
        let detail: String
        let level: Level

        var body: some View {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(level.color.opacity(0.18))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: level.icon)
                            .foregroundStyle(level.color)
                            .font(.system(size: 12, weight: .semibold))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Typography.body.weight(.semibold))
                        .foregroundStyle(Colors.text)
                    Text(detail)
                        .font(Typography.caption)
                        .foregroundStyle(Colors.subtext)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Colors.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(DS.Colors.grid, lineWidth: 1)
            )
        }
    }

    struct Meter: View {
        let title: String
        let value: Int
        let max: Int
        let hint: String

        private var ratio: Double { min(1, Double(value) / Double(max)) }
        private var level: Level {
            // 0–70%: ok (green), 70–80%: watch (orange), 80%+: risk (red)
            if ratio < 0.70 { return .ok }
            if ratio <= 0.80 { return .watch }
            return .risk
        }


        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(Typography.caption)
                        .foregroundStyle(Colors.subtext)
                    Spacer()
                    Text(hint)
                        .font(Typography.caption)
                        .foregroundStyle(level == .ok ? Colors.subtext : level.color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Colors.surface2)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(level.color)
                            .frame(width: geo.size.width * ratio)
                            .opacity(0.85)
                            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: ratio)
                    }
                }
                .frame(height: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Colors.grid, lineWidth: 1)
                )
            }
        }
    }

    enum Format {
        static func money(_ cents: Int) -> String {
            let currencyCode = UserDefaults.standard.string(forKey: "app.currency") ?? "EUR"
            
            let nf = NumberFormatter()
            nf.numberStyle = .currency
            nf.locale = .current
            nf.currencyCode = currencyCode
            
            // Set symbol based on currency
            switch currencyCode {
            case "EUR": nf.currencySymbol = "€"
            case "USD": nf.currencySymbol = "$"
            case "GBP": nf.currencySymbol = "£"
            case "JPY": nf.currencySymbol = "¥"
            case "CAD": nf.currencySymbol = "C$"
            default: nf.currencySymbol = currencyCode
            }
            
            nf.minimumFractionDigits = 2
            nf.maximumFractionDigits = 2

            let value = Decimal(cents) / Decimal(100)
            return nf.string(from: value as NSDecimalNumber) ?? "\(nf.currencySymbol ?? "")\(value)"
        }
        
        /// Format money with superscript cents (e.g., 105,²⁴ €)
        static func moneyAttributed(_ cents: Int) -> AttributedString {
            let currencyCode = UserDefaults.standard.string(forKey: "app.currency") ?? "EUR"
            let currencySymbol: String
            
            switch currencyCode {
            case "EUR": currencySymbol = "€"
            case "USD": currencySymbol = "$"
            case "GBP": currencySymbol = "£"
            case "JPY": currencySymbol = "¥"
            case "CAD": currencySymbol = "C$"
            default: currencySymbol = currencyCode
            }
            
            let value = Double(cents) / 100.0
            let euros = Int(value)
            let centsPart = abs(cents % 100)
            
            // Format: 105,²⁴ €
            var result = AttributedString("\(euros),")
            
            // Superscript cents
            var centsStr = AttributedString(String(format: "%02d", centsPart))
            centsStr.font = .system(size: 11, weight: .medium)
            centsStr.baselineOffset = 6
            
            result += centsStr
            result += AttributedString(" \(currencySymbol)")
            
            return result
        }
        
        // Alias for ProfileView compatibility
        static func currency(_ cents: Int) -> String {
            return money(cents)
        }

        static func percent(_ value: Double) -> String {
            let nf = NumberFormatter()
            nf.numberStyle = .percent
            nf.locale = .current
            nf.minimumFractionDigits = 0
            nf.maximumFractionDigits = 0
            return nf.string(from: NSNumber(value: value)) ?? "\(Int(value * 100))%"
        }

        /// Parses user-entered money text into **euro cents**.
        /// Accepts: "250", "250.5", "250.50", "250,50"
        static func cents(from text: String) -> Int {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return 0 }

            var cleaned = ""
            var didAddDot = false

            for ch in trimmed {
                if ch.isNumber {
                    cleaned.append(ch)
                } else if (ch == "." || ch == ",") && !didAddDot {
                    cleaned.append(".")
                    didAddDot = true
                }
            }

            guard !cleaned.isEmpty else { return 0 }

            // If no decimal separator: treat as euros (e.g. "250" => 25000 cents)
            if !cleaned.contains(".") {
                let euros = Int(cleaned) ?? 0
                return max(0, euros * 100)
            }

            let dec = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) ?? 0
            let centsDec = dec * Decimal(100)
            let cents = NSDecimalNumber(decimal: centsDec).rounding(accordingToBehavior: nil).intValue
            return max(0, cents)
        }

        static func relativeDateTime(_ date: Date) -> String {
            let fmt = RelativeDateTimeFormatter()
            fmt.locale = .current
            fmt.unitsStyle = .abbreviated
            return fmt.localizedString(for: date, relativeTo: Date())
        }
    }
}

// MARK: - Domain

// MARK: - Transaction Type

enum TransactionType: String, Codable, Hashable, CaseIterable {
    case expense = "expense"
    case income = "income"
    
    var icon: String {
        switch self {
        case .expense: return "minus"
        case .income: return "plus"
        }
    }
    
    var color: Color {
        switch self {
        case .expense: return Color.white  // ← سفید عادی
        case .income: return .green
        }
    }
    
    var title: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        }
    }
}

// MARK: - Transaction

struct Transaction: Identifiable, Hashable, Codable {
    let id: UUID
    var amount: Int
    var date: Date
    var category: Category
    var note: String
    var paymentMethod: PaymentMethod
    var type: TransactionType  // ← جدید: income یا expense
    var attachmentData: Data?
    var attachmentType: AttachmentType?
    var lastModified: Date

    init(id: UUID = UUID(), amount: Int, date: Date, category: Category, note: String, paymentMethod: PaymentMethod = .card, type: TransactionType = .expense, attachmentData: Data? = nil, attachmentType: AttachmentType? = nil, lastModified: Date = Date()) {
        self.id = id
        self.amount = amount
        self.date = date
        self.category = category
        self.note = note
        self.paymentMethod = paymentMethod
        self.type = type
        self.attachmentData = attachmentData
        self.attachmentType = attachmentType
        self.lastModified = lastModified
    }
    
    enum CodingKeys: String, CodingKey {
        case id, amount, date, category, note, paymentMethod, type, attachmentData, attachmentType, lastModified
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        amount = try container.decode(Int.self, forKey: .amount)
        date = try container.decode(Date.self, forKey: .date)
        category = try container.decode(Category.self, forKey: .category)
        note = try container.decode(String.self, forKey: .note)
        
        // Old data compatibility
        paymentMethod = try container.decodeIfPresent(PaymentMethod.self, forKey: .paymentMethod) ?? .card
        type = try container.decodeIfPresent(TransactionType.self, forKey: .type) ?? .expense
        attachmentData = try container.decodeIfPresent(Data.self, forKey: .attachmentData)
        attachmentType = try container.decodeIfPresent(AttachmentType.self, forKey: .attachmentType)
        lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) ?? date
    }
}

// MARK: - Recurring Transaction

struct RecurringTransaction: Identifiable, Hashable, Codable {
    let id: UUID
    var amount: Int
    var category: Category
    var note: String
    var paymentMethod: PaymentMethod
    var type: TransactionType
    var frequency: RecurringFrequency
    var startDate: Date
    var endDate: Date?
    var lastGenerated: Date?
    var isActive: Bool
    
    init(id: UUID = UUID(), amount: Int, category: Category, note: String, paymentMethod: PaymentMethod = .card, type: TransactionType = .expense, frequency: RecurringFrequency, startDate: Date, endDate: Date? = nil, lastGenerated: Date? = nil, isActive: Bool = true) {
        self.id = id
        self.amount = amount
        self.category = category
        self.note = note
        self.paymentMethod = paymentMethod
        self.type = type
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.lastGenerated = lastGenerated
        self.isActive = isActive
    }
    
    func shouldGenerateForDate(_ date: Date) -> Bool {
        guard isActive else { return false }
        
        // Check if date is within range
        if date < startDate { return false }
        if let end = endDate, date > end { return false }
        
        let calendar = Calendar.current
        
        // Check if already generated for this period
        if let last = lastGenerated {
            switch frequency {
            case .daily:
                if calendar.isDate(last, inSameDayAs: date) { return false }
            case .weekly:
                if calendar.isDate(last, equalTo: date, toGranularity: .weekOfYear) { return false }
            case .monthly:
                if calendar.isDate(last, equalTo: date, toGranularity: .month) { return false }
            case .yearly:
                if calendar.isDate(last, equalTo: date, toGranularity: .year) { return false }
            }
        }
        
        return true
    }
    
    func nextOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current
        
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily: return L10n.t("recurring.daily")
        case .weekly: return L10n.t("recurring.weekly")
        case .monthly: return L10n.t("recurring.monthly")
        case .yearly: return L10n.t("recurring.yearly")
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "sun.max"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .yearly: return "calendar.badge.checkmark"
        }
    }
}

// MARK: - Payment Method

enum PaymentMethod: String, Codable, Hashable, CaseIterable {
    case cash = "cash"
    case card = "card"
    
    var icon: String {
        switch self {
        case .cash: return "banknote"
        case .card: return "creditcard.fill"  // ← fill برای جذاب‌تر شدن
        }
    }
    
    var displayName: String {
        switch self {
        case .cash: return L10n.t("payment.cash")
        case .card: return L10n.t("payment.card")
        }
    }
    
    var tint: Color {
        switch self {
        case .cash: return Color(hex: 0x2ECC71)  // سبز زنده
        case .card: return Color(hex: 0x667EEA)  // آبی-بنفش خفن
        }
    }
    
    var tintSecondary: Color {
        switch self {
        case .cash: return Color(hex: 0x27AE60)  // سبز تیره‌تر
        case .card: return Color(hex: 0x764BA2)  // بنفش تیره‌تر
        }
    }
    
    var accentColor: Color {
        switch self {
        case .cash: return Color(hex: 0x2ECC71)
        case .card: return Color(hex: 0x667EEA)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .cash:
            return [Color(hex: 0x0E0E10), Color(hex: 0x2ECC71)]  // مشکی برنامه → سبز
        case .card:
            return [Color(hex: 0x0E0E10), Color(hex: 0x9333EA)]  // مشکی برنامه → بنفش
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .cash:
            return LinearGradient(
                colors: [Color(hex: 0x0E0E10), Color(hex: 0x2ECC71)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .card:
            return LinearGradient(
                colors: [Color(hex: 0x0E0E10), Color(hex: 0x9333EA)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// نوع فایل پیوست
enum AttachmentType: String, Codable, Hashable {
    case image
    case pdf
    case other
}

// MARK: - Image/File Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Binding var attachmentType: AttachmentType?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                // فشرده‌سازی عکس برای ذخیره‌سازی بهتر
                if let compressed = image.jpegData(compressionQuality: 0.6) {
                    parent.imageData = compressed
                    parent.attachmentType = .image
                }
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileData: Data?
    @Binding var attachmentType: AttachmentType?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                parent.fileData = data
                
                // تشخیص نوع فایل
                if url.pathExtension.lowercased() == "pdf" {
                    parent.attachmentType = .pdf
                } else if ["jpg", "jpeg", "png", "heic"].contains(url.pathExtension.lowercased()) {
                    parent.attachmentType = .image
                } else {
                    parent.attachmentType = .other
                }
            } catch {
                print("Error reading file: \(error)")
            }
            
            parent.dismiss()
        }
    }
}


enum Category: Hashable, Codable {
    case groceries, rent, bills, transport, health, education, dining, shopping, entertainment, other
    case custom(String)

    // فقط کتگوری‌های پیش‌فرض (برای بودجه‌ها/سقف‌ها)
    static var allCases: [Category] {
        [.groceries, .rent, .bills, .transport, .health, .education, .dining, .shopping, .entertainment, .other]
    }

    /// Stable key for persistence / dictionaries.
    /// NOTE: for custom categories we prefix with `custom:`.
    var storageKey: String {
        switch self {
        case .groceries: return "groceries"
        case .rent: return "rent"
        case .bills: return "bills"
        case .transport: return "transport"
        case .health: return "health"
        case .education: return "education"
        case .dining: return "dining"
        case .shopping: return "shopping"
        case .entertainment: return "entertainment"
        case .other: return "other"
        case .custom(let name):
            return "custom:\(name)"
        }
    }

    var title: String {
        switch self {
        case .groceries: return "Groceries"
        case .rent: return "Rent"
        case .bills: return "Bills"
        case .transport: return "Transport"
        case .health: return "Health"
        case .education: return "Education"
        case .dining: return "Dining"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .other: return "Other"
        case .custom(let name): return name
        }
    }

    var icon: String {
        switch self {
        case .custom:
            return "tag"
        default:
            switch self {
            case .groceries: return "basket"
            case .rent: return "house"
            case .bills: return "doc.text"
            case .transport: return "car"
            case .health: return "cross.case"
            case .education: return "book"
            case .dining: return "fork.knife"
            case .shopping: return "bag"
            case .entertainment: return "gamecontroller"
            case .other: return "square.grid.2x2"
            case .custom: return "tag" // unreachable (handled بالا)
            }
        }
    }

    var tint: Color {
        switch self {
        case .custom:
            return Color(hex: 0x8395A7)
        default:
            switch self {
            case .groceries: return Color.green
            case .rent: return Color.yellow
            case .bills: return Color.orange
            case .transport: return Color.blue
            case .health: return Color(hex: 0x68DEA9)
            case .education: return Color(hex: 0x576574)
            case .dining: return Color(hex: 0xFF6B6B)
            case .shopping: return Color(hex: 0xE84393)
            case .entertainment: return Color.purple
            case .other: return Color(hex: 0x8395A7)
            case .custom: return Color(hex: 0x8395A7) // unreachable
            }
        }
    }

    // MARK: - Codable
    private enum CodingKeys: String, CodingKey { case type, value }
    private enum Kind: String, Codable { case system, custom }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(Kind.self, forKey: .type)
        switch type {
        case .system:
            let v = try c.decode(String.self, forKey: .value)
            // map string -> system case
            switch v {
            case "groceries": self = .groceries
            case "rent": self = .rent
            case "bills": self = .bills
            case "transport": self = .transport
            case "health": self = .health
            case "education": self = .education
            case "dining": self = .dining
            case "shopping": self = .shopping
            case "entertainment": self = .entertainment
            default: self = .other
            }
        case .custom:
            let name = try c.decode(String.self, forKey: .value)
            self = .custom(name)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .custom(let name):
            try c.encode(Kind.custom, forKey: .type)
            try c.encode(name, forKey: .value)
        default:
            try c.encode(Kind.system, forKey: .type)
            // store stable raw string
            let raw: String
            switch self {
            case .groceries: raw = "groceries"
            case .rent: raw = "rent"
            case .bills: raw = "bills"
            case .transport: raw = "transport"
            case .health: raw = "health"
            case .education: raw = "education"
            case .dining: raw = "dining"
            case .shopping: raw = "shopping"
            case .entertainment: raw = "entertainment"
            case .other: raw = "other"
            case .custom: raw = "other"
            }
            try c.encode(raw, forKey: .value)
        }
    }
}

// MARK: - Store

struct Store: Hashable, Codable {
    var selectedMonth: Date = Date()
    var budgetsByMonth: [String: Int] = [:]
    /// Optional per-category budgets per month, stored in euro cents.
    /// Outer key: YYYY-MM, inner key: Category.storageKey
    var categoryBudgetsByMonth: [String: [String: Int]] = [:]
    var transactions: [Transaction] = []
    // Custom categories created by user
    var customCategoryNames: [String] = []
    // Track deleted transactions for sync (Array for better JSON compatibility)
    var deletedTransactionIds: [String] = []  // UUID as string
    
    // MARK: - New Features
    var recurringTransactions: [RecurringTransaction] = []

    static func monthKey(_ date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        return String(format: "%04d-%02d", y, m)
    }

    /// Budget for the currently selected month.
    var budgetTotal: Int {
        get { budgetsByMonth[Self.monthKey(selectedMonth)] ?? 0 }
        set { budgetsByMonth[Self.monthKey(selectedMonth)] = max(0, newValue) }
    }

    func budget(for month: Date) -> Int {
        budgetsByMonth[Self.monthKey(month)] ?? 0
    }
    
    // MARK: - Savings

    /// Total spent in a given month (EUR cents).
    /// Total spent (expenses only) for a given month (EUR cents).
    func spent(for month: Date) -> Int {
        let cal = Calendar.current
        return transactions
            .filter {
                cal.isDate($0.date, equalTo: month, toGranularity: .month) &&
                $0.type == .expense
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Total income for a given month (EUR cents).
    func income(for month: Date) -> Int {
        let cal = Calendar.current
        return transactions
            .filter {
                cal.isDate($0.date, equalTo: month, toGranularity: .month) &&
                $0.type == .income
            }
            .reduce(0) { $0 + $1.amount }
    }

    /// Remaining (budget + income - spent) for a given month (EUR cents).
    func remaining(for month: Date) -> Int {
        budget(for: month) + income(for: month) - spent(for: month)
    }

    /// "Saved" is positive remainder only (never negative).
    /// For current/future months, saved is 0 (because month isn't complete yet).
    func saved(for month: Date) -> Int {
        let cal = Calendar.current
        let now = Date()
        
        // Only count saved money for months that are FULLY COMPLETE
        // If the month is current or future, saved = 0 (month isn't done yet)
        if cal.isDate(month, equalTo: now, toGranularity: .month) {
            // Current month - not complete yet, so saved = 0
            return 0
        }
        
        if month > now {
            // Future month - saved = 0
            return 0
        }
        
        // Past month - calculate actual saved
        return max(0, remaining(for: month))
    }

    /// Total saved across all COMPLETED months that have a budget set.
    var totalSaved: Int {
        let cal = Calendar.current
        var sum = 0

        for key in budgetsByMonth.keys {
            let parts = key.split(separator: "-")
            guard parts.count == 2,
                  let y = Int(parts[0]),
                  let m = Int(parts[1]) else { continue }

            var comps = DateComponents()
            comps.year = y
            comps.month = m
            comps.day = 1

            guard let d = cal.date(from: comps) else { continue }
            sum += saved(for: d)  // saved() now handles current/future month filtering
        }

        return sum
    }

    /// Saved delta vs previous month (positive => saved more).
    /// Only meaningful when comparing two COMPLETED months.
    func savedDeltaVsPreviousMonth(for month: Date) -> Int {
        let cal = Calendar.current
        guard let prev = cal.date(byAdding: .month, value: -1, to: month) else { return 0 }
        
        // If current month isn't complete, delta is meaningless
        let now = Date()
        if cal.isDate(month, equalTo: now, toGranularity: .month) || month > now {
            return 0
        }
        
        // Both months are complete - calculate delta
        return saved(for: month) - saved(for: prev)
    }

    mutating func setBudget(_ value: Int, for month: Date) {
        budgetsByMonth[Self.monthKey(month)] = max(0, value)
    }
    
    func categoryBudget(for category: Category, month: Date) -> Int {
        categoryBudgetsByMonth[Self.monthKey(month)]?[category.storageKey] ?? 0
    }

    /// Category budget for the currently selected month.
    func categoryBudget(for category: Category) -> Int {
        categoryBudget(for: category, month: selectedMonth)
    }

    mutating func setCategoryBudget(_ value: Int, for category: Category, month: Date) {
        let key = Self.monthKey(month)
        var m = categoryBudgetsByMonth[key] ?? [:]
        m[category.storageKey] = max(0, value)
        categoryBudgetsByMonth[key] = m
    }

    mutating func setCategoryBudget(_ value: Int, for category: Category) {
        setCategoryBudget(value, for: category, month: selectedMonth)
    }

    func totalCategoryBudgets(for month: Date) -> Int {
        let key = Self.monthKey(month)
        return (categoryBudgetsByMonth[key] ?? [:]).values.reduce(0, +)
    }

    func totalCategoryBudgets() -> Int {
        totalCategoryBudgets(for: selectedMonth)
    }

    mutating func add(_ t: Transaction) { transactions.append(t) }

    mutating func deleteTransactions(in items: [Transaction], offsets: IndexSet) {
        let toDelete = offsets.map { items[$0].id }
        transactions.removeAll { toDelete.contains($0.id) }
    }

    mutating func delete(id: UUID) {
        transactions.removeAll { $0.id == id }
    }

    mutating func clearMonthData(for month: Date) {
        let key = Self.monthKey(month)
        let cal = Calendar.current

        // حذف تمام تراکنش‌های ماه
        transactions.removeAll {
            cal.isDate($0.date, equalTo: month, toGranularity: .month)
        }

        // حذف بودجه کل ماه
        budgetsByMonth.removeValue(forKey: key)

        // حذف سقف‌های دسته‌بندی
        categoryBudgetsByMonth.removeValue(forKey: key)
    }
    
    /// Returns true if the given month has any stored data (transactions or budgets/caps).
    func hasMonthData(for month: Date) -> Bool {
        let key = Self.monthKey(month)
        let cal = Calendar.current

        let hasTx = transactions.contains { cal.isDate($0.date, equalTo: month, toGranularity: .month) }
        let hasBudget = (budgetsByMonth[key] ?? 0) > 0
        let hasCaps = (categoryBudgetsByMonth[key] ?? [:]).values.contains { $0 > 0 }

        return hasTx || hasBudget || hasCaps
    }
    
    var allCategories: [Category] {
        Category.allCases + customCategoryNames.map { Category.custom($0) }
    }

    mutating func addCustomCategory(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let exists = customCategoryNames.contains { $0.lowercased() == trimmed.lowercased() }
        guard !exists else { return }

        customCategoryNames.append(trimmed)
        customCategoryNames.sort { $0.lowercased() < $1.lowercased() }
    }

    // MARK: - Persistence

    private static let storageKey = "balance.store.v1"

    static func load(userId: String? = nil) -> Store {
        // Get user-specific key
        let key: String
        if let userId = userId {
            key = "store_\(userId)"
        } else {
            // Fallback to old key for migration
            key = storageKey
        }
        
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return Store()
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Store.self, from: data)
        } catch {
            // If decoding fails (schema change, corrupted data), start fresh.
            return Store()
        }
    }

    func save(userId: String? = nil) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self)
            
            // Get user-specific key
            let key: String
            if let userId = userId {
                key = "store_\(userId)"
            } else {
                key = Self.storageKey
            }
            
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // Ignore save failures silently for now.
        }
    }
}

// MARK: - Analytics

struct Insight: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let level: Level
}

enum Level: Hashable {
    case ok, watch, risk

    var icon: String {
        switch self {
        case .ok: return "checkmark"
        case .watch: return "exclamationmark"
        case .risk: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .ok: return DS.Colors.positive
        case .watch: return DS.Colors.warning
        case .risk: return DS.Colors.danger
        }
    }
}

// MARK: - Enhanced Design System

extension DS {
    /// Consistent spacing values
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    /// Standard animations
    enum Animations {
        static let quick = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let standard = Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let smooth = Animation.spring(response: 0.45, dampingFraction: 0.9)
        static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.95)
    }
    
    /// Corner radius standards
    enum Corners {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
    }
}

enum Analytics {

    struct MonthSummary {
        let budgetCents: Int  // ← اضافه شد
        let totalSpent: Int
        let remaining: Int
        let dailyAvg: Int
        let spentRatio: Double
    }

    struct Pressure {
        let title: String
        let detail: String
        let level: Level
    }

    struct Projection {
        let projectedTotal: Int
        let deltaAbs: Int
        let statusText: String
        let level: Level
    }

    struct DayPoint: Identifiable {
        let id = UUID()
        let day: Int
        let amount: Int
    }

    struct CategoryRow: Identifiable {
        let id = UUID()
        let category: Category
        let total: Int
    }
    
    struct PaymentBreakdown: Identifiable {
        let id = UUID()
        let method: PaymentMethod
        let total: Int
        let percentage: Double
    }

    struct DayGroup {
        let day: Date
        let title: String
        let items: [Transaction]
    }

    static func monthTransactions(store: Store) -> [Transaction] {
        let cal = Calendar.current
        return store.transactions
            .filter { cal.isDate($0.date, equalTo: store.selectedMonth, toGranularity: .month) }
            .sorted { $0.date > $1.date }
    }

    static func monthSummary(store: Store) -> MonthSummary {
        let tx = monthTransactions(store: store)
        let total = tx.reduce(0) { $0 + $1.amount }
        let remaining = store.budgetTotal - total

        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: store.selectedMonth) ?? 1..<31
        let daysInMonth = range.count
        let dayNow = cal.component(.day, from: Date())
        let isCurrentMonth = cal.isDate(Date(), equalTo: store.selectedMonth, toGranularity: .month)
        let divisor = max(1, isCurrentMonth ? min(dayNow, daysInMonth) : daysInMonth)
        let dailyAvg = total / divisor

        let ratio = store.budgetTotal > 0 ? Double(total) / Double(store.budgetTotal) : 0
        return .init(budgetCents: store.budgetTotal, totalSpent: total, remaining: remaining, dailyAvg: dailyAvg, spentRatio: ratio)
    }

    static func budgetPressure(store: Store) -> Pressure {
        let s = monthSummary(store: store)
        if s.spentRatio < 0.75 {
            return .init(title: NSLocalizedString("status.stable.title", comment: ""),
                        detail: NSLocalizedString("status.stable.detail", comment: ""), level: .ok)
        } else if s.spentRatio < 0.95 {
            return .init(title: NSLocalizedString("status.needs_attention.title", comment: ""),
                        detail: NSLocalizedString("status.needs_attention.detail", comment: ""), level: .watch)
        } else {
            return .init(title: NSLocalizedString("status.budget_pressure.title", comment: ""),
                        detail: NSLocalizedString("status.budget_pressure.detail", comment: ""), level: .risk)
        }
    }


    /// Returns a status line if any category cap is near/over for the selected month.
    /// Shows RISK immediately when over; otherwise WATCH when >= 90% used.
    static func categoryCapPressure(store: Store) -> Pressure? {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return nil }

        var bestWatch: Pressure? = nil

        for c in Category.allCases {
            let cap = store.categoryBudget(for: c)
            guard cap > 0 else { continue }

            let spent = tx.filter { $0.category == c }.reduce(0) { $0 + $1.amount }
            guard spent > 0 else { continue }

            if spent > cap {
                let over = spent - cap
                return .init(
                    title: "Over cap: \(c.title)",
                    detail: "You’re \(DS.Format.money(over)) above your \(DS.Format.money(cap)) cap.",
                    level: .risk
                )
            }

            let ratio = Double(spent) / Double(max(1, cap))
            if ratio >= 0.9 {
                bestWatch = .init(
                    title: "Near cap: \(c.title)",
                    detail: "Used \(DS.Format.percent(ratio)) of your \(DS.Format.money(cap)) cap.",
                    level: .watch
                )
            }
        }

        return bestWatch
    }

    static func projectedEndOfMonth(store: Store) -> Projection {
        let summary = monthSummary(store: store)
        guard store.budgetTotal > 0 else {
            return Projection(projectedTotal: summary.totalSpent, deltaAbs: 0, statusText: "Budget not set", level: .watch)
        }

        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: store.selectedMonth) ?? 1..<31
        let daysInMonth = range.count

        let isCurrentMonth = calendar.isDate(Date(), equalTo: store.selectedMonth, toGranularity: .month)
        let dayNow = calendar.component(.day, from: Date())
        let elapsed = max(1, isCurrentMonth ? min(dayNow, daysInMonth) : daysInMonth)

        // Robust daily average (outlier-resistant): winsorize daily totals across elapsed days.
        // This reduces the impact of a single unusually large day early in the month.
        let tx = monthTransactions(store: store)
        var byDay: [Int: Int] = [:]
        for t in tx {
            let d = calendar.component(.day, from: t.date)
            byDay[d, default: 0] += t.amount
        }

        // Include zero-spend days up to `elapsed` so one big day doesn't dominate.
        let dailyTotals: [Int] = (1...elapsed).map { byDay[$0] ?? 0 }

        func winsorizedMean(_ xs: [Int]) -> Double {
            guard !xs.isEmpty else { return 0 }
            if xs.count < 5 {
                // Not enough data: fall back to plain mean.
                let sum = xs.reduce(0, +)
                return Double(sum) / Double(max(1, xs.count))
            }

            let s = xs.sorted()
            let n = s.count
            let lowIdx = Int(Double(n) * 0.10)
            let highIdx = max(lowIdx, Int(Double(n) * 0.90) - 1)

            let low = s[min(max(0, lowIdx), n - 1)]
            let high = s[min(max(0, highIdx), n - 1)]

            let clampedSum = xs.reduce(0) { acc, v in
                acc + min(max(v, low), high)
            }
            return Double(clampedSum) / Double(n)
        }

        let robustDailyAvg = winsorizedMean(dailyTotals)
        let projected = Int((robustDailyAvg * Double(daysInMonth)).rounded())

        let delta = projected - store.budgetTotal

        if delta <= 0 {
            return Projection(projectedTotal: projected, deltaAbs: abs(delta), statusText: "Below monthly budget", level: .ok)
        } else if delta < store.budgetTotal / 10 {
            return Projection(projectedTotal: projected, deltaAbs: delta, statusText: "Close to budget limit", level: .watch)
        } else {
            return Projection(projectedTotal: projected, deltaAbs: delta, statusText: "Likely to exceed budget", level: .risk)
        }
    }

    static func dailySpendPoints(store: Store) -> [DayPoint] {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return [] }

        let cal = Calendar.current
        var byDay: [Int: Int] = [:]
        for t in tx {
            let d = cal.component(.day, from: t.date)
            byDay[d, default: 0] += t.amount
        }
        return byDay.keys.sorted().map { DayPoint(day: $0, amount: byDay[$0] ?? 0) }
    }

    static func categoryBreakdown(store: Store) -> [CategoryRow] {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return [] }

        var map: [Category: Int] = [:]
        for t in tx { map[t.category, default: 0] += t.amount }

        return map
            .map { CategoryRow(category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }
    
    static func paymentBreakdown(store: Store) -> [PaymentBreakdown] {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return [] }
        
        var map: [PaymentMethod: Int] = [:]
        for t in tx { map[t.paymentMethod, default: 0] += t.amount }
        
        let total = map.values.reduce(0, +)
        
        return map
            .map { PaymentBreakdown(
                method: $0.key,
                total: $0.value,
                percentage: total > 0 ? Double($0.value) / Double(total) : 0
            )}
            .sorted { $0.total > $1.total }
    }

    static func groupedByDay(_ tx: [Transaction]) -> [DayGroup] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: tx) { cal.startOfDay(for: $0.date) }

        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.setLocalizedDateFormatFromTemplate("EEEE, MMM d")

        return groups
            .map { (day, items) in
                DayGroup(day: day, title: fmt.string(from: day), items: items.sorted { $0.date > $1.date })
            }
            .sorted { $0.day > $1.day }
    }

    static func generateInsights(store: Store) -> [Insight] {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return [] }

        var out: [Insight] = []

        // Only run projection and breakdown with enough data
        if tx.count >= 5 {
            let proj = projectedEndOfMonth(store: store)
            if proj.level != .ok {
                let title = proj.level == .risk ? "This trend will pressure your budget" : "Approaching the limit"
                let detail = proj.level == .risk
                    ? "End-of-month projection is above budget. Prioritize cutting discretionary costs."
                    : "To stay in control, trim one discretionary category slightly."
                out.append(.init(title: title, detail: detail, level: proj.level))
            } else {
                out.append(.init(title: "Good control", detail: "Current trend aligns with your Main budget. Keep it steady.", level: .ok))
            }

            let breakdown = categoryBreakdown(store: store)
            if let top = breakdown.first {
                let total = breakdown.reduce(0) { $0 + $1.total }
                let share = total > 0 ? Double(top.total) / Double(total) : 0
                if share > 0.35 {
                    out.append(.init(
                        title: "Spending concentrated in “\(top.category.title)”",
                        detail: "This category is \(DS.Format.percent(share)) of monthly spending. If reducible, start here.",
                        level: .watch
                    ))
                }
            }
        }

        // Category budget caps (optional)
        for c in Category.allCases {
            let cap = store.categoryBudget(for: c)
            guard cap > 0 else { continue }

            let spent = tx.filter { $0.category == c }.reduce(0) { $0 + $1.amount }

            if spent > cap {
                let over = spent - cap
                out.append(.init(
                    title: "Over budget in “\(c.title)”",
                    detail: "You’re \(DS.Format.money(over)) above your \(DS.Format.money(cap)) cap for this category.",
                    level: .risk
                ))
            } else {
                let ratio = Double(spent) / Double(max(1, cap))
                if ratio >= 0.9 {
                    out.append(.init(
                        title: "Near the cap in “\(c.title)”",
                        detail: "You’ve used \(DS.Format.percent(ratio)) of your \(DS.Format.money(cap)) cap.",
                        level: .watch
                    ))
                }
            }
        }

        // Only run smalls, discretionary, over budget with enough data
        if tx.count >= 5 {
            let smallThreshold = max(80_000, store.budgetTotal / 500)
            let smalls = tx.filter { $0.amount <= smallThreshold }
            if smalls.count >= 8 {
                let sum = smalls.reduce(0) { $0 + $1.amount }
                out.append(.init(
                    title: "Small expenses are adding up",
                    detail: "You have \(smalls.count) small transactions totaling \(DS.Format.money(sum)). Set a daily cap for small spending.",
                    level: .watch
                ))
            }

            let dining = tx.filter { $0.category == .dining }.reduce(0) { $0 + $1.amount }
            let ent = tx.filter { $0.category == .entertainment }.reduce(0) { $0 + $1.amount }
            let total = tx.reduce(0) { $0 + $1.amount }
            if total > 0 {
                let opt = dining + ent
                let share = Double(opt) / Double(total)
                if share > 0.22 {
                    out.append(.init(
                        title: "Discretionary costs can be reduced",
                        detail: "Dining + Entertainment is \(DS.Format.percent(share)) of spending. A 10% cut noticeably reduces pressure.",
                        level: .watch
                    ))
                }
            }

            let s = monthSummary(store: store)
            if s.remaining < 0 {
                out.append(.init(
                    title: "Over budget",
                    detail: "You’re above the monthly budget. Firm move: pause non‑essential spending until month end.",
                    level: .risk
                ))
            }
        }

        return out.sorted { rank($0.level) > rank($1.level) }
    }

    static func quickActions(store: Store) -> [String] {
        let tx = monthTransactions(store: store)
        guard !tx.isEmpty else { return [] }

        var actions: [String] = []
        // Category cap driven actions (show even with few transactions)
        for c in Category.allCases {
            let cap = store.categoryBudget(for: c)
            guard cap > 0 else { continue }

            let spent = tx.filter { $0.category == c }.reduce(0) { $0 + $1.amount }
            if spent > cap {
                actions.append("Pause spending in “\(c.title)” for the rest of the month or reduce it sharply.")
                break
            }

            let ratio = Double(spent) / Double(max(1, cap))
            if ratio >= 0.9 {
                actions.append("You’re close to the “\(c.title)” cap—set a mini-cap for the next 7 days.")
                break
            }
        }

        // Only show projection/top-category actions with enough data
        if tx.count >= 5 {
            let proj = projectedEndOfMonth(store: store)

            if proj.level == .risk {
                actions.append("Set a daily spending cap for the next 7 days.")
                actions.append("Temporarily limit one discretionary category (Dining / Entertainment / Shopping).")
            }

            if let top = categoryBreakdown(store: store).first {
                actions.append("Set a weekly cap for “\(top.category.title)”.")
            }
        }

        return Array(actions.prefix(3))
    }

    private static func rank(_ l: Level) -> Int { l == .risk ? 3 : (l == .watch ? 2 : 1) }
}


private struct UUIDWrapper: Identifiable {
    let id: UUID
}

// MARK: - Helpers

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Notifications

private final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCenterDelegate()

    // Show notifications even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Banner + sound makes the test + future reminders visible while the app is open.
        return [.banner, .sound]
    }
}

private enum Notifications {
    // Identifiers
    private static let dailyID = "balance.notif.daily"
    private static let weeklyID = "balance.notif.weekly"
    private static let paydayID = "balance.notif.payday"

    // Smart (one-off) identifiers are built from these prefixes
    private static let t70Prefix = "balance.notif.threshold70."
    private static let t80Prefix = "balance.notif.threshold80."
    private static let overBudgetPrefix = "balance.notif.overbudget."
    private static let overspendPrefix = "balance.notif.overspend."
    private static let categoryPrefix = "balance.notif.categorycap."

    // Persist “already notified” markers
    private static func monthKey(_ date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        return String(format: "%04d-%02d", y, m)
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    static func syncAll(store: Store) async {
        // If not authorized, do nothing.
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else { return }

        scheduleDailyReminder()
        scheduleWeeklyCheckIn()
        schedulePaydayReminder()

        await evaluateSmartRules(store: store)
    }

    // 1) Daily reminder (simple)
    private static func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])

        var dc = DateComponents()
        dc.hour = 20
        dc.minute = 30

        let content = UNMutableNotificationContent()
        content.title = "Balance"
        content.body = "Quick check: did you log today’s expenses?"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger)
        center.add(req)
    }

    // 2) Weekly check-in (simple)
    private static func scheduleWeeklyCheckIn() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [weeklyID])

        // Sunday 18:00 (can be changed later in Settings)
        var dc = DateComponents()
        dc.weekday = 1 // Sunday
        dc.hour = 18
        dc.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Balance — Weekly check"
        content.body = "Take 60 seconds to review this week’s spending and adjust next week."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: weeklyID, content: content, trigger: trigger)
        center.add(req)
    }

    // 7) Payday reminder (simple: 1st of month at 09:00)
    private static func schedulePaydayReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [paydayID])

        var dc = DateComponents()
        dc.day = 1
        dc.hour = 9
        dc.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Balance — New month"
        content.body = "New month started. Set your budget and category caps for better control."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: paydayID, content: content, trigger: trigger)
        center.add(req)
    }

    // Smart rules (evaluated while user uses the app)
    static func evaluateSmartRules(store: Store) async {
        guard store.budgetTotal > 0 else { return }

        let mKey = monthKey(store.selectedMonth)
        let summary = Analytics.monthSummary(store: store)

        // 3) Monthly budget notifications (edge-triggered)
        // If user goes over budget, notify once. If they later go back under (e.g., edit/delete), reset so crossing again notifies again.
        let overKey = overBudgetPrefix + mKey
        let isOverNow = summary.spentRatio >= 1.0

        if !isOverNow {
            // Reset once we are back under budget.
            UserDefaults.standard.removeObject(forKey: overKey)
        }

        let alreadyOverBudgetNotified = UserDefaults.standard.bool(forKey: overKey)
        if isOverNow {
            if !alreadyOverBudgetNotified {
                // Mark and send immediately
                UserDefaults.standard.set(true, forKey: overKey)
                await scheduleImmediate(
                    id: overKey,
                    title: "Over budget",
                    body: "You’re over your monthly budget. Review spending and pause non‑essentials until month end."
                )
            }
        } else {
            // Repeatable 70/80 alerts while not over-budget.
            // 70/80 alerts (edge-triggered, once per month).
            // We keep a simple state so entering Insights or re-evaluations don't spam.
            let thresholdStateKey = "balance.notif.threshold.state." + mKey
            let lastState = UserDefaults.standard.string(forKey: thresholdStateKey) ?? "none" // none | t70 | t80

            let newState: String
            if summary.spentRatio >= 0.80 {
                newState = "t80"
            } else if summary.spentRatio >= 0.70 {
                newState = "t70"
            } else {
                newState = "none"
            }

            if newState == "none" {
                // Reset once we are back under 70% so future crossings can notify again.
                if lastState != "none" {
                    UserDefaults.standard.removeObject(forKey: thresholdStateKey)
                }
            } else {
                // Only notify on upward transitions (none -> t70, t70 -> t80, none -> t80).
                let shouldNotify: Bool
                if lastState == "none" {
                    shouldNotify = true
                } else if lastState == "t70" && newState == "t80" {
                    shouldNotify = true
                } else {
                    shouldNotify = false
                }

                if shouldNotify {
                    UserDefaults.standard.set(newState, forKey: thresholdStateKey)

                    if newState == "t70" {
                        let id = t70Prefix + mKey
                        await scheduleImmediate(
                            id: id,
                            title: "Budget alert",
                            body: "You’ve used 70% of your monthly budget. Consider trimming discretionary spending this week."
                        )
                    } else {
                        let id = t80Prefix + mKey
                        await scheduleImmediate(
                            id: id,
                            title: "Budget warning",
                            body: "You’ve used 80% of your monthly budget. Tighten spending to avoid exceeding your limit."
                        )
                    }
                }
            }
        }

        // 4) Overspend today vs daily cap — notify every time rule is evaluated
        

        // 5) Category cap near/over — edge-triggered per category per month
        let monthTx = Analytics.monthTransactions(store: store)
        for c in Category.allCases {
            let cap = store.categoryBudget(for: c)
            guard cap > 0 else { continue }

            let spent = monthTx.filter { $0.category == c }.reduce(0) { $0 + $1.amount }
            let ratio = Double(spent) / Double(max(1, cap))

            // Track last state so we only notify on transitions.
            // States: none (<0.90), near (>=0.90 and <1.0), over (>=1.0)
            let stateKey = categoryPrefix + "state." + mKey + "." + c.storageKey
            let lastState = (UserDefaults.standard.string(forKey: stateKey) ?? "none")

            let newState: String
            if ratio >= 1.0 {
                newState = "over"
            } else if ratio >= 0.90 {
                newState = "near"
            } else {
                newState = "none"
            }

            // Reset when back below threshold so future crossings notify again.
            if newState == "none" {
                if lastState != "none" {
                    UserDefaults.standard.removeObject(forKey: stateKey)
                }
                continue
            }

            // Transition: none -> near, near -> over, none -> over
            if newState != lastState {
                UserDefaults.standard.set(newState, forKey: stateKey)

                if newState == "over" {
                    let over = max(0, spent - cap)
                    let overPct = cap > 0 ? Double(over) / Double(cap) : 0
                    let id = categoryPrefix + UUID().uuidString
                    await scheduleImmediate(
                        id: id,
                        title: "Category cap exceeded",
                        body: "\(c.title): \(DS.Format.percent(overPct)) over cap (\(DS.Format.money(over)) above \(DS.Format.money(cap)))"
                    )
                } else {
                    let id = categoryPrefix + UUID().uuidString
                    await scheduleImmediate(
                        id: id,
                        title: "Approaching category cap",
                        body: "\(c.title): used \(DS.Format.percent(min(1.5, ratio))) of your \(DS.Format.money(cap)) cap."
                    )
                }
            }
        }
    }


    // Send helpers
    private static func sendOncePerMonth(id: String, title: String, body: String) async {
        // Marker is stored in UserDefaults so we don’t spam.
        let ud = UserDefaults.standard
        if ud.bool(forKey: id) { return }
        ud.set(true, forKey: id)
        await scheduleImmediate(id: id, title: title, body: body)
    }

    private static func sendOnce(id: String, title: String, body: String) async {
        let ud = UserDefaults.standard
        if ud.bool(forKey: id) { return }
        ud.set(true, forKey: id)
        await scheduleImmediate(id: id, title: title, body: body)
    }

    private static func scheduleImmediate(id: String, title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Deliver immediately (no trigger). This removes the noticeable delay.
        let req = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        do {
            try await center.add(req)
        } catch {
            // ignore
        }
    }
}



private enum Exporter {
    // MARK: - XLSX (real Office Open XML container)
    static func makeXLSX(
        monthKey: String,
        currency: String,
        budgetCents: Int,
        categoryCapsCents: [Category: Int],
        summary: Analytics.MonthSummary,
        transactions: [Transaction],
        categories: [Analytics.CategoryRow],
        daily: [Analytics.DayPoint]
    ) -> Data {
        // Build worksheets (richer export)
        let generatedAt = Date()
        let generatedFmt = DateFormatter()
        generatedFmt.locale = .current
        generatedFmt.dateFormat = "yyyy-MM-dd HH:mm:ss"

        // Parse YYYY-MM
        let parts = monthKey.split(separator: "-")
        let y = Int(parts.first ?? "0") ?? 0
        let m = Int(parts.dropFirst().first ?? "0") ?? 0

        let cal = Calendar.current
        var monthComps = DateComponents()
        monthComps.year = y
        monthComps.month = m
        monthComps.day = 1
        let monthDate = cal.date(from: monthComps) ?? Date()

        let dayNameFmt = DateFormatter()
        dayNameFmt.locale = .current
        dayNameFmt.dateFormat = "EEE" // Mon, Tue...

        // Category maps
        let spentByCategory: [Category: Int] = Dictionary(uniqueKeysWithValues: categories.map { ($0.category, $0.total) })
        let txCountByCategory: [Category: Int] = {
            var out: [Category: Int] = [:]
            for t in transactions { out[t.category, default: 0] += 1 }
            return out
        }()

        let totalSpentCents = categories.reduce(0) { $0 + $1.total }

        // Summary sheet
        let summaryRows: [[Cell]] = [
            [.s("Month"), .s(monthKey)],
            [.s("Currency"), .s(currency)],
            [.s("Generated at"), .s(generatedFmt.string(from: generatedAt))],
            [],
            [.s("Budget (€)"), .s("Spent (€)"), .s("Remaining (€)"), .s("Daily Avg (€)"), .s("Spent %")],
            [
                .n(Double(budgetCents) / 100.0),
                .n(Double(summary.totalSpent) / 100.0),
                .n(Double(summary.remaining) / 100.0),
                .n(Double(summary.dailyAvg) / 100.0),
                .n(summary.spentRatio * 100.0)
            ],
            [],
            [.s("Transactions count"), .n(Double(transactions.count))],
            [.s("Categories used"), .n(Double(Set(transactions.map { $0.category }).count))]
        ]

        // Categories sheet (add % share + transaction count)
        var catRows: [[Cell]] = [[.s("Category"), .s("Transactions"), .s("Spent (€)"), .s("Share (%)")]]
        for r in categories {
            let share = totalSpentCents > 0 ? (Double(r.total) / Double(totalSpentCents) * 100.0) : 0
            catRows.append([
                .s(r.category.title),
                .n(Double(txCountByCategory[r.category] ?? 0)),
                .n(Double(r.total) / 100.0),
                .n(share)
            ])
        }

        // Category caps sheet (full budgeting context)
        var capRows: [[Cell]] = [[.s("Category"), .s("Cap (€)"), .s("Spent (€)"), .s("Remaining (€)"), .s("Used (%)"), .s("Transactions")]]
        for c in Category.allCases {
            let cap = categoryCapsCents[c] ?? 0
            let spent = spentByCategory[c] ?? 0
            let remaining = cap - spent
            let used = cap > 0 ? (Double(spent) / Double(cap) * 100.0) : 0
            let cnt = txCountByCategory[c] ?? 0
            capRows.append([
                .s(c.title),
                .n(Double(cap) / 100.0),
                .n(Double(spent) / 100.0),
                .n(Double(remaining) / 100.0),
                .n(used),
                .n(Double(cnt))
            ])
        }

        // Daily sheet (add weekday + cumulative + remaining)
        var dailyRows: [[Cell]] = [[.s("Date"), .s("Weekday"), .s("Spent (€)"), .s("Cumulative (€)"), .s("Remaining (€)")]]
        var cumulativeDayCents = 0
        for d in daily.sorted(by: { $0.day < $1.day }) {
            cumulativeDayCents += d.amount

            var comps = DateComponents()
            comps.year = y
            comps.month = m
            comps.day = d.day
            let date = cal.date(from: comps) ?? monthDate

            dailyRows.append([
                .s(String(format: "%04d-%02d-%02d", y, m, d.day)),
                .s(dayNameFmt.string(from: date)),
                .n(Double(d.amount) / 100.0),
                .n(Double(cumulativeDayCents) / 100.0),
                .n(Double(budgetCents - cumulativeDayCents) / 100.0)
            ])
        }

        // Transactions sheet (most detailed)
        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "yyyy-MM-dd"

        var txRows: [[Cell]] = [[
            .s("Date"),
            .s("Category"),
            .s("Payment Method"),  // ← جدید
            .s("Note"),
            .s("Amount (€)"),
            .s("Amount (cents)"),
            .s("Running spent (€)"),
            .s("Remaining (€)"),
            .s("Transaction ID")
        ]]

        var runningCents = 0
        for t in transactions.sorted(by: { $0.date < $1.date }) {
            runningCents += t.amount
            txRows.append([
                .s(df.string(from: t.date)),
                .s(t.category.title),
                .s(t.paymentMethod.displayName),  // ← جدید
                .s(t.note),
                .n(Double(t.amount) / 100.0),
                .n(Double(t.amount)),
                .n(Double(runningCents) / 100.0),
                .n(Double(budgetCents - runningCents) / 100.0),
                .s(t.id.uuidString)
            ])
        }

        // Payment breakdown sheet (new)
        var paymentMap: [PaymentMethod: Int] = [:]
        for t in transactions { paymentMap[t.paymentMethod, default: 0] += t.amount }
        
        let totalSpent = paymentMap.values.reduce(0, +)
        let paymentBreakdown = paymentMap.map { (method, total) in
            (method: method, total: total, percentage: totalSpent > 0 ? Double(total) / Double(totalSpent) : 0)
        }.sorted { $0.total > $1.total }
        
        var paymentRows: [[Cell]] = [[.s("Payment Method"), .s("Transactions"), .s("Amount (€)"), .s("Share (%)")]]
        for p in paymentBreakdown {
            let txCount = transactions.filter { $0.paymentMethod == p.method }.count
            paymentRows.append([
                .s(p.method.displayName),
                .n(Double(txCount)),
                .n(Double(p.total) / 100.0),
                .n(p.percentage * 100.0)
            ])
        }

        let sheets = [
            (name: "Summary", rows: summaryRows),
            (name: "Categories", rows: catRows),
            (name: "Category caps", rows: capRows),
            (name: "Payment methods", rows: paymentRows),  // ← جدید
            (name: "Daily", rows: dailyRows),
            (name: "Transactions", rows: txRows)
        ]

        let sheetNames = sheets.map { $0.name }
        let sheetCount = sheets.count

        // Assemble all files required for a minimal XLSX
        var entries: [(String, Data)] = []

        entries.append(("[Content_Types].xml", Data(contentTypesXML(sheetCount: sheetCount).utf8)))
        entries.append(("_rels/.rels", Data(relsXML().utf8)))
        entries.append(("xl/workbook.xml", Data(workbookXML(sheetNames: sheetNames).utf8)))
        entries.append(("xl/_rels/workbook.xml.rels", Data(workbookRelsXML(sheetCount: sheetCount).utf8)))

        // Minimal styles (so Excel is happy)
        entries.append(("xl/styles.xml", Data(stylesXML().utf8)))

        for (idx, s) in sheets.enumerated() {
            let xml = worksheetXML(rows: s.rows)
            entries.append(("xl/worksheets/sheet\(idx + 1).xml", Data(xml.utf8)))
        }

        return zipXLSX(entries: entries)
    }

    private static func contentTypesXML(sheetCount: Int) -> String {
        let overrides = (1...sheetCount).map { i in
            "  <Override PartName=\"/xl/worksheets/sheet\(i).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
        }.joined(separator: "\n")

        return """
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">
  <Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>
  <Default Extension=\"xml\" ContentType=\"application/xml\"/>
  <Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>
  <Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>
\(overrides)
</Types>
"""
    }

    private static func stylesXML() -> String {
        return """
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">
  <fonts count=\"1\"><font/></fonts>
  <fills count=\"2\">
    <fill><patternFill patternType=\"none\"/></fill>
    <fill><patternFill patternType=\"gray125\"/></fill>
  </fills>
  <borders count=\"1\"><border/></borders>
  <cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs>
  <cellXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/></cellXfs>
  <cellStyles count=\"1\"><cellStyle name=\"Normal\" xfId=\"0\" builtinId=\"0\"/></cellStyles>
</styleSheet>
"""
    }

private static func zipXLSX(entries: [(String, Data)]) -> Data {
    let fm = FileManager.default
    let dir = fm.temporaryDirectory.appendingPathComponent("balance.xlsx.tmp", isDirectory: true)
    try? fm.removeItem(at: dir)
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

    let zipURL = dir.appendingPathComponent("out.xlsx")
    try? fm.removeItem(at: zipURL)

    do {
        let archive = try Archive(url: zipURL, accessMode: .create)

        for (path, data) in entries {
            try archive.addEntry(
                with: path,
                type: .file,
                uncompressedSize: Int64(data.count),
                compressionMethod: .deflate,
                bufferSize: 16_384,
                progress: nil,
                provider: { position, size in
                    let start = Int(position)
                    let end = min(start + Int(size), data.count)
                    return data.subdata(in: start..<end)
                }
            )
        }

        return (try? Data(contentsOf: zipURL)) ?? Data()
    } catch {
        return Data()
    }
}

    // ---------- CSV (همین که داری می‌مونه)

    // MARK: - CSV (single file with sections)
    static func makeCSV(
        monthKey: String,
        currency: String,
        budgetCents: Int,
        summary: Analytics.MonthSummary,
        transactions: [Transaction],
        categories: [Analytics.CategoryRow],
        daily: [Analytics.DayPoint]
    ) -> String {
        func esc(_ s: String) -> String {
            let needsQuotes = s.contains(",") || s.contains("\n") || s.contains("\"")
            var out = s.replacingOccurrences(of: "\"", with: "\"\"")
            if needsQuotes { out = "\"" + out + "\"" }
            return out
        }

        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "yyyy-MM-dd"

        var lines: [String] = []

        // Summary
        lines.append("# Summary")
        lines.append("month,currency,budget_eur,spent_eur,remaining_eur,daily_avg_eur,spent_percent")
        lines.append("\(monthKey),\(currency),\(String(format: "%.2f", Double(budgetCents)/100.0)),\(String(format: "%.2f", Double(summary.totalSpent)/100.0)),\(String(format: "%.2f", Double(summary.remaining)/100.0)),\(String(format: "%.2f", Double(summary.dailyAvg)/100.0)),\(Int((summary.spentRatio*100.0).rounded()))%")
        lines.append("")

        // Categories
        lines.append("# Categories")
        lines.append("category,spent_eur")
        for r in categories {
            lines.append("\(esc(r.category.title)),\(String(format: "%.2f", Double(r.total)/100.0))")
        }
        lines.append("")

        // Daily
        lines.append("# Daily")
        lines.append("day,spent_eur")
        for d in daily.sorted(by: { $0.day < $1.day }) {
            lines.append("\(d.day),\(String(format: "%.2f", Double(d.amount)/100.0))")
        }
        lines.append("")

        // Transactions
        lines.append("# Transactions")
        lines.append("date,category,payment_method,note,amount_eur")
        for t in transactions.sorted(by: { $0.date < $1.date }) {
            let dateStr = df.string(from: t.date)
            let cat = esc(t.category.title)
            let payment = esc(t.paymentMethod.displayName)  // ← جدید
            let note = esc(t.note)
            let eur = String(format: "%.2f", Double(t.amount) / 100.0)
            lines.append("\(dateStr),\(cat),\(payment),\(note),\(eur)")
        }

        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - SpreadsheetML 2003 XML (Excel can open; extension is kept as .xlsx by caller)
    static func makeExcelXML(
        monthKey: String,
        currency: String,
        budgetCents: Int,
        summary: Analytics.MonthSummary,
        transactions: [Transaction],
        categories: [Analytics.CategoryRow],
        daily: [Analytics.DayPoint]
    ) -> String {
        func xesc(_ s: String) -> String {
            s.replacingOccurrences(of: "&", with: "&amp;")
             .replacingOccurrences(of: "<", with: "&lt;")
             .replacingOccurrences(of: ">", with: "&gt;")
             .replacingOccurrences(of: "\"", with: "&quot;")
             .replacingOccurrences(of: "'", with: "&apos;")
        }

        let df = DateFormatter()
        df.locale = .current
        df.dateFormat = "yyyy-MM-dd"

        func row(_ cells: [String], header: Bool = false) -> String {
            var out = "      <Row>\n"
            for c in cells {
                let style = header ? " ss:StyleID=\"sHeader\"" : ""
                out += "        <Cell\(style)><Data ss:Type=\"String\">\(xesc(c))</Data></Cell>\n"
            }
            out += "      </Row>\n"
            return out
        }

        func sheet(_ name: String, _ rows: [String]) -> String {
            var out = "  <Worksheet ss:Name=\"\(xesc(name))\">\n    <Table>\n"
            for r in rows { out += r }
            out += "    </Table>\n  </Worksheet>\n"
            return out
        }

        let summaryRows: [String] = [
            row(["Month", monthKey], header: true),
            row(["Currency", currency]),
            row([""], header: false),
            row(["Budget (€)", "Spent (€)", "Remaining (€)", "Daily Avg (€)", "Spent %"], header: true),
            row([
                String(format: "%.2f", Double(budgetCents)/100.0),
                String(format: "%.2f", Double(summary.totalSpent)/100.0),
                String(format: "%.2f", Double(summary.remaining)/100.0),
                String(format: "%.2f", Double(summary.dailyAvg)/100.0),
                String(format: "%.0f%%", summary.spentRatio*100.0)
            ])
        ]

        var catRows: [String] = [row(["Category", "Spent (€)"], header: true)]
        for r in categories {
            catRows.append(row([r.category.title, String(format: "%.2f", Double(r.total)/100.0)]))
        }

        var dayRows: [String] = [row(["Day", "Spent (€)"], header: true)]
        for d in daily.sorted(by: { $0.day < $1.day }) {
            dayRows.append(row(["\(d.day)", String(format: "%.2f", Double(d.amount)/100.0)]))
        }

        var txRows: [String] = [row(["Date", "Category", "Note", "Amount (€)"], header: true)]
        for t in transactions.sorted(by: { $0.date < $1.date }) {
            txRows.append(row([
                df.string(from: t.date),
                t.category.title,
                t.note,
                String(format: "%.2f", Double(t.amount)/100.0)
            ]))
        }

        let workbook = """
        <?xml version="1.0"?>
        <?mso-application progid="Excel.Sheet"?>
        <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
         xmlns:o="urn:schemas-microsoft-com:office:office"
         xmlns:x="urn:schemas-microsoft-com:office:excel"
         xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
          <Styles>
            <Style ss:ID="sHeader"><Font ss:Bold="1"/></Style>
          </Styles>
        """

        return workbook
            + sheet("Summary", summaryRows)
            + sheet("Categories", catRows)
            + sheet("Daily", dayRows)
            + sheet("Transactions", txRows)
            + "</Workbook>\n"
    }

    private static func relsXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
    }

    private static func workbookXML(sheetNames: [String]) -> String {
        let sheets = sheetNames.enumerated().map { idx, name in
            "<sheet name=\"\(xmlEsc(name))\" sheetId=\"\(idx+1)\" r:id=\"rId\(idx+1)\"/>"
        }.joined()

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
          xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>\(sheets)</sheets>
        </workbook>
        """
    }

    private static func workbookRelsXML(sheetCount: Int) -> String {
        let sheetRels = (1...sheetCount).map { i in
            "<Relationship Id=\"rId\(i)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet\(i).xml\"/>"
        }.joined(separator: "\n  ")

        let stylesRel = "<Relationship Id=\"rId\(sheetCount + 1)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>"

        return """
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">
  \(sheetRels)
  \(stylesRel)
</Relationships>
"""
    }
    
    private enum Cell {
        case s(String)   // string
        case n(Double)   // number
    }

    private static func worksheetXML(rows: [[Cell]]) -> String {
        func colRef(_ col: Int) -> String {
            var n = col
            var s = ""
            while n > 0 {
                let r = (n - 1) % 26
                s = String(UnicodeScalar(65 + r)!) + s
                n = (n - 1) / 26
            }
            return s
        }

        var xmlRows = ""
        for (rIdx, row) in rows.enumerated() {
            let rowNum = rIdx + 1
            var cells = ""
            for (cIdx, cell) in row.enumerated() {
                let ref = "\(colRef(cIdx + 1))\(rowNum)"
                switch cell {
                case .s(let v):
                    cells += "<c r=\"\(ref)\" t=\"inlineStr\"><is><t>\(xmlEsc(v))</t></is></c>"
                case .n(let v):
                    let s = String(format: "%.2f", v) // dot decimal
                    cells += "<c r=\"\(ref)\"><v>\(s)</v></c>"
                }
            }
            xmlRows += "<row r=\"\(rowNum)\">\(cells)</row>"
        }

        return """
<?xml version="1.0" encoding="UTF-8"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>\(xmlRows)</sheetData>
</worksheet>
"""
    }

    private static func centsToEuros(_ cents: Int) -> Double { Double(cents) / 100.0 }

    private static func xmlEsc(_ s: String) -> String {
        var out = s
        out = out.replacingOccurrences(of: "&", with: "&amp;")
        out = out.replacingOccurrences(of: "<", with: "&lt;")
        out = out.replacingOccurrences(of: ">", with: "&gt;")
        out = out.replacingOccurrences(of: "\"", with: "&quot;")
        out = out.replacingOccurrences(of: "'", with: "&apos;")
        return out
    }
}



private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
    

// MARK: - Import Mode

enum ImportMode {
    case merge    // اضافه کردن به موجودی
    case replace  // پاک کردن موجودی و جایگزینی
}

// MARK: - Import Transactions Screen

private struct ImportTransactionsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var store: Store
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var firestoreManager: FirestoreManager

    @State private var pickedURL: URL? = nil
    @State private var parsed: ParsedCSV? = nil
    @State private var statusText: String? = nil
    @State private var isPicking = false
    @State private var showImportModeAlert = false  // ← جدید
    @State private var pendingImportParsed: ParsedCSV? = nil  // ← موقت نگه داری

    // Column mapping
    @State private var colDate: Int? = nil
    @State private var colAmount: Int? = nil
    @State private var colCategory: Int? = nil
    @State private var colNote: Int? = nil
    @State private var colPaymentMethod: Int? = nil  // جدید

    @State private var hasHeaderRow: Bool = true

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    DS.Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.t("import.from_csv"))
                                .font(DS.Typography.section)
                                .foregroundStyle(DS.Colors.text)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(L10n.t("import.csv_columns"))
                                Text(L10n.t("import.csv_format"))
                                Text("Note: If you import the same CSV again, Balance will only add transactions that aren’t already in the app (duplicates are skipped).")
                            }
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)

                            Button {
                                isPicking = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc")
                                    Text(pickedURL == nil ? "Choose CSV file" : pickedURL!.lastPathComponent)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(DS.PrimaryButton())

                            Text(L10n.t("import.xlsx_tip"))
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                        }
                    }

                    if let parsed {
                        DS.Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(L10n.t("import.columns"))
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                Toggle(L10n.t("import.header_row"), isOn: $hasHeaderRow)
                                    .tint(DS.Colors.positive)

                                columnPicker(title: "Date", columns: parsed.columns, selection: $colDate)
                                columnPicker(title: "Amount", columns: parsed.columns, selection: $colAmount)
                                columnPicker(title: "Category", columns: parsed.columns, selection: $colCategory)
                                columnPicker(title: "Note (optional)", columns: parsed.columns, selection: $colNote)
                                columnPicker(title: "Payment Method (optional)", columns: parsed.columns, selection: $colPaymentMethod)

                                Divider().overlay(DS.Colors.grid)

                                Text(L10n.t("import.preview"))
                                    .font(DS.Typography.section)
                                    .foregroundStyle(DS.Colors.text)

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(parsed.previewRows.prefix(10).indices, id: \.self) { i in
                                        let row = parsed.previewRows[i]
                                        Text(row.joined(separator: "  |  "))
                                            .font(DS.Typography.caption)
                                            .foregroundStyle(DS.Colors.subtext)
                                            .lineLimit(1)
                                    }
                                }

                                Divider().overlay(DS.Colors.grid)

                                Button {
                                    // Check if transactions exist
                                    if !store.transactions.isEmpty {
                                        // Ask user: merge or replace
                                        pendingImportParsed = parsed
                                        showImportModeAlert = true
                                    } else {
                                        // No transactions, just import
                                        importNow(parsed, mode: .merge)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text(L10n.t("import.import_btn"))
                                    }
                                }
                                .buttonStyle(DS.PrimaryButton())
                                .disabled(colDate == nil || colAmount == nil || colCategory == nil)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if let statusText {
                        DS.Card {
                            Text(statusText)
                                .font(DS.Typography.caption)
                                .foregroundStyle(statusText.hasPrefix("Imported") ? DS.Colors.positive : DS.Colors.danger)
                        }
                        .transition(.opacity)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(DS.Colors.subtext)
            }
        }
        .sheet(isPresented: $isPicking) {
            CSVDocumentPicker { url in
                pickedURL = url
                parse(url: url)
            }
        }
        .onChange(of: hasHeaderRow) { _, _ in
            if let parsed { autoDetectMapping(parsed) }
        }
        .alert(L10n.t("import.mode_title"), isPresented: $showImportModeAlert) {
            Button(L10n.t("import.mode_merge")) {
                if let p = pendingImportParsed {
                    importNow(p, mode: .merge)
                    pendingImportParsed = nil
                }
            }
            
            Button(L10n.t("import.mode_replace"), role: .destructive) {
                if let p = pendingImportParsed {
                    importNow(p, mode: .replace)
                    pendingImportParsed = nil
                }
            }
            
            Button(L10n.t("common.cancel"), role: .cancel) {
                pendingImportParsed = nil
            }
        } message: {
            Text(String(format: L10n.t("import.mode_message"), store.transactions.count))
        }
    }

    // MARK: UI helpers

    private func columnPicker(title: String, columns: [String], selection: Binding<Int?>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.subtext)

            Picker(title, selection: Binding(get: {
                selection.wrappedValue ?? -1
            }, set: { newValue in
                selection.wrappedValue = (newValue >= 0 ? newValue : nil)
            })) {
                Text("—").tag(-1)
                ForEach(columns.indices, id: \.self) { idx in
                    Text(columns[idx]).tag(idx)
                }
            }
            .pickerStyle(.menu)
            .tint(DS.Colors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(DS.Colors.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Colors.grid, lineWidth: 1)
            )
        }
    }

    // MARK: Parsing / Mapping

    private func readCSVText(from url: URL) throws -> String {
        // DocumentPicker URLs may require security-scoped access
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)

        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .windowsCP1252, // Excel in many locales (e.g., €)
            .isoLatin1
        ]

        for enc in encodings {
            if let s = String(data: data, encoding: enc) {
                return s
            }
        }

        throw NSError(domain: "CSV", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported text encoding"])
    }

    private func parse(url: URL) {
        statusText = nil
        parsed = nil

        do {
            let text = try readCSVText(from: url)
            let table = CSV.parse(text)

            guard !table.isEmpty else {
                statusText = "CSV is empty."
                return
            }

            let header = table.first ?? []
            let rows = Array(table.dropFirst())

            let columns: [String]
            let previewRows: [[String]]

            if hasHeaderRow {
                columns = header.map { $0.isEmpty ? "(empty)" : $0 }
                previewRows = Array(rows.prefix(14))
            } else {
                let maxCols = table.map { $0.count }.max() ?? 0
                columns = (0..<maxCols).map { "Column \($0 + 1)" }
                previewRows = Array(table.prefix(14))
            }

            let parsedCSV = ParsedCSV(raw: table, columns: columns, previewRows: previewRows)
            parsed = parsedCSV
            autoDetectMapping(parsedCSV)

        } catch {
            statusText = "Could not read file. Export as CSV UTF-8 (or a standard CSV)."
        }
    }

    private func autoDetectMapping(_ parsed: ParsedCSV) {
        func norm(_ s: String) -> String {
            s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        let names = parsed.columns.map(norm)

        func firstIndex(matching any: [String]) -> Int? {
            for a in any {
                if let idx = names.firstIndex(where: { $0 == a || $0.contains(a) }) { return idx }
            }
            return nil
        }

        colDate = firstIndex(matching: ["date", "day", "datum"])
        colAmount = firstIndex(matching: ["amount", "value", "spent", "cost", "eur", "€"])
        colCategory = firstIndex(matching: ["category", "cat", "type"])
        colNote = firstIndex(matching: ["note", "description", "desc", "memo"])
        colPaymentMethod = firstIndex(matching: ["payment", "method", "zahlungsmethode", "cash", "card"])
    }

    private func parseDate(_ s: String) -> Date? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        // 1) Try plain date formats (most common)
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")

        let fmts = [
            "yyyy-MM-dd",
            "dd.MM.yyyy",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "yyyy/MM/dd"
        ]
        for f in fmts {
            df.dateFormat = f
            if let d = df.date(from: trimmed) { return d }
        }

        // 2) Try dates with time (Excel / Numbers often exports these)
        let fmtsWithTime = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]
        for f in fmtsWithTime {
            df.dateFormat = f
            if let d = df.date(from: trimmed) { return d }
        }

        // 3) Try ISO 8601 (with/without fractional seconds)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: trimmed) { return d }

        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]
        if let d = iso2.date(from: trimmed) { return d }

        return nil
    }

    private func mapCategory(_ s: String) -> Category {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.isEmpty { return .other }

        for c in Category.allCases {
            if c.title.lowercased() == t { return c }
            if c.storageKey.lowercased() == t { return c }
        }

        if t.contains("groc") { return .groceries }
        if t.contains("rent") { return .rent }
        if t.contains("bill") { return .bills }
        if t.contains("trans") || t.contains("uber") || t.contains("taxi") { return .transport }
        if t.contains("health") || t.contains("pharm") { return .health }
        if t.contains("edu") || t.contains("school") { return .education }
        if t.contains("dining") || t.contains("food") || t.contains("restaurant") { return .dining }
        if t.contains("shop") { return .shopping }
        if t.contains("ent") || t.contains("movie") || t.contains("game") { return .entertainment }
        return .other
    }
    
    private func mapPaymentMethod(_ s: String) -> PaymentMethod {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.isEmpty { return .cash }  // default
        
        // Check for exact matches
        if t == "cash" || t == "bar" || t == "bargeld" || t == "efectivo" || t == "نقدی" { return .cash }
        if t == "card" || t == "karte" || t == "tarjeta" || t == "کارت" { return .card }
        
        // Check for partial matches
        if t.contains("cash") || t.contains("bar") { return .cash }
        if t.contains("card") || t.contains("kart") { return .card }
        
        return .cash  // default to cash if unknown
    }

    private func importNow(_ parsed: ParsedCSV, mode: ImportMode) {
        guard let dIdx = colDate, let aIdx = colAmount, let cIdx = colCategory else {
            statusText = "Please map Date, Amount, Category columns."
            return
        }

        let table = parsed.raw
        let dataRows: [[String]] = hasHeaderRow ? Array(table.dropFirst()) : table

        // If mode is Replace, clear all existing transactions first
        if mode == .replace {
            store.transactions.removeAll()
        }

        // Build a signature set for existing transactions so we can prevent re-importing
        // the same data even if the filename differs.
        func txSignature(date: Date, amountCents: Int, category: Category, note: String) -> String {
            let day = Calendar.current.startOfDay(for: date)
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd"
            let dayStr = df.string(from: day)
            let noteNorm = note.trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(dayStr)|\(amountCents)|\(category.storageKey)|\(noteNorm)"
        }

        var existingSigs: Set<String> = []
        existingSigs.reserveCapacity(store.transactions.count)
        for t in store.transactions {
            existingSigs.insert(txSignature(date: t.date, amountCents: t.amount, category: t.category, note: t.note))
        }

        // First pass: validate + detect duplicates (against store and within the CSV)
        var newTransactions: [Transaction] = []
        newTransactions.reserveCapacity(max(0, dataRows.count))

        var newSigs: Set<String> = []
        var added = 0
        var skipped = 0
        var dupesFound = 0
        var importedMonths: Set<String> = []
        var latestImportedDate: Date? = nil

        for r in dataRows {
            func cell(_ idx: Int) -> String { idx < r.count ? r[idx] : "" }

            guard let date = parseDate(cell(dIdx)) else { skipped += 1; continue }

            let amountCents = DS.Format.cents(from: cell(aIdx))
            if amountCents <= 0 { skipped += 1; continue }

            let category = mapCategory(cell(cIdx))
            let note = (colNote == nil) ? "" : cell(colNote!)
            let paymentMethod = (colPaymentMethod == nil) ? .cash : mapPaymentMethod(cell(colPaymentMethod!))

            let sig = txSignature(date: date, amountCents: amountCents, category: category, note: note)

            // Duplicate against existing store OR repeated rows inside the CSV.
            if existingSigs.contains(sig) || newSigs.contains(sig) {
                dupesFound += 1
                continue
            }

            newSigs.insert(sig)
            importedMonths.insert(Store.monthKey(date))
            if let cur = latestImportedDate {
                if date > cur { latestImportedDate = date }
            } else {
                latestImportedDate = date
            }

            newTransactions.append(Transaction(
                amount: amountCents,
                date: date,
                category: category,
                note: note,
                paymentMethod: paymentMethod
            ))
            added += 1
        }

        if added == 0 {
            if dupesFound > 0 {
                statusText = "Nothing new to import. \(dupesFound) duplicate transaction(s) detected and skipped."
            } else {
                statusText = "No rows imported. Check date format and amount values."
            }
            return
        }

        // Second pass: apply changes only after we know there are no duplicates.
        for t in newTransactions {
            store.add(t)
        }

        // Jump to a relevant month so the user can immediately see what was imported.
        // If multiple months exist in the CSV, jump to the latest imported month.
        if let latestImportedDate {
            store.selectedMonth = latestImportedDate
        } else if let anyKey = importedMonths.first {
            // Fallback: should rarely happen, but keep it safe.
            // Keep selectedMonth unchanged if we can't derive a date.
            _ = anyKey
        }

        // Save
        if let userId = self.authManager.currentUser?.uid {
            store.save(userId: userId)
            
            // Also save to cloud
            Task {
                try? await self.firestoreManager.saveStore(store, userId: userId)
            }
        }
        
        Haptics.importSuccess()  // ← استفاده از haptic مخصوص import
        statusText = "Imported \(added) new transaction(s). Skipped \(skipped). Duplicates skipped: \(dupesFound)."
    }

    // MARK: Models

    private struct ParsedCSV {
        let raw: [[String]]
        let columns: [String]
        let previewRows: [[String]]
    }
}

// MARK: - CSV Document Picker

private struct CSVDocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [UTType.commaSeparatedText, UTType.plainText]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

// MARK: - CSV Parser

private enum CSV {
    static func parse(_ text: String) -> [[String]] {
        // Strip UTF-8 BOM if present (common with Excel/Numbers exports)
        let cleaned = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text

        // Normalize line endings so parsing is consistent:
        // - CRLF (\r\n)
        // - CR-only (\r)
        // - Unicode line separators (\u2028 / \u2029)
        let normalized = cleaned
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n")

        // Auto-detect delimiter: Excel in many EU locales uses ';' instead of ','
        let firstLine = normalized.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
        let commaCount = firstLine.filter { $0 == "," }.count
        let semiCount = firstLine.filter { $0 == ";" }.count
        let delimiter: Character = (semiCount > commaCount) ? ";" : ","

        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false

        func endField() {
            row.append(field)
            field = ""
        }

        func endRow() {
            rows.append(row)
            row = []
        }

        let chars = Array(normalized)
        var i = 0
        while i < chars.count {
            let ch = chars[i]

            if inQuotes {
                if ch == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" {
                        field.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(ch)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                } else if ch == delimiter {
                    endField()
                } else if ch == "\n" {
                    endField()
                    endRow()
                } else {
                    field.append(ch)
                }
            }

            i += 1
        }

        if !field.isEmpty || !row.isEmpty {
            endField()
            endRow()
        }

        return rows.map { $0.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
    }
}
