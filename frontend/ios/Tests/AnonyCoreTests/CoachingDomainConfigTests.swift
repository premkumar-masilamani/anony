import Foundation
import Testing
@testable import AnonyCore

@Suite("CoachingDomainConfigTests")
struct CoachingDomainConfigTests {

    @Test("standardDomains contains expected seed coaching domains with non-empty metadata")
    func testStandardDomainsIntegrity() {
        let domains = CoachingDomainConfig.standardDomains
        #expect(domains.count >= 8)

        for domain in domains {
            #expect(!domain.code.isEmpty)
            #expect(!domain.label.isEmpty)
            #expect(domain.id == domain.code)
        }
    }

    @Test("label(forCode:) formats standard codes into human-readable titles")
    func testStandardDomainLabelFormatting() {
        #expect(CoachingDomainConfig.label(forCode: "CAREER") == "Career")
        #expect(CoachingDomainConfig.label(forCode: "LEADERSHIP") == "Leadership")
        #expect(CoachingDomainConfig.label(forCode: "WORK_LIFE_BALANCE") == "Work-Life Balance")
        #expect(CoachingDomainConfig.label(forCode: "BURNOUT") == "Burnout")
        #expect(CoachingDomainConfig.label(forCode: "COMMUNICATION") == "Communication")
    }

    @Test("label(forCode:) formats custom domain codes into clean Title Case")
    func testCustomDomainLabelFormatting() {
        #expect(CoachingDomainConfig.label(forCode: "EXECUTIVE_PRESENCE") == "Executive Presence")
        #expect(CoachingDomainConfig.label(forCode: "PUBLIC_SPEAKING") == "Public Speaking")
        #expect(CoachingDomainConfig.label(forCode: "adhd_coaching") == "Adhd Coaching")
    }

    @Test("normalizeCode(from:) sanitizes user input to uppercase code identifier")
    func testNormalizeCode() {
        #expect(CoachingDomainConfig.normalizeCode(from: "Executive Presence") == "EXECUTIVE_PRESENCE")
        #expect(CoachingDomainConfig.normalizeCode(from: "ADHD Coaching") == "ADHD_COACHING")
        #expect(CoachingDomainConfig.normalizeCode(from: "Work-Life") == "WORK_LIFE")
    }
}
