//
//  ViewController.swift
//  SelectVideoPhotoDemo
//
//  Created by 艺教星 on 2018/11/23.
//  Copyright © 2018 艺教星. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        
        
    }

    @IBAction func selectVideoPhotoAction(_ sender: UIButton) {        
        let vc = SelectVideoPhotoVC()
        self.present(vc, animated: true, completion: nil)
    }
    
}

