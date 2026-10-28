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
        #expect(params1.symbolName == params2.symbolName)
        #expect(!params1.symbolName.isEmpty)
    }

    @Test("All random procedural alias nouns map deterministically to valid SF Symbols")
    func allProceduralAliasNounsMapToSFSymbols() {
        for adjective in ClientProfile.adjectives {
            for noun in ClientProfile.nouns {
                let aliasSeed = "\(adjective) \(noun)"
                let params = AvatarCircleView.ProceduralParameters.generate(from: aliasSeed)
                #expect(AvatarCircleView.ProceduralParameters.curatedSymbols.contains(params.symbolName))
            }
        }

        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Courageous Owl").symbolName == "bird.fill")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Tranquil Hare").symbolName == "hare.fill")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Gentle Tortoise").symbolName == "tortoise.fill")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Serene Fish").symbolName == "fish.fill")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Calm Fox").symbolName == "pawprint.fill")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Peaceful Willow").symbolName == "tree.fill")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Silent Meadow").symbolName == "leaf.fill")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Quiet River").symbolName == "drop.fill")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Restful Breeze").symbolName == "wind")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Mindful Cloud").symbolName == "cloud.fill")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Courageous Peak").symbolName == "mountain.2.fill")
        #expect(AvatarCircleView.ProceduralParameters.generate(from: "Tranquil Star").symbolName == "moon.stars.fill")
    }

    @Test("Built-in iOS ImageRenderer snapshots AvatarCircleView to CGImage")
    @MainActor
    func builtInImageRendererProducesCGImage() {
        let alias = ClientProfile.generateTranquilAlias()
        let avatarView = AvatarCircleView(seed: alias, size: .medium, showAura: false)
        let cgImage = avatarView.renderCGImage()
        #expect(cgImage != nil)
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
