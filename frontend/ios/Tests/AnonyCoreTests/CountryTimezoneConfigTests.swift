import Foundation
import Testing
@testable import AnonyCore

@Suite("CountryTimezoneConfigTests")
struct CountryTimezoneConfigTests {

    @Test("allCountries contains complete ISO country list with valid ISO-3166 alpha-2 codes and timezones")
    func testAllCountriesIntegrity() {
        let countries = CountryTimezoneConfig.allCountries
        #expect(countries.count >= 190)

        let isoRegex = try! NSRegularExpression(pattern: "^[A-Z]{2}$")

        for country in countries {
            #expect(!country.name.isEmpty)
            #expect(!country.isoCode.isEmpty)
            let range = NSRange(location: 0, length: country.isoCode.utf16.count)
            #expect(isoRegex.firstMatch(in: country.isoCode, options: [], range: range) != nil, "ISO code \(country.isoCode) for \(country.name) must be 2 uppercase letters")
            #expect(!country.timezones.isEmpty, "\(country.name) must have at least one timezone")

            for tz in country.timezones {
                #expect(!tz.value.isEmpty)
                #expect(!tz.label.isEmpty)
                #expect(tz.id == tz.value)
            }
        }
    }

    @Test("Single-timezone country returns exactly one timezone and auto-selects first")
    func testSingleTimezoneCountry() {
        let afghanistanTzs = CountryTimezoneConfig.timezones(forCountry: "Afghanistan")
        #expect(afghanistanTzs.count == 1)
        #expect(afghanistanTzs.first?.value == "Asia/Kabul")
        #expect(afghanistanTzs.first?.label.contains("GMT+4:30") == true)
        #expect(CountryTimezoneConfig.isoCode(forCountry: "Afghanistan") == "AF")

        let albaniaTzs = CountryTimezoneConfig.timezones(forCountry: "Albania")
        #expect(albaniaTzs.count == 1)
        #expect(albaniaTzs.first?.value == "Europe/Tirane")
        #expect(albaniaTzs.first?.label.contains("GMT+2") == true)
        #expect(CountryTimezoneConfig.isoCode(forCountry: "Albania") == "AL")

        let indiaTzs = CountryTimezoneConfig.timezones(forCountry: "India")
        #expect(indiaTzs.count == 2)
        #expect(indiaTzs.first?.value == "Asia/Kolkata")
        #expect(indiaTzs.first?.label.contains("GMT+5:30") == true)
        #expect(CountryTimezoneConfig.isoCode(forCountry: "India") == "IN")
    }

    @Test("Multi-timezone country returns all available timezones with first as default")
    func testMultiTimezoneCountry() {
        let usTzs = CountryTimezoneConfig.timezones(forCountry: "United States")
        #expect(usTzs.count > 1)
        #expect(usTzs.first?.value == "America/New_York")
        #expect(usTzs.contains(where: { $0.value == "America/Chicago" }))
        #expect(usTzs.contains(where: { $0.value == "America/Los_Angeles" }))
        #expect(CountryTimezoneConfig.isoCode(forCountry: "United States") == "US")

        let australiaTzs = CountryTimezoneConfig.timezones(forCountry: "Australia")
        #expect(australiaTzs.count >= 8)
        #expect(australiaTzs.first?.value == "Australia/Sydney")
        #expect(australiaTzs.contains(where: { $0.value == "Australia/Melbourne" }))
        #expect(australiaTzs.contains(where: { $0.value == "Australia/Perth" }))
        #expect(CountryTimezoneConfig.isoCode(forCountry: "Australia") == "AU")

        let canadaTzs = CountryTimezoneConfig.timezones(forCountry: "Canada")
        #expect(canadaTzs.count > 1)
        #expect(CountryTimezoneConfig.isoCode(forCountry: "Canada") == "CA")
    }

    @Test("Lookup ISO code and country name bidirectionally")
    func testBidirectionalLookup() {
        #expect(CountryTimezoneConfig.countryName(forIsoCode: "US") == "United States")
        #expect(CountryTimezoneConfig.countryName(forIsoCode: "IN") == "India")
        #expect(CountryTimezoneConfig.countryName(forIsoCode: "GB") == "United Kingdom")
        #expect(CountryTimezoneConfig.countryName(forIsoCode: "FR") == "France")
        #expect(CountryTimezoneConfig.countryName(forIsoCode: "DE") == "Germany")
        #expect(CountryTimezoneConfig.countryName(forIsoCode: "JP") == "Japan")

        #expect(CountryTimezoneConfig.isoCode(forCountry: "Japan") == "JP")
        #expect(CountryTimezoneConfig.isoCode(forCountry: "United Kingdom") == "GB")
        #expect(CountryTimezoneConfig.isoCode(forCountry: "Germany") == "DE")
    }

    @Test("Resolve country name from timezone identifier")
    func testCountryNameForTimezone() {
        #expect(CountryTimezoneConfig.countryName(forTimezone: "Asia/Kolkata") == "India")
        #expect(CountryTimezoneConfig.countryName(forTimezone: "Asia/Kabul") == "Afghanistan")
        #expect(CountryTimezoneConfig.countryName(forTimezone: "America/New_York") == "United States")
        #expect(CountryTimezoneConfig.countryName(forTimezone: "Australia/Sydney") == "Australia")
        #expect(CountryTimezoneConfig.countryName(forTimezone: "Europe/London") == "United Kingdom")
        #expect(CountryTimezoneConfig.countryName(forTimezone: "NonExistent/Timezone") == nil)
    }

    @Test("Fallback behaviors for unknown inputs")
    func testFallbacks() {
        #expect(CountryTimezoneConfig.countryName(forIsoCode: "ZZ") == "United States")
        #expect(CountryTimezoneConfig.isoCode(forCountry: "Unknown Land") == "US")
        let unknownTzs = CountryTimezoneConfig.timezones(forCountry: "Unknown Land")
        #expect(!unknownTzs.isEmpty)
    }
}
