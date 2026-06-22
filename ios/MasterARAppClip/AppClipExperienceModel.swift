import Foundation

@MainActor
final class AppClipExperienceModel: ObservableObject {
  enum Phase: Equatable {
    case loading
    case ready
    case ar
    case failed(String)
  }

  @Published private(set) var phase: Phase = .loading
  @Published private(set) var campaign: Campaign?
  @Published var trackingMessage = "Preparing native image tracking…"

  private var invocationURL: URL?
  private var loadTask: Task<Void, Never>?

  init() {
    invocationURL = ProcessInfo.processInfo.environment["_XCAppClipURL"]
      .flatMap(URL.init(string:))
    reload()
  }

  func acceptInvocation(_ url: URL) {
    guard invocationURL != url else { return }
    invocationURL = url
    reload()
  }

  func startAR() {
    guard campaign != nil else { return }
    trackingMessage = "Loading tracking image…"
    phase = .ar
  }

  func retry() {
    reload()
  }

  func updateTrackingMessage(_ message: String) {
    trackingMessage = message
  }

  private func reload() {
    loadTask?.cancel()
    phase = .loading
    campaign = nil

    let url = invocationURL
    loadTask = Task {
      do {
        let loadedCampaign = try await CampaignLoader.load(invocationURL: url)
        try Task.checkCancellation()
        campaign = loadedCampaign
        phase = .ready
      } catch is CancellationError {
        return
      } catch {
        phase = .failed(error.localizedDescription)
      }
    }
  }
}
