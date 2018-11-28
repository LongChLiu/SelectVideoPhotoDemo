//
//  WQPhotoAlbumViewController.swift
//  ZYImagePickerAndBrower
//
//  Created by Nvr on 2018/8/17.
//  Copyright © 2018年 ZY. All rights reserved.
//

import UIKit
import Photos

enum SelectStyle:Int{
    case check
    case number
}

class ZYVideoAlbumViewController: ZYBaseViewController, PHPhotoLibraryChangeObserver, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var assetsFetchResult: PHFetchResult<PHAsset>?
    var maxSelectCount = 0
    var selectStyle:SelectStyle = .number
    // 剪裁大小
    var clipBounds: CGSize = CGSize(width: ZYScreenWidth, height: ZYScreenWidth)
    
    weak var photoAlbumDelegate: ZYPhotoAlbumProtocol?
    
    private let cellIdentifier = "PhotoCollectionCell"
    private lazy var photoCollectionView: UICollectionView = {
        // 竖屏时每行显示4张图片
        let shape: CGFloat = 5
        let cellWidth: CGFloat = (ZYScreenWidth - 5 * shape) / 4
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: ZYNavigationTotalHeight, left: shape, bottom: 44+ZYHomeBarHeight, right: shape)
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        flowLayout.minimumLineSpacing = shape
        flowLayout.minimumInteritemSpacing = shape
        //  collectionView
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: ZYScreenWidth, height: ZYScreenHeight-64), collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.white
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: ZYNavigationTotalHeight, left: 0, bottom: 44+ZYHomeBarHeight, right: 0)
        // 添加协议方法 //
        collectionView.delegate = self
        collectionView.dataSource = self
        //  设置 cell
        collectionView.register(ZYPhotoCollectionViewCell.self, forCellWithReuseIdentifier: self.cellIdentifier)
        return collectionView
    }()
    
    //var bottomView = ZYAlbumBottomView()
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
        if ZYPhotoAlbumEnableDebugOn{
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
        self.rightClicked = { [unowned self] in
            self.selectSuccess(fromView: self.view, selectAssetArray: self.photoData.seletedAssetArray)
        }
        self.getAllPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarStyle(.lightContent, animated: true)
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
        self.setNavTitle(title: "所有视频")
        self.setBackNav()
        self.setRightTextButton(text: "取消", color: UIColor.white)
        self.view.bringSubviewToFront(self.naviView)
    }
    
    // 完成闭包
    var rightClicked: (() -> Void)?
    
    private func getAllPhotos() {
        //  注意点！！-这里必须注册通知，不然第一次运行程序时获取不到图片，以后运行会正常显示。体验方式：每次运行项目时修改一下 Bundle Identifier，就可以看到效果。
        PHPhotoLibrary.shared().register(self)
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .restricted || status == .denied {
            // 无权限
            // do something...
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
            //let fetchAssets = self.assetsFetchResult ?? PHAsset.fetchAssets(with: allOptions)
            let fetchAssets = self.assetsFetchResult ?? PHAsset.fetchAssets(with: PHAssetMediaType.video, options: allOptions)
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
    
    private func selectSuccess(fromView: UIView, selectAssetArray: [PHAsset]) {
        self.showLoadingView(inView: fromView)
        var selectPhotos: [ZYPhotoModel] = Array(repeating: ZYPhotoModel(), count: selectAssetArray.count)
        let group = DispatchGroup()
        
        /*得到选中视频的URL*/
        for i in 0 ..< selectAssetArray.count {
            let asset = selectAssetArray[i]
            group.enter()
            let options = PHVideoRequestOptions.init()
            options.version = PHVideoRequestOptionsVersion.current
            options.deliveryMode = PHVideoRequestOptionsDeliveryMode.automatic
            let manager = PHImageManager.default()
            var urlUse : URL!
            manager.requestAVAsset(forVideo: asset, options: options) { (asset:AVAsset?, audioMix:AVAudioMix?,info:[AnyHashable:Any]?) in
                let urlAsset : AVURLAsset = asset as! AVURLAsset;
                let url = urlAsset.url;
                urlUse = url;
                //let data = NSData.init(contentsOf: url);
                print("选中视频的url: \(String(describing: urlUse))")
                group.leave()
            }
        }
        /*得到选中视频的图片*/
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
        
        /*任务都完成之后，得到通知*/
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
        
        cell.timeLabel.isHidden = false
        let assetTime = asset.duration;print("视频时长: \(assetTime)");
        if let assetSecond = assetTime/60 as Double?,assetSecond >= 60 {
            if let assetThird = assetSecond/60 as Double?,assetThird  >= 60{
                let hourStr = String.init(format: "%02ld", Int(assetThird));
                let minites = String.init(format: "%02ld", Int(assetSecond.truncatingRemainder(dividingBy: 60)));
                let seconds = String.init(format: "%02ld", Int(assetThird.truncatingRemainder(dividingBy: 3600)));
                cell.timeLabel.text = "\(hourStr):\(minites):\(seconds)"
            }else{//不足小时
                let minites = String.init(format: "%02ld", Int(assetSecond));//分钟
                let seconds = String.init(format: "%02ld", Int(assetTime.truncatingRemainder(dividingBy: 60)));//秒
                cell.timeLabel.text = "\(minites):\(seconds)"
            }
        }else{//不足一分钟，展示秒 00：58
            let seconds = String.init(format: "%02ld", Int(assetTime));
            cell.timeLabel.text = "00:\(seconds)"
        }
        
        
        
        if selectStyle == .number {
            if let Index = photoData.seletedAssetArray.index(of: asset) {
                cell.layer.mask = nil
                cell.selectNumber = Index
                //cell.selectButton.asyncSetImage(UIImage.zyCreateImageWithView(view: ZYVideoNavigationViewController.zyGetSelectNuberView(index: "\(Index + 1)")), for: .selected)
                cell.selectButton.setImage(UIImage.zyCreateImageWithView(view: ZYVideoNavigationViewController.zyGetSelectNuberView(index: "\(Index + 1)")), for: .selected)
            }else{
                cell.selectButton.isSelected = false
                if maxSelectCount != 0, photoData.seletedAssetArray.count >= maxSelectCount
                {
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
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let phAsset : PHAsset = self.photoData.assetArray[indexPath.item];
        
        self.showLoadingView(inView: self.view)
        var selectPhotos: [ZYPhotoModel] = Array(repeating: ZYPhotoModel(), count: 1)
        let group = DispatchGroup()
        /*得到选中视频的图片*/
        group.enter()
        let photoModel = ZYPhotoModel()
        _ = ZYCachingImageManager.default().requestThumbnailImage(for: phAsset, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
            photoModel.thumbnailImage = image
        })
        _ = ZYCachingImageManager.default().requestPreviewImage(for: phAsset, progressHandler: nil, resultHandler: { (image: UIImage?, dictionry: Dictionary?) in
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
                selectPhotos[0] = photoModel
                group.leave()
            }
        })
        
        group.enter()
        let options = PHVideoRequestOptions.init()
        options.version = PHVideoRequestOptionsVersion.current
        options.deliveryMode = PHVideoRequestOptionsDeliveryMode.automatic
        let manager = PHImageManager.default()
        var urlUse : URL!
        manager.requestAVAsset(forVideo: phAsset, options: options) { (asset:AVAsset?, audioMix:AVAudioMix?,info:[AnyHashable:Any]?) in
            
            let urlAsset : AVURLAsset = asset as! AVURLAsset;
            let url = urlAsset.url;urlUse = url;
            //let data = NSData.init(contentsOf: url);
            print("选中视频的url: \(String(describing: urlUse))");
            /*————————————————————进行视频的播放——————————————————*/
            DispatchQueue.main.async(execute: {
                let window = UIApplication.shared.delegate?.window
                let cell  = collectionView.cellForItem(at: indexPath)
                let frameRelativeToWindow = collectionView.convert(cell!.frame, to: window as! UIView)
                let videoPlayView = VideoPlayView.init(frame: frameRelativeToWindow)
                (window as! UIView).addSubview(videoPlayView)
                videoPlayView.makeViewToPlay(url: urlUse)
                videoPlayView.backgroundColor = UIColor.init(white: 0, alpha: 0)
                
                UIView.animate(withDuration: 0.25, animations: {
                    videoPlayView.frame = CGRect.init(x: 0, y: 0, width: ZYScreenWidth, height: ZYScreenHeight)
                    videoPlayView.backgroundColor = UIColor.init(white: 0, alpha: 1)
                }, completion: { (finish) in
                    
                })
                
                videoPlayView.tapClosure = {(_ tap:UITapGestureRecognizer) in
                    UIView.animate(withDuration: 0.25, animations: {
                        videoPlayView.frame = frameRelativeToWindow
                        videoPlayView.backgroundColor = UIColor.init(white: 0, alpha: 0)
                    }) { (finish) in
                        videoPlayView.player.pause()
                        videoPlayView.removeFromSuperview()
                    }
                };
                
            })
            /*-------------------------------------------------*/
            
            group.leave()
        }
        
        /*任务都完成之后，得到通知*/
        group.notify(queue: DispatchQueue.main, execute: {
            self.hideLoadingView()
            if self.photoAlbumDelegate != nil {
                if self.photoAlbumDelegate!.responds(to: #selector(ZYPhotoAlbumProtocol.photoAlbum(selectPhotoAssets:))){
                    self.photoAlbumDelegate?.photoAlbum!(selectPhotoAssets: [phAsset])
                }
                if self.photoAlbumDelegate!.responds(to: #selector(ZYPhotoAlbumProtocol.photoAlbum(selectPhotos:))) {
                    self.photoAlbumDelegate?.photoAlbum!(selectPhotos: selectPhotos)
                }
            }
            //self.dismiss(animated: true, completion: nil)
        })
        
    }
    
}


/*---------------------------------*/
class VideoPlayView: UIView {
    
    var player: AVPlayer! = nil
    var tapClosure : ((_ tap:UITapGestureRecognizer)->Void)! = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(VideoPlayView.tapGestureAction(tap:))))
        self.isUserInteractionEnabled = true;
    }
    
    @objc func tapGestureAction(tap:UITapGestureRecognizer) -> Void {
        if tapClosure != nil {
            tapClosure(tap)
        }
    }
    
    var layerOfVideo:AVPlayerLayer! = nil
    
    func makeViewToPlay(url:URL){
        //1.获取URL(远程/本地)
        let item = AVPlayerItem.init(url: url)
        //2.创建AVPlayer
        self.player = AVPlayer.init(playerItem: item)
        //添加AVPlayerLayer
        let layer = AVPlayerLayer.init(player: self.player)
        self.layer.addSublayer(layer);self.layerOfVideo = layer;
        //---------------------
        self.player.play()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layerOfVideo.frame = CGRect.init(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
