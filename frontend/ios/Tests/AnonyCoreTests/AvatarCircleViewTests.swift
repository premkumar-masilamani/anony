import Testing
import SwiftUI
@testable import AnonyCore

@Suite("AvatarCircleViewTests")
struct AvatarCircleViewTests {

    @Test("Avatar size diameters match specifications")
    func avatarSizeDiameters() {
        #expect(AvatarCircleView.Size.small.diameter == 32)
        #expect(AvatarCircleView.Size.medium.diameter == 44)
        #expect(AvatarCircleView.Size.large.diameter == 64)
        #expect(AvatarCircleView.Size.extraLarge.diameter == 88)
    }

    @Test("Deterministic procedural parameters for identical seeds")
    func deterministicProceduralParametersForIdenticalSeed() {
        let seed = "anonymous-client-789"
        let params1 = AvatarCircleView.ProceduralParameters.generate(from: seed)
        let params2 = AvatarCircleView.ProceduralParameters.generate(from: seed)

        #expect(params1.primaryColorIndex == params2.primaryColorIndex)
        #expect(params1.secondaryColorIndex == params2.secondaryColorIndex)
        #expect(params1.motifIndex == params2.motifIndex)
        #expect(params1.rotationAngle == params2.rotationAngle)
    }

    @Test("Procedural parameters vary across different seeds")
    func proceduralParametersVaryForDifferentSeeds() {
        let paramsA = AvatarCircleView.ProceduralParameters.generate(from: "seed-alpha")
        let paramsB = AvatarCircleView.ProceduralParameters.generate(from: "seed-beta")

        let hasVariance = (paramsA.primaryColorIndex != paramsB.primaryColorIndex) ||
                          (paramsA.secondaryColorIndex != paramsB.secondaryColorIndex) ||
                          (paramsA.motifIndex != paramsB.motifIndex) ||
                          (paramsA.rotationAngle != paramsB.rotationAngle)
        #expect(hasVariance)
    }

    @Test("View initialization properties")
    func viewInitialization() {
        let avatarView = AvatarCircleView(seed: "user-abc", size: .large, showAura: true)
        #expect(avatarView.seed == "user-abc")
        #expect(avatarView.size == .large)
        #expect(avatarView.showAura == true)
    }
}
