import SwiftUI

@main
struct MasterARAppClip: App {
  @StateObject private var model = AppClipExperienceModel()

  var body: some Scene {
    WindowGroup {
      ContentView(model: model)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
          guard let url = activity.webpageURL else { return }
          model.acceptInvocation(url)
        }
    }
  }
}
