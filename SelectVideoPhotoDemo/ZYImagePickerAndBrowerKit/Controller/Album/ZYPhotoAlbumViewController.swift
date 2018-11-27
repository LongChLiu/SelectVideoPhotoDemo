//
//  WQPhotoAlbumViewController.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit
import Photos


class ZYPhotoAlbumViewController: ZYBaseViewController, PHPhotoLibraryChangeObserver, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var assetsFetchResult: PHFetchResult<PHAsset>?
    
    var maxSelectCount = 0
    
    var selectStyle:SelectStyle = .number
    
    var type: ZYPhotoAlbumType = .selectPhoto
    
    // 剪裁大小
    var clipBounds: CGSize = CGSize(width: ZYScreenWidth, height: ZYScreenWidth)
    
    weak var photoAlbumDelegate: ZYPhotoAlbumProtocol?
    
    private let cellIdentifier = "PhotoCollectionCell"
    private lazy var photoCollectionView: UICollectionView = {
        // 竖屏时每行显示4张图片
        let shape: CGFloat = 5
        let cellWidth: CGFloat = (ZYScreenWidth - 5 * shape) / 4
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: ZYNavigationTotalHeight, left: shape, bottom: self.type == .selectPhoto ? 44+ZYHomeBarHeight:0, right: shape)
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        flowLayout.minimumLineSpacing = shape
        flowLayout.minimumInteritemSpacing = shape
        //  collectionView
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: ZYScreenWidth, height: ZYScreenHeight-44*2-20), collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.white
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: ZYNavigationTotalHeight, left: 0, bottom: 44+ZYHomeBarHeight, right: 0)
        //  添加协议方法
        collectionView.delegate = self
        collectionView.dataSource = self
        //  设置 cell
        collectionView.register(ZYPhotoCollectionViewCell.self, forCellWithReuseIdentifier: self.cellIdentifier)
        return collectionView
    }()
    
    private lazy var loadingView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: ZYNavigationTotalHeight, width: ZYScreenWidth, height: ZYScreenHeight-ZYNavigationTotalHeight))
        view.backgroundColor = UIColor.clear
        let loadingBackView = UIImageView(frame: CGRect(x: view.frame.width/2-54, y: view.frame.height/2-32-54, width: 108, height: 108))
        loadingBackView.image = UIImage.zyCreateImageWithColor(color: UIColor(white: 0, alpha: 0.8), size: CGSize(width: 108, height: 108))?.zySetRoundedCorner(radius: 6)
        view.addSubview(loadingBackView)
        let loading = UIActivityIndicatorView(style: .whiteLarge)
        loading.center = CGPoint(x: 54, y: 54)
        loading.startAnimating()
        loadingBackView.addSubview(loading)
        return view
    }()
    
    //  数据源
    private var photoData = ZYPhotoDataSource()
    
    deinit {
        if ZYPhotoAlbumEnableDebugOn {
            print("=====================\(self)未内存泄露")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            self.photoCollectionView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        self.view.addSubview(self.photoCollectionView)
        //self.initNavigation()
        if type == .selectPhoto {
            self.rightClicked = { [unowned self] in
                self.selectSuccess(fromeView: self.view, selectAssetArray: self.photoData.seletedAssetArray)
            }
        }
        self.getAllPhotos()
    }
    
    var rightClicked: (()->Void)?
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.photoData.dataChanged {
            self.photoCollectionView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.photoData.dataChanged = false
    }
    
    //  MARK:- private method
    private func initNavigation() {
        self.setNavTitle(title: "所有图片")
        self.setBackNav()
        self.setRightTextButton(text: "取消", color: UIColor.white)
        self.view.bringSubviewToFront(self.naviView)
    }
    
    private func getAllPhotos() {
        //  注意点！！-这里必须注册通知，不然第一次运行程序时获取不到图片，以后运行会正常显示。体验方式：每次运行项目时修改一下 Bundle Identifier，就可以看到效果。
        PHPhotoLibrary.shared().register(self)
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .restricted || status == .denied {
            // 无权限 // do something...
            if ZYPhotoAlbumEnableDebugOn {
                print("无相册访问权限")
            }
            let alert = UIAlertController(title: nil, message: "请打开相册访问权限", preferredStyle: .alert)
            let cancleAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alert.addAction(cancleAction)
            let goAction = UIAlertAction(title: "设置", style: .default, handler: { (action) in
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                }
            })
            alert.addAction(goAction)
            self.present(alert, animated: true, completion: nil)
            return;
        }
        DispatchQueue.global(qos: .userInteractive).async {
            //  获取所有系统图片信息集合体
            let allOptions = PHFetchOptions()
            //  对内部元素排序，按照时间由远到近排序
            allOptions.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
            //  将元素集合拆解开，此时 allResults 内部是一个个的PHAsset单元
            let fetchAssets = self.assetsFetchResult ?? PHAsset.fetchAssets(with: .image, options: allOptions);            
            self.photoData.assetArray = fetchAssets.objects(at: IndexSet.init(integersIn: 0..<fetchAssets.count))
            if self.photoData.divideArray.count == 0 {
                self.photoData.divideArray = Array(repeating: false, count: self.photoData.assetArray.count)
                self.photoData.dataChanged = false
            }
            DispatchQueue.main.async {
                self.photoCollectionView.reloadData()
            }
        }
    }
    
    private func showLoadingView(inView: UIView) {
        inView.addSubview(loadingView)
    }
    private func hideLoadingView() {
        loadingView.removeFromSuperview()
    }
    
    private func getThumbnailSize(originSize: CGSize) -> CGSize {
        let thumbnailWidth: CGFloat = (ZYScreenWidth - 5 * 5) / 4 * UIScreen.main.scale
        let pixelScale = CGFloat(originSize.width)/CGFloat(originSize.height)
        let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailWidth/pixelScale)
        return thumbnailSize
    }
    
    private func selectPhotoCell(cell: ZYPhotoCollectionViewCell, index: Int) {
        photoData.divideArray[index] = !photoData.divideArray[index]
        let asset = photoData.assetArray[index]
        if photoData.divideArray[index] {
            if maxSelectCount != 0, photoData.seletedAssetArray.count >= maxSelectCount {
                //超过最大数
                cell.isChoose = false
                photoData.divideArray[index] = !photoData.divideArray[index]
                let alert = UIAlertController(title: nil, message: "您最多只能选择\(maxSelectCount)张照片", preferredStyle: .alert)
                let action = UIAlertAction(title: "我知道了", style: .cancel, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
                photoCollectionView.reloadData()
                return
            }
            photoData.seletedAssetArray.append(asset)
        } else {
            if let removeIndex = photoData.seletedAssetArray.index(of: asset) {
                photoData.seletedAssetArray.remove(at: removeIndex)
            }
        }
        photoCollectionView.reloadData()
    }
    
    private func selectSuccess(fromeView: UIView, selectAssetArray: [PHAsset]) {
        self.showLoadingView(inView: fromeView)
        var selectPhotos: [ZYPhotoModel] = Array(repeating: ZYPhotoModel(), count: selectAssetArray.count)
        let group = DispatchGroup()
        for i in 0 ..< selectAssetArray.count {
            let asset = selectAssetArray[i]
            group.enter()
            let photoModel = ZYPhotoModel()
            _ = ZYCachingImageManager.default().requestThumbnailImage(for: asset, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                photoModel.thumbnailImage = image
            })
            _ = ZYCachingImageManager.default().requestPreviewImage(for: asset, progressHandler: nil, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
                var downloadFinined = true
                if let cancelled = dictionry![PHImageCancelledKey] as? Bool {
                    downloadFinined = !cancelled
                }
                if downloadFinined, let error = dictionry![PHImageErrorKey] as? Bool {
                    downloadFinined = !error
                }
                if downloadFinined, let resultIsDegraded = dictionry![PHImageResultIsDegradedKey] as? Bool {
                    downloadFinined = !resultIsDegraded
                }
                if downloadFinined, let photoImage = image {
                    photoModel.originImage = photoImage
                    selectPhotos[i] = photoModel
                    group.leave()
                }
            })
        }
        group.notify(queue: DispatchQueue.main, execute: {
            self.hideLoadingView()
            if self.photoAlbumDelegate != nil {
                if self.photoAlbumDelegate!.responds(to: #selector(ZYPhotoAlbumProtocol.photoAlbum(selectPhotoAssets:))){
                    self.photoAlbumDelegate?.photoAlbum!(selectPhotoAssets: selectAssetArray)
                }
                if self.photoAlbumDelegate!.responds(to: #selector(ZYPhotoAlbumProtocol.photoAlbum(selectPhotos:))) {
                    self.photoAlbumDelegate?.photoAlbum!(selectPhotos: selectPhotos)
                }
            }
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    override func rightButtonClick(button: UIButton) {
        self.navigationController?.dismiss(animated: true)
    }
    
    // MARK:- delegate
    //  PHPhotoLibraryChangeObserver  第一次获取相册信息，这个方法只会进入一次
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard self.photoData.assetArray.count == 0 else {return}
        DispatchQueue.main.async {
            self.getAllPhotos()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoData.assetArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? ZYPhotoCollectionViewCell, self.photoData.assetArray.count > indexPath.row else {return ZYPhotoCollectionViewCell()}
        let asset = self.photoData.assetArray[indexPath.row]
        
        cell.selectButton.isHidden = false;
        
        // 新建一个默认类型的图像管理器imageManager
        let imageManager = PHImageManager.default()
        // 新建一个PHImageRequestOptions对象
        let imageRequestOption = PHImageRequestOptions()
        // PHImageRequestOptions是否有效
        imageRequestOption.isSynchronous = true
        // 缩略图的压缩模式设置为无
        imageRequestOption.resizeMode = .none
        // 缩略图的质量为快速
        imageRequestOption.deliveryMode = .fastFormat
        // 按照PHImageRequestOptions指定的规则取出图片
        imageManager.requestImage(for: asset, targetSize: CGSize.init(width: 140, height: 140), contentMode: .aspectFill, options: imageRequestOption, resultHandler: {
            (result, _) -> Void in
            cell.photoImage = result!
        })
        
        if type == .selectPhoto {
            
            if selectStyle == .number {
                if let Index = photoData.seletedAssetArray.index(of: asset) {
                    cell.layer.mask = nil
                    cell.selectNumber = Index
                    //cell.selectButton.asyncSetImage(UIImage.zyCreateImageWithView(view: ZYPhotoNavigationViewController.zyGetSelectNuberView(index: "\(Index + 1)")), for: .selected)
                    cell.selectButton.setImage(UIImage.zyCreateImageWithView(view: ZYPhotoNavigationViewController.zyGetSelectNuberView(index: "\(Index + 1)")), for: .selected)
                    
                    //cell.selectButton.asyncSetImage(UIImage.zyCreateImageWithView(view: ZYPhotoNavigationViewController.zyGetSelectNuberView(index: "\(Index + 1)")), for: .selected)
                    
                }else{
                    cell.selectButton.isSelected = false
                    if maxSelectCount != 0, photoData.seletedAssetArray.count >= maxSelectCount{
                        let maskLayer = CALayer()
                        maskLayer.frame = cell.bounds
                        maskLayer.backgroundColor = UIColor.init(white: 1, alpha: 0.5).cgColor
                        cell.layer.mask = maskLayer
                    }else{
                        cell.layer.mask = nil
                    }
                }
            }else{
                cell.isChoose = self.photoData.divideArray[indexPath.row]
            }
            
            cell.selectPhotoCompleted = { [weak self] in
                guard let strongSelf = self else {return}
                strongSelf.selectPhotoCell(cell: cell, index: indexPath.row)
            }
            
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.type == .selectPhoto {
            //应该是点击放大的操作
            
        }
    }
    
    
}


