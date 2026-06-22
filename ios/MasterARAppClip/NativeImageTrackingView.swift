import ARKit
import AVFoundation
import CryptoKit
import ImageIO
import RealityKit
import SwiftUI
import UIKit

struct NativeImageTrackingView: UIViewRepresentable {
  let campaign: Campaign
  let onStatus: (String) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onStatus: onStatus)
  }

  func makeUIView(context: Context) -> ARView {
    let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
    context.coordinator.attach(to: view)
    context.coordinator.start(campaign: campaign)
    return view
  }

  func updateUIView(_ uiView: ARView, context: Context) {}

  static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
    coordinator.stop()
  }

  final class Coordinator: NSObject, ARSessionDelegate {
    private weak var arView: ARView?
    private let onStatus: (String) -> Void
    private var campaign: Campaign?
    private var players: [UUID: AVQueuePlayer] = [:]
    private var loopers: [UUID: AVPlayerLooper] = [:]
    private var lastStatus = ""

    init(onStatus: @escaping (String) -> Void) {
      self.onStatus = onStatus
    }

    func attach(to view: ARView) {
      arView = view
      view.session.delegate = self
    }

    func start(campaign: Campaign) {
      self.campaign = campaign
      report("Loading tracking image…")

      Task {
        do {
          let (data, response) = try await URLSession.shared.data(from: campaign.targetImageURL)
          guard let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode),
                data.count <= 12_000_000,
                let image = UIImage(data: data),
                let cgImage = image.cgImage else {
            throw CampaignError.invalidConfiguration("The tracking image could not be decoded.")
          }

          if let expectedChecksum = campaign.targetImageSHA256 {
            let actualChecksum = SHA256.hash(data: data)
              .map { String(format: "%02x", $0) }
              .joined()
            guard actualChecksum.caseInsensitiveCompare(expectedChecksum) == .orderedSame else {
              throw CampaignError.invalidConfiguration(
                "The tracking image failed its integrity check."
              )
            }
          }

          let referenceImage = ARReferenceImage(
            cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation),
            physicalWidth: campaign.physicalWidthMeters
          )
          referenceImage.name = campaign.id

          await MainActor.run { [weak self] in
            self?.runSession(with: referenceImage)
          }
        } catch {
          report("Tracking setup failed: \(error.localizedDescription)")
        }
      }
    }

    func stop() {
      arView?.session.pause()
      players.values.forEach { $0.pause() }
      players.removeAll()
      loopers.removeAll()
    }

    private func runSession(with referenceImage: ARReferenceImage) {
      guard ARImageTrackingConfiguration.isSupported else {
        report("Native image tracking is unavailable on this device.")
        return
      }

      let configuration = ARImageTrackingConfiguration()
      configuration.trackingImages = [referenceImage]
      configuration.maximumNumberOfTrackedImages = 1
      players.values.forEach { $0.pause() }
      players.removeAll()
      loopers.removeAll()
      arView?.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
      report("Point the camera at the full printed image")
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
      guard let view = arView, let campaign else { return }

      for case let imageAnchor as ARImageAnchor in anchors {
        let anchorEntity = AnchorEntity(anchor: imageAnchor)
        let size = imageAnchor.referenceImage.physicalSize
        let videoHeight = min(
          size.height,
          size.width / campaign.videoAspectRatio
        )
        let mesh = MeshResource.generatePlane(
          width: Float(size.width),
          depth: Float(videoHeight)
        )

        let playerItem = AVPlayerItem(url: campaign.videoURL)
        let player = AVQueuePlayer()
        let looper = AVPlayerLooper(player: player, templateItem: playerItem)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let material = VideoMaterial(avPlayer: player)
        let videoEntity = ModelEntity(mesh: mesh, materials: [material])

        // RealityKit planes are generated in X-Z; image anchors lie in X-Y.
        videoEntity.orientation = simd_quatf(
          angle: -.pi / 2,
          axis: SIMD3<Float>(1, 0, 0)
        )
        videoEntity.position.z = 0.001

        anchorEntity.addChild(videoEntity)
        view.scene.addAnchor(anchorEntity)
        players[imageAnchor.identifier] = player
        loopers[imageAnchor.identifier] = looper
        player.play()
        report("Image found — playing experience")
      }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
      for case let imageAnchor as ARImageAnchor in anchors {
        guard let player = players[imageAnchor.identifier] else { continue }
        if imageAnchor.isTracked {
          player.play()
          report("Tracking image")
        } else {
          player.pause()
          report("Move back until the full image is visible")
        }
      }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
      report("AR session failed: \(error.localizedDescription)")
    }

    func sessionWasInterrupted(_ session: ARSession) {
      report("AR paused")
    }

    func sessionInterruptionEnded(_ session: ARSession) {
      guard let referenceImage = session.configuration
        .flatMap({ ($0 as? ARImageTrackingConfiguration)?.trackingImages.first }) else {
        return
      }
      runSession(with: referenceImage)
    }

    private func report(_ message: String) {
      guard message != lastStatus else { return }
      lastStatus = message
      DispatchQueue.main.async { [onStatus] in
        onStatus(message)
      }
    }
  }
}

private extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
