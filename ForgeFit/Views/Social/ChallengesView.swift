import SwiftUI
import SwiftData

struct ChallengesView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = ChallengeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if vm.challenges.isEmpty && !vm.isLoading {
                    emptyState
                } else {
                    ForEach(vm.challenges) { challenge in
                        challengeCard(challenge)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm.showingCreate = true
                } label: {
                    Image(systemName: "plus").foregroundStyle(Color.ffAccent)
                }
            }
        }
        .sheet(isPresented: $vm.showingCreate) {
            CreateChallengeSheet(vm: vm)
        }
        .onAppear {
            vm.configure(context: modelContext, userId: appState.currentUserId)
            vm.load()
        }
    }

    // MARK: - Challenge Card

    private func challengeCard(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: challenge.challengeType.icon)
                    .font(.system(size: 14)).foregroundStyle(Color.ffAccent)
                Text(challenge.title)
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.ffText)
                Spacer()
                statusBadge(challenge)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.ffSurface)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(challenge.progressFraction >= 1 ? Color.ffGreen : Color.ffAccent)
                            .frame(width: max(0, geo.size.width * challenge.progressFraction), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(vm.progressLabel(for: challenge))
                        .font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
                    Spacer()
                    if !challenge.isExpired {
                        Text("\(challenge.daysRemaining)d left")
                            .font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    vm.syncProgress(for: challenge)
                } label: {
                    Label("Sync Progress", systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.ffAccent)
                }

                Spacer()

                NavigationLink {
                    ChallengeLeaderboardView(challenge: challenge, vm: vm)
                        .onAppear { vm.loadLeaderboard(for: challenge) }
                } label: {
                    Label("Leaderboard", systemImage: "list.number")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.ffAccent)
                }
            }
        }
        .padding(14)
        .ffCard()
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { vm.delete(challenge) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func statusBadge(_ challenge: Challenge) -> some View {
        let (label, color): (String, Color) = {
            switch challenge.status {
            case .active:    return (challenge.isExpired ? "Expired" : "Active", challenge.isExpired ? Color.ffSubtext : Color.ffGreen)
            case .completed: return ("Done", .ffGold)
            case .expired:   return ("Expired", .ffSubtext)
            }
        }()
        Text(label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "trophy").font(.system(size: 44)).foregroundStyle(Color.ffBorder)
            Text("No challenges yet").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.ffSubtext)
            Text("Create a challenge and invite friends to compete")
                .font(.system(size: 13)).foregroundStyle(Color.ffSubtext.opacity(0.7))
                .multilineTextAlignment(.center)
            Button { vm.showingCreate = true } label: {
                Text("Create Challenge")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.ffAccent).clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60).padding(.horizontal, 32)
    }
}

// MARK: - Create Challenge Sheet

struct CreateChallengeSheet: View {
    @ObservedObject var vm: ChallengeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Challenge") {
                    TextField("Title", text: $vm.newTitle)
                        .foregroundStyle(Color.ffText)

                    Picker("Type", selection: $vm.newType) {
                        ForEach(ChallengeType.allCases, id: \.self) {
                            Label($0.label, systemImage: $0.icon).tag($0)
                        }
                    }

                    HStack {
                        Text("Goal")
                        Spacer()
                        TextField("", value: $vm.newGoal, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .foregroundStyle(Color.ffAccent)
                        Text(vm.newType.unit).foregroundStyle(Color.ffSubtext)
                    }

                    DatePicker("End Date", selection: $vm.newEndDate, in: Date()..., displayedComponents: .date)
                        .colorScheme(.dark)
                }
                .listRowBackground(Color.ffSurface)

                Section {
                    Button("Create & Invite All Friends") {
                        vm.createChallenge(inviteAllFriends: true)
                    }
                    .foregroundStyle(Color.ffAccent)
                    .disabled(!vm.canCreate)

                    Button("Create Solo") {
                        vm.createChallenge(inviteAllFriends: false)
                    }
                    .foregroundStyle(Color.ffSubtext)
                    .disabled(!vm.canCreate)
                }
                .listRowBackground(Color.ffSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.ffBackground)
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.ffSubtext)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Challenge Leaderboard

struct ChallengeLeaderboardView: View {
    let challenge: Challenge
    @ObservedObject var vm: ChallengeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Challenge summary
                HStack {
                    Image(systemName: challenge.challengeType.icon).foregroundStyle(Color.ffAccent)
                    Text(challenge.title).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.ffText)
                    Spacer()
                    Text("Goal: \(Int(challenge.goal)) \(challenge.challengeType.unit)")
                        .font(.system(size: 12)).foregroundStyle(Color.ffSubtext)
                }
                .padding(.horizontal, 16).padding(.top, 4)

                Divider().background(Color.ffBorder)

                if vm.isLoadingLeaderboard {
                    HStack { Spacer(); ProgressView().tint(Color.ffAccent); Spacer() }.padding(.top, 40)
                } else {
                    ForEach(vm.leaderboardEntries) { entry in
                        HStack(spacing: 14) {
                            Text("#\(entry.rank)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(entry.rank <= 3 ? Color.ffGold : Color.ffSubtext)
                                .frame(width: 28, alignment: .leading)

                            Circle().fill(Color.ffSurface2).frame(width: 36, height: 36)
                                .overlay {
                                    Text(entry.displayName.prefix(1).uppercased())
                                        .font(.system(size: 14, weight: .bold)).foregroundStyle(Color.ffAccent)
                                }

                            Text(entry.displayName)
                                .font(.system(size: 14)).foregroundStyle(Color.ffText)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.0f", entry.progress))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.ffText)
                                Text(challenge.challengeType.unit)
                                    .font(.system(size: 10)).foregroundStyle(Color.ffSubtext)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        Divider().background(Color.ffBorder).padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.ffBackground)
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}
