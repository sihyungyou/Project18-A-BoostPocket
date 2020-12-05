//
//  AddHistoryViewController.swift
//  BoostPocket
//
//  Created by sihyung you on 2020/12/03.
//  Copyright © 2020 BoostPocket. All rights reserved.
//

import UIKit

struct NewHistoryViewModel {
    var isIncome: Bool
    var flagImage: Data
    var currencyCode: String
    var currentDate: Date
    var exchangeRate: Double
}

struct NewHistoryData {
    var title: String
    var memo: String?
    var date: Date
    var image: Data?
    var amount: Double
    var category: HistoryCategory
    var isCard: Bool?
}

class AddHistoryViewController: UIViewController {
    static let identifier = "AddHistoryViewController"
    
    var saveButtonHandler: ((NewHistoryData) -> Void)?
    var newHistoryViewModel: NewHistoryViewModel?
    private var isAddingIncome: Bool = false
    private var historyTitle: String?
    private var memo: String?
    private var date: Date = Date()
    private var image: Data?
    private var amount: Double = 0
    private var category: HistoryCategory = .etc
    private var isCard: Bool = false
    private var imagePicker = UIImagePickerController()
    private let historyTitlePlaceholder = "항목명을 입력해주세요 (선택)"
    
    @IBOutlet weak var historyTitleLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var historyTypeLabel: UILabel!
    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var currencyCodeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var calculatorExpressionLabel: UILabel!
    @IBOutlet weak var calculatedAmountLabel: UILabel!
    @IBOutlet weak var currencyConvertedAmountLabel: UILabel!
    @IBOutlet var coloredButtons: [UIButton]!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var memoButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        configureViews()
    }
    
    private func configureViews() {
        guard let newHistoryViewModel = self.newHistoryViewModel else { return }
        
        self.isAddingIncome = newHistoryViewModel.isIncome
        
        let color = isAddingIncome ? .systemGreen : UIColor(named: "deleteButtonColor")
        
        segmentedControl.isHidden = isAddingIncome
        imageButton.isHidden = isAddingIncome
        memoButton.isHidden = isAddingIncome
        
        // 상단 뷰 색상
        headerView.backgroundColor = color
        
        // 기록 타입
        historyTypeLabel.text = isAddingIncome ? "수입" : "지출"
        historyTypeLabel.textColor = .white
        
        // 국기 이미지
        flagImageView.image = UIImage(data: newHistoryViewModel.flagImage)
        
        // 환율코드
        currencyCodeLabel.text = newHistoryViewModel.currencyCode
        
        // 계산식 레이블
        calculatorExpressionLabel.text = ""
        
        // 계산된 금액 레이블
        calculatedAmountLabel.text = "0"
        calculatedAmountLabel.textColor = .white
        
        // 환율을 적용하여 변환한 금액 레이블
        currencyConvertedAmountLabel.text = "KRW"
        
        // 항목명
        let titleTap = UITapGestureRecognizer(target: self, action: #selector(titleLabelTapped))
        historyTitleLabel.addGestureRecognizer(titleTap)
        historyTitleLabel.text = historyTitlePlaceholder
        historyTitleLabel.textColor = .systemGray2
        
        // 날짜
        // TODO: DatePicker로 변경해서 사용자가 날짜를 바꿀 수 있도록 하는 기능 구현
        date = newHistoryViewModel.currentDate
        let dateLabelText = date.convertToString(format: .dotted)
        dateLabel.text = dateLabelText
        
        // 이미지, 메모 버튼
        
        // 계산기 버튼 색상
        coloredButtons.forEach { button in
            button.setTitleColor(color, for: .normal)
            button.tintColor = color
        }
    }
    
    private func changeCalculatedAmountLabel() {
        guard let stringWithMathematicalOperation = calculatorExpressionLabel.text, isValidExpression(stringWithMathematicalOperation) else { return }
        
        let exp: NSExpression = NSExpression(format: stringWithMathematicalOperation)
        if let amount = exp.expressionValue(with: nil, context: nil) as? Double, let exchangeRate = newHistoryViewModel?.exchangeRate {
            
            calculatedAmountLabel.text = "\(amount.insertComma)"
            
            let convertedAmount = amount / exchangeRate
            currencyConvertedAmountLabel.text = "KRW " + convertedAmount.insertComma
            
            self.amount = amount
        }
    }
    
    private func isValidExpression(_ exp: String) -> Bool {
        let operators = CharacterSet(charactersIn: "+_*/")
        let numbersOnly = exp.components(separatedBy: operators)
        
        for str in numbersOnly {
            let pieces = str.components(separatedBy: ".")
            if pieces.count > 2 {
                print("invalid!")
                return false
            }
        }
        
        return true
    }
    
    @objc func titleLabelTapped() {
        let previousTitle = historyTitleLabel.text == historyTitlePlaceholder ? "" : historyTitleLabel.text
        
        TitleEditViewController.present(at: self, previousTitle: previousTitle ?? "") { [weak self] (newTitle) in
            guard let self = self else { return }
            if self.isAddingIncome {
                self.historyTitle = newTitle.isEmpty ? HistoryCategory.income.name : newTitle
            } else {
                self.historyTitle = newTitle.isEmpty ? HistoryCategory.etc.name : newTitle
            }
            
            self.historyTitleLabel.textColor = self.historyTitle == self.historyTitlePlaceholder ? .systemGray2 : .black
            self.historyTitleLabel.text = self.historyTitle
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        if isAddingIncome {
            let newIncome = NewHistoryData(title: historyTitle ?? HistoryCategory.income.name, memo: memo, date: date, image: nil, amount: amount, category: .income, isCard: nil)
            saveButtonHandler?(newIncome)
        } else {
            let newExpense = NewHistoryData(title: historyTitle ?? HistoryCategory.etc.name, memo: memo, date: date, image: image, amount: amount, category: category, isCard: isCard)
            saveButtonHandler?(newExpense)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addImageButtonTapped(_ sender: Any) {
        openPhotoLibrary()
    }
    
    private func openPhotoLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: false, completion: nil)
    }
    
    @IBAction func addMemoButtonTapped(_ sender: Any) {
        MemoEditViewController.present(at: self, memoType: .expenseMemo) { [weak self] newMemo in
            // TODO: - 메모 입력확인 toaster
            self?.memo = newMemo
        }
    }
    
}

extension AddHistoryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        if let newImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.image = newImage.pngData()
        }
        
        dismiss(animated: true) {
            // TODO: - 이미지 추가확인 toaster
        }
    }
}

// MARK: - Calculator IBActions

extension AddHistoryViewController {
    
    @IBAction func btnNumber(sender: UIButton) {
        guard let buttonText = sender.titleLabel?.text else { return }
        
        if buttonText == ".", let lastCharacter = calculatorExpressionLabel.text?.last, lastCharacter.isOperation() {
            calculatorExpressionLabel.text?.removeLast()
        }
        
        calculatorExpressionLabel.text! += buttonText
        
        if buttonText != "." {
            changeCalculatedAmountLabel()
        }
    }
    
    @IBAction func btnOperator(sender: UIButton) {
        let buttonText = sender.titleLabel?.text
        
        if let lastCharacter = calculatorExpressionLabel.text?.last, lastCharacter.isOperation() {
            calculatorExpressionLabel.text?.removeLast()
        }
        
        calculatorExpressionLabel.text! += buttonText!
    }
    
    @IBAction func backTapped(_ sender: Any) {
        guard let length = calculatorExpressionLabel.text?.count, length > 0 else { return }
        calculatorExpressionLabel.text?.removeLast()
        
        if let lastCharacter = calculatorExpressionLabel.text?.last,
            !lastCharacter.isOperation() {
            changeCalculatedAmountLabel()
        } else if calculatorExpressionLabel.text?.count == 0 {
            calculatedAmountLabel.text = "0"
            currencyConvertedAmountLabel.text = "KRW"
        }
    }
    
}

extension AddHistoryViewController {
    
    static let nibName = "AddHistoryViewController"
    
    static func present(at viewController: UIViewController,
                        newHistoryViewModel: NewHistoryViewModel,
                        saveButtonHandler: ((NewHistoryData) -> Void)?,
                        onPresent: @escaping (() -> Void)) {
        
        let vc = AddHistoryViewController(nibName: nibName, bundle: nil)
        
        vc.newHistoryViewModel = newHistoryViewModel
        vc.saveButtonHandler = saveButtonHandler
        viewController.present(vc, animated: true) {
            onPresent()
        }
    }
    
}
