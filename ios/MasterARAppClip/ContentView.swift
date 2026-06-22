import SwiftUI

struct ContentView: View {
  @ObservedObject var model: AppClipExperienceModel

  var body: some View {
    ZStack {
      Color(red: 0.035, green: 0.055, blue: 0.11)
        .ignoresSafeArea()

      switch model.phase {
      case .loading:
        progress(message: "Loading experience…")

      case .ready:
        launchCard

      case .ar:
        if let campaign = model.campaign {
          NativeImageTrackingView(
            campaign: campaign,
            onStatus: model.updateTrackingMessage
          )
          .ignoresSafeArea()

          VStack {
            statusPill(model.trackingMessage)
            Spacer()
          }
          .padding(.horizontal, 20)
          .padding(.top, 12)
        }

      case .failed(let message):
        errorCard(message: message)
      }
    }
    .preferredColorScheme(.dark)
  }

  private var launchCard: some View {
    VStack(spacing: 22) {
      Image(systemName: "viewfinder.circle.fill")
        .font(.system(size: 72))
        .foregroundStyle(.indigo)

      VStack(spacing: 8) {
        Text(model.campaign?.name ?? "AR Experience")
          .font(.title2.bold())
          .multilineTextAlignment(.center)
        Text("Point your camera at the printed image to reveal the experience.")
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      Button(action: model.startAR) {
        Label("Open Camera", systemImage: "camera.fill")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 15)
      }
      .buttonStyle(.borderedProminent)
      .tint(.indigo)
    }
    .padding(28)
    .frame(maxWidth: 440)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .padding(24)
  }

  private func progress(message: String) -> some View {
    VStack(spacing: 16) {
      ProgressView()
        .controlSize(.large)
      Text(message)
        .foregroundStyle(.secondary)
    }
  }

  private func statusPill(_ message: String) -> some View {
    Text(message)
      .font(.subheadline.weight(.semibold))
      .multilineTextAlignment(.center)
      .padding(.horizontal, 18)
      .padding(.vertical, 12)
      .background(.ultraThinMaterial, in: Capsule())
  }

  private func errorCard(message: String) -> some View {
    VStack(spacing: 18) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 46))
        .foregroundStyle(.orange)
      Text("Unable to load AR")
        .font(.title3.bold())
      Text(message)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Button("Try Again", action: model.retry)
        .buttonStyle(.borderedProminent)
    }
    .padding(28)
    .frame(maxWidth: 440)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .padding(24)
  }
}
