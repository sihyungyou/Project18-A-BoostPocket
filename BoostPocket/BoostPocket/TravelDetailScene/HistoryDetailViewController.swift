//
//  HistoryDetailViewController.swift
//  BoostPocket
//
//  Created by 이승진 on 2020/12/03.
//  Copyright © 2020 BoostPocket. All rights reserved.
//

import UIKit

protocol HistoryDetailDelegate: AnyObject {
    func deleteHistory(id: UUID?)
    func updateHistory(at historyId: UUID?, updatedHistoryData: NewHistoryData)
}

class HistoryDetailViewController: UIViewController {
    
    static let identifier = "HistoryDetailViewController"
    weak var delegate: HistoryDetailDelegate?
    weak var historyItemViewModel: HistoryItemPresentable?
    private var baseHistoryViewModel: BaseHistoryViewModel?
    private weak var presentingVC: UIViewController?
    
    @IBOutlet weak var historyDateLabel: UILabel!
    @IBOutlet weak var categoryImageView: UIImageView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var exchangedMoneyLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    // Expense
    @IBOutlet weak var historyImageView: UIImageView!
    @IBOutlet weak var expenseMemoLabel: UILabel!
    @IBOutlet weak var isPrepareImageView: UIImageView!
    
    // Income
    @IBOutlet weak var currencyCodeLabel: UILabel!
    @IBOutlet weak var exchangeRateLabel: UILabel!
    @IBOutlet weak var incomeMemoLabel: UILabel!

    @IBOutlet weak var expanseStackView: UIStackView!
    @IBOutlet weak var incomeStackView: UIStackView!
    @IBOutlet weak var buttonStackView: UIStackView!
    
    private var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    private func configureViews() {
        imagePicker.delegate = self
        
        let titleTap = UITapGestureRecognizer(target: self, action: #selector(titleLabelTapped))
        let isPrepareTap = UITapGestureRecognizer(target: self, action: #selector(isPrepareTapped))
        let historyImageTap = UITapGestureRecognizer(target: self, action: #selector(historyImageTapped))
        
        titleLabel.addGestureRecognizer(titleTap)
        isPrepareImageView.addGestureRecognizer(isPrepareTap)
        historyImageView.addGestureRecognizer(historyImageTap)
        
        guard let history = baseHistoryViewModel else { return }
        configureContraints(history: history)
        configureAttributes(history: history)
    }
    
    private func configureContraints(history: BaseHistoryViewModel) {
        expanseStackView.translatesAutoresizingMaskIntoConstraints = false
        incomeStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let trueState = history.isIncome
        expanseStackView.isHidden = trueState
        incomeStackView.isHidden = !trueState
        buttonStackView.topAnchor.constraint(equalTo: expanseStackView.bottomAnchor, constant: 70).isActive = !trueState
        buttonStackView.topAnchor.constraint(equalTo: incomeStackView.bottomAnchor, constant: 70).isActive = trueState
    }
    
    private func configureAttributes(history: BaseHistoryViewModel) {
        // 공통
        historyDateLabel.text = history.currentDate.convertToString(format: .fullKoreanDated)
        if let category = history.category, let title = history.title, let amount = history.amount, let identifier = history.countryIdentifier {
            amountLabel.text = "\(identifier.currencySymbol) \(amount.getCurrencyFormat(identifier: identifier))"
            exchangedMoneyLabel.text = "KRW \((amount / history.exchangeRate).getCurrencyFormat(identifier: identifier))"
            categoryImageView.image = UIImage(named: category.imageName)
            titleLabel.text = title.isEmpty ? category.name : title
        }
        
        if history.isIncome {
            // 수입
            amountLabel.textColor = UIColor(named: "incomeColor")
            currencyCodeLabel.text = history.currencyCode
            let exchangedKoreanCurrency = 1.00 / history.exchangeRate
            exchangeRateLabel.text = "\(history.currencyCode) 1.00 = KRW \(exchangedKoreanCurrency.getCurrencyFormat(identifier: "ko_KR"))"
            if let memo = history.memo {
                incomeMemoLabel.text = memo
            }
        } else {
            // 지출
            amountLabel.textColor = UIColor(named: "deleteButtonColor")
            if let previousImage = history.image {
                historyImageView.image = UIImage(data: previousImage)
            }
            
            if let previousMemo = history.memo {
                expenseMemoLabel.text = previousMemo
            }
            
            if let isPrepare = history.isPrepare {
                if isPrepare {
                    isPrepareImageView.image = UIImage(named: "isPrepareTrue")
                } else {
                    isPrepareImageView.image = UIImage(named: "isPrepareFalse")
                }
            }
        }
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        delegate?.deleteHistory(id: baseHistoryViewModel?.id)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        guard let baseHistoryViewModel = self.baseHistoryViewModel else { return }

        let onDismiss: (() -> Void)? = { [weak self] in
            guard let self = self,
                let historyItemViewModel = self.historyItemViewModel,
                let countryIdentifier = baseHistoryViewModel.countryIdentifier
                else { return }
            
            // date
            self.baseHistoryViewModel?.currentDate = historyItemViewModel.date
            self.historyDateLabel.text = historyItemViewModel.date.convertToString(format: .fullKoreanDated)
            
            // amount
            self.baseHistoryViewModel?.amount = historyItemViewModel.amount
            self.amountLabel.text = "\(countryIdentifier.currencySymbol) \(historyItemViewModel.amount.getCurrencyFormat(identifier: countryIdentifier))"
            
            // currency converted amount
            self.exchangedMoneyLabel.text = "KRW \((historyItemViewModel.amount / baseHistoryViewModel.exchangeRate).getCurrencyFormat(identifier: countryIdentifier))"
            
            // category도 해줘야 함
            
            // title
            self.baseHistoryViewModel?.title = self.historyItemViewModel?.title
            self.titleLabel.text = self.historyItemViewModel?.title
            
            // image
            self.baseHistoryViewModel?.image = historyItemViewModel.image
            if let image = historyItemViewModel.image {
                self.historyImageView.image = UIImage(data: image)
            }
            
            // memo
            self.baseHistoryViewModel?.memo = historyItemViewModel.memo
            if historyItemViewModel.isIncome {
                self.incomeMemoLabel.text = historyItemViewModel.memo
            } else {
                self.expenseMemoLabel.text = historyItemViewModel.memo
            }
        }
        
        AddHistoryViewController.present(at: self,
                                         delegateTarget: self.presentingVC ?? UIViewController(),
                                         baseHistoryViewModel: baseHistoryViewModel,
                                         onPresent: nil,
                                         onDismiss: onDismiss)
    }
    
    @objc func titleLabelTapped() {
        let previousTitle = titleLabel.text
        
        TitleEditViewController.present(at: self, previousTitle: previousTitle ?? "") { [weak self] (newTitle) in
            guard let self = self else { return }
            let updatingTitle = newTitle.isEmpty ? previousTitle : newTitle
            self.titleLabel.text = updatingTitle
            self.baseHistoryViewModel?.title = updatingTitle
            self.updateHistory()
        }
    }
    
    private func updateHistory() {
        guard let history = self.baseHistoryViewModel else { return }
        let updatedHistory = NewHistoryData(isIncome: history.isIncome, title: history.title ?? "", memo: history.memo, date: history.currentDate, image: history.image, amount: history.amount ?? 0, category: history.category ?? (history.isIncome ? .income : .etc), isCard: history.isCard, isPrepare: history.isPrepare)
        delegate?.updateHistory(at: history.id, updatedHistoryData: updatedHistory)
    }
    
    @objc func historyImageTapped() {
        openPhotoLibrary()
    }
    
    @objc func isPrepareTapped() {
        
        guard let history = baseHistoryViewModel, let isPrepare = history.isPrepare else { return }
    
        if isPrepare {
            isPrepareImageView.image = UIImage(named: "isPrepareTrue")
        } else {
            isPrepareImageView.image = UIImage(named: "isPrepareFalse")
        }
        
        baseHistoryViewModel?.isPrepare = !isPrepare
        // TO-DO : 값 업데이트
    }
    
    
    
    private func openPhotoLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: false, completion: nil)
    }
}

extension HistoryDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        if let newImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            historyImageView.image = newImage
            
            // TO-DO : update
        }
        dismiss(animated: true, completion: nil)
    }
}

extension HistoryDetailViewController {
    
    static let storyboardName = "TravelDetail"
    
    static func present(at viewController: UIViewController,
                        baseHistoryViewModel: BaseHistoryViewModel,
                        historyItemViewModel: HistoryItemPresentable) {
        
        let storyBoard = UIStoryboard(name: storyboardName, bundle: Bundle.main)
        
        guard let vc = storyBoard.instantiateViewController(withIdentifier: HistoryDetailViewController.identifier) as? HistoryDetailViewController else { return }
        
        if let historyListViewController = viewController as? HistoryListViewController {
            vc.presentingVC = historyListViewController
            vc.delegate = historyListViewController
        }
        
        vc.historyItemViewModel = historyItemViewModel
        vc.baseHistoryViewModel = baseHistoryViewModel
        viewController.present(vc, animated: true, completion: nil)
    }
    
}
