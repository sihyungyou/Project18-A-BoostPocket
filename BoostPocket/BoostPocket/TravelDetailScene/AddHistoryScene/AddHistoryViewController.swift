//
//  AddHistoryViewController.swift
//  BoostPocket
//
//  Created by sihyung you on 2020/12/03.
//  Copyright © 2020 BoostPocket. All rights reserved.
//

import UIKit
import Toaster

protocol AddHistoryDelegate: AnyObject {
    func createHistory(newHistoryData: NewHistoryData)
    func updateHistory(at historyId: UUID?, newHistoryData: NewHistoryData)
}

struct BaseHistoryViewModel {
    // update, delete 시 필요
    var id: UUID?
    // new, edit 모두 필요한 정보
    var isIncome: Bool
    var flagImage: Data
    var currencyCode: String
    var currentDate: Date
    var exchangeRate: Double
    // edit 시 필요한 정보
    var isCard: Bool?
    var category: HistoryCategory?
    var title: String?
    var memo: String?
    var image: Data?
    var amount: Double?
    // 상세화면
    var isPrepare: Bool?
    var countryIdentifier: String?
}

struct NewHistoryData {
    var isIncome: Bool
    var title: String
    var memo: String?
    var date: Date
    var image: Data?
    var amount: Double
    var category: HistoryCategory
    var isCard: Bool?
    var isPrepare: Bool?
}

class AddHistoryViewController: UIViewController {
    static let identifier = "AddHistoryViewController"
    weak var delegate: AddHistoryDelegate?
    
    private var saveButtonHandler: (() -> Void)?
    private var baseHistoryViewModel: BaseHistoryViewModel?
    private var isAddingIncome: Bool = false
    private var memo: String?
    private var image: Data?
    private var amount: Double = 0
    private var category: HistoryCategory = .etc
    private var imagePicker = UIImagePickerController()
    private let historyTitlePlaceholder = "항목명을 입력해주세요 (선택)"
    private var categories: [HistoryCategory] = [.food, .shopping, .tourism, .transportation, .accommodation, .etc]
    private var isCreate: Bool = true
    
    @IBOutlet weak var historyTitleLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var historyTypeLabel: UILabel!
    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var currencyCodeLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var calculatorExpressionLabel: UILabel!
    @IBOutlet weak var calculatedAmountLabel: UILabel!
    @IBOutlet weak var currencyConvertedAmountLabel: UILabel!
    @IBOutlet var coloredButtons: [UIButton]!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var memoButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var categoryCollectionView: UICollectionView!
    @IBOutlet weak var incomeInfoView: UIView!
    @IBOutlet weak var currencyInfoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        configureViews()
    }
    
    private func configureViews() {
        guard let baseHistoryViewModel = self.baseHistoryViewModel else { return }
        
        self.isAddingIncome = baseHistoryViewModel.isIncome
        
        if let _ = baseHistoryViewModel.id {
            self.isCreate = false
        }
        
        let backgroundColor = isAddingIncome ? UIColor(named: "incomeBackgroundColor") : UIColor(named: "expenseBackgroundColor")
        let textColor = isAddingIncome ? UIColor(named: "incomeTextColor") : UIColor(named: "expenseTextColor")
        
        segmentedControl.isHidden = isAddingIncome
        imageButton.isHidden = isAddingIncome
        memoButton.isHidden = isAddingIncome
        categoryCollectionView.isHidden = isAddingIncome
        
        // 상단 뷰 색상
        headerView.backgroundColor = backgroundColor
        
        // 기타 텍스트 색상
        if isAddingIncome {
            calculatorExpressionLabel.textColor = UIColor(named: "incomeTextColor")
            currencyCodeLabel.textColor = UIColor(named: "incomeTextColor")
            currencyConvertedAmountLabel.textColor = UIColor(named: "incomeTextColor")
        } else {
            calculatorExpressionLabel.textColor = UIColor(named: "expenseTextColor")
            currencyCodeLabel.textColor = UIColor(named: "expenseTextColor")
            currencyConvertedAmountLabel.textColor = UIColor(named: "expenseTextColor")
        }
        
        // 기록 타입
        historyTypeLabel.text = isAddingIncome ? "수입" : "지출"
        historyTypeLabel.textColor = .white
        
        // 국기 이미지
        flagImageView.image = UIImage(data: baseHistoryViewModel.flagImage)
        
        // 환율코드
        currencyCodeLabel.text = baseHistoryViewModel.currencyCode
        
        // 계산식 레이블, 계산된 금액 레이블, 환율을 적용하여 변환한 금액 레이블
        calculatedAmountLabel.textColor = .white
        if let previousAmount = baseHistoryViewModel.amount {
            self.amount = previousAmount
            calculatorExpressionLabel.text = previousAmount.convertToString()
            calculatedAmountLabel.text = previousAmount.convertToString()
            currencyConvertedAmountLabel.text = "KRW \((previousAmount / baseHistoryViewModel.exchangeRate).getCurrencyFormat(identifier: baseHistoryViewModel.countryIdentifier ?? ""))"
        } else {
            calculatorExpressionLabel.text = "0"
            calculatedAmountLabel.text = "0"
            currencyConvertedAmountLabel.text = "KRW"
        }
        
        // 카드/현금 여부
        if let previousIsCard = baseHistoryViewModel.isCard, previousIsCard {
            segmentedControl.selectedSegmentIndex = 1
        } else {
            segmentedControl.selectedSegmentIndex = 0
        }
        
        // 수입/지출 infromation view
        if isAddingIncome {
            categoryCollectionView.isHidden = true
            let currencyCode = baseHistoryViewModel.currencyCode
            var convertedString = (1 / baseHistoryViewModel.exchangeRate).getCurrencyFormat(identifier: "ko_KR")
            
            if let index = convertedString.range(of: ".")?.lowerBound {
                let substring = convertedString[..<index]
                convertedString = String(substring)
            }
            
            currencyInfoLabel.text = "\(currencyCode) 1.00 = KRW \(convertedString)"
        }
        
        // 카테고리 CollectionView
        if !isAddingIncome {
            incomeInfoView.isHidden = true
            categoryCollectionView.delegate = self
            categoryCollectionView.dataSource = self
            categoryCollectionView.register(UINib(nibName: CategoryCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: CategoryCollectionViewCell.identifier)
            category = baseHistoryViewModel.category ?? .etc
        }
        
        // 항목명
        let titleTap = UITapGestureRecognizer(target: self, action: #selector(titleLabelTapped))
        historyTitleLabel.addGestureRecognizer(titleTap)
        if let previousTitle = baseHistoryViewModel.title {
            historyTitleLabel.text = previousTitle
            historyTitleLabel.textColor = UIColor(named: "basicBlackTextColor") ?? .black
        } else {
            historyTitleLabel.text = historyTitlePlaceholder
            historyTitleLabel.textColor = .systemGray2
        }
        
        // 날짜
        datePicker.setDate(baseHistoryViewModel.currentDate, animated: true)
        
        // 이미지
        if let previousImage = baseHistoryViewModel.image {
            self.image = previousImage
            self.imageButton.tintColor = UIColor(named: "basicBlackTextColor") ?? .black
        }
        
        // 메모
        if let previousMemo = baseHistoryViewModel.memo {
            self.memo = previousMemo
            self.memoButton.tintColor = UIColor(named: "basicBlackTextColor") ?? .black
        }
        
        // 저장버튼 색상
        saveButton.backgroundColor = backgroundColor
        saveButton.setTitleColor(textColor, for: .normal)
        
        // 계산기 버튼 색상
        coloredButtons.forEach { button in
            button.setTitleColor(backgroundColor, for: .normal)
            button.tintColor = backgroundColor
        }
    }
    
    private func changeCalculatedAmountLabel() {
        guard let stringWithMathematicalOperation = calculatorExpressionLabel.text, isValidExpression(stringWithMathematicalOperation) else { return }
        
        let exp: NSExpression = NSExpression(format: stringWithMathematicalOperation)
        if let amount = exp.expressionValue(with: nil, context: nil) as? Double, let exchangeRate = baseHistoryViewModel?.exchangeRate {
            
            calculatedAmountLabel.text = "\(amount.insertComma)"
            
            let convertedAmount = amount / exchangeRate
            currencyConvertedAmountLabel.text = "KRW " + convertedAmount.getCurrencyFormat(identifier: baseHistoryViewModel?.countryIdentifier ?? "")
            
            self.amount = amount
        }
    }
    
    private func isValidExpression(_ exp: String) -> Bool {
        let operators = CharacterSet(charactersIn: "+_*/")
        let numbersOnly = exp.components(separatedBy: operators)
        
        for str in numbersOnly {
            let pieces = str.components(separatedBy: ".")
            if pieces.count > 2 {
                // print("invalid!")
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
                self.historyTitleLabel.text = newTitle.isEmpty ? HistoryCategory.income.name : newTitle
            } else {
                self.historyTitleLabel.text = newTitle.isEmpty ? HistoryCategory.etc.name : newTitle
            }
            
            self.historyTitleLabel.textColor = self.historyTitleLabel.text == self.historyTitlePlaceholder ? .systemGray2 : UIColor(named: "basicBlackTextColor") ?? .black
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard amount > 0, !amount.isNaN, !amount.isInfinite else {
            let title = amount.isNaN || amount.isInfinite ? "입력할 수 없는 금액입니다!" : "금액을 입력해주세요!"
            let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "확인", style: .default)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
        }
        
        var newHistoryData: NewHistoryData
        
        var defaultTitle: String
        if let titleLabelText = historyTitleLabel.text {
            defaultTitle = titleLabelText.isPlaceholder() ? category.name : titleLabelText
        } else {
            defaultTitle = category.name
        }
        
        if isAddingIncome {
            newHistoryData = NewHistoryData(isIncome: true,
                                            title: defaultTitle.isCategory() ? HistoryCategory.income.name : defaultTitle ,
                                            memo: memo,
                                            date: datePicker.date,
                                            image: nil,
                                            amount: amount,
                                            category: .income,
                                            isCard: nil)
        } else {
            
            newHistoryData = NewHistoryData(isIncome: false,
                                            title: defaultTitle.isCategory() ? category.name : defaultTitle,
                                            memo: memo,
                                            date: datePicker.date,
                                            image: image,
                                            amount: amount,
                                            category: category,
                                            isCard: segmentedControl.selectedSegmentIndex == 0 ? false : true, isPrepare: baseHistoryViewModel?.isPrepare)
        }
        
        if isCreate {
            delegate?.createHistory(newHistoryData: newHistoryData)
        } else {
            delegate?.updateHistory(at: baseHistoryViewModel?.id, newHistoryData: newHistoryData)
        }
        
        saveButtonHandler?()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addImageButtonTapped(_ sender: UIButton) {
        openPhotoLibrary()
    }
    
    private func openPhotoLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: false, completion: nil)
    }
    
    @IBAction func addMemoButtonTapped(_ sender: UIButton) {
        MemoEditViewController.present(at: self, memoType: .expenseMemo, previousMemo: memo) { [weak self] newMemo in
            let memoToast = Toast(text: "메모를 입력했습니다", duration: Delay.short)
            memoToast.show()
            
            if newMemo.isEmpty {
                self?.memo = nil
                self?.memoButton.tintColor = .lightGray
            } else {
                self?.memo = newMemo
                self?.memoButton.tintColor = UIColor(named: "basicBlackTextColor")
            }
        }
    }
}

extension AddHistoryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        if let newImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let imageToast = Toast(text: "사진을 추가했습니다", duration: Delay.short)
            imageToast.show()
            
            self.image = newImage.pngData()
            self.imageButton.tintColor = UIColor(named: "basicBlackTextColor")
        }
        
        dismiss(animated: true)
    }
    
}

// MARK: - Calculator IBActions

extension AddHistoryViewController {
    
    @IBAction func btnNumber(sender: UIButton) {
        guard let buttonText = sender.titleLabel?.text else { return }
        
        if buttonText == ".", let lastCharacter = calculatorExpressionLabel.text?.last, lastCharacter.isOperation() {
            calculatorExpressionLabel.text?.removeLast()
        }
        
        if calculatorExpressionLabel.text?.count == 1,
            let lastCharacter = calculatorExpressionLabel.text?.last,
            lastCharacter == "0" {
            calculatorExpressionLabel.text?.removeLast()
        }
        
        calculatorExpressionLabel.text! += buttonText
        
        if buttonText != "." {
            changeCalculatedAmountLabel()
        }
    }
    
    @IBAction func btnOperator(sender: UIButton) {
        if let lastCharacter = calculatorExpressionLabel.text?.last, lastCharacter.isOperation() {
            calculatorExpressionLabel.text?.removeLast()
        }
        
        guard let labelText = calculatorExpressionLabel.text,
              let buttonText = sender.titleLabel?.text else { return }
        calculatorExpressionLabel.text = labelText + buttonText
    }
    
    @IBAction func backTapped(_ sender: Any) {
        guard let length = calculatorExpressionLabel.text?.count, length > 0 else { return }
        calculatorExpressionLabel.text?.removeLast()
        
        if let lastCharacter = calculatorExpressionLabel.text?.last,
            !lastCharacter.isOperation() {
            changeCalculatedAmountLabel()
        } else if calculatorExpressionLabel.text?.count == 0 {
            initializeLabels()
        } else if calculatorExpressionLabel.text?.count == 1,
            let isOperation = calculatorExpressionLabel.text?.last?.isOperation(), isOperation {
            initializeLabels()
        }
    }
    
    private func initializeLabels() {
        calculatorExpressionLabel.text = "0"
        calculatedAmountLabel.text = "0"
        currencyConvertedAmountLabel.text = "KRW"
        changeCalculatedAmountLabel()
    }
    
}

extension AddHistoryViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = categoryCollectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionViewCell.identifier,
                                                                    for: indexPath) as? CategoryCollectionViewCell
            else {
                return UICollectionViewCell()
            }
        
        cell.configure(with: categories[indexPath.row], isSelected: categories[indexPath.row] == self.category)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        category = categories[indexPath.row]
        collectionView.reloadData()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.view.frame.width * 0.17
        return CGSize(width: width, height: width)
    }
    
}

extension AddHistoryViewController {
    
    static let nibName = "AddHistoryViewController"
    
    static func present(at viewController: UIViewController,
                        delegateTarget: UIViewController,
                        baseHistoryViewModel: BaseHistoryViewModel,
                        onPresent: (() -> Void)?,
                        onDismiss: (() -> Void)?) {
        
        let vc = AddHistoryViewController(nibName: nibName, bundle: nil)
        
        if let historyListVC = delegateTarget as? HistoryListViewController {
            vc.delegate = historyListVC
        }
        
        vc.saveButtonHandler = onDismiss
        vc.baseHistoryViewModel = baseHistoryViewModel
        viewController.present(vc, animated: true) {
            onPresent?()
        }
    }
    
}
