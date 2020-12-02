//
//  HistoryListViewController.swift
//  BoostPocket
//
//  Created by 송주 on 2020/12/02.
//  Copyright © 2020 BoostPocket. All rights reserved.
//

struct DummyHistory: Hashable {
    var category: HistoryCategory
    var title: String
    var amount: Double
    var date: Date
}

struct HistoryListSectionHeader: Hashable {
    var dayNumber: Int?
    var date: Date
    var amount: Double
}

import UIKit

class HistoryListViewController: UIViewController {
    typealias DataSource = UITableViewDiffableDataSource<HistoryListSectionHeader, DummyHistory>
    typealias Snapshot = NSDiffableDataSourceSnapshot<HistoryListSectionHeader, DummyHistory>
    
    @IBOutlet weak var historyListTableView: UITableView!
    private let dummyVM = [
        DummyHistory(category: .income, title: "수입", amount: 100000, date: Date()),
        DummyHistory(category: .food, title: "마라탕", amount: 18000, date: Date()),
        DummyHistory(category: .accommodation, title: "qweqwe", amount: 2000, date:  Date()),
        DummyHistory(category: .food, title: "파스타", amount: 12000, date: Date()),
        DummyHistory(category: .food, title: "김치찌개", amount: 10000, date: Date())
    ]
    private lazy var dataSource = configureDatasource()
    private lazy var headers = setupSection(with: dummyVM)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        historyListTableView.delegate = self
        historyListTableView.register(HistoryCell.getNib(), forCellReuseIdentifier: HistoryCell.identifier)
        historyListTableView.register(HistoryHeaderCell.getNib(), forHeaderFooterViewReuseIdentifier: HistoryHeaderCell.identifier)
        applySnapshot(with: dummyVM)
    }
    
    private func configureDatasource() -> DataSource {
        let datasource = DataSource(tableView: historyListTableView) { (tableview, indexPath, item) -> UITableViewCell? in
            guard let cell = tableview.dequeueReusableCell(withIdentifier: HistoryCell.identifier, for: indexPath) as? HistoryCell else { return UITableViewCell() }
            cell.configure(with: item)
            
            return cell
        }
        return datasource
    }
    
    private func applySnapshot(with histories: [DummyHistory]) {
        var snapshot = Snapshot()
        let sections = self.setupSection(with: histories)
        snapshot.appendSections(sections)
        histories.forEach { history in
            if let section = sections.filter({ Calendar.current.isDate(history.date, inSameDayAs: $0.date) }).first {
                snapshot.appendItems([history], toSection: section)
            }
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func setupSection(with histories: [DummyHistory]) -> [HistoryListSectionHeader] {
        var dayNumber = 1
        var days = Set<HistoryListSectionHeader>()
        histories.forEach { history in
            let amount = history.amount
            let date = history.date
            // TODO: daynumber는 현재 날짜 - travelItemViewModel의 시작 날짜 + 1, 만약 음수면 prepare로 들어감
            if var day = days.filter({ Calendar.current.isDate(date, inSameDayAs: $0.date) }).first {
                day.amount += amount
            } else {
                days.insert(HistoryListSectionHeader(dayNumber: dayNumber, date: date, amount: amount))
                dayNumber += 1
            }
        }
        var sections = [HistoryListSectionHeader](days)
        sections = sections.sorted(by: {$0.date < $1.date})
        return sections
    }
}

extension HistoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.bounds.height * 0.1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: HistoryHeaderCell.identifier) as? HistoryHeaderCell else { return UIView() }
        headerView.configure(with: headers[section].dayNumber, date: headers[section].date, amount: headers[section].amount)
        return headerView
    }
}
