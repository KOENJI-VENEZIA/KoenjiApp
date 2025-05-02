//
//  SidebarView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 28/12/24.
//

import SwiftUI

// Custom button style for navigation links
struct NavigationButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? 
                          Color.accentColor.opacity(0.2) :
                          configuration.isPressed ? 
                          Color.primary.opacity(0.1) : 
                          Color.secondary.opacity(0.05))
            )
            .overlay(
                HStack {
                    if isActive {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 4)
                    }
                    Spacer()
                }
                .mask(RoundedRectangle(cornerRadius: 10))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Modifier to conditionally add the simultaneousGesture only on iPad
struct iPadGestureModifier: ViewModifier {
    @Binding var selectedNavItem: String
    var itemName: String
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @ViewBuilder
    func body(content: Content) -> some View {
        // Only apply the gesture on iPad (horizontalSizeClass == .regular)
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .simultaneousGesture(TapGesture().onEnded {
                    selectedNavItem = itemName
                })
        } else {
            content
        }
    }
}

/// A view that displays a sidebar navigation menu
///
/// This view shows a sidebar navigation menu with various options for the user.
/// It includes links to the database, timeline, layout, sales manager, and profile.
/// It also displays the app version and profile avatar.
struct SidebarView: View {
    @EnvironmentObject var env: AppDependencies
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: AppleSignInViewModel

    @Environment(\.horizontalSizeClass) private var sizeClass
    
    @StateObject private var notificationManager = NotificationManager.shared

    @State var unitView = LayoutUnitViewModel()
    
    @Binding  var selectedReservation: Reservation?
    @Binding  var currentReservation: Reservation?
    @Binding  var selectedCategory: Reservation.ReservationCategory? 
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var isSessionIconShift: Bool
    
    @State private var showingReservationInfo = false
    @AppStorage("userIdentifier") private var userIdentifier: String = ""
    
    // Track the currently selected navigation item
    @State private var selectedNavItem: String = ""

    
    private var isCompact: Bool { sizeClass == .compact }
    
    init(selectedReservation: Binding<Reservation?>, currentReservation: Binding<Reservation?>, selectedCategory: Binding<Reservation.ReservationCategory?>, columnVisibility: Binding<NavigationSplitViewVisibility>, isSessionIconShift: Binding<Bool>) {
        self._selectedReservation = selectedReservation
        self._currentReservation = currentReservation
        self._selectedCategory = selectedCategory
        self._columnVisibility = columnVisibility
        self._isSessionIconShift = isSessionIconShift
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            appState.selectedCategory.sidebarColor
                .ignoresSafeArea() // Sidebar background
            
            Image("logo_image")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 90) // Adjust size as needed
                .frame(maxWidth: .infinity, alignment: .bottomLeading)
                .padding(.horizontal)
                .drawingGroup()
            
            VStack(alignment: .leading) {
                HStack {    
                    Text("KOENJI. VENEZIA")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.leading, 8)

                    Spacer()
                    
                    ProfileAvatarView(profile: ProfileStore.shared.currentProfile)
                            .padding(.trailing, 8)
//
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("NAVIGATION")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        
                        // Database button
                        NavigationLink(
                            destination: DatabaseView(
                                columnVisibility: $columnVisibility, isDatabase: $isSessionIconShift
                            )
                        ) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 18))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.primary)
                                
                                Text("Database")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.clear)
                            .cornerRadius(10)
                        }
                        .buttonStyle(NavigationButtonStyle(isActive: selectedNavItem == "Database"))
                        #if targetEnvironment(macCatalyst) || os(iOS)
                        .modifier(iPadGestureModifier(selectedNavItem: $selectedNavItem, itemName: "Database"))
                        #endif
                        
                        // Timeline button
                        NavigationLink(
                            destination: TabsView(
                                columnVisibility: $columnVisibility,
                                isSessionIconShift: $isSessionIconShift
                            )
                            .ignoresSafeArea(.container, edges: .top)
                        ) {
                            HStack {
                                Image(systemName: "calendar.day.timeline.left")
                                    .font(.system(size: 18))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.primary)
                                
                                Text("Timeline")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.clear)
                            .cornerRadius(10)
                        }
                        .buttonStyle(NavigationButtonStyle(isActive: selectedNavItem == "Timeline"))
                        #if targetEnvironment(macCatalyst) || os(iOS)
                        .modifier(iPadGestureModifier(selectedNavItem: $selectedNavItem, itemName: "Timeline"))
                        #endif
                        
                        // Layout button
                        if !isCompact {
                            NavigationLink(
                                destination: LayoutView(
                                    appState: appState,
                                    store: env.store,
                                    reservationService: env.reservationService,
                                    clusterServices: env.clusterServices,
                                    layoutServices: env.layoutServices,
                                    resCache: env.resCache,
                                    selectedReservation: $selectedReservation,
                                    columnVisibility: $columnVisibility
                                )
                            ) {
                                HStack {
                                    Image(systemName: "rectangle.grid.3x2")
                                        .font(.system(size: 18))
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.primary)
                                    
                                    Text("Layout Tavoli")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.clear)
                                .cornerRadius(10)
                            }
                            .buttonStyle(NavigationButtonStyle(isActive: selectedNavItem == "Layout"))
#if targetEnvironment(macCatalyst) || os(iOS)
                            .modifier(iPadGestureModifier(selectedNavItem: $selectedNavItem, itemName: "Layout"))
#endif
                        }
                        // Sales Manager button
                        NavigationLink(
                            destination: SalesManagerView(columnVisibility: $appState.columnVisibility)
                                .environmentObject(env)
                        ) {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.system(size: 18))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.primary)
                                
                                Text("Gestione Vendite")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.clear)
                            .cornerRadius(10)
                        }
                        .buttonStyle(NavigationButtonStyle(isActive: selectedNavItem == "SalesManager"))
                        #if targetEnvironment(macCatalyst) || os(iOS)
                        .modifier(iPadGestureModifier(selectedNavItem: $selectedNavItem, itemName: "SalesManager"))
                        #endif
                        
                        Spacer(minLength: 30)
                        
                        Divider()
                            .background(Color.primary.opacity(0.1))
                            .padding(.vertical, 8)
                        
                        // Settings button
                        NavigationLink(destination: AppVersionView()
                            .padding()
                            .opacity(0.8)) {
                            HStack {
                                Image(systemName: "gear")
                                    .font(.system(size: 18))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.primary)
                                
                                Text("Settings")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.clear)
                            .cornerRadius(10)
                        }
                        .buttonStyle(NavigationButtonStyle(isActive: selectedNavItem == "Settings"))
                        #if targetEnvironment(macCatalyst) || os(iOS)
                        .modifier(iPadGestureModifier(selectedNavItem: $selectedNavItem, itemName: "Settings"))
                        #endif
                    }
                    .padding(.horizontal, 16)
                }
                .background(.clear)
                    
            }
            // Reservation info card
            .sheet(isPresented: Binding<Bool>(
                       get: { notificationManager.selectedReservationID != nil },
                       set: { if !$0 { notificationManager.selectedReservationID = nil } }
                   )) {
                       if let reservationID = notificationManager.selectedReservationID {
                           NavigationStack {
                               ReservationInfoCard(
                                   reservationID: reservationID,
                                   onClose: { notificationManager.selectedReservationID = nil },
                                   onEdit: { _ in
                                       notificationManager.selectedReservationID = nil
                                       // Handle edit action if needed
                                   }
                               )
                               .environment(unitView)
                               .navigationTitle("Dettagli Prenotazione")
                               .navigationBarTitleDisplayMode(.inline)
                               .toolbar {
                                   ToolbarItem(placement: .topBarTrailing) {
                                       Button(action: { notificationManager.selectedReservationID = nil }) {
                                           Image(systemName: "xmark.circle.fill")
                                               .foregroundStyle(.secondary)
                                       }
                                   }
                               }
                           }
                           .presentationDetents([.medium, .large])
                       }
                   }
                   .task {
                       await notificationManager.requestNotificationAuthorization()
                       
                       // Load the current profile if available
                       if !userIdentifier.isEmpty {
                           if let profile = env.profileService.getProfile(withID: userIdentifier) {
                               ProfileStore.shared.setCurrentProfile(profile)
                           }
                       }
                   }
            .ignoresSafeArea(.keyboard)
            
            
        }
    }
}

#Preview {
    SidebarView(
        selectedReservation: .constant(nil),
        currentReservation: .constant(nil),
        selectedCategory: .constant(nil),
        columnVisibility: .constant(.automatic),
        isSessionIconShift: .constant(false)
    )
    .environmentObject(AppDependencies.createPreviewInstance())
    .environmentObject(AppState())
    .environmentObject(AppleSignInViewModel())
}





