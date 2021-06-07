//
//  Formatter.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 03/11/2015.
//  Copyright © 2021 Roy Marmelstein. All rights reserved.
//

import Foundation

final class Formatter {
    #warning("这里用的是 weak")
    weak var regexManager: RegexManager?

    init(phoneNumberKit: PhoneNumberKit) {
        self.regexManager = phoneNumberKit.regexManager
    }

    init(regexManager: RegexManager) {
        self.regexManager = regexManager
    }

    // MARK: Formatting functions

    /// Formats phone numbers for display
    ///
    /// - Parameters:
    ///   - phoneNumber: Phone number object.
    ///   - formatType: Format type.
    ///   - regionMetadata: Region meta data.
    /// - Returns: Formatted Modified national number ready for display.
    func format(phoneNumber: PhoneNumber, formatType: PhoneNumberFormat, regionMetadata: MetadataTerritory?) -> String {
        var formattedNationalNumber = phoneNumber.adjustedNationalNumber()
        if let regionMetadata = regionMetadata {
            formattedNationalNumber = self.formatNationalNumber(formattedNationalNumber, regionMetadata: regionMetadata, formatType: formatType)
            if let formattedExtension = formatExtension(phoneNumber.numberExtension, regionMetadata: regionMetadata) {
                formattedNationalNumber = formattedNationalNumber + formattedExtension
            }
        }
        return formattedNationalNumber
    }

    /// Formats extension for display
    /// 格式化电话号码扩展部分的显示。
    ///
    /// - Parameters:
    ///   - numberExtension: Number extension string.
    ///   - regionMetadata: Region meta data.
    /// - Returns: Modified number extension with either a preferred extension prefix or the default one.
    func formatExtension(_ numberExtension: String?, regionMetadata: MetadataTerritory) -> String? {
        guard let extns = numberExtension else {
            return nil
        }
        if let preferredExtnPrefix = regionMetadata.preferredExtnPrefix {
            return "\(preferredExtnPrefix)\(extns)"
        } else {
            return "\(PhoneNumberConstants.defaultExtnPrefix)\(extns)"
        }
    }

    /// Formats national number for display
    /// 将电话号码，根据正则，替换掉对应的字符串，换成格式好的
    ///
    /// - Parameters:
    ///   - nationalNumber: National number string.
    ///   - regionMetadata: Region meta data.
    ///   - formatType: Format type.
    /// - Returns: Modified nationalNumber for display.
    func formatNationalNumber(_ nationalNumber: String,
                              regionMetadata: MetadataTerritory,
                              formatType: PhoneNumberFormat) -> String {
        guard let regexManager = regexManager else { return nationalNumber }
        let formats = regionMetadata.numberFormats
        var selectedFormat: MetadataPhoneNumberFormat?
        // regionMetadata 中定义了 numberFormats，
        // 通过下面的要求选择一个规则
        // 1. 如果电话号码，开头符合 format 的 leadingDigitsPatterns，并且整体符合 format.pattern
        // 2. 没有定义 leadingDigitsPatterns，并且整体符合 format.pattern
        for format in formats {
            if let leadingDigitPattern = format.leadingDigitsPatterns?.last {
                if regexManager.stringPositionByRegex(leadingDigitPattern, string: nationalNumber) == 0 {
                    if regexManager.matchesEntirely(format.pattern, string: nationalNumber) {
                        selectedFormat = format
                        break
                    }
                }
            } else {
                if regexManager.matchesEntirely(format.pattern, string: String(nationalNumber)) {
                    selectedFormat = format
                    break
                }
            }
        }
        
        if let formatPattern = selectedFormat {
            guard let numberFormatRule = (formatType == PhoneNumberFormat.international
                                            && formatPattern.intlFormat != nil) ? formatPattern.intlFormat : formatPattern.format,
                  let pattern = formatPattern.pattern else {
                return nationalNumber
            }
            
            var formattedNationalNumber = String()
            var prefixFormattingRule = String()
            // 国家前缀规则 nationalPrefixFormattingRule 符合 npPattern 的替换成 nationalPrefix
            // 国家前缀规则 nationalPrefixFormattingRule 符合 fgPattern 的替换成 "\\$1"
            if let nationalPrefixFormattingRule = formatPattern.nationalPrefixFormattingRule,
               let nationalPrefix = regionMetadata.nationalPrefix {
                prefixFormattingRule = regexManager.replaceStringByRegex(PhoneNumberPatterns.npPattern,
                                                                         string: nationalPrefixFormattingRule,
                                                                         template: nationalPrefix)
                prefixFormattingRule = regexManager.replaceStringByRegex(PhoneNumberPatterns.fgPattern,
                                                                         string: prefixFormattingRule,
                                                                         template: "\\$1")
            }
            if formatType == PhoneNumberFormat.national, regexManager.hasValue(prefixFormattingRule) {
                let replacePattern = regexManager.replaceFirstStringByRegex(PhoneNumberPatterns.firstGroupPattern,
                                                                            string: numberFormatRule,
                                                                            templateString: prefixFormattingRule)
                formattedNationalNumber = regexManager.replaceStringByRegex(pattern,
                                                                            string: nationalNumber,
                                                                            template: replacePattern)
            } else {
                formattedNationalNumber = regexManager.replaceStringByRegex(pattern,
                                                                            string: nationalNumber,
                                                                            template: numberFormatRule)
            }
            return formattedNationalNumber
        } else {
            return nationalNumber
        }
    }
}

public extension PhoneNumber {
    /**
     Adjust national number for display by adding leading zero if needed. Used for basic formatting functions.
     - Returns: A string representing the adjusted national number.
     */
    func adjustedNationalNumber() -> String {
        if self.leadingZero {
            return "0" + String(nationalNumber)
        } else {
            return String(nationalNumber)
        }
    }
}
