//
//  ZYVideoNavigationVC.swift
//  SelectVideoPhotoDemo
//
//  Created by 艺教星 on 2018/11/23.
//  Copyright © 2018 艺教星. All rights reserved.
//

import UIKit

class ZYVideoNavigationVC: UINavigationController {

    /// 最大选择张数
    public var maxSelectCount = 0 {
        didSet {
            self.photoAlbumVC.maxSelectCount = maxSelectCount
        }
    }
    
    /// 裁剪大小
    public var clipBounds: CGSize = CGSize(width: ZYScreenWidth, height: ZYScreenWidth) {
        didSet {
            self.photoAlbumVC.clipBounds = clipBounds
        }
    }
    
    private let photoAlbumVC = ZYPhotoAlbumViewController()
    
    private convenience init() {
        self.init(photoAlbumDelegate: nil)
    }
    
    /// 接入SDK照片列表构造方法
    ///
    /// - Parameters:
    ///   - photoAlbumDelegate: 代理回调方法
    ///   - photoAlbumType: 相册类型
    public init(photoAlbumDelegate: ZYPhotoAlbumProtocol?) {
        let photoAlbumListVC = ZYPhotoAlbumListViewController()
        photoAlbumListVC.photoAlbumDelegate = photoAlbumDelegate
        super.init(rootViewController: photoAlbumListVC)
        self.isNavigationBarHidden = true
        photoAlbumVC.photoAlbumDelegate = photoAlbumDelegate
        self.pushViewController(photoAlbumVC, animated: false)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if ZYPhotoAlbumEnableDebugOn {
            print("=====================\(self)未内存泄露")
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    class func zyGetSelectView() -> UIView {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        view.backgroundColor = ZYPhotoAlbumSkinColor
        view.image = UIImage.zyImageFromeBundle(named: "album_select_blue.png")
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.masksToBounds = true
        return view
    }
    
    class func zyGetSelectNuberView(index:String) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        view.backgroundColor = ZYPhotoAlbumSkinColor
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        
        let indexLabel = UILabel()
        indexLabel.frame = view.bounds
        indexLabel.layer.cornerRadius = 16
        indexLabel.layer.masksToBounds = true
        indexLabel.textColor = UIColor.white
        indexLabel.text = index
        indexLabel.textAlignment = .center
        indexLabel.font = UIFont.systemFont(ofSize: 20)
        
        view.addSubview(indexLabel)
        return view
    }

}
