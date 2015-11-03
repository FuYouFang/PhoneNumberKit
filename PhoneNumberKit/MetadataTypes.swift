//
//  MetadataTypes.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 02/11/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

import Foundation

/**
MetadataTerritory object
- Parameter codeID: ISO 639 compliant region code
- Parameter countryCode: International country code
- Parameter internationalPrefix: International prefix. Optional.
- Parameter mainCountryForCode: Whether the current metadata is the main country for its country code.
- Parameter nationalPrefix: National prefix
- Parameter nationalPrefixForParsing: National prefix for parsing
- Parameter nationalPrefixTransformRule: National prefix transform rule
- Parameter emergency: MetadataPhoneNumberDesc for emergency numbers
- Parameter fixedLine: MetadataPhoneNumberDesc for fixed line numbers
- Parameter generalDesc: MetadataPhoneNumberDesc for general numbers
- Parameter mobile: MetadataPhoneNumberDesc for mobile numbers
- Parameter pager: MetadataPhoneNumberDesc for pager numbers
- Parameter personalNumber: MetadataPhoneNumberDesc for personal number numbers
- Parameter premiumRate: MetadataPhoneNumberDesc for premium rate numbers
- Parameter sharedCost: MetadataPhoneNumberDesc for shared cost numbers
- Parameter tollFree: MetadataPhoneNumberDesc for toll free numbers
- Parameter voicemail: MetadataPhoneNumberDesc for voice mail numbers
- Parameter voip: MetadataPhoneNumberDesc for voip numbers
- Parameter uan: MetadataPhoneNumberDesc for uan numbers
*/
struct MetadataTerritory {
    let codeID: String
    let countryCode: UInt64
    let internationalPrefix: String?
    var mainCountryForCode: Bool = false
    let nationalPrefix: String?
    let nationalPrefixForParsing: String?
    let nationalPrefixTransformRule: String?
    let emergency: MetadataPhoneNumberDesc?
    let fixedLine: MetadataPhoneNumberDesc?
    let generalDesc: MetadataPhoneNumberDesc?
    let mobile: MetadataPhoneNumberDesc?
    let pager: MetadataPhoneNumberDesc?
    let personalNumber: MetadataPhoneNumberDesc?
    let premiumRate: MetadataPhoneNumberDesc?
    let sharedCost: MetadataPhoneNumberDesc?
    let tollFree: MetadataPhoneNumberDesc?
    let voicemail: MetadataPhoneNumberDesc?
    let voip: MetadataPhoneNumberDesc?
    let uan: MetadataPhoneNumberDesc?
}

extension MetadataTerritory {
    /**
    Parse a json dictionary into a MetadataTerritory.
    - Parameter jsondDict: json dictionary from attached json metadata file.
    */
    init(jsondDict: NSDictionary) {
        self.generalDesc = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("generalDesc") as? NSDictionary)!)
        self.fixedLine = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("fixedLine") as? NSDictionary))
        self.mobile = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("mobile") as? NSDictionary))
        self.tollFree = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("tollFree") as? NSDictionary))
        self.premiumRate = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("premiumRate") as? NSDictionary))
        self.sharedCost = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("sharedCost") as? NSDictionary))
        self.personalNumber = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("personalNumber") as? NSDictionary))
        self.voip = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("voip") as? NSDictionary))
        self.pager = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("pager") as? NSDictionary))
        self.uan = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("uan") as? NSDictionary))
        self.emergency = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("emergency") as? NSDictionary))
        self.voicemail = MetadataPhoneNumberDesc(jsondDict: (jsondDict.valueForKey("voicemail") as? NSDictionary))
        self.codeID = jsondDict.valueForKey("_id") as! String
        self.countryCode = UInt64(jsondDict.valueForKey("_countryCode") as! String)!
        self.internationalPrefix = jsondDict.valueForKey("_internationalPrefix") as? String
        self.nationalPrefixTransformRule = jsondDict.valueForKey("_nationalPrefixTransformRule") as? String
        let possibleNationalPrefixForParsing = jsondDict.valueForKey("_nationalPrefixForParsing") as? String
        let possibleNationalPrefix = jsondDict.valueForKey("_nationalPrefix") as? String
        self.nationalPrefix = possibleNationalPrefix
        if (possibleNationalPrefixForParsing == nil && possibleNationalPrefix != nil) {
            self.nationalPrefixForParsing = self.nationalPrefix
        }
        else {
            self.nationalPrefixForParsing = possibleNationalPrefixForParsing
        }
        let _mainCountryForCode = jsondDict.valueForKey("_mainCountryForCode") as? NSString
        if (_mainCountryForCode != nil) {
            self.mainCountryForCode = _mainCountryForCode!.boolValue
        }
    }
}


/**
MetadataPhoneNumberDesc object
- Parameter exampleNumber: An example phone number for the given type. Optional.
- Parameter nationalNumberPattern:  National number regex pattern. Optional.
- Parameter possibleNumberPattern:  Possible number regex pattern. Optional.
*/
struct MetadataPhoneNumberDesc {
    let exampleNumber: String?
    let nationalNumberPattern: String?
    let possibleNumberPattern: String?
}

extension MetadataPhoneNumberDesc {
    /**
    Parse a json dictionary into a MetadataTerritory.
    - Parameter jsondDict: json dictionary from attached json metadata file.
    */
    init(jsondDict: NSDictionary?) {
        self.nationalNumberPattern = jsondDict?.valueForKey("nationalNumberPattern") as? String
        self.possibleNumberPattern = jsondDict?.valueForKey("possibleNumberPattern") as? String
        self.exampleNumber = jsondDict?.valueForKey("exampleNumber") as? String
        
    }
}