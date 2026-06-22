import Foundation

struct Campaign: Decodable, Equatable {
  let id: String
  let name: String
  let targetImageURL: URL
  let targetImageSHA256: String?
  let videoURL: URL
  let physicalWidthMeters: Double
  let videoAspectRatio: Double

  private enum CodingKeys: String, CodingKey {
    case id
    case name
    case targetImageURL = "targetImageUrl"
    case targetImageSHA256 = "targetImageSha256"
    case videoURL = "videoUrl"
    case physicalWidthMeters
    case legacyPhysicalWidth = "physicalWidth"
    case videoAspectRatio
  }

  init(
    id: String,
    name: String,
    targetImageURL: URL,
    targetImageSHA256: String? = nil,
    videoURL: URL,
    physicalWidthMeters: Double,
    videoAspectRatio: Double = 16 / 9
  ) {
    self.id = id
    self.name = name
    self.targetImageURL = targetImageURL
    self.targetImageSHA256 = targetImageSHA256
    self.videoURL = videoURL
    self.physicalWidthMeters = physicalWidthMeters
    self.videoAspectRatio = videoAspectRatio
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    name = try values.decode(String.self, forKey: .name)
    targetImageURL = try values.decode(URL.self, forKey: .targetImageURL)
    targetImageSHA256 = try values.decodeIfPresent(
      String.self,
      forKey: .targetImageSHA256
    )
    videoURL = try values.decode(URL.self, forKey: .videoURL)
    physicalWidthMeters =
      try values.decodeIfPresent(Double.self, forKey: .physicalWidthMeters)
      ?? values.decode(Double.self, forKey: .legacyPhysicalWidth)
    videoAspectRatio = try values.decodeIfPresent(
      Double.self,
      forKey: .videoAspectRatio
    ) ?? 16 / 9
  }

  func validate() throws {
    guard !id.isEmpty, !name.isEmpty else {
      throw CampaignError.invalidConfiguration("Campaign identity is missing.")
    }
    guard targetImageURL.scheme == "https", videoURL.scheme == "https" else {
      throw CampaignError.invalidConfiguration("Campaign assets must use HTTPS.")
    }
    if let targetImageSHA256,
       targetImageSHA256.range(
        of: #"^[0-9a-fA-F]{64}$"#,
        options: .regularExpression
       ) == nil {
      throw CampaignError.invalidConfiguration("The target-image checksum is invalid.")
    }
    guard (0.02...5).contains(physicalWidthMeters) else {
      throw CampaignError.invalidConfiguration(
        "Target width must be between 2 cm and 5 m."
      )
    }
    guard (0.25...4).contains(videoAspectRatio) else {
      throw CampaignError.invalidConfiguration("The video aspect ratio is invalid.")
    }
  }
}

enum CampaignError: LocalizedError {
  case invalidInvocation
  case invalidConfiguration(String)
  case server(Int)

  var errorDescription: String? {
    switch self {
    case .invalidInvocation:
      return "This link does not contain a valid campaign ID."
    case .invalidConfiguration(let message):
      return message
    case .server(let status):
      return "The campaign server returned HTTP \(status)."
    }
  }
}

enum CampaignLoader {
  static func load(invocationURL: URL?) async throws -> Campaign {
    let campaignID = campaignID(from: invocationURL) ?? "postcard"

    if let builtIn = builtInCampaigns[campaignID] {
      try builtIn.validate()
      return builtIn
    }

    guard campaignID.range(of: #"^[a-zA-Z0-9_-]{1,80}$"#, options: .regularExpression) != nil else {
      throw CampaignError.invalidInvocation
    }

    guard let baseURLString = Bundle.main.object(
      forInfoDictionaryKey: "CampaignAPIBaseURL"
    ) as? String,
    let apiBaseURL = URL(string: baseURLString) else {
      throw CampaignError.invalidConfiguration("The campaign API URL is not configured.")
    }

    let url = apiBaseURL.appendingPathComponent(campaignID)
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw CampaignError.invalidConfiguration("The campaign response was invalid.")
    }
    guard (200..<300).contains(httpResponse.statusCode) else {
      throw CampaignError.server(httpResponse.statusCode)
    }

    let campaign = try JSONDecoder().decode(Campaign.self, from: data)
    try campaign.validate()
    return campaign
  }

  static func campaignID(from url: URL?) -> String? {
    guard let url else { return nil }

    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let queryID = components.queryItems?.first(where: {
         $0.name == "client" || $0.name == "campaign"
       })?.value,
       !queryID.isEmpty {
      return queryID
    }

    let path = url.pathComponents.filter { $0 != "/" }
    if let experienceIndex = path.lastIndex(where: { $0 == "e" || $0 == "experience" }),
       path.indices.contains(experienceIndex + 1) {
      return path[experienceIndex + 1]
    }

    return nil
  }

  private static let builtInCampaigns: [String: Campaign] = [
    "postcard": Campaign(
      id: "postcard",
      name: "India Postcard Experience",
      targetImageURL: URL(
        string: "https://raw.githubusercontent.com/prashant1998gupta/AR_ImageTracking/main/Assets/AR_Assets/India%20Post%20card/Postcard_Target_Image.jpg.jpeg"
      )!,
      targetImageSHA256: "38a605cb58fb6036d51da4728e73fe55fe5ae739649d9ab9915259428da5d96b",
      videoURL: URL(
        string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
      )!,
      physicalWidthMeters: 0.15,
      videoAspectRatio: 16 / 9
    )
  ]
}
