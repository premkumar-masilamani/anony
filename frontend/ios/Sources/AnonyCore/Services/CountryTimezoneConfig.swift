// Generated CountryTimezoneConfig.swift
import Foundation

/// Represents a timezone entry with value identifier and human-readable label.
public struct TimezoneOption: Codable, Sendable, Hashable, Identifiable {
    public var id: String { value }
    public let value: String
    public let label: String

    public init(value: String, label: String) {
        self.value = value
        self.label = label
    }
}

/// Represents a selectable country option with ISO-3166 alpha-2 code and associated timezones.
public struct CountryOption: Codable, Sendable, Hashable, Identifiable {
    public var id: String { name }
    public let name: String
    public let isoCode: String
    public let timezones: [TimezoneOption]

    public init(name: String, isoCode: String, timezones: [TimezoneOption]) {
        self.name = name
        self.isoCode = isoCode
        self.timezones = timezones
    }
}

/// Static configuration providing country-to-timezone mappings and lookup utilities.
public enum CountryTimezoneConfig {

    /// All supported country entries ordered alphabetically.
    public static let allCountries: [CountryOption] = [
        CountryOption(
            name: "Afghanistan",
            isoCode: "AF",
            timezones: [
                TimezoneOption(value: "Asia/Kabul", label: "Asia/Kabul (GMT+4:30)"),
            ]
        ),
        CountryOption(
            name: "Albania",
            isoCode: "AL",
            timezones: [
                TimezoneOption(value: "Europe/Tirane", label: "Europe/Tirane (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Algeria",
            isoCode: "DZ",
            timezones: [
                TimezoneOption(value: "Africa/Algiers", label: "Africa/Algiers (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Andorra",
            isoCode: "AD",
            timezones: [
                TimezoneOption(value: "Europe/Andorra", label: "Europe/Andorra (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Angola",
            isoCode: "AO",
            timezones: [
                TimezoneOption(value: "Africa/Luanda", label: "Africa/Luanda (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Antigua and Barbuda",
            isoCode: "AG",
            timezones: [
                TimezoneOption(value: "America/Antigua", label: "America/Antigua (AST)"),
            ]
        ),
        CountryOption(
            name: "Argentina",
            isoCode: "AR",
            timezones: [
                TimezoneOption(value: "America/Argentina/Buenos_Aires", label: "America/Argentina/Buenos_Aires (GMT-3)"),
                TimezoneOption(value: "America/Argentina/Cordoba", label: "America/Argentina/Cordoba (GMT-3)"),
                TimezoneOption(value: "America/Argentina/Salta", label: "America/Argentina/Salta (GMT-3)"),
                TimezoneOption(value: "America/Argentina/Jujuy", label: "America/Argentina/Jujuy (GMT-3)"),
                TimezoneOption(value: "America/Argentina/Tucuman", label: "America/Argentina/Tucuman (GMT-3)"),
                TimezoneOption(value: "America/Argentina/Catamarca", label: "America/Argentina/Catamarca (GMT-3)"),
                TimezoneOption(value: "America/Argentina/La_Rioja", label: "America/Argentina/La_Rioja (GMT-3)"),
                TimezoneOption(value: "America/Argentina/San_Juan", label: "America/Argentina/San_Juan (GMT-3)"),
                TimezoneOption(value: "America/Argentina/Mendoza", label: "America/Argentina/Mendoza (GMT-3)"),
                TimezoneOption(value: "America/Argentina/San_Luis", label: "America/Argentina/San_Luis (GMT-3)"),
                TimezoneOption(value: "America/Argentina/Rio_Gallegos", label: "America/Argentina/Rio_Gallegos (GMT-3)"),
                TimezoneOption(value: "America/Argentina/Ushuaia", label: "America/Argentina/Ushuaia (GMT-3)"),
            ]
        ),
        CountryOption(
            name: "Armenia",
            isoCode: "AM",
            timezones: [
                TimezoneOption(value: "Asia/Yerevan", label: "Asia/Yerevan (GMT+4)"),
            ]
        ),
        CountryOption(
            name: "Australia",
            isoCode: "AU",
            timezones: [
                TimezoneOption(value: "Australia/Sydney", label: "Australia/Sydney (GMT+10)"),
                TimezoneOption(value: "Australia/Melbourne", label: "Australia/Melbourne (GMT+10)"),
                TimezoneOption(value: "Australia/Brisbane", label: "Australia/Brisbane (GMT+10)"),
                TimezoneOption(value: "Australia/Adelaide", label: "Australia/Adelaide (GMT+9:30)"),
                TimezoneOption(value: "Australia/Perth", label: "Australia/Perth (GMT+8)"),
                TimezoneOption(value: "Australia/Darwin", label: "Australia/Darwin (GMT+9:30)"),
                TimezoneOption(value: "Australia/Hobart", label: "Australia/Hobart (GMT+10)"),
                TimezoneOption(value: "Australia/Lord_Howe", label: "Australia/Lord_Howe (GMT+10:30)"),
            ]
        ),
        CountryOption(
            name: "Austria",
            isoCode: "AT",
            timezones: [
                TimezoneOption(value: "Europe/Vienna", label: "Europe/Vienna (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Azerbaijan",
            isoCode: "AZ",
            timezones: [
                TimezoneOption(value: "Asia/Baku", label: "Asia/Baku (GMT+4)"),
            ]
        ),
        CountryOption(
            name: "Bahamas",
            isoCode: "BS",
            timezones: [
                TimezoneOption(value: "America/Nassau", label: "America/Nassau (EDT)"),
            ]
        ),
        CountryOption(
            name: "Bahrain",
            isoCode: "BH",
            timezones: [
                TimezoneOption(value: "Asia/Bahrain", label: "Asia/Bahrain (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Bangladesh",
            isoCode: "BD",
            timezones: [
                TimezoneOption(value: "Asia/Dhaka", label: "Asia/Dhaka (GMT+6)"),
            ]
        ),
        CountryOption(
            name: "Barbados",
            isoCode: "BB",
            timezones: [
                TimezoneOption(value: "America/Barbados", label: "America/Barbados (AST)"),
            ]
        ),
        CountryOption(
            name: "Belarus",
            isoCode: "BY",
            timezones: [
                TimezoneOption(value: "Europe/Minsk", label: "Europe/Minsk (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Belgium",
            isoCode: "BE",
            timezones: [
                TimezoneOption(value: "Europe/Brussels", label: "Europe/Brussels (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Belize",
            isoCode: "BZ",
            timezones: [
                TimezoneOption(value: "America/Belize", label: "America/Belize (CST)"),
            ]
        ),
        CountryOption(
            name: "Benin",
            isoCode: "BJ",
            timezones: [
                TimezoneOption(value: "Africa/Porto-Novo", label: "Africa/Porto-Novo (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Bhutan",
            isoCode: "BT",
            timezones: [
                TimezoneOption(value: "Asia/Thimphu", label: "Asia/Thimphu (GMT+6)"),
            ]
        ),
        CountryOption(
            name: "Bolivia",
            isoCode: "BO",
            timezones: [
                TimezoneOption(value: "America/La_Paz", label: "America/La_Paz (GMT-4)"),
            ]
        ),
        CountryOption(
            name: "Bosnia and Herzegovina",
            isoCode: "BA",
            timezones: [
                TimezoneOption(value: "Europe/Sarajevo", label: "Europe/Sarajevo (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Botswana",
            isoCode: "BW",
            timezones: [
                TimezoneOption(value: "Africa/Gaborone", label: "Africa/Gaborone (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Brazil",
            isoCode: "BR",
            timezones: [
                TimezoneOption(value: "America/Noronha", label: "America/Noronha (GMT-2)"),
                TimezoneOption(value: "America/Belem", label: "America/Belem (GMT-3)"),
                TimezoneOption(value: "America/Fortaleza", label: "America/Fortaleza (GMT-3)"),
                TimezoneOption(value: "America/Recife", label: "America/Recife (GMT-3)"),
                TimezoneOption(value: "America/Araguaina", label: "America/Araguaina (GMT-3)"),
                TimezoneOption(value: "America/Maceio", label: "America/Maceio (GMT-3)"),
                TimezoneOption(value: "America/Bahia", label: "America/Bahia (GMT-3)"),
                TimezoneOption(value: "America/Sao_Paulo", label: "America/Sao_Paulo (GMT-3)"),
                TimezoneOption(value: "America/Campo_Grande", label: "America/Campo_Grande (GMT-4)"),
                TimezoneOption(value: "America/Cuiaba", label: "America/Cuiaba (GMT-4)"),
                TimezoneOption(value: "America/Santarem", label: "America/Santarem (GMT-3)"),
                TimezoneOption(value: "America/Porto_Velho", label: "America/Porto_Velho (GMT-4)"),
                TimezoneOption(value: "America/Boa_Vista", label: "America/Boa_Vista (GMT-4)"),
                TimezoneOption(value: "America/Manaus", label: "America/Manaus (GMT-4)"),
                TimezoneOption(value: "America/Eirunepe", label: "America/Eirunepe (GMT-5)"),
                TimezoneOption(value: "America/Rio_Branco", label: "America/Rio_Branco (GMT-5)"),
            ]
        ),
        CountryOption(
            name: "Brunei",
            isoCode: "BN",
            timezones: [
                TimezoneOption(value: "Asia/Brunei", label: "Asia/Brunei (GMT+8)"),
            ]
        ),
        CountryOption(
            name: "Bulgaria",
            isoCode: "BG",
            timezones: [
                TimezoneOption(value: "Europe/Sofia", label: "Europe/Sofia (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Burkina Faso",
            isoCode: "BF",
            timezones: [
                TimezoneOption(value: "Africa/Ouagadougou", label: "Africa/Ouagadougou (GMT)"),
            ]
        ),
        CountryOption(
            name: "Burundi",
            isoCode: "BI",
            timezones: [
                TimezoneOption(value: "Africa/Bujumbura", label: "Africa/Bujumbura (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Cabo Verde",
            isoCode: "CV",
            timezones: [
                TimezoneOption(value: "Atlantic/Cape_Verde", label: "Atlantic/Cape_Verde (GMT-1)"),
            ]
        ),
        CountryOption(
            name: "Cambodia",
            isoCode: "KH",
            timezones: [
                TimezoneOption(value: "Asia/Phnom_Penh", label: "Asia/Phnom_Penh (GMT+7)"),
            ]
        ),
        CountryOption(
            name: "Cameroon",
            isoCode: "CM",
            timezones: [
                TimezoneOption(value: "Africa/Douala", label: "Africa/Douala (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Canada",
            isoCode: "CA",
            timezones: [
                TimezoneOption(value: "America/St_Johns", label: "America/St_Johns (GMT-2:30)"),
                TimezoneOption(value: "America/Halifax", label: "America/Halifax (ADT)"),
                TimezoneOption(value: "America/Glace_Bay", label: "America/Glace_Bay (ADT)"),
                TimezoneOption(value: "America/Moncton", label: "America/Moncton (ADT)"),
                TimezoneOption(value: "America/Goose_Bay", label: "America/Goose_Bay (ADT)"),
                TimezoneOption(value: "America/Blanc-Sablon", label: "America/Blanc-Sablon (AST)"),
                TimezoneOption(value: "America/Toronto", label: "America/Toronto (EDT)"),
                TimezoneOption(value: "America/Nipigon", label: "America/Nipigon (EDT)"),
                TimezoneOption(value: "America/Thunder_Bay", label: "America/Thunder_Bay (EDT)"),
                TimezoneOption(value: "America/Iqaluit", label: "America/Iqaluit (EDT)"),
                TimezoneOption(value: "America/Pangnirtung", label: "America/Pangnirtung (EDT)"),
                TimezoneOption(value: "America/Atikokan", label: "America/Atikokan (EST)"),
                TimezoneOption(value: "America/Winnipeg", label: "America/Winnipeg (CDT)"),
                TimezoneOption(value: "America/Resolute", label: "America/Resolute (CDT)"),
                TimezoneOption(value: "America/Rankin_Inlet", label: "America/Rankin_Inlet (CDT)"),
                TimezoneOption(value: "America/Regina", label: "America/Regina (CST)"),
                TimezoneOption(value: "America/Swift_Current", label: "America/Swift_Current (CST)"),
                TimezoneOption(value: "America/Edmonton", label: "America/Edmonton (MDT)"),
                TimezoneOption(value: "America/Cambridge_Bay", label: "America/Cambridge_Bay (MDT)"),
                TimezoneOption(value: "America/Yellowknife", label: "America/Yellowknife (MDT)"),
                TimezoneOption(value: "America/Inuvik", label: "America/Inuvik (MDT)"),
                TimezoneOption(value: "America/Whitehorse", label: "America/Whitehorse (GMT-7)"),
                TimezoneOption(value: "America/Dawson", label: "America/Dawson (GMT-7)"),
                TimezoneOption(value: "America/Vancouver", label: "America/Vancouver (PDT)"),
                TimezoneOption(value: "America/Fort_Nelson", label: "America/Fort_Nelson (MST)"),
                TimezoneOption(value: "America/Dawson_Creek", label: "America/Dawson_Creek (MST)"),
                TimezoneOption(value: "America/Creston", label: "America/Creston (MST)"),
            ]
        ),
        CountryOption(
            name: "Central African Republic",
            isoCode: "CF",
            timezones: [
                TimezoneOption(value: "Africa/Bangui", label: "Africa/Bangui (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Chad",
            isoCode: "TD",
            timezones: [
                TimezoneOption(value: "Africa/Ndjamena", label: "Africa/Ndjamena (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Chile",
            isoCode: "CL",
            timezones: [
                TimezoneOption(value: "America/Santiago", label: "America/Santiago (GMT-4)"),
                TimezoneOption(value: "Pacific/Easter", label: "Pacific/Easter (GMT-6)"),
            ]
        ),
        CountryOption(
            name: "China",
            isoCode: "CN",
            timezones: [
                TimezoneOption(value: "Asia/Shanghai", label: "Asia/Shanghai (GMT+8)"),
                TimezoneOption(value: "Asia/Urumqi", label: "Asia/Urumqi (GMT+6)"),
            ]
        ),
        CountryOption(
            name: "Colombia",
            isoCode: "CO",
            timezones: [
                TimezoneOption(value: "America/Bogota", label: "America/Bogota (GMT-5)"),
            ]
        ),
        CountryOption(
            name: "Comoros",
            isoCode: "KM",
            timezones: [
                TimezoneOption(value: "Indian/Comoro", label: "Indian/Comoro (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Costa Rica",
            isoCode: "CR",
            timezones: [
                TimezoneOption(value: "America/Costa_Rica", label: "America/Costa_Rica (CST)"),
            ]
        ),
        CountryOption(
            name: "Croatia",
            isoCode: "HR",
            timezones: [
                TimezoneOption(value: "Europe/Zagreb", label: "Europe/Zagreb (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Cuba",
            isoCode: "CU",
            timezones: [
                TimezoneOption(value: "America/Havana", label: "America/Havana (GMT-4)"),
            ]
        ),
        CountryOption(
            name: "Cyprus",
            isoCode: "CY",
            timezones: [
                TimezoneOption(value: "Asia/Nicosia", label: "Asia/Nicosia (GMT+3)"),
                TimezoneOption(value: "Asia/Famagusta", label: "Asia/Famagusta (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Czechia",
            isoCode: "CZ",
            timezones: [
                TimezoneOption(value: "Europe/Prague", label: "Europe/Prague (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Democratic Republic of the Congo",
            isoCode: "CD",
            timezones: [
                TimezoneOption(value: "Africa/Kinshasa", label: "Africa/Kinshasa (GMT+1)"),
                TimezoneOption(value: "Africa/Lubumbashi", label: "Africa/Lubumbashi (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Denmark",
            isoCode: "DK",
            timezones: [
                TimezoneOption(value: "Europe/Copenhagen", label: "Europe/Copenhagen (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Djibouti",
            isoCode: "DJ",
            timezones: [
                TimezoneOption(value: "Africa/Djibouti", label: "Africa/Djibouti (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Dominica",
            isoCode: "DM",
            timezones: [
                TimezoneOption(value: "America/Dominica", label: "America/Dominica (AST)"),
            ]
        ),
        CountryOption(
            name: "Dominican Republic",
            isoCode: "DO",
            timezones: [
                TimezoneOption(value: "America/Santo_Domingo", label: "America/Santo_Domingo (AST)"),
            ]
        ),
        CountryOption(
            name: "Ecuador",
            isoCode: "EC",
            timezones: [
                TimezoneOption(value: "America/Guayaquil", label: "America/Guayaquil (GMT-5)"),
                TimezoneOption(value: "Pacific/Galapagos", label: "Pacific/Galapagos (GMT-6)"),
            ]
        ),
        CountryOption(
            name: "Egypt",
            isoCode: "EG",
            timezones: [
                TimezoneOption(value: "Africa/Cairo", label: "Africa/Cairo (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "El Salvador",
            isoCode: "SV",
            timezones: [
                TimezoneOption(value: "America/El_Salvador", label: "America/El_Salvador (CST)"),
            ]
        ),
        CountryOption(
            name: "Equatorial Guinea",
            isoCode: "GQ",
            timezones: [
                TimezoneOption(value: "Africa/Malabo", label: "Africa/Malabo (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Eritrea",
            isoCode: "ER",
            timezones: [
                TimezoneOption(value: "Africa/Asmara", label: "Africa/Asmara (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Estonia",
            isoCode: "EE",
            timezones: [
                TimezoneOption(value: "Europe/Tallinn", label: "Europe/Tallinn (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Eswatini",
            isoCode: "SZ",
            timezones: [
                TimezoneOption(value: "Africa/Mbabane", label: "Africa/Mbabane (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Ethiopia",
            isoCode: "ET",
            timezones: [
                TimezoneOption(value: "Africa/Addis_Ababa", label: "Africa/Addis_Ababa (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Fiji",
            isoCode: "FJ",
            timezones: [
                TimezoneOption(value: "Pacific/Fiji", label: "Pacific/Fiji (GMT+12)"),
            ]
        ),
        CountryOption(
            name: "Finland",
            isoCode: "FI",
            timezones: [
                TimezoneOption(value: "Europe/Helsinki", label: "Europe/Helsinki (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "France",
            isoCode: "FR",
            timezones: [
                TimezoneOption(value: "Europe/Paris", label: "Europe/Paris (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Gabon",
            isoCode: "GA",
            timezones: [
                TimezoneOption(value: "Africa/Libreville", label: "Africa/Libreville (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Gambia",
            isoCode: "GM",
            timezones: [
                TimezoneOption(value: "Africa/Banjul", label: "Africa/Banjul (GMT)"),
            ]
        ),
        CountryOption(
            name: "Georgia",
            isoCode: "GE",
            timezones: [
                TimezoneOption(value: "Asia/Tbilisi", label: "Asia/Tbilisi (GMT+4)"),
            ]
        ),
        CountryOption(
            name: "Germany",
            isoCode: "DE",
            timezones: [
                TimezoneOption(value: "Europe/Berlin", label: "Europe/Berlin (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Ghana",
            isoCode: "GH",
            timezones: [
                TimezoneOption(value: "Africa/Accra", label: "Africa/Accra (GMT)"),
            ]
        ),
        CountryOption(
            name: "Greece",
            isoCode: "GR",
            timezones: [
                TimezoneOption(value: "Europe/Athens", label: "Europe/Athens (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Grenada",
            isoCode: "GD",
            timezones: [
                TimezoneOption(value: "America/Grenada", label: "America/Grenada (AST)"),
            ]
        ),
        CountryOption(
            name: "Guatemala",
            isoCode: "GT",
            timezones: [
                TimezoneOption(value: "America/Guatemala", label: "America/Guatemala (CST)"),
            ]
        ),
        CountryOption(
            name: "Guinea",
            isoCode: "GN",
            timezones: [
                TimezoneOption(value: "Africa/Conakry", label: "Africa/Conakry (GMT)"),
            ]
        ),
        CountryOption(
            name: "Guinea-Bissau",
            isoCode: "GW",
            timezones: [
                TimezoneOption(value: "Africa/Bissau", label: "Africa/Bissau (GMT)"),
            ]
        ),
        CountryOption(
            name: "Guyana",
            isoCode: "GY",
            timezones: [
                TimezoneOption(value: "America/Guyana", label: "America/Guyana (GMT-4)"),
            ]
        ),
        CountryOption(
            name: "Haiti",
            isoCode: "HT",
            timezones: [
                TimezoneOption(value: "America/Port-au-Prince", label: "America/Port-au-Prince (EDT)"),
            ]
        ),
        CountryOption(
            name: "Honduras",
            isoCode: "HN",
            timezones: [
                TimezoneOption(value: "America/Tegucigalpa", label: "America/Tegucigalpa (CST)"),
            ]
        ),
        CountryOption(
            name: "Hungary",
            isoCode: "HU",
            timezones: [
                TimezoneOption(value: "Europe/Budapest", label: "Europe/Budapest (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Iceland",
            isoCode: "IS",
            timezones: [
                TimezoneOption(value: "Atlantic/Reykjavik", label: "Atlantic/Reykjavik (GMT)"),
            ]
        ),
        CountryOption(
            name: "India",
            isoCode: "IN",
            timezones: [
                TimezoneOption(value: "Asia/Kolkata", label: "Asia/Kolkata (GMT+5:30)"),
                TimezoneOption(value: "Asia/Calcutta", label: "Asia/Calcutta (GMT+5:30)"),
            ]
        ),
        CountryOption(
            name: "Indonesia",
            isoCode: "ID",
            timezones: [
                TimezoneOption(value: "Asia/Jakarta", label: "Asia/Jakarta (GMT+7)"),
                TimezoneOption(value: "Asia/Pontianak", label: "Asia/Pontianak (GMT+7)"),
                TimezoneOption(value: "Asia/Makassar", label: "Asia/Makassar (GMT+8)"),
                TimezoneOption(value: "Asia/Jayapura", label: "Asia/Jayapura (GMT+9)"),
            ]
        ),
        CountryOption(
            name: "Iran",
            isoCode: "IR",
            timezones: [
                TimezoneOption(value: "Asia/Tehran", label: "Asia/Tehran (GMT+3:30)"),
            ]
        ),
        CountryOption(
            name: "Iraq",
            isoCode: "IQ",
            timezones: [
                TimezoneOption(value: "Asia/Baghdad", label: "Asia/Baghdad (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Ireland",
            isoCode: "IE",
            timezones: [
                TimezoneOption(value: "Europe/Dublin", label: "Europe/Dublin (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Israel",
            isoCode: "IL",
            timezones: [
                TimezoneOption(value: "Asia/Jerusalem", label: "Asia/Jerusalem (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Italy",
            isoCode: "IT",
            timezones: [
                TimezoneOption(value: "Europe/Rome", label: "Europe/Rome (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Ivory Coast",
            isoCode: "CI",
            timezones: [
                TimezoneOption(value: "Africa/Abidjan", label: "Africa/Abidjan (GMT)"),
            ]
        ),
        CountryOption(
            name: "Jamaica",
            isoCode: "JM",
            timezones: [
                TimezoneOption(value: "America/Jamaica", label: "America/Jamaica (EST)"),
            ]
        ),
        CountryOption(
            name: "Japan",
            isoCode: "JP",
            timezones: [
                TimezoneOption(value: "Asia/Tokyo", label: "Asia/Tokyo (GMT+9)"),
            ]
        ),
        CountryOption(
            name: "Jordan",
            isoCode: "JO",
            timezones: [
                TimezoneOption(value: "Asia/Amman", label: "Asia/Amman (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Kazakhstan",
            isoCode: "KZ",
            timezones: [
                TimezoneOption(value: "Asia/Almaty", label: "Asia/Almaty (GMT+5)"),
                TimezoneOption(value: "Asia/Qyzylorda", label: "Asia/Qyzylorda (GMT+5)"),
                TimezoneOption(value: "Asia/Aqtobe", label: "Asia/Aqtobe (GMT+5)"),
                TimezoneOption(value: "Asia/Aqtau", label: "Asia/Aqtau (GMT+5)"),
                TimezoneOption(value: "Asia/Atyrau", label: "Asia/Atyrau (GMT+5)"),
                TimezoneOption(value: "Asia/Oral", label: "Asia/Oral (GMT+5)"),
            ]
        ),
        CountryOption(
            name: "Kenya",
            isoCode: "KE",
            timezones: [
                TimezoneOption(value: "Africa/Nairobi", label: "Africa/Nairobi (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Kiribati",
            isoCode: "KI",
            timezones: [
                TimezoneOption(value: "Pacific/Tarawa", label: "Pacific/Tarawa (GMT+12)"),
                TimezoneOption(value: "Pacific/Kanton", label: "Pacific/Kanton (GMT+13)"),
                TimezoneOption(value: "Pacific/Kiritimati", label: "Pacific/Kiritimati (GMT+14)"),
            ]
        ),
        CountryOption(
            name: "Kuwait",
            isoCode: "KW",
            timezones: [
                TimezoneOption(value: "Asia/Kuwait", label: "Asia/Kuwait (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Kyrgyzstan",
            isoCode: "KG",
            timezones: [
                TimezoneOption(value: "Asia/Bishkek", label: "Asia/Bishkek (GMT+6)"),
            ]
        ),
        CountryOption(
            name: "Laos",
            isoCode: "LA",
            timezones: [
                TimezoneOption(value: "Asia/Vientiane", label: "Asia/Vientiane (GMT+7)"),
            ]
        ),
        CountryOption(
            name: "Latvia",
            isoCode: "LV",
            timezones: [
                TimezoneOption(value: "Europe/Riga", label: "Europe/Riga (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Lebanon",
            isoCode: "LB",
            timezones: [
                TimezoneOption(value: "Asia/Beirut", label: "Asia/Beirut (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Lesotho",
            isoCode: "LS",
            timezones: [
                TimezoneOption(value: "Africa/Maseru", label: "Africa/Maseru (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Liberia",
            isoCode: "LR",
            timezones: [
                TimezoneOption(value: "Africa/Monrovia", label: "Africa/Monrovia (GMT)"),
            ]
        ),
        CountryOption(
            name: "Libya",
            isoCode: "LY",
            timezones: [
                TimezoneOption(value: "Africa/Tripoli", label: "Africa/Tripoli (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Liechtenstein",
            isoCode: "LI",
            timezones: [
                TimezoneOption(value: "Europe/Vaduz", label: "Europe/Vaduz (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Lithuania",
            isoCode: "LT",
            timezones: [
                TimezoneOption(value: "Europe/Vilnius", label: "Europe/Vilnius (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Luxembourg",
            isoCode: "LU",
            timezones: [
                TimezoneOption(value: "Europe/Luxembourg", label: "Europe/Luxembourg (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Madagascar",
            isoCode: "MG",
            timezones: [
                TimezoneOption(value: "Indian/Antananarivo", label: "Indian/Antananarivo (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Malawi",
            isoCode: "MW",
            timezones: [
                TimezoneOption(value: "Africa/Blantyre", label: "Africa/Blantyre (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Malaysia",
            isoCode: "MY",
            timezones: [
                TimezoneOption(value: "Asia/Kuala_Lumpur", label: "Asia/Kuala_Lumpur (GMT+8)"),
                TimezoneOption(value: "Asia/Kuching", label: "Asia/Kuching (GMT+8)"),
            ]
        ),
        CountryOption(
            name: "Maldives",
            isoCode: "MV",
            timezones: [
                TimezoneOption(value: "Indian/Maldives", label: "Indian/Maldives (GMT+5)"),
            ]
        ),
        CountryOption(
            name: "Mali",
            isoCode: "ML",
            timezones: [
                TimezoneOption(value: "Africa/Bamako", label: "Africa/Bamako (GMT)"),
            ]
        ),
        CountryOption(
            name: "Malta",
            isoCode: "MT",
            timezones: [
                TimezoneOption(value: "Europe/Malta", label: "Europe/Malta (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Marshall Islands",
            isoCode: "MH",
            timezones: [
                TimezoneOption(value: "Pacific/Majuro", label: "Pacific/Majuro (GMT+12)"),
                TimezoneOption(value: "Pacific/Kwajalein", label: "Pacific/Kwajalein (GMT+12)"),
            ]
        ),
        CountryOption(
            name: "Mauritania",
            isoCode: "MR",
            timezones: [
                TimezoneOption(value: "Africa/Nouakchott", label: "Africa/Nouakchott (GMT)"),
            ]
        ),
        CountryOption(
            name: "Mauritius",
            isoCode: "MU",
            timezones: [
                TimezoneOption(value: "Indian/Mauritius", label: "Indian/Mauritius (GMT+4)"),
            ]
        ),
        CountryOption(
            name: "Mexico",
            isoCode: "MX",
            timezones: [
                TimezoneOption(value: "America/Mexico_City", label: "America/Mexico_City (CST)"),
                TimezoneOption(value: "America/Cancun", label: "America/Cancun (EST)"),
                TimezoneOption(value: "America/Merida", label: "America/Merida (CST)"),
                TimezoneOption(value: "America/Monterrey", label: "America/Monterrey (CST)"),
                TimezoneOption(value: "America/Matamoros", label: "America/Matamoros (CDT)"),
                TimezoneOption(value: "America/Mazatlan", label: "America/Mazatlan (GMT-7)"),
                TimezoneOption(value: "America/Chihuahua", label: "America/Chihuahua (CST)"),
                TimezoneOption(value: "America/Ojinaga", label: "America/Ojinaga (CDT)"),
                TimezoneOption(value: "America/Hermosillo", label: "America/Hermosillo (GMT-7)"),
                TimezoneOption(value: "America/Tijuana", label: "America/Tijuana (PDT)"),
                TimezoneOption(value: "America/Bahia_Banderas", label: "America/Bahia_Banderas (CST)"),
            ]
        ),
        CountryOption(
            name: "Micronesia",
            isoCode: "FM",
            timezones: [
                TimezoneOption(value: "Pacific/Tarawa", label: "Pacific/Tarawa (GMT+12)"),
                TimezoneOption(value: "Pacific/Chuuk", label: "Pacific/Chuuk (GMT+10)"),
                TimezoneOption(value: "Pacific/Pohnpei", label: "Pacific/Pohnpei (GMT+11)"),
                TimezoneOption(value: "Pacific/Kosrae", label: "Pacific/Kosrae (GMT+11)"),
            ]
        ),
        CountryOption(
            name: "Moldova",
            isoCode: "MD",
            timezones: [
                TimezoneOption(value: "Europe/Chisinau", label: "Europe/Chisinau (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Monaco",
            isoCode: "MC",
            timezones: [
                TimezoneOption(value: "Europe/Monaco", label: "Europe/Monaco (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Mongolia",
            isoCode: "MN",
            timezones: [
                TimezoneOption(value: "Asia/Ulaanbaatar", label: "Asia/Ulaanbaatar (GMT+8)"),
                TimezoneOption(value: "Asia/Hovd", label: "Asia/Hovd (GMT+7)"),
                TimezoneOption(value: "Asia/Choibalsan", label: "Asia/Choibalsan (GMT+8)"),
            ]
        ),
        CountryOption(
            name: "Montenegro",
            isoCode: "ME",
            timezones: [
                TimezoneOption(value: "Europe/Podgorica", label: "Europe/Podgorica (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Morocco",
            isoCode: "MA",
            timezones: [
                TimezoneOption(value: "Africa/Casablanca", label: "Africa/Casablanca (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Mozambique",
            isoCode: "MZ",
            timezones: [
                TimezoneOption(value: "Africa/Maputo", label: "Africa/Maputo (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Myanmar",
            isoCode: "MM",
            timezones: [
                TimezoneOption(value: "Asia/Yangon", label: "Asia/Yangon (GMT+6:30)"),
            ]
        ),
        CountryOption(
            name: "Namibia",
            isoCode: "NA",
            timezones: [
                TimezoneOption(value: "Africa/Windhoek", label: "Africa/Windhoek (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Nauru",
            isoCode: "NR",
            timezones: [
                TimezoneOption(value: "Pacific/Nauru", label: "Pacific/Nauru (GMT+12)"),
            ]
        ),
        CountryOption(
            name: "Nepal",
            isoCode: "NP",
            timezones: [
                TimezoneOption(value: "Asia/Kathmandu", label: "Asia/Kathmandu (GMT+5:45)"),
            ]
        ),
        CountryOption(
            name: "Netherlands",
            isoCode: "NL",
            timezones: [
                TimezoneOption(value: "Europe/Amsterdam", label: "Europe/Amsterdam (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "New Zealand",
            isoCode: "NZ",
            timezones: [
                TimezoneOption(value: "Pacific/Auckland", label: "Pacific/Auckland (GMT+12)"),
                TimezoneOption(value: "Pacific/Chatham", label: "Pacific/Chatham (GMT+12:45)"),
            ]
        ),
        CountryOption(
            name: "Nicaragua",
            isoCode: "NI",
            timezones: [
                TimezoneOption(value: "America/Managua", label: "America/Managua (CST)"),
            ]
        ),
        CountryOption(
            name: "Niger",
            isoCode: "NE",
            timezones: [
                TimezoneOption(value: "Africa/Niamey", label: "Africa/Niamey (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Nigeria",
            isoCode: "NG",
            timezones: [
                TimezoneOption(value: "Africa/Lagos", label: "Africa/Lagos (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "North Korea",
            isoCode: "KP",
            timezones: [
                TimezoneOption(value: "Asia/Pyongyang", label: "Asia/Pyongyang (GMT+9)"),
            ]
        ),
        CountryOption(
            name: "North Macedonia",
            isoCode: "MK",
            timezones: [
                TimezoneOption(value: "Europe/Skopje", label: "Europe/Skopje (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Norway",
            isoCode: "NO",
            timezones: [
                TimezoneOption(value: "Europe/Oslo", label: "Europe/Oslo (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Oman",
            isoCode: "OM",
            timezones: [
                TimezoneOption(value: "Asia/Muscat", label: "Asia/Muscat (GMT+4)"),
            ]
        ),
        CountryOption(
            name: "Pakistan",
            isoCode: "PK",
            timezones: [
                TimezoneOption(value: "Asia/Karachi", label: "Asia/Karachi (GMT+5)"),
            ]
        ),
        CountryOption(
            name: "Palau",
            isoCode: "PW",
            timezones: [
                TimezoneOption(value: "Pacific/Palau", label: "Pacific/Palau (GMT+9)"),
            ]
        ),
        CountryOption(
            name: "Palestine",
            isoCode: "PS",
            timezones: [
                TimezoneOption(value: "Asia/Gaza", label: "Asia/Gaza (GMT+3)"),
                TimezoneOption(value: "Asia/Hebron", label: "Asia/Hebron (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Panama",
            isoCode: "PA",
            timezones: [
                TimezoneOption(value: "America/Panama", label: "America/Panama (EST)"),
            ]
        ),
        CountryOption(
            name: "Papua New Guinea",
            isoCode: "PG",
            timezones: [
                TimezoneOption(value: "Pacific/Port_Moresby", label: "Pacific/Port_Moresby (GMT+10)"),
                TimezoneOption(value: "Pacific/Bougainville", label: "Pacific/Bougainville (GMT+11)"),
            ]
        ),
        CountryOption(
            name: "Paraguay",
            isoCode: "PY",
            timezones: [
                TimezoneOption(value: "America/Asuncion", label: "America/Asuncion (GMT-3)"),
            ]
        ),
        CountryOption(
            name: "Peru",
            isoCode: "PE",
            timezones: [
                TimezoneOption(value: "America/Lima", label: "America/Lima (GMT-5)"),
            ]
        ),
        CountryOption(
            name: "Philippines",
            isoCode: "PH",
            timezones: [
                TimezoneOption(value: "Asia/Manila", label: "Asia/Manila (GMT+8)"),
            ]
        ),
        CountryOption(
            name: "Poland",
            isoCode: "PL",
            timezones: [
                TimezoneOption(value: "Europe/Warsaw", label: "Europe/Warsaw (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Portugal",
            isoCode: "PT",
            timezones: [
                TimezoneOption(value: "Europe/Lisbon", label: "Europe/Lisbon (GMT+1)"),
                TimezoneOption(value: "Atlantic/Madeira", label: "Atlantic/Madeira (GMT+1)"),
                TimezoneOption(value: "Atlantic/Azores", label: "Atlantic/Azores (GMT+0)"),
            ]
        ),
        CountryOption(
            name: "Qatar",
            isoCode: "QA",
            timezones: [
                TimezoneOption(value: "Asia/Qatar", label: "Asia/Qatar (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Republic of the Congo",
            isoCode: "CG",
            timezones: [
                TimezoneOption(value: "Africa/Brazzaville", label: "Africa/Brazzaville (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Romania",
            isoCode: "RO",
            timezones: [
                TimezoneOption(value: "Europe/Bucharest", label: "Europe/Bucharest (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Russia",
            isoCode: "RU",
            timezones: [
                TimezoneOption(value: "Europe/Moscow", label: "Europe/Moscow (GMT+3)"),
                TimezoneOption(value: "Europe/Simferopol", label: "Europe/Simferopol (GMT+3)"),
                TimezoneOption(value: "Europe/Kirov", label: "Europe/Kirov (GMT+3)"),
                TimezoneOption(value: "Europe/Astrakhan", label: "Europe/Astrakhan (GMT+4)"),
                TimezoneOption(value: "Europe/Volgograd", label: "Europe/Volgograd (GMT+3)"),
                TimezoneOption(value: "Europe/Saratov", label: "Europe/Saratov (GMT+4)"),
                TimezoneOption(value: "Europe/Ulyanovsk", label: "Europe/Ulyanovsk (GMT+4)"),
                TimezoneOption(value: "Europe/Samara", label: "Europe/Samara (GMT+4)"),
                TimezoneOption(value: "Asia/Yekaterinburg", label: "Asia/Yekaterinburg (GMT+5)"),
                TimezoneOption(value: "Asia/Omsk", label: "Asia/Omsk (GMT+6)"),
                TimezoneOption(value: "Asia/Novosibirsk", label: "Asia/Novosibirsk (GMT+7)"),
                TimezoneOption(value: "Asia/Barnaul", label: "Asia/Barnaul (GMT+7)"),
                TimezoneOption(value: "Asia/Tomsk", label: "Asia/Tomsk (GMT+7)"),
                TimezoneOption(value: "Asia/Novokuznetsk", label: "Asia/Novokuznetsk (GMT+7)"),
                TimezoneOption(value: "Asia/Krasnoyarsk", label: "Asia/Krasnoyarsk (GMT+7)"),
                TimezoneOption(value: "Asia/Irkutsk", label: "Asia/Irkutsk (GMT+8)"),
                TimezoneOption(value: "Asia/Chita", label: "Asia/Chita (GMT+9)"),
                TimezoneOption(value: "Asia/Yakutsk", label: "Asia/Yakutsk (GMT+9)"),
                TimezoneOption(value: "Asia/Vladivostok", label: "Asia/Vladivostok (GMT+10)"),
                TimezoneOption(value: "Asia/Khandyga", label: "Asia/Khandyga (GMT+9)"),
                TimezoneOption(value: "Asia/Sakhalin", label: "Asia/Sakhalin (GMT+11)"),
                TimezoneOption(value: "Asia/Ust-Nera", label: "Asia/Ust-Nera (GMT+10)"),
                TimezoneOption(value: "Asia/Magadan", label: "Asia/Magadan (GMT+11)"),
                TimezoneOption(value: "Asia/Srednekolymsk", label: "Asia/Srednekolymsk (GMT+11)"),
                TimezoneOption(value: "Asia/Kamchatka", label: "Asia/Kamchatka (GMT+12)"),
                TimezoneOption(value: "Asia/Anadyr", label: "Asia/Anadyr (GMT+12)"),
            ]
        ),
        CountryOption(
            name: "Rwanda",
            isoCode: "RW",
            timezones: [
                TimezoneOption(value: "Africa/Kigali", label: "Africa/Kigali (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Saint Kitts and Nevis",
            isoCode: "KN",
            timezones: [
                TimezoneOption(value: "America/St_Kitts", label: "America/St_Kitts (AST)"),
            ]
        ),
        CountryOption(
            name: "Saint Lucia",
            isoCode: "LC",
            timezones: [
                TimezoneOption(value: "America/St_Lucia", label: "America/St_Lucia (AST)"),
            ]
        ),
        CountryOption(
            name: "Saint Vincent and the Grenadines",
            isoCode: "VC",
            timezones: [
                TimezoneOption(value: "America/St_Vincent", label: "America/St_Vincent (AST)"),
            ]
        ),
        CountryOption(
            name: "Samoa",
            isoCode: "WS",
            timezones: [
                TimezoneOption(value: "Pacific/Apia", label: "Pacific/Apia (GMT+13)"),
            ]
        ),
        CountryOption(
            name: "San Marino",
            isoCode: "SM",
            timezones: [
                TimezoneOption(value: "Europe/San_Marino", label: "Europe/San_Marino (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Sao Tome and Principe",
            isoCode: "ST",
            timezones: [
                TimezoneOption(value: "Africa/Sao_Tome", label: "Africa/Sao_Tome (GMT)"),
            ]
        ),
        CountryOption(
            name: "Saudi Arabia",
            isoCode: "SA",
            timezones: [
                TimezoneOption(value: "Asia/Riyadh", label: "Asia/Riyadh (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Senegal",
            isoCode: "SN",
            timezones: [
                TimezoneOption(value: "Africa/Dakar", label: "Africa/Dakar (GMT)"),
            ]
        ),
        CountryOption(
            name: "Serbia",
            isoCode: "RS",
            timezones: [
                TimezoneOption(value: "Europe/Belgrade", label: "Europe/Belgrade (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Seychelles",
            isoCode: "SC",
            timezones: [
                TimezoneOption(value: "Indian/Mahe", label: "Indian/Mahe (GMT+4)"),
            ]
        ),
        CountryOption(
            name: "Sierra Leone",
            isoCode: "SL",
            timezones: [
                TimezoneOption(value: "Africa/Freetown", label: "Africa/Freetown (GMT)"),
            ]
        ),
        CountryOption(
            name: "Singapore",
            isoCode: "SG",
            timezones: [
                TimezoneOption(value: "Asia/Singapore", label: "Asia/Singapore (GMT+8)"),
            ]
        ),
        CountryOption(
            name: "Slovakia",
            isoCode: "SK",
            timezones: [
                TimezoneOption(value: "Europe/Bratislava", label: "Europe/Bratislava (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Slovenia",
            isoCode: "SI",
            timezones: [
                TimezoneOption(value: "Europe/Ljubljana", label: "Europe/Ljubljana (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Solomon Islands",
            isoCode: "SB",
            timezones: [
                TimezoneOption(value: "Pacific/Guadalcanal", label: "Pacific/Guadalcanal (GMT+11)"),
            ]
        ),
        CountryOption(
            name: "Somalia",
            isoCode: "SO",
            timezones: [
                TimezoneOption(value: "Africa/Mogadishu", label: "Africa/Mogadishu (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "South Africa",
            isoCode: "ZA",
            timezones: [
                TimezoneOption(value: "Africa/Johannesburg", label: "Africa/Johannesburg (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "South Korea",
            isoCode: "KR",
            timezones: [
                TimezoneOption(value: "Asia/Seoul", label: "Asia/Seoul (GMT+9)"),
            ]
        ),
        CountryOption(
            name: "South Sudan",
            isoCode: "SS",
            timezones: [
                TimezoneOption(value: "Africa/Juba", label: "Africa/Juba (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Spain",
            isoCode: "ES",
            timezones: [
                TimezoneOption(value: "Europe/Madrid", label: "Europe/Madrid (GMT+2)"),
                TimezoneOption(value: "Africa/Ceuta", label: "Africa/Ceuta (GMT+2)"),
                TimezoneOption(value: "Atlantic/Canary", label: "Atlantic/Canary (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Sri Lanka",
            isoCode: "LK",
            timezones: [
                TimezoneOption(value: "Asia/Colombo", label: "Asia/Colombo (GMT+5:30)"),
            ]
        ),
        CountryOption(
            name: "Sudan",
            isoCode: "SD",
            timezones: [
                TimezoneOption(value: "Africa/Khartoum", label: "Africa/Khartoum (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Suriname",
            isoCode: "SR",
            timezones: [
                TimezoneOption(value: "America/Paramaribo", label: "America/Paramaribo (GMT-3)"),
            ]
        ),
        CountryOption(
            name: "Sweden",
            isoCode: "SE",
            timezones: [
                TimezoneOption(value: "Europe/Stockholm", label: "Europe/Stockholm (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Switzerland",
            isoCode: "CH",
            timezones: [
                TimezoneOption(value: "Europe/Zurich", label: "Europe/Zurich (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Syria",
            isoCode: "SY",
            timezones: [
                TimezoneOption(value: "Asia/Damascus", label: "Asia/Damascus (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Tajikistan",
            isoCode: "TJ",
            timezones: [
                TimezoneOption(value: "Asia/Dushanbe", label: "Asia/Dushanbe (GMT+5)"),
            ]
        ),
        CountryOption(
            name: "Tanzania",
            isoCode: "TZ",
            timezones: [
                TimezoneOption(value: "Africa/Dar_es_Salaam", label: "Africa/Dar_es_Salaam (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Thailand",
            isoCode: "TH",
            timezones: [
                TimezoneOption(value: "Asia/Bangkok", label: "Asia/Bangkok (GMT+7)"),
            ]
        ),
        CountryOption(
            name: "Timor-Leste",
            isoCode: "TL",
            timezones: [
                TimezoneOption(value: "Asia/Dili", label: "Asia/Dili (GMT+9)"),
            ]
        ),
        CountryOption(
            name: "Togo",
            isoCode: "TG",
            timezones: [
                TimezoneOption(value: "Africa/Lome", label: "Africa/Lome (GMT)"),
            ]
        ),
        CountryOption(
            name: "Tonga",
            isoCode: "TO",
            timezones: [
                TimezoneOption(value: "Pacific/Tongatapu", label: "Pacific/Tongatapu (GMT+13)"),
            ]
        ),
        CountryOption(
            name: "Trinidad and Tobago",
            isoCode: "TT",
            timezones: [
                TimezoneOption(value: "America/Port_of_Spain", label: "America/Port_of_Spain (AST)"),
            ]
        ),
        CountryOption(
            name: "Tunisia",
            isoCode: "TN",
            timezones: [
                TimezoneOption(value: "Africa/Tunis", label: "Africa/Tunis (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "Turkey",
            isoCode: "TR",
            timezones: [
                TimezoneOption(value: "Europe/Istanbul", label: "Europe/Istanbul (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Turkmenistan",
            isoCode: "TM",
            timezones: [
                TimezoneOption(value: "Asia/Ashgabat", label: "Asia/Ashgabat (GMT+5)"),
            ]
        ),
        CountryOption(
            name: "Tuvalu",
            isoCode: "TV",
            timezones: [
                TimezoneOption(value: "Pacific/Funafuti", label: "Pacific/Funafuti (GMT+12)"),
            ]
        ),
        CountryOption(
            name: "Uganda",
            isoCode: "UG",
            timezones: [
                TimezoneOption(value: "Africa/Kampala", label: "Africa/Kampala (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Ukraine",
            isoCode: "UA",
            timezones: [
                TimezoneOption(value: "Europe/Kyiv", label: "Europe/Kyiv (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "United Arab Emirates",
            isoCode: "AE",
            timezones: [
                TimezoneOption(value: "Asia/Dubai", label: "Asia/Dubai (GMT+4)"),
            ]
        ),
        CountryOption(
            name: "United Kingdom",
            isoCode: "GB",
            timezones: [
                TimezoneOption(value: "Europe/London", label: "Europe/London (GMT+1)"),
            ]
        ),
        CountryOption(
            name: "United States",
            isoCode: "US",
            timezones: [
                TimezoneOption(value: "America/New_York", label: "America/New_York (EDT)"),
                TimezoneOption(value: "America/Detroit", label: "America/Detroit (EDT)"),
                TimezoneOption(value: "America/Kentucky/Louisville", label: "America/Kentucky/Louisville (EDT)"),
                TimezoneOption(value: "America/Kentucky/Monticello", label: "America/Kentucky/Monticello (EDT)"),
                TimezoneOption(value: "America/Indiana/Indianapolis", label: "America/Indiana/Indianapolis (EDT)"),
                TimezoneOption(value: "America/Indiana/Vincennes", label: "America/Indiana/Vincennes (EDT)"),
                TimezoneOption(value: "America/Indiana/Winamac", label: "America/Indiana/Winamac (EDT)"),
                TimezoneOption(value: "America/Indiana/Marengo", label: "America/Indiana/Marengo (EDT)"),
                TimezoneOption(value: "America/Indiana/Petersburg", label: "America/Indiana/Petersburg (EDT)"),
                TimezoneOption(value: "America/Indiana/Vevay", label: "America/Indiana/Vevay (EDT)"),
                TimezoneOption(value: "America/Chicago", label: "America/Chicago (CDT)"),
                TimezoneOption(value: "America/Indiana/Tell_City", label: "America/Indiana/Tell_City (CDT)"),
                TimezoneOption(value: "America/Indiana/Knox", label: "America/Indiana/Knox (CDT)"),
                TimezoneOption(value: "America/North_Dakota/Center", label: "America/North_Dakota/Center (CDT)"),
                TimezoneOption(value: "America/North_Dakota/New_Salem", label: "America/North_Dakota/New_Salem (CDT)"),
                TimezoneOption(value: "America/North_Dakota/Beulah", label: "America/North_Dakota/Beulah (CDT)"),
                TimezoneOption(value: "America/Denver", label: "America/Denver (MDT)"),
                TimezoneOption(value: "America/Boise", label: "America/Boise (MDT)"),
                TimezoneOption(value: "America/Phoenix", label: "America/Phoenix (MST)"),
                TimezoneOption(value: "America/Los_Angeles", label: "America/Los_Angeles (PDT)"),
                TimezoneOption(value: "America/Anchorage", label: "America/Anchorage (AKDT)"),
                TimezoneOption(value: "America/Juneau", label: "America/Juneau (AKDT)"),
                TimezoneOption(value: "America/Sitka", label: "America/Sitka (AKDT)"),
                TimezoneOption(value: "America/Metlakatla", label: "America/Metlakatla (AKDT)"),
                TimezoneOption(value: "America/Yakutat", label: "America/Yakutat (AKDT)"),
                TimezoneOption(value: "America/Nome", label: "America/Nome (AKDT)"),
                TimezoneOption(value: "America/Adak", label: "America/Adak (HADT)"),
                TimezoneOption(value: "Pacific/Honolulu", label: "Pacific/Honolulu (HST)"),
            ]
        ),
        CountryOption(
            name: "Uruguay",
            isoCode: "UY",
            timezones: [
                TimezoneOption(value: "America/Montevideo", label: "America/Montevideo (GMT-3)"),
            ]
        ),
        CountryOption(
            name: "Uzbekistan",
            isoCode: "UZ",
            timezones: [
                TimezoneOption(value: "Asia/Samarkand", label: "Asia/Samarkand (GMT+5)"),
                TimezoneOption(value: "Asia/Tashkent", label: "Asia/Tashkent (GMT+5)"),
            ]
        ),
        CountryOption(
            name: "Vanuatu",
            isoCode: "VU",
            timezones: [
                TimezoneOption(value: "Pacific/Efate", label: "Pacific/Efate (GMT+11)"),
            ]
        ),
        CountryOption(
            name: "Venezuela",
            isoCode: "VE",
            timezones: [
                TimezoneOption(value: "America/Caracas", label: "America/Caracas (GMT-4)"),
            ]
        ),
        CountryOption(
            name: "Vietnam",
            isoCode: "VN",
            timezones: [
                TimezoneOption(value: "Asia/Ho_Chi_Minh", label: "Asia/Ho_Chi_Minh (GMT+7)"),
            ]
        ),
        CountryOption(
            name: "Yemen",
            isoCode: "YE",
            timezones: [
                TimezoneOption(value: "Asia/Aden", label: "Asia/Aden (GMT+3)"),
            ]
        ),
        CountryOption(
            name: "Zambia",
            isoCode: "ZM",
            timezones: [
                TimezoneOption(value: "Africa/Lusaka", label: "Africa/Lusaka (GMT+2)"),
            ]
        ),
        CountryOption(
            name: "Zimbabwe",
            isoCode: "ZW",
            timezones: [
                TimezoneOption(value: "Africa/Harare", label: "Africa/Harare (GMT+2)"),
            ]
        ),
    ]

    /// Returns timezones for the specified country name.
    public static func timezones(forCountry name: String) -> [TimezoneOption] {
        if let match = allCountries.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame || ($0.name == "United States" && name == "USA") }) {
            return match.timezones
        }
        return [TimezoneOption(value: TimeZone.current.identifier, label: TimeZone.current.identifier)]
    }

    /// Returns the 2-letter ISO country code for the specified country name.
    public static func isoCode(forCountry name: String) -> String {
        if let match = allCountries.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame || ($0.name == "United States" && name == "USA") }) {
            return match.isoCode
        }
        return "US"
    }

    /// Returns the country name corresponding to a 2-letter ISO country code.
    public static func countryName(forIsoCode code: String) -> String {
        if let match = allCountries.first(where: { $0.isoCode.caseInsensitiveCompare(code) == .orderedSame }) {
            return match.name
        }
        return "United States"
    }

    /// Resolves country name for a given timezone identifier.
    public static func countryName(forTimezone timezoneId: String) -> String? {
        for country in allCountries {
            if country.timezones.contains(where: { $0.value == timezoneId }) {
                return country.name
            }
        }
        return nil
    }
}
