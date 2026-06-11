//
//  HomeScreenViewController+TableView.swift
//  letsApply
//
//  Created by Reuben Simphiwe Kuse on 2025/01/12.
//

//import Foundation
//import UIKit
//
//extension HomeViewController {
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if indexPath.section == 0 {
//            return 219
//        } else {
//            return 116
//        }
//    }
//    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return starBucksDatabase.categoriesArray.count
//        
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//
//        
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//        // Comment: Practice Switch Statements
//        switch indexPath.section {
//        case 0:
//            let featuredProductCell = tableView.dequeueReusableCell(withIdentifier: "FeaturedJobsTableViewCellID", for: indexPath) as! FeaturedProductsTableViewCell
//            featuredProductCell.featuredProductsArray = starBucksDatabase.sortedFeaturedProducts()
//            return featuredProductCell
//        case 1:
//            let productCell = tableView.dequeueReusableCell(withIdentifier: "VacanciesTableViewCellID", for: indexPath) as! ProductTableViewCell
//            let product = starBucksDatabase.pickedForYouArray[indexPath.row]
//            productCell.productImageView.image = product.image
//            productCell.productNameLabel.text = product.name
//            productCell.priceLabel.text = "R\(product.price)"
//            productCell.menuDescriptionLabel.text = product.description
//            return productCell
//        default:
//            let productCell = tableView.dequeueReusableCell(withIdentifier: "VacanciesTableViewCellID", for: indexPath) as! ProductTableViewCell
//            let product = starBucksDatabase.bakeryArray[indexPath.row]
//            productCell.productImageView.image = product.image
//            productCell.productNameLabel.text = product.name
//            productCell.priceLabel.text = "R\(product.price)"
//            productCell.menuDescriptionLabel.text = product.description
//            return productCell
//        }
//        
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        var product: Product
//        switch indexPath.section {
//        case 0:
//            return
//        case 1:
//            product = starBucksDatabase.pickedForYouArray[indexPath.row]
//        default:
//            product = starBucksDatabase.bakeryArray[indexPath.row]
//        }
//        let productViewController = ProductViewController(product: product)
//        productViewController.hidesBottomBarWhenPushed = true
////        productViewController.productName = product.name
////        productViewController.productPrice = product.price
//        navigationController?.pushViewController(productViewController, animated: true)
//    }
//
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let headerView = TableSectionHeaderView()
//        
//        // Comment: Adds the tappability of the seeAllButton
//        headerView.seeAllButton.addTarget(self,
//                                          action: #selector(seeAllButtonTapped),
//                                          for: .touchUpInside)
//        headerView.seeAllButton.tag = section
//        headerView.title = starBucksDatabase.categoriesArray[section]
//
//        
//        return headerView
//    }
//    
//    @objc func seeAllButtonTapped(sender: UIButton) {
//       
//        var productsToShow: [Product] = []
//        
//        // Use the categories array + sender.tag to access the titles.
//        let categoryTitle = starBucksDatabase.categoriesArray[sender.tag]
//        
//        // Practice More of Switch Statements.
//        switch sender.tag {
//        case 0:
//            productsToShow = starBucksDatabase.sortedFeaturedProducts()
//        case 1:
//            productsToShow = starBucksDatabase.pickedForYouArray
//        case 2:
//            productsToShow = starBucksDatabase.bakeryArray
//        default:
//            break
//        }
//    
//        let productsViewController = ProductsViewController(products: productsToShow,
//                                                            title: categoryTitle)
//        productsViewController.hidesBottomBarWhenPushed = true
//        navigationController?.pushViewController(productsViewController, animated: true)
//    }
//
//}
//
//
