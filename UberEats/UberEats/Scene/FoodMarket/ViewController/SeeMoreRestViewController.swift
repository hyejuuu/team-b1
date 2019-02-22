//
//  SeeMoreRestViewController.swift
//  UberEats
//
//  Created by admin on 20/02/2019.
//  Copyright © 2019 team-b1. All rights reserved.
//

import UIKit
import Common
import Service
import ServiceInterface
import DependencyContainer

class SeeMoreRestViewController: UIViewController {

    private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var foods: [FoodForView]?

    private var stores: [StoreForView]?

    public var section: TableViewSection?

    private var foodMarketService: FoodMarketService = DependencyContainer.share.getDependency(key: .foodMarketService)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

        guard let collectionViewTag = section else {
            return
        }

        initFoodMarket(section: collectionViewTag)
        setupTableView()
    }

    private func setupTableView() {
        tableView.dataSource = self

        let SeeMoreRestTableViewCellNIB = UINib(nibName: "SeeMoreRestTableViewCell", bundle: nil)
        tableView.register(SeeMoreRestTableViewCellNIB, forCellReuseIdentifier: "SeeMoreRestTableViewCellId")
    }

    private func initFoodMarket(section: TableViewSection) {
        switch section {
        case .recommendFood:
            reloadTableViewFoodsData()
        case .expectedTime, .nearestRest, .newRest:
            reloadTableViewStoreData(section: section)
        default:
            break
        }
    }

    private func reloadTableViewFoodsData() {
        foodMarketService.requestFoodMarketMore(dispatchQueue: DispatchQueue.global()) { [weak self] (dataResponse) in
            guard dataResponse.isSuccess,
                let foods = dataResponse.value?.recommendFood else {
                return
            }

            self?.foods = foods
            self?.tableView.reloadData()
        }
    }

    private func reloadTableViewStoreData(section: TableViewSection) {
        foodMarketService.requestFoodMarketMore(dispatchQueue: DispatchQueue.global()) { [weak self] (dataResponse) in
            if dataResponse.isSuccess {
                switch section {
                case .expectedTime:
                    guard let expectTimeRest = dataResponse.value?.expectTimeRest else {
                        return
                    }
                    self?.stores = expectTimeRest
                case .nearestRest:
                    guard let nearestRest = dataResponse.value?.nearestRest else {
                        return
                    }
                    self?.stores = nearestRest
                case .newRest:
                    guard let newRest = dataResponse.value?.newRests else {
                        return
                    }
                    self?.stores = newRest
                default:
                    break
                }
            } else {
                fatalError()
            }
            self?.tableView.reloadData()
        }
    }

}

extension SeeMoreRestViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let foods = self.foods {
            return foods.count
        }

        if let stores = self.stores {
            return stores.count
        }

        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let moreRestTableViewCell = tableView.dequeueReusableCell(
            withIdentifier: "SeeMoreRestTableViewCellId",
            for: indexPath) as? SeeMoreRestTableViewCell else {
                return .init()
        }

        if let stores = self.stores {
            if stores.count > indexPath.row {
                moreRestTableViewCell.moreRests = stores[indexPath.row]

                guard let imageURL = URL(string: stores[indexPath.row].mainImage) else {
                    return moreRestTableViewCell
                }

                ImageNetworkManager.shared.getImageByCache(imageURL: imageURL) { [weak moreRestTableViewCell] (downloadImage, error) in
                    if error != nil {
                        return
                    }

                    guard moreRestTableViewCell?.moreRests?.mainImage == imageURL.absoluteString else {
                        return
                    }

                    moreRestTableViewCell?.mainImage.image = downloadImage
                }
            }
        }

        if let foods = self.foods {
            if foods.count > indexPath.row {
                moreRestTableViewCell.moreFoods = foods[indexPath.row]

                guard let imageURL = URL(string: foods[indexPath.row].foodImageURL) else {
                    return moreRestTableViewCell
                }

                ImageNetworkManager.shared.getImageByCache(imageURL: imageURL) { [weak moreRestTableViewCell] (downloadImage, error) in
                    if error != nil {
                        return
                    }

                    guard moreRestTableViewCell?.moreFoods?.foodImageURL == imageURL.absoluteString else {
                        return
                    }

                    moreRestTableViewCell?.mainImage.image = downloadImage
                }
            }
        }

        return moreRestTableViewCell
    }
}
