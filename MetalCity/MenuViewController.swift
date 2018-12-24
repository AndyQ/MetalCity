//
//  MenuViewController.swift
//  MetalCity
//
//  Created by Andy Qua on 23/12/2018.
//  Copyright © 2018 Andy Qua. All rights reserved.
//

import UIKit

enum MenuItem {
    case toggleAutocam
    case nextAutocamMode
    case rebuildCity
    case regenerateTextures
}

class MenuViewController: UIViewController {

    @IBOutlet weak var tableView : UITableView!
    var menuItems = ["Toggle autocam", "Next autocam mode", "Rebuild city", "Regenerate textures"]
    
    var menuSelected : ((MenuItem )->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.view.layer.cornerRadius = 10
        self.tableView.layer.cornerRadius = 10
    }
}

extension MenuViewController : UITableViewDataSource {

    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MenuCell
        
        cell.menuLabel.text = menuItems[indexPath.row]
        
        return cell
    }
}

extension MenuViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            menuSelected?(.toggleAutocam)
        case 1:
            menuSelected?(.nextAutocamMode)
        case 2:
            menuSelected?(.rebuildCity)
        case 3:
            menuSelected?(.regenerateTextures)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: false)

    }
    

}
