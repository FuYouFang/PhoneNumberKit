//
//  PhoneNumberTextField.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 07/11/2015.
//  Copyright © 2021 Roy Marmelstein. All rights reserved.
//

#if canImport(UIKit)

import Foundation
import UIKit

/// Custom text field that formats phone numbers
open class PhoneNumberTextField: UITextField, UITextFieldDelegate {
    public let phoneNumberKit: PhoneNumberKit

    public lazy var flagButton = UIButton()

    /// Override setText so number will be automatically formatted when setting text by code
    open override var text: String? {
        set {
            if isPartialFormatterEnabled, let newValue = newValue {
                let formattedNumber = partialFormatter.formatPartial(newValue)
                super.text = formattedNumber
            } else {
                super.text = newValue
            }
            NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: self)
        }
        get {
            return super.text
        }
    }

    /// allows text to be set without formatting
    open func setTextUnformatted(newValue: String?) {
        super.text = newValue
    }

    private lazy var _defaultRegion: String = PhoneNumberKit.defaultRegionCode()

    /// Override region to set a custom region. Automatically uses the default region code.
    open var defaultRegion: String {
        get {
            return self._defaultRegion
        }
        @available(
            *,
            deprecated,
            message: """
                The setter of defaultRegion is deprecated,
                please override defaultRegion in a subclass instead.
            """
        )
        set {
            self.partialFormatter.defaultRegion = newValue
        }
    }

    public var withPrefix: Bool = true {
        didSet {
            self.partialFormatter.withPrefix = self.withPrefix
            if self.withPrefix == false {
                self.keyboardType = .numberPad
            } else {
                self.keyboardType = .phonePad
            }
            if self.withExamplePlaceholder {
                self.updatePlaceholder()
            }
        }
    }

    public var withFlag: Bool = false {
        didSet {
            leftView = self.withFlag ? self.flagButton : nil
            leftViewMode = self.withFlag ? .always : .never
            self.updateFlag()
        }
    }

    public var withExamplePlaceholder: Bool = false {
        didSet {
            if self.withExamplePlaceholder {
                self.updatePlaceholder()
            } else {
                attributedPlaceholder = nil
            }
        }
    }

    #if compiler(>=5.1)
    /// Available on iOS 13 and above just.
    public var countryCodePlaceholderColor: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return UIColor(red: 0, green: 0, blue: 0.0980392, alpha: 0.22)
        }
    }() {
        didSet {
            self.updatePlaceholder()
        }
    }

    /// Available on iOS 13 and above just.
    public var numberPlaceholderColor: UIColor = {
        if #available(iOS 13.0, *) {
            return .tertiaryLabel
        } else {
            return UIColor(red: 0, green: 0, blue: 0.0980392, alpha: 0.22)
        }
    }() {
        didSet {
            self.updatePlaceholder()
        }
    }
    #endif

    private var _withDefaultPickerUI: Bool = false {
        didSet {
            if #available(iOS 11.0, *), flagButton.actions(forTarget: self, forControlEvent: .touchUpInside) == nil {
                flagButton.addTarget(self, action: #selector(didPressFlagButton), for: .touchUpInside)
            }
        }
    }

    @available(iOS 11.0, *)
    public var withDefaultPickerUI: Bool {
        get { _withDefaultPickerUI }
        set { _withDefaultPickerUI = newValue }
    }

    public var isPartialFormatterEnabled = true

    public var maxDigits: Int? {
        didSet {
            self.partialFormatter.maxDigits = self.maxDigits
        }
    }

    public private(set) lazy var partialFormatter: PartialFormatter = PartialFormatter(
        phoneNumberKit: phoneNumberKit,
        defaultRegion: defaultRegion,
        withPrefix: withPrefix
    )

    let nonNumericSet: NSCharacterSet = {
        var mutableSet = NSMutableCharacterSet.decimalDigit().inverted
        mutableSet.remove(charactersIn: PhoneNumberConstants.plusChars)
        mutableSet.remove(charactersIn: PhoneNumberConstants.pausesAndWaitsChars)
        mutableSet.remove(charactersIn: PhoneNumberConstants.operatorChars)
        return mutableSet as NSCharacterSet
    }()

    
    /// 当前类实现了自己的代理，但是不能影响其他类使用当前类的代理
    /// 所以类有两个 deleget:
    /// 1. super.delegate = self
    /// 2. _delegate
    private weak var _delegate: UITextFieldDelegate?

    open override var delegate: UITextFieldDelegate? {
        get {
            return self._delegate
        }
        set {
            self._delegate = newValue
        }
    }

    // MARK: Status

    public var currentRegion: String {
        return self.partialFormatter.currentRegion
    }

    public var nationalNumber: String {
        let rawNumber = self.text ?? String()
        return self.partialFormatter.nationalNumber(from: rawNumber)
    }

    public var isValidNumber: Bool {
        let rawNumber = self.text ?? String()
        do {
            _ = try phoneNumberKit.parse(rawNumber, withRegion: currentRegion)
            return true
        } catch {
            return false
        }
    }

    /**
     Returns the current valid phone number.
     - returns: PhoneNumber?
     */
    public var phoneNumber: PhoneNumber? {
        guard let rawNumber = self.text else { return nil }
        do {
            return try phoneNumberKit.parse(rawNumber, withRegion: currentRegion)
        } catch {
            return nil
        }
    }

    #warning("todo 在layoutSubviews 中设置 flagButton 的宽度")
    open override func layoutSubviews() {
        if self.withFlag { // update the width of the flagButton automatically, iOS <13 doesn't handle this for you
            let width = self.flagButton.systemLayoutSizeFitting(bounds.size).width
            self.flagButton.frame.size.width = width
        }
        super.layoutSubviews()
    }

    // MARK: Lifecycle

    /**
     Init with a phone number kit instance. Because a PhoneNumberKit initialization is expensive,
     you can pass a pre-initialized instance to avoid incurring perf penalties.

     - parameter phoneNumberKit: A PhoneNumberKit instance to be used by the text field.

     - returns: UITextfield
     */
    public convenience init(withPhoneNumberKit phoneNumberKit: PhoneNumberKit) {
        self.init(frame: .zero, phoneNumberKit: phoneNumberKit)
    }

    /**
     Init with frame and phone number kit instance.

     - parameter frame: UITextfield frame
     - parameter phoneNumberKit: A PhoneNumberKit instance to be used by the text field.

     - returns: UITextfield
     */
    public init(frame: CGRect, phoneNumberKit: PhoneNumberKit) {
        self.phoneNumberKit = phoneNumberKit
        super.init(frame: frame)
        self.setup()
    }

    /**
     Init with frame

     - parameter frame: UITextfield F

     - returns: UITextfield
     */
    public override init(frame: CGRect) {
        self.phoneNumberKit = PhoneNumberKit()
        super.init(frame: frame)
        self.setup()
    }

    /**
     Init with coder

     - parameter aDecoder: decoder

     - returns: UITextfield
     */
    public required init(coder aDecoder: NSCoder) {
        self.phoneNumberKit = PhoneNumberKit()
        super.init(coder: aDecoder)!
        self.setup()
    }

    func setup() {
        self.autocorrectionType = .no
        self.keyboardType = .phonePad
        super.delegate = self
    }

    func internationalPrefix(for countryCode: String) -> String? {
        guard let countryCode = phoneNumberKit.countryCode(for: currentRegion)?.description else { return nil }
        return "+" + countryCode
    }

    open func updateFlag() {
        guard self.withFlag else { return }
        let flagBase = UnicodeScalar("🇦").value - UnicodeScalar("A").value

        let flag = self.currentRegion
            .uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(flagBase + $0.value)?.description }
            .joined()

        self.flagButton.setTitle(flag + " ", for: .normal)
        /*
         下面两行代码为什么不写成：
         self.flagButton.titleLabel?.font = font ?? UIFont.preferredFont(forTextStyle: .body)
         */
        let fontSize = (font ?? UIFont.preferredFont(forTextStyle: .body)).pointSize
        self.flagButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
    }

    open func updatePlaceholder() {
        guard self.withExamplePlaceholder else { return }
        if isEditing, !(self.text ?? "").isEmpty { return } // No need to update a placeholder while the placeholder isn't showing

        let format = self.withPrefix ? PhoneNumberFormat.international : .national
        let example = self.phoneNumberKit.getFormattedExampleNumber(forCountry: self.currentRegion, withFormat: format, withPrefix: self.withPrefix) ?? "12345678"
        let font = self.font ?? UIFont.preferredFont(forTextStyle: .body)
        let ph = NSMutableAttributedString(string: example, attributes: [.font: font])

        #if compiler(>=5.1)
        if #available(iOS 13.0, *), self.withPrefix {
            // because the textfield will automatically handle insert & removal of the international prefix we make the
            // prefix darker to indicate non default behaviour to users, this behaviour currently only happens on iOS 13
            // and above just because that is where we have access to label colors
            let firstSpaceIndex = example.firstIndex(where: { $0 == " " }) ?? example.startIndex

            ph.addAttribute(.foregroundColor, value: self.countryCodePlaceholderColor, range: NSRange(..<firstSpaceIndex, in: example))
            ph.addAttribute(.foregroundColor, value: self.numberPlaceholderColor, range: NSRange(firstSpaceIndex..., in: example))
        }
        #endif

        self.attributedPlaceholder = ph
    }

    @available(iOS 11.0, *)
    @objc func didPressFlagButton() {
        guard withDefaultPickerUI else { return }
        let vc = CountryCodePickerViewController(phoneNumberKit: phoneNumberKit)
        vc.delegate = self
        if let nav = containingViewController?.navigationController, !PhoneNumberKit.CountryCodePicker.forceModalPresentation {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            containingViewController?.present(nav, animated: true)
        }
    }

    /// containingViewController looks at the responder chain to find the view controller nearest to itself
    var containingViewController: UIViewController? {
        var responder: UIResponder? = self
        while !(responder is UIViewController) && responder != nil {
            responder = responder?.next
        }
        return (responder as? UIViewController)
    }


    // MARK: Phone number formatting

    /**
     *  To keep the cursor position, we find the character immediately after the cursor and count the number of times it repeats in the remaining string as this will remain constant in every kind of editing.
     */

    internal struct CursorPosition {
        let numberAfterCursor: String // 光标后的数字
        let repetitionCountFromEnd: Int // 从光标后面看一共有多少个重复的
    }

    
    /// 提取当前的光标位置
    /// 从**当前是的字符串** 当前位置向后查找，找到第一个电话号的字符，然后看后面一共有多少个
    /// 然后在**新的字符串**当中，找到对应的字符位置，即为新的选中位置
    /// - Returns:
    internal func extractCursorPosition() -> CursorPosition? {
        var repetitionCountFromEnd = 0
        // Check that there is text in the UITextField
        guard let text = text, let selectedTextRange = selectedTextRange else {
            return nil
        }
        let textAsNSString = text as NSString
        // 从文章的开始，到光标的位置
        // UITextPosition 最前面为 0，一个字符之后 +1
        // 所有 cursorEnd 偏移量为光标后的的字符
        // func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int
        let cursorEnd = offset(from: beginningOfDocument, to: selectedTextRange.end)
        
        // 如果光标的后面为空格等，则向后查找
        // Look for the next valid number after the cursor, when found return a CursorPosition struct
        for i in cursorEnd..<textAsNSString.length {
            let cursorRange = NSRange(location: i, length: 1)
            let candidateNumberAfterCursor = textAsNSString.substring(with: cursorRange) as NSString
            // 如果不是空格等
            if candidateNumberAfterCursor.rangeOfCharacter(from: self.nonNumericSet as CharacterSet).location == NSNotFound {
                // 感觉直接从下个目标找就行了
                for j in cursorRange.location..<textAsNSString.length {
                    let candidateCharacter = textAsNSString.substring(with: NSRange(location: j, length: 1))
                    if candidateCharacter == candidateNumberAfterCursor as String {
                        repetitionCountFromEnd += 1
                    }
                }
                return CursorPosition(numberAfterCursor: candidateNumberAfterCursor as String, repetitionCountFromEnd: repetitionCountFromEnd)
            }
        }
        return nil
    }

    // Finds position of previous cursor in new formatted text
    internal func selectionRangeForNumberReplacement(textField: UITextField,
                                                     formattedText: String) -> NSRange? {
        guard let cursorPosition = extractCursorPosition() else {
            return nil
        }
        let textAsNSString = formattedText as NSString
        var countFromEnd = 0

        //
        for i in stride(from: textAsNSString.length - 1, through: 0, by: -1) {
            let candidateRange = NSRange(location: i, length: 1)
            let candidateCharacter = textAsNSString.substring(with: candidateRange)
            if candidateCharacter == cursorPosition.numberAfterCursor {
                countFromEnd += 1
                if countFromEnd == cursorPosition.repetitionCountFromEnd {
                    return candidateRange
                }
            }
        }

        return nil
    }

    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // This allows for the case when a user autocompletes a phone number:
        if range == NSRange(location: 0, length: 0) && string.isBlank {
            return true
        }

        guard let text = text else {
            return false
        }

        // allow delegate to intervene
        guard self._delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true else {
            return false
        }
        guard self.isPartialFormatterEnabled else {
            return true
        }

        let textAsNSString = text as NSString
        let changedRange = textAsNSString.substring(with: range) as NSString
        let modifiedTextField = textAsNSString.replacingCharacters(in: range, with: string)

        
        var selectedTextRange: NSRange?

        // 修改的位置有非法字符
        let nonNumericRange = (changedRange.rangeOfCharacter(from: self.nonNumericSet as CharacterSet).location != NSNotFound)
        // 修个分成了两种情况：
        // 1. 删除了一个字符串，并且删除的位置为非法字符
        //    则将 text 赋值为修改后的内容，直接通过删除当前位置的字符后的字符串进行定位
        // 2. 添加、删除多个字符
        //    则首先移出所有的非法字符，然后格式化，通过格式化后的字符串进行定位
        if range.length == 1, string.isEmpty, nonNumericRange {
            // modifiedTextField 修改后的字符
            selectedTextRange = self.selectionRangeForNumberReplacement(textField: textField, formattedText: modifiedTextField)
            textField.text = modifiedTextField
        } else {
            // 过滤非法字符
            let filteredCharacters = modifiedTextField.filter {
                String($0).rangeOfCharacter(from: (textField as! PhoneNumberTextField).nonNumericSet as CharacterSet) == nil
            }
            let rawNumberString = String(filteredCharacters)

            let formattedNationalNumber = self.partialFormatter.formatPartial(rawNumberString)
            // formattedNationalNumber 格式化后的字符
            selectedTextRange = self.selectionRangeForNumberReplacement(textField: textField, formattedText: formattedNationalNumber)
            textField.text = formattedNationalNumber
        }
        // 发送 editingChanged 通知
        sendActions(for: .editingChanged)
        /*
         selectedTextRange
         selectionRangePosition 开始的位置
         selectionRange 选择的区间
         */
        if let selectedTextRange = selectedTextRange,
           let selectionRangePosition = textField.position(from: beginningOfDocument,
                                                           offset: selectedTextRange.location) {
            
            let selectionRange = textField.textRange(from: selectionRangePosition, to: selectionRangePosition)
            textField.selectedTextRange = selectionRange
        }

        // we change the default region to be the one most recently typed
        self._defaultRegion = self.currentRegion
        self.partialFormatter.defaultRegion = self.currentRegion
        self.updateFlag()
        self.updatePlaceholder()

        return false
    }

    // MARK: UITextfield Delegate

    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return self._delegate?.textFieldShouldBeginEditing?(textField) ?? true
    }

    open func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.withExamplePlaceholder,
           self.withPrefix,
           let countryCode = phoneNumberKit.countryCode(for: currentRegion)?.description,
           (text ?? "").isEmpty {
            text = "+" + countryCode + " "
        }
        self._delegate?.textFieldDidBeginEditing?(textField)
    }

    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return self._delegate?.textFieldShouldEndEditing?(textField) ?? true
    }

    open func textFieldDidEndEditing(_ textField: UITextField) {
        updateTextFieldDidEndEditing(textField)
        self._delegate?.textFieldDidEndEditing?(textField)
    }

    @available (iOS 10.0, tvOS 10.0, *)
    open func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        updateTextFieldDidEndEditing(textField)
        
        // 应该是兼容老版本
        if let _delegate = _delegate {
            if (_delegate.responds(to: #selector(textFieldDidEndEditing(_:reason:)))) {
                _delegate.textFieldDidEndEditing?(textField, reason: reason)
            } else {
                _delegate.textFieldDidEndEditing?(textField)
            }
        }
    }

    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return self._delegate?.textFieldShouldClear?(textField) ?? true
    }

    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self._delegate?.textFieldShouldReturn?(textField) ?? true
    }

    private func updateTextFieldDidEndEditing(_ textField: UITextField) {
        // 编辑结束的时候，如果 text 中，只有区号，则清空
        // 这样就可以显示 placeholder 了
        // 当再次开始编辑的时候，从再加上区号
        if self.withExamplePlaceholder, self.withPrefix,
           let countryCode = phoneNumberKit.countryCode(for: currentRegion)?.description,
            let text = textField.text,
            text == internationalPrefix(for: countryCode) {
            textField.text = ""
            sendActions(for: .editingChanged)
            self.updateFlag()
            self.updatePlaceholder()
        }
    }
}

@available(iOS 11.0, *)
extension PhoneNumberTextField: CountryCodePickerDelegate {

    public func countryCodePickerViewControllerDidPickCountry(_ country: CountryCodePickerViewController.Country) {
        text = isEditing ? "+" + country.prefix : ""
        _defaultRegion = country.code
        partialFormatter.defaultRegion = country.code
        updateFlag()
        updatePlaceholder()

        if let nav = containingViewController?.navigationController, !PhoneNumberKit.CountryCodePicker.forceModalPresentation {
            nav.popViewController(animated: true)
        } else {
            containingViewController?.dismiss(animated: true)
        }
    }
}

extension String {
  var isBlank: Bool {
    return allSatisfy({ $0.isWhitespace })
  }
}

#endif
